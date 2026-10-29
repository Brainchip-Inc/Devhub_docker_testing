# Devhub Docker testing

Internal beta test of the official Akida Docker images with DevHub pre-installed
(REQ-TOOL-005, Jira [AK-7557](https://brainchip.atlassian.net/browse/AK-7557)).

**Status: interim.** Two GPU images were tested on a host with no Akida board. `ubuntu24.04-cpu-aarch64`
was tested on a Raspberry Pi 5 with an AKD1500 board (branch `test/rpi5-aarch64-images`). The other CPU
images, the driver installer and the Secure Boot flow are not yet tested.

## What is here

| File | What it is |
|------|------------|
| [report.md](report.md) | The test report: summary, acceptance criteria, notebook results, 26 findings, documentation fixes, recommendations and the full test log. **Start here.** |
| [plan.md](plan.md) | The test plan: objectives, phases, and facts taken from AK-7557. |
| [evidence/rpi5/](evidence/rpi5/) | Raspberry Pi 5 run: results table, notebook run logs, device checks, and the scripts used. Executed notebooks are not copied (internal content). |
| [jira_comment_draft.md](jira_comment_draft.md) | Draft feedback comment for AK-7557. It is a draft and has not been posted. |

The documents under test (USER_GUIDE and the READMEs in `akida_docker/metatf_public_images`) are
internal-only and are **not** copied into this repo. The report names the versions that were reviewed.

## Results at a glance

Tested: `akida-devhub:ubuntu24.04-gpu-x86` (in depth) and `ubuntu22.04-gpu-x86`, on a Linux host
with 2x NVIDIA A30 and no Akida board.

- **Works:** pull and start, GPU access without `--privileged`, JupyterLab with token, DevHub at
  the pinned commit, one full training notebook (`plant_village`), and 5 of 6 benchmark and
  evaluation notebooks. Results on the 22.04 image match the 24.04 image.
- **Major issues (5, proposed):** the guide's step 2 and step 4 use different image names so `docker run`
  fails (DOC-1); `vww_notebook_benchmark` fails because its dataset is missing (NB-1); no no-board
  or GPU path in the guide (DOC-3, DOC-4); wrong notebook folder in the build README (DOC-13).
- **Raspberry Pi 5 + AKD1500 (`ubuntu24.04-cpu-aarch64`):** the board is visible in the container, also
  without `--privileged` (only `--device /dev/akd1500_0`). 5 of 6 benchmark and evaluation notebooks pass
  with their hardware cells running on the board. `vww` fails as on x86 (NB-1). New: `speech_commands`
  accuracy is 0.9024 on the board against 0.9306 on the software device (NB-4). Power was not measured.
  The test Pi kills running containers on every SSH login, so use one session at a time.
- **Not tested:** the driver installer, the Secure Boot flow, boards in x86 hosts, `ubuntu22.04-cpu-aarch64`,
  the CPU x86 images, power measurement, and the other training notebooks. Those are reported as
  **not tested**, not as passed.

See [report.md](report.md) for evidence, severities and suggested fixes.

## How the tests were run

Replace `<registry>` with the internal registry that holds the images. Use the **full** image name
in every command, because a pull does not create the short name (DOC-1).

```bash
# Host checks
nvidia-smi; docker info | grep -i runtimes

# Pull
docker pull <registry>/akida-devhub:ubuntu24.04-gpu-x86

# GPU smoke test, no board, not privileged. Jupyter is bound to localhost only.
docker run -d --gpus all -p 127.0.0.1:8888:8888 --name akida-dev \
    <registry>/akida-devhub:ubuntu24.04-gpu-x86
docker logs akida-dev        # the token URL is printed here

# Run a notebook headlessly (timeout disabled, executed copy kept in /tmp/executed)
docker exec -w /workspace akida-dev jupyter nbconvert --to notebook --execute \
    --ExecutePreprocessor.timeout=-1 --output-dir /tmp/executed \
    brainchip_devhub/akida1/model_zoo/plant_village/plant_village_notebook_benchmark.ipynb

# Clean up (this deletes anything you saved inside the container)
docker rm -f akida-dev
```

Expect first runs to download datasets from the internet. In the tests, 5 to 35 minutes per notebook,
and about 14 GB in the container after four notebooks (DOC-20).

## Rules for the report

- Only what was actually run and observed is recorded.
- Anything not run is marked **Not tested**.
- Severities are proposed, for the image and document owners to confirm.
- Notebook issues belong in [AK-7601](https://brainchip.atlassian.net/browse/AK-7601), everything
  else in AK-7557.

## Contacts

- Requested by: Tharak Krishnan
- Images built by: Tejaswini Dasika and Kevin Tsiknos
- Testers: Ali Kayyam and Douglas McLelland (Douglas's results are not in this report yet)
