#!/usr/bin/env bash
# Usage: run_image.sh <tag> <notebook-list-name>. Runs on orion in ONE session. Board must be claimed (akq).
TAG=$1; SET=$2
I=172.17.0.39:5000/akida-devhub:$TAG
OUT=$HOME/akida_test/$TAG; mkdir -p $OUT
C=akida-t-${TAG//[^a-zA-Z0-9]/-}
docker rm -f $C >/dev/null 2>&1
echo "[$TAG] image: $(docker image inspect $I --format 'size={{.Size}} created={{.Created}} cmd={{.Config.Cmd}} entrypoint={{.Config.Entrypoint}} user={{.Config.User}} labels={{.Config.Labels}}')"
docker run -d --name $C --group-add 0 --device /dev/akd1500_0 -p 127.0.0.1:0:8888 $I >/dev/null || { echo "START FAILED"; exit 1; }
sleep 25
echo "[$TAG] container: $(docker inspect $C --format '{{.State.Status}}') started $(date -u +%FT%TZ)"
docker logs $C 2>&1 | grep -E "token=|devices found|GPUs visible" | head -4 | sed 's/token=[0-9a-f]*/token=<redacted>/'
docker cp /tmp/check_inside.sh $C:/tmp/check_inside.sh
docker exec $C bash /tmp/check_inside.sh > $OUT/check.log 2>&1; cat $OUT/check.log
case $SET in
 full) NBS="imagenet_akidanet/imagenet_akidanet_notebook_benchmark imagenet_akidanet/imagenet_akidanet_notebook_evaluation speech_commands/speech_commands_notebook_benchmark vww/vww_notebook_benchmark plant_village/plant_village_notebook_benchmark arrhythmia_classification/arrhythmia_notebook_benchmark";;
 part) NBS="imagenet_akidanet/imagenet_akidanet_notebook_evaluation plant_village/plant_village_notebook_benchmark arrhythmia_classification/arrhythmia_notebook_benchmark";;
esac
docker exec $C mkdir -p /tmp/logs /tmp/executed
printf 'notebook\texit\tseconds\n' > $OUT/results.tsv
for nb in $NBS; do
  name=$(basename $nb); t0=$(date +%s); echo "[$TAG] START $name $(date -u +%T)"
  docker exec -w /workspace $C timeout 5400 jupyter nbconvert --to notebook --execute \
    --ExecutePreprocessor.timeout=-1 --output-dir /tmp/executed brainchip_devhub/akida1/model_zoo/$nb.ipynb > $OUT/$name.log 2>&1
  rc=$?; s=$(( $(date +%s) - t0 ))
  printf '%s\t%s\t%s\n' "$name" "$rc" "$s" >> $OUT/results.tsv
  echo "[$TAG] DONE  $name exit=$rc ${s}s disk_free=$(df -h / | tail -1 | awk '{print $4}')"
done
mkdir -p $OUT/executed; docker cp $C:/tmp/executed/. $OUT/executed/
echo "[$TAG] disk in container: $(docker exec $C du -sh /home/akida /workspace 2>/dev/null | tr '\n' ' ')"
docker rm -f $C >/dev/null 2>&1; echo "[$TAG] container removed $(date -u +%FT%TZ)"
