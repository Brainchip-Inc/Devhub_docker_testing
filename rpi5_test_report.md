# Raspberry Pi 5 test report: Akida Docker image `ubuntu24.04-cpu-aarch64`

REQ-TOOL-005 / AK-7557. Tester: Ali Kayyam. Date: 2026-10-29.
Full detail: `report.md` section 4d. Evidence: `evidence/rpi5/`.

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
- `ubuntu22.04-cpu-aarch64`
- Power measurement (the Pi has no I2C power sensor)
- Training notebooks (the aarch64 image is inference-only)

## Note for anyone using this Pi

The Pi kills all running containers whenever anyone logs in over SSH (a login hook, by design, so demos don't conflict on the board). Use one session at a time. This is a property of the machine and not of the image.
