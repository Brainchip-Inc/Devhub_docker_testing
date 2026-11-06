# Devhub Docker testing

Internal beta test of the official Akida Docker images with DevHub pre-installed
(REQ-TOOL-005, Jira [AK-7557](https://brainchip.atlassian.net/browse/AK-7557)).

**Status: interim.** Two GPU images were tested on a host with no Akida board, and the two x86 CPU
images were tested with an AKD1500 board. The two aarch64 images were tested on a Raspberry Pi 5 with
an AKD1500 board, and their results are on a separate branch (see the table below). The floating tags
have been rebuilt since the first tests, so check the digests in each report. Not yet tested: the PCIe
driver installer.

## Image status

Results come from three machines: a GPU host (2x NVIDIA A30, no board, used for the GPU images and
training), `orion` (x86, no GPU, with an AKD1500 board, used for the x86 CPU images) and a Raspberry Pi 5
with an AKD1500 board. The six images in scope are the floating tags of `akida-devhub`. The versioned
`2.19.3-` tags are internal CI images and are not tested here.

| Image | Tested? | Machine | Board? | Result | Where |
|-------|---------|---------|--------|--------|-------|
| `ubuntu24.04-gpu-x86` | Yes, in depth (build of 2026-10-14) | GPU host (2x A30) | No | Works with workarounds. One training notebook and 5 of 6 notebooks pass. `vww` fails (NB-1). | `main`: [report.md](report.md) |
| `ubuntu22.04-gpu-x86` | Yes, partly (build of 2026-10-14) | GPU host | No | 3 notebooks and the quantize and convert steps pass, matching 24.04. No training notebook was run. | `main`: [report.md](report.md), section 4c |
| `ubuntu24.04-cpu-x86` | Yes (build of 2026-11-02) | `orion` | Yes, AKD1500 | 5 of 6 notebooks pass on the board. `vww` fails (NB-1). Needs `--group-add 0` (DOC-23). | `main`: [report.md](report.md) section 4e, [orion_x86_board_test_report.md](orion_x86_board_test_report.md) |
| `ubuntu22.04-cpu-x86` | Yes, partly (build of 2026-11-02) | `orion` | Yes, AKD1500 | 3 notebooks run, all pass. The other 3 were not run. Needs `--group-add 0` (DOC-23). | `main`: same as above |
| `ubuntu24.04-cpu-aarch64` | Yes (older build, pulled 2026-10-29) | Raspberry Pi 5 | Yes, AKD1500 | 5 of 6 notebooks pass. `vww` fails. `speech_commands` accuracy 0.9024 against 0.9306 on x86 (NB-4). | Branch [`test/rpi5-aarch64-images`](https://github.com/Brainchip-Inc/Devhub_docker_testing/tree/test/rpi5-aarch64-images), not yet merged: `rpi5_test_report.md`, `report.md` section 4d |
| `ubuntu22.04-cpu-aarch64` | Yes, partly (build of 2026-11-02, tested 2026-11-05) | Raspberry Pi 5 | Yes, AKD1500 | 4 of 5 notebooks pass on the board. `plant_village` did not complete: its dataset download from `data.mendeley.com` broke twice (NB-5). `vww` not run. `speech_commands` accuracy 0.8753 (NB-4). | Branch [`test/rpi5-aarch64-images`](https://github.com/Brainchip-Inc/Devhub_docker_testing/tree/test/rpi5-aarch64-images), not yet merged: `rpi5_test_report.md`, `report.md` section 4d-2 |
| `akida-pcie-driver-installer` (24.04 and 22.04) | **No** | | | | Needs a fresh machine with a board, and its README |

All six images have been run, and four of them only partly. The PCIe driver installer has not. The GPU
images and `ubuntu24.04-cpu-aarch64` have been rebuilt since they were tested, so those results describe
the older builds. The findings from the Pi runs (NB-4, NB-5, DOC-22) are in the Pi branch's `report.md`,
not in the `report.md` on `main`, until the branch is merged.

## What is here

| File | What it is |
|------|------------|
| [report.md](report.md) | The test report: summary, acceptance criteria, notebook results, 26 findings, documentation fixes, recommendations and the full test log. **Start here.** |
| [orion_x86_board_test_report.md](orion_x86_board_test_report.md) | The two x86 CPU images run with an AKD1500 board: notebook results and two new findings (DOC-23: the container user cannot open the board by default, DOC-24: entrypoint banner). Evidence in [evidence/orion/](evidence/orion/). |
| [plan.md](plan.md) | The test plan: objectives, phases, and facts taken from AK-7557. |
| [jira_comment_draft.md](jira_comment_draft.md) | Draft feedback comment for AK-7557. It is a draft and has not been posted. |

The documents under test (USER_GUIDE and the READMEs in `akida_docker/metatf_public_images`) are
internal-only and are **not** copied into this repo. The report names the versions that were reviewed.

## Results at a glance

Tested on three machines (the third, a Raspberry Pi 5, is described on its branch):

- **GPU host** (2x NVIDIA A30, no Akida board): `akida-devhub:ubuntu24.04-gpu-x86` (in depth, including
  a training notebook) and `ubuntu22.04-gpu-x86`.
- **`orion`** (x86, no GPU, AKD1500 board): `ubuntu24.04-cpu-x86` and `ubuntu22.04-cpu-x86`.
- **Raspberry Pi 5** (aarch64, AKD1500 board): `ubuntu24.04-cpu-aarch64` and `ubuntu22.04-cpu-aarch64`
  (branch `test/rpi5-aarch64-images`).

- **Works (GPU host):** pull and start, GPU access without `--privileged`, JupyterLab with token,
  DevHub at the pinned commit, one full training notebook (`plant_village`), and 5 of 6 benchmark
  and evaluation notebooks. Results on the 22.04 image match the 24.04 image.
- **Major issues (6, proposed):** the guide's step 2 and step 4 use different image names so `docker run`
  fails (DOC-1); `vww_notebook_benchmark` fails because its dataset is missing (NB-1); no no-board
  or GPU path in the guide (DOC-3, DOC-4); wrong notebook folder in the build README (DOC-13);
  the container user cannot open the board by default (DOC-23).
- **With a board (x86 CPU images):** both find the board and run the notebooks on it, but only as
  root or with an extra `--group-add 0`. With the guide's flags the container user sees no board and
  nothing says why (DOC-23, proposed Major).
- **With a board (Raspberry Pi 5, branch `test/rpi5-aarch64-images`):** both aarch64 images find the
  board, also with only `--device /dev/akd1500_0`. Benchmark notebooks run on the board: 5 of 6 on 24.04
  and 4 of 5 on 22.04. Timings are identical between the two images. `speech_commands` accuracy on the
  board varies: 0.9024 (24.04, Pi), 0.8753 (22.04, Pi) and 0.9306 (x86 with a board), which is open
  (NB-4). The `plant_village` dataset download from `data.mendeley.com` fails from the Pi (NB-5).
- **Not tested:** the PCIe driver installer, the GPU images with a board, `plant_village` on
  `ubuntu22.04-cpu-aarch64`, and the other training notebooks. Those are reported as **not tested**, not as passed.

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
