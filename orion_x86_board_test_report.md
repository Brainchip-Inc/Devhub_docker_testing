# x86 CPU images with an Akida AKD1500 board: test report

REQ-TOOL-005 / AK-7557. Tester: Ali Kayyam. Date: 2026-11-03.
Evidence: `evidence/orion/`. Earlier results (GPU images, no board): `report.md`.

## Result

**Both x86 CPU images work with an AKD1500 board, but only as root, or with an extra flag.** With the documented flags, a container started as the image's normal user does not see the board, and says nothing useful about why (DOC-23). With `--group-add 0` added, both images find the board and the notebooks run on it.

| Image | Result |
|-------|--------|
| `ubuntu24.04-cpu-x86` | 5 of 6 notebooks pass on the board. `vww` fails (dataset missing, NB-1). |
| `ubuntu22.04-cpu-x86` | 3 of 3 notebooks run pass on the board. The other three were not run. |

## What was tested

| Item | Value |
|------|-------|
| Images | `akida-devhub:ubuntu24.04-cpu-x86` (digest `sha256:6f3c566e...baa73`, built 2026-11-02 06:45 UTC) and `akida-devhub:ubuntu22.04-cpu-x86` (digest `sha256:aa46d20d...d0acc`, built 2026-11-02 06:56 UTC). Floating tags, as in the registry on 2026-11-03. |
| Host | Ubuntu 22.04.5, kernel 6.8.0-138, 16 cores, 30 GB RAM, Docker 29.5.2, no GPU |
| Board | `PCIe/AKD1500/16MB/0`, 32 NPs, ip_version BC.A1.003.009. Host driver `akida_pcie` already loaded. The host device node is `crw-rw----+ root root`, with access granted per user by the lab's `akq` tool. |
| Access | The board is shared. It was claimed with `akq claim` in a few sessions on 2026-11-03 (the first at 14:29 PST, the longest about 45 minutes) and released after each. |
| How the images got there | The host cannot reach the registry, and Docker there has no insecure-registry entry. The images were pulled on another host (pull time 150 s and 147 s) and sent with `docker save` and `docker load`. The pull times are therefore not from this host, and the digest was not re-checked after the transfer. |

## Results

Image contents (both images, identical to the earlier GPU images except where noted):

| Check | Result |
|-------|--------|
| Packages | akida, cnn2snn, metatf 2.19.3; quantizeml 1.2.5; akida_models 1.14.2; TensorFlow 2.19.1. Keras 3.15.1 (24.04) and 3.12.4 (22.04). JupyterLab 4.6.5. Python 3.12.3 and 3.10.12. |
| DevHub | Pinned commit `8be7c232`, clean tree |
| `pip check` | Same conflict as before: `brainchip-utils` wants `akida_models==1.14.0`, 1.14.2 is installed (DOC-19) |
| Image labels | **New in this build:** `com.brainchip.devhub-commit`, `com.brainchip.metatf-version`, `org.opencontainers.image.created` and `org.opencontainers.image.version`. The earlier GPU builds had only the version label (DOC-18), so DOC-18 looks fixed in this build. |
| Default start (JupyterLab) | Pass. 403 without the token. |
| Board visible as the image's user (UID 1000) | **Fail** with `--device /dev/akd1500_0` alone, and with the guide's `--privileged -v /dev:/dev`. **Pass** with `--group-add 0`, or as root. See DOC-23. |
| Board visible, `ubuntu24.04-cpu-x86`, with `--group-add 0` | Pass. `akida devices` lists `PCIe/AKD1500/16MB/0`. |

Notebooks (headless, on the board, one at a time, first run with dataset downloads):

| Notebook | 24.04 | 22.04 | Key numbers |
|----------|-------|-------|-------------|
| `imagenet_akidanet_notebook_benchmark` | Pass, 397 s | not run | 150.7 ms per inference (system clock) |
| `imagenet_akidanet_notebook_evaluation` | Pass, 31 s | Pass, 35 s | 10-image smoke test, 100% (DOC-21) |
| `speech_commands_notebook_benchmark` | Pass, 356 s | not run | Accuracy 0.9306. 0.361 ms per inference |
| `plant_village_notebook_benchmark` | Pass, 605 s | Pass, 606 s | Accuracy 0.9943 on both. 99.0 ms per inference |
| `arrhythmia_notebook_benchmark` | Pass, 256 s | Pass, 258 s | Accuracy 0.9577 (24.04) and 0.9584 (22.04). 2.47 ms per inference |
| `vww_notebook_benchmark` | **Fail**, 5 s | not run | `FileNotFoundError: './data/vw_coco2014_96'` (NB-1) |

No error cells in any passing notebook. The disk used by the six notebooks in the 24.04 container was about 13 GB.

The customer how-to's example script (`predict_demo.py`) also ran on the board with `--group-add 0`: 16 layers, `running on: PCIe/AKD1500/16MB/0`.

## Findings (proposed severity)

- **DOC-23 (Major, proposed): the image's user cannot open the board unless the host device node is world-accessible.** The image runs as UID 1000. Docker's `--device` creates a new node inside the container with the host's mode (here 0660, root) and without the host's ACL. So the container user cannot open it, and the result is `Akida devices found: 0` with no error. The guide's `--privileged -v /dev:/dev` has the same result here. Runs on this host (`ubuntu24.04-cpu-x86`):

  | Flags | Board found |
  |-------|-------------|
  | `--device /dev/akd1500_0`, default user | No (`open()` gives Permission denied) |
  | `--device`, `--user 1003:1004` (the host user named in the ACL) | No |
  | `--privileged -v /dev:/dev`, default user | No |
  | `--device`, `--user 0` | Yes |
  | `--device --group-add 0`, default user | Yes |

  The Raspberry Pi in the earlier test worked without extra flags only because its node was mode 666. The severity depends on what the PCIe driver installer sets by default, and its README was not supplied. If it does not make the node accessible to UID 1000, a customer on a normal host hits this. Suggested fix: say in the guide that the node must be accessible to the container user, and document a tested flag. `--group-add 0` works, but it adds the root group inside the container. Alternatively, the installer's udev rule could set a group or mode that the image user can use.

- **DOC-24 (Minor): the entrypoint banner.** Every `docker run <image> <command>` first prints `TensorFlow 2.19.1 - GPUs visible: N` and `akida 2.19.3 - Akida devices found: N` on stdout. This pollutes the output of scripted commands (it appeared in the captured output of `id`), adds about 3 seconds from importing TensorFlow, logs a `cuInit` error on the CPU-only image, and says `devices found: 0` when the real cause is a permissions problem (DOC-23). `docker exec` skips the entrypoint, so it is not affected. Suggest sending the banner to stderr, or only when the container is interactive, and adding a hint when a device node exists but cannot be opened.

- **NB-4 (updated view; the finding is on branch `test/rpi5-aarch64-images`):** `speech_commands` gives 0.9306 on the board here, the same as the software device on the x86 GPU host. The Raspberry Pi gave 0.9024. So the difference follows the Pi (aarch64), not the board. One caution: the Pi ran an older build of the aarch64 image (digest `c533329f...`, the tag has since moved). A re-run on the Pi with the current build would settle it.

- **NB-1 (Major, already known):** `vww` dataset missing. It reproduces on this image too.

- **NB-3 (Minor, already known):** the `plant_village` evaluation loop still runs one input at a time. On the board it takes 1.65 s per step for 170 steps, so the notebook takes about 10 minutes.

- **Observation, arrhythmia:** accuracy is 0.9577 on 24.04 and 0.9584 on 22.04 (macro F1 0.8355 against 0.8372), both on the board. `plant_village` is identical on both. The cause is not known. The difference is small, and it may come from the TensorFlow and Keras versions (Keras 3.15.1 and 3.12.4).

## Something to know about the earlier results

The floating tags have moved since the earlier tests. The registry digests on 2026-11-03 differ from the ones tested: `ubuntu24.04-gpu-x86` (tested `b50e7eb3...`, now `c0022e3d...`), `ubuntu22.04-gpu-x86` (tested `93a9f848...`, now `1eb9d9be...`) and `ubuntu24.04-cpu-aarch64` (tested `c533329f...`, now `c47bd41e...`). The results in `report.md` describe the older builds. The two CPU x86 images above were tested on the current builds.

## Not tested

- `ubuntu22.04-cpu-aarch64`
- The GPU x86 images with a board, and the new builds of the GPU and aarch64 images
- On 22.04: `speech_commands`, `imagenet` benchmark and `vww`
- Training notebooks (the CPU images are inference-only)
- Power measurement
- The PCIe driver installer and the Secure Boot flow (the driver was already loaded)
- A host where the device node is world-accessible, on x86 (the Pi covered that case)
