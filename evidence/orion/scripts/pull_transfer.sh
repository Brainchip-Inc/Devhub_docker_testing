#!/bin/bash
# Pull each image here (timed), then stream it to orion. Logs to pull_transfer.log
R=172.17.0.39:5000/akida-devhub
for t in ubuntu24.04-cpu-x86 ubuntu22.04-cpu-x86; do
  s=$(date +%s); docker pull $R:$t 2>&1 | tail -2; e=$(date +%s)
  echo "PULL $t $((e-s))s"
  docker image inspect $R:$t --format "ID={{.Id}} size={{.Size}} created={{.Created}} digest={{index .RepoDigests 0}}"
  s=$(date +%s); docker save $R:$t | ssh -o BatchMode=yes <user>@<orion> docker load 2>&1 | tail -2; e=$(date +%s)
  echo "TRANSFER $t $((e-s))s"
done
echo ALLDONE
