#!/usr/bin/env bash
# Runs on the Pi in ONE ssh session (a second login kills the containers, see the Pi report).
I=bender:5000/akida-devhub:ubuntu22.04-cpu-aarch64
OUT=/tmp/akida22_out; rm -rf $OUT; mkdir -p $OUT/logs $OUT/executed
P() { echo "[$(date -u +%T)] $*"; }
P "host $(hostname) | $(uname -r) | disk_free=$(df -h / | tail -1 | awk '{print $4}') | start"
cat > /tmp/check_inside.sh <<'CHK'
#!/usr/bin/env bash
# Runs inside an akida-devhub container. Prints facts only; modifies nothing outside /tmp.
echo "=== OS / user ==="; . /etc/os-release; echo "$PRETTY_NAME | $(whoami) uid=$(id -u) gid=$(id -g) groups=$(id -G) | arch $(uname -m) | python $(python --version 2>&1 | cut -d' ' -f2)"
echo "=== devhub ==="; git -C /workspace/brainchip_devhub rev-parse HEAD; echo "status: [$(git -C /workspace/brainchip_devhub status --short | head -3)]"
echo "akida1: $(ls /workspace/brainchip_devhub/akida1 | tr '\n' ' ')| akida2: $(ls /workspace/brainchip_devhub/akida2 | tr '\n' ' ')"
echo "=== key packages ==="; pip list 2>/dev/null | grep -iE "^(akida|akida[-_]models|cnn2snn|quantizeml|metatf|tensorflow|keras|jupyterlab) " | sed 's/  */ /g'
echo "=== pip check ==="; pip check 2>&1 | tail -4
echo "=== device node visible ==="; ls -l /dev | grep -iE "akd|akida"
echo "=== akida devices ==="; akida devices 2>&1 | tail -5
echo "=== python view ==="
python -I - <<'PY' 2>&1 | grep -vE 'cuda|computation_placer|absl::InitializeLog|cpu_feature_guard|rebuild TensorFlow|^[EWI]0000|^20[0-9-]+ [0-9:.]+: [IWE]'
import akida
devs = akida.devices()
print("akida", akida.__version__, "| devices:", [d.desc for d in devs])
for d in devs:
    print("  ip_version:", d.version, "| NPs:", len(d.mesh.nps) if hasattr(d.mesh, "nps") else "?")
PY
echo "=== jupyter token check (inside container) ==="
python -I - <<'PY'
import urllib.request, urllib.error
try:
    r = urllib.request.urlopen("http://127.0.0.1:8888/api/contents"); print("no token:", r.status)
except urllib.error.HTTPError as e: print("no token:", e.code)
except Exception as e: print("no token: error", e)
PY
CHK
s=$(date +%s); docker pull $I 2>&1 | tail -2; P "PULL $(( $(date +%s) - s ))s | disk_free=$(df -h / | tail -1 | awk '{print $4}')"
docker image inspect $I --format 'ID={{.Id}} size={{.Size}} created={{.Created}} arch={{.Architecture}} cmd={{.Config.Cmd}} entrypoint={{.Config.Entrypoint}} user={{.Config.User}} labels={{.Config.Labels}} digest={{index .RepoDigests 0}}'

P "== Test A: guide flags (--privileged -v /dev:/dev), default user"
docker run --rm --privileged -v /dev:/dev $I python -c "import akida; print(akida.devices())" 2>&1 | grep "devices found\|^\[" 
P "== Test B: narrow --device /dev/akd1500_0, default user"
docker run --rm --device /dev/akd1500_0 $I python -c "import akida; print(akida.devices())" 2>&1 | grep "devices found\|^\["
P "== Banner on stdout? (DOC-24): capture of 'id' via docker run"
docker run --rm $I id 2>/dev/null | head -4

P "== default CMD start + contents check"
docker rm -f akida-chk >/dev/null 2>&1
docker run -d --name akida-chk --device /dev/akd1500_0 $I >/dev/null; sleep 40
P "container: $(docker inspect akida-chk --format '{{.State.Status}}')"
docker logs akida-chk 2>&1 | grep -E "token=|devices found|GPUs visible" | head -4 | sed 's/token=[0-9a-f]*/token=<redacted>/'
docker cp /tmp/check_inside.sh akida-chk:/tmp/check_inside.sh
docker exec akida-chk bash /tmp/check_inside.sh > $OUT/check.log 2>&1; cat $OUT/check.log
docker rm -f akida-chk >/dev/null 2>&1

Z=brainchip_devhub/akida1/model_zoo
printf 'notebook\texit\tseconds\n' > $OUT/results.tsv
for nb in imagenet_akidanet/imagenet_akidanet_notebook_evaluation arrhythmia_classification/arrhythmia_notebook_benchmark plant_village/plant_village_notebook_benchmark speech_commands/speech_commands_notebook_benchmark imagenet_akidanet/imagenet_akidanet_notebook_benchmark; do
  name=$(basename $nb); free=$(df -BG / | tail -1 | awk '{gsub("G","",$4); print $4}')
  if [ "$name" = speech_commands_notebook_benchmark ] && [ "$free" -lt 13 ]; then P "SKIP $name: only ${free}G free"; printf '%s\tskipped\t0\n' $name >> $OUT/results.tsv; continue; fi
  C=akida22-$$-nb; docker rm -f $C >/dev/null 2>&1
  docker run -d --name $C --device /dev/akd1500_0 $I sleep infinity >/dev/null || { P "START FAILED $name"; continue; }
  sleep 5; P "START $name | disk_free=${free}G"; t0=$(date +%s)
  docker exec $C mkdir -p /tmp/executed
  docker exec -w /workspace $C timeout 5400 jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=-1 --output-dir /tmp/executed $Z/$nb.ipynb > $OUT/logs/$name.log 2>&1
  rc=$?; s=$(( $(date +%s) - t0 ))
  state=$(docker inspect $C --format '{{.State.Status}} exit={{.State.ExitCode}}')
  docker cp $C:/tmp/executed/. $OUT/executed/ 2>/dev/null
  printf '%s\t%s\t%s\n' $name $rc $s >> $OUT/results.tsv
  P "DONE  $name exit=$rc ${s}s container=[$state] disk_in_container=$(docker exec $C du -sh /home/akida 2>/dev/null | cut -f1)"
  docker rm -f $C >/dev/null 2>&1; P "removed | disk_free=$(df -h / | tail -1 | awk '{print $4}')"
done
P "== results =="; cat $OUT/results.tsv
echo "---TARBEGIN---"; tar -C $OUT -cz executed logs results.tsv check.log | base64; echo "---TAREND---"
P "finished | disk_free=$(df -h / | tail -1 | awk '{print $4}')"
