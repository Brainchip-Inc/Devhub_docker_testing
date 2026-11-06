# Raspberry Pi 5 test report: Akida Docker images `ubuntu24.04-cpu-aarch64` and `ubuntu22.04-cpu-aarch64`

REQ-TOOL-005 / AK-7557. Tester: Ali Kayyam. Dates: 2026-10-29 (24.04), 2026-11-05 (22.04).
Full detail: `report.md` sections 4d and 4d-2. Evidence: `evidence/rpi5/` (24.04) and `evidence/rpi5/ubuntu22.04/`.
The first half of this file is the 24.04 image. The 22.04 image is in the section "Image `ubuntu22.04-cpu-aarch64`" below.

## Result

**Works on a Raspberry Pi 5 with an AKD1500 board.** The board is visible in the container, and 5 of 6 benchmark and evaluation notebooks pass with their hardware cells running on the board. One accuracy difference (NB-4) needs an owner's view.

## What was tested

| Item | Value |
|------|-------|
| Image | `akida-devhub:ubuntu24.04-cpu-aarch64`, ID `15c17289d5f5`, 4.1 GB |
| Host | Raspberry Pi 5 Model B, 4 cores, 7.8 GB RAM, 29 GB SD card, Ubuntu 24.04, Docker 27.0.3 |
| Board | `PCIe/AKD1500/16MB/0`, 32 NPs. Host driver `akida_pcie` was already loaded. |
| Registry | `bender:5000` (resolves to `172.17.0.39`, so the two names are the same registry) |

## Results

| Check | Result |
|-------|--------|
| Pull | Pass, 267 s |
| Container contents | Pass. akida 2.19.3, DevHub at the pinned commit `8be7c232`, same package versions as the x86 image. Same `pip check` conflict (`akida_models` 1.14.0 vs 1.14.2, DOC-19). |
| Board visible, guide's flags (`--privileged -v /dev:/dev`) | Pass |
| Board visible, narrow flag (`--device /dev/akd1500_0`, not privileged) | Pass, identical output |

Notebooks (headless, run on the board, one at a time):

| Notebook | Result | Time | Key numbers |
|----------|--------|------|-------------|
| `imagenet_akidanet_notebook_benchmark` | Pass | 454 s | 142.9 ms per inference (133.5 ms on chip) |
| `imagenet_akidanet_notebook_evaluation` | Pass | 107 s | 10-image smoke test (100%), no hardware cells |
| `speech_commands_notebook_benchmark` | Pass | 1374 s | Accuracy 0.9024 (see NB-4). 0.37 ms per inference |
| `plant_village_notebook_benchmark` | Pass | 724 s | Accuracy 0.9943. 97.6 ms per inference |
| `arrhythmia_notebook_benchmark` | Pass | 424 s | Accuracy 0.9577. 2.49 ms per inference |
| `vww_notebook_benchmark` | **Fail** | 13 s | Dataset missing, same as NB-1 on x86 |

No error cells in the five passing notebooks.

## Findings (proposed severity)

- **NB-4 (Minor, needs an owner's view):** `speech_commands` accuracy is 0.9024 on the board against 0.9306 on the software device (x86). `plant_village` and `arrhythmia` match exactly. The cause is unknown. A check of both on the same data in one session would settle it.
- **DOC-5 (resolved):** the guide's `--privileged -v /dev:/dev` is not needed. `--device /dev/akd1500_0` is enough. Recommend the narrower form.
- **DOC-22 (Minor):** the guide gives no disk requirement. Free space on the SD card fell from 22 GB to 4.3 GB after the pull and the six notebooks (`speech_commands` alone about 11 GB).
- **NB-1 (Major, already known):** `vww` dataset missing. Reproduces on aarch64.

## Not tested

- Driver installer and Secure Boot flow (the driver was already loaded on the Pi)
- `plant_village` on `ubuntu22.04-cpu-aarch64` (its dataset download failed, see below)
- A same-session check of board against software accuracy on the Pi (NB-4)
- Power measurement (the Pi has no I2C power sensor)
- Training notebooks (the aarch64 image is inference-only)

## Image `ubuntu22.04-cpu-aarch64` (2026-11-05)

### Result

**Works on the same Pi and board.** The board is visible with both flag sets, and **4 of 5** notebooks pass with their hardware cells on the board. `plant_village` did not complete because its dataset download failed twice (NB-5). `vww` was not run. Timings match the 24.04 image. Accuracy differs for `speech_commands` (0.8753, NB-4) and, slightly, for `arrhythmia` (0.9584).

### What was tested

| Item | Value |
|------|-------|
| Image | `akida-devhub:ubuntu22.04-cpu-aarch64`, ID `f0ef35ea12ea`, digest `sha256:0e3fd291...57c9`, 3.86 GB, built 2026-11-02, Python 3.10.12, Keras 3.12.4, JupyterLab 4.6.5 |
| Host and board | As above (same Pi, same `PCIe/AKD1500/16MB/0`) |
| Pull | 258 s (2026-11-03) |
| History | The first attempt (2026-11-03) was cut off when the Pi stopped responding, and the Pi was offline for about two days. After it rebooted the whole test was rerun from the start on 2026-11-05. Only the rerun is reported. |

### Results

| Check | Result |
|-------|--------|
| Container contents | Pass. akida 2.19.3, DevHub at `8be7c232`, same `pip check` conflict (DOC-19), 403 without the Jupyter token. |
| Board visible, guide's flags | Pass (1 device) |
| Board visible, `--device /dev/akd1500_0` only | Pass (1 device) |

| Notebook | Result | Time | Key numbers |
|----------|--------|------|-------------|
| `imagenet_akidanet_notebook_evaluation` | Pass | 187 s | 10-image smoke test (100%) |
| `arrhythmia_notebook_benchmark` | Pass | 404 s | Accuracy 0.9584. 2.484 ms per inference |
| `plant_village_notebook_benchmark` | **Did not complete** | 854 s, retry 1206 s | Dataset download from `data.mendeley.com` broke twice (`IncompleteRead`) |
| `speech_commands_notebook_benchmark` | Pass | 1752 s | Accuracy 0.8753 (NB-4). 0.374 ms per inference |
| `imagenet_akidanet_notebook_benchmark` | Pass | 518 s | 142.8 ms per inference (133.4 ms on chip) |
| `vww_notebook_benchmark` | Not run | | |

No error outputs in the four passing notebooks. Power was not measured.

### Comparison with other runs of the same notebooks

| Notebook | 24.04, Pi | 22.04, Pi | 24.04, x86 + board | 22.04, x86 + board |
|----------|-----------|-----------|--------------------|--------------------|
| `arrhythmia` accuracy | 0.9577 | 0.9584 | 0.9577 | 0.9584 |
| `speech_commands` accuracy | 0.9024 | 0.8753 | 0.9306 | not run |

Timings, on-chip clock counts and sparsity are identical between the two Pi images. The `arrhythmia` difference follows the image's OS, not the machine. The `speech_commands` difference does not: the Pi gives two different values and the x86 host gives a third.

### New and changed findings

- **NB-4 (Minor, widened):** the Pi gives 0.9024 and 0.8753 for `speech_commands` with two different images, and x86 with a board gives 0.9306. Next step: software and board on the same data in one session on the Pi, and the validation sample counts.
- **NB-5 (Minor, new):** the `plant_village` dataset (868 MB) comes from `data.mendeley.com`. From the Pi two attempts broke (58 MB and 36 MB read), and a plain `curl` moved 25 MB in 15 minutes (about 28 KB/s). Other datasets downloaded fine. It worked on this Pi on 2026-10-29. Suggest a BrainChip mirror, as for `imagenet_like`, or a retry in the notebook. Not known: whether the cause is today's route from the Pi or throttling at Mendeley.

## Note for anyone using this Pi

The Pi kills all running containers whenever anyone logs in over SSH (a login hook, by design, so demos don't conflict on the board). Use one session at a time. This is a property of the machine and not of the image.
