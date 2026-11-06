#!/usr/bin/env bash
I=bender:5000/akida-devhub:ubuntu22.04-cpu-aarch64
OUT=/tmp/akida22_pv; rm -rf $OUT; mkdir -p $OUT/logs $OUT/executed
P() { echo "[$(date -u +%T)] $*"; }
Z=brainchip_devhub/akida1/model_zoo; name=plant_village_notebook_benchmark; C=akida22-pv
docker rm -f $C >/dev/null 2>&1
docker run -d --name $C --device /dev/akd1500_0 $I sleep infinity >/dev/null; sleep 5
P "START $name | disk_free=$(df -h / | tail -1 | awk '{print $4}')"; t0=$(date +%s)
docker exec $C mkdir -p /tmp/executed
docker exec -w /workspace $C timeout 5400 jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=-1 --output-dir /tmp/executed $Z/plant_village/$name.ipynb > $OUT/logs/$name.log 2>&1
rc=$?; s=$(( $(date +%s) - t0 ))
docker cp $C:/tmp/executed/. $OUT/executed/ 2>/dev/null
printf 'notebook\texit\tseconds\n%s\t%s\t%s\n' $name $rc $s > $OUT/results.tsv
P "DONE $name exit=$rc ${s}s"; docker rm -f $C >/dev/null 2>&1
echo "---TARBEGIN---"; tar -C $OUT -cz executed logs results.tsv | base64; echo "---TAREND---"
P finished
