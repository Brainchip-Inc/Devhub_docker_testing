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
