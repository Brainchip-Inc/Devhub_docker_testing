#!/usr/bin/env bash
I=bender:5000/akida-devhub:ubuntu22.04-cpu-aarch64
P() { echo "[$(date -u +%T)] $*"; }
P "find URL"
URL=$(docker run --rm $I python -I -c "
import tensorflow_datasets as tfds
b=tfds.builder('plant_village')
print(list(b.url_infos.keys())[0] if b.url_infos else '')" 2>/dev/null | tail -1)
echo "URL=$URL"
[ -z "$URL" ] && { P "no url"; exit 1; }
host=$(echo $URL | awk -F/ '{print $3}')
P "dns/route: $(getent hosts $host | head -1)"
P "curl download start"
timeout 900 curl -L -sS -o /tmp/pv.bin -w 'http=%{http_code} size=%{size_download} speed=%{speed_download}B/s time=%{time_total}s exit-ok\n' "$URL"; echo "curl rc=$?"
ls -l /tmp/pv.bin; rm -f /tmp/pv.bin
P finished
