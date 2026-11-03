# Devhub Docker testing

Internal beta test of the official Akida Docker images with DevHub pre-installed
(REQ-TOOL-005, Jira [AK-7557](https://brainchip.atlassian.net/browse/AK-7557)).

**Status: interim.** Two GPU images were tested on a host with no Akida board, and the two x86 CPU
images were tested with an AKD1500 board. The Raspberry Pi image is on a separate branch (see the
table below). The floating tags have been rebuilt since the first tests, so check the digests in each
report. Not yet tested: `ubuntu22.04-cpu-aarch64` and the PCIe driver installer.

## Image status

The six images in scope are the floating tags of `akida-devhub`. The versioned `2.19.3-` tags are
internal CI images and are not tested here.

| Image | Tested? | Where the results are |
|-------|---------|-----------------------|
| `ubuntu24.04-gpu-x86` | Yes, in depth (no board) | `main`: [report.md](report.md) |
| `ubuntu22.04-gpu-x86` | Yes, partly (no board) | `main`: [report.md](report.md), section 4c |
| `ubuntu24.04-cpu-aarch64` | Yes, on a Raspberry Pi 5 with an AKD1500 board | Branch [`test/rpi5-aarch64-images`](https://github.com/Brainchip-Inc/Devhub_docker_testing/tree/test/rpi5-aarch64-images), not yet merged |
| `ubuntu24.04-cpu-x86` | Yes, on an x86 host with an AKD1500 board (5 of 6 notebooks pass) | `main`: [orion_x86_board_test_report.md](orion_x86_board_test_report.md) |
| `ubuntu22.04-cpu-x86` | Yes, partly, with the board (3 notebooks run, all pass) | `main`: [orion_x86_board_test_report.md](orion_x86_board_test_report.md) |
| `ubuntu22.04-cpu-aarch64` | No | Not started |

The PCIe driver installer images (`akida-pcie-driver-installer`) are not tested either.

## What is here

| File | What it is |
|------|------------|
| [report.md](report.md) | The test report: summary, acceptance criteria, notebook results, 24 findings, documentation fixes, recommendations and the full test log. **Start here.** |
| [orion_x86_board_test_report.md](orion_x86_board_test_report.md) | The two x86 CPU images run with an AKD1500 board: notebook results and two new findings (DOC-23: the container user cannot open the board by default, DOC-24: entrypoint banner). Evidence in [evidence/orion/](evidence/orion/). |
| [plan.md](plan.md) | The test plan: objectives, phases, and facts taken from AK-7557. |
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
- **With a board (x86 CPU images):** both find the board and run the notebooks on it, but only as
  root or with an extra `--group-add 0`. With the guide's flags the container user sees no board and
  nothing says why (DOC-23, proposed Major).
- **Not tested:** `ubuntu22.04-cpu-aarch64`, the PCIe driver installer, the GPU images with a board,
  and the other training notebooks. Those are reported as **not tested**, not as passed.

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
