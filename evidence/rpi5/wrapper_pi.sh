#!/usr/bin/env bash
# Runs on the Pi in ONE ssh session (a second login kills the container, see report).
I=bender:5000/akida-devhub:ubuntu24.04-cpu-aarch64
docker rm -f akida-rpi-nb >/dev/null 2>&1
docker run -d --name akida-rpi-nb --device /dev/akd1500_0 $I sleep infinity >/dev/null || { echo "START FAILED"; exit 1; }
sleep 5
echo "container: $(docker inspect akida-rpi-nb --format '{{.State.Status}}') | started $(date -u +%FT%TZ)"
docker exec -i akida-rpi-nb bash -s <<'INNER'
Z=brainchip_devhub/akida1/model_zoo
mkdir -p /tmp/logs /tmp/executed
printf 'notebook\texit\tseconds\n' > /tmp/results.tsv
cd /workspace
( while true; do sleep 300; echo "  heartbeat $(date -u +%T) cur=$(cat /tmp/cur 2>/dev/null) disk_free=$(df -h / | tail -1 | awk '{print $4}') last: $(tail -c 160 /tmp/logs/$(cat /tmp/cur 2>/dev/null).log 2>/dev/null | tr '\n\r' '  ')"; done ) &
HB=$!
for nb in \
  imagenet_akidanet/imagenet_akidanet_notebook_benchmark.ipynb \
  imagenet_akidanet/imagenet_akidanet_notebook_evaluation.ipynb \
  speech_commands/speech_commands_notebook_benchmark.ipynb \
  vww/vww_notebook_benchmark.ipynb \
  plant_village/plant_village_notebook_benchmark.ipynb \
  arrhythmia_classification/arrhythmia_notebook_benchmark.ipynb ; do
  name=$(basename "$nb" .ipynb); echo "$name" > /tmp/cur; t0=$(date +%s)
  echo "START $name $(date -u +%T)"
  timeout 5400 jupyter nbconvert --to notebook --execute \
    --ExecutePreprocessor.timeout=-1 --output-dir /tmp/executed $Z/$nb > /tmp/logs/$name.log 2>&1
  rc=$?
  printf '%s\t%s\t%s\n' "$name" "$rc" "$(( $(date +%s) - t0 ))" >> /tmp/results.tsv
  echo "DONE  $name exit=$rc $(( $(date +%s) - t0 ))s disk_free=$(df -h / | tail -1 | awk '{print $4}')"
done
kill $HB 2>/dev/null
INNER
echo "== results =="; docker exec akida-rpi-nb cat /tmp/results.tsv
echo "== disk in container =="; docker exec akida-rpi-nb du -sh /home/akida /tmp /workspace 2>/dev/null
echo "---TARBEGIN---"; docker exec akida-rpi-nb tar -C /tmp -cz executed logs results.tsv | base64; echo "---TAREND---"
docker rm -f akida-rpi-nb >/dev/null 2>&1; echo "container removed $(date -u +%FT%TZ)"
