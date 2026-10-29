# Beta Test Report: Akida Docker Containers (REQ-TOOL-005, AK-7557)

- **Tester:** Ali Kayyam (Douglas McLelland covering: TBD)
- **Requested by:** Tharak Krishnan
- **Report status:** DRAFT, interim. The two GPU images (`ubuntu24.04-gpu-x86`, much more fully, and `ubuntu22.04-gpu-x86`) have been tested without an Akida board. `ubuntu24.04-cpu-aarch64` has been tested on a Raspberry Pi 5 with an AKD1500 board (section 4d). The other CPU and aarch64 images, the driver installer, and the Secure Boot flow are not yet tested.
- **Last updated:** 2026-10-29 (UTC). Raspberry Pi 5 run added (section 4d, NB-4).
- **Plan:** [plan.md](plan.md)

Rules for this file: record only what was actually run and observed. Anything not run is **Not tested**.

## 1. Summary

**Interim verdict: works for GPU training and no-board use with workarounds, but not ready to hand to external users as documented.** Severities below are proposed, for the owners to confirm.

**What was tested.** Two images, on a Linux host with 2x NVIDIA A30 and no Akida board. `akida-devhub:ubuntu24.04-gpu-x86` was pulled, launched, and used to run one training notebook and six benchmark or evaluation notebooks from the Akida 1 model zoo. `akida-devhub:ubuntu22.04-gpu-x86` was pulled, checked against the same list, and ran three of those notebooks plus the quantize, convert and inference steps, with identical results (section 4c). The USER_GUIDE and the two READMEs supplied were read and checked against what actually happened.

**Raspberry Pi 5 with a board (added 2026-10-29, section 4d).** `ubuntu24.04-cpu-aarch64` was pulled (267 s, 4.1 GB) and run on a Raspberry Pi 5 with an AKD1500 PCIe board. The container sees the board with the guide's `--privileged -v /dev:/dev`, and also with only `--device /dev/akd1500_0` and no privilege. Five of six benchmark and evaluation notebooks pass, and their hardware cells now run on the board (latency and clock cycles reported). `vww` fails the same way as on x86 (NB-1). **New finding NB-4:** `speech_commands` reports 0.9024 accuracy on the board against 0.9306 on the software device, while `plant_village` and `arrhythmia` match exactly. Power was not measured (no I2C power sensor). The test Pi also kills running containers on every SSH login (section 4d), which matters for anyone sharing it.

**What works**
- The image pulls (258 s), starts in about 7 s as a non-root user, and ships DevHub at the pinned commit `8be7c232` with a clean tree.
- GPU access works without `--privileged` or `/dev`. TensorFlow sees both A30s, and a compute check ran at about 30 TFLOPS each.
- JupyterLab starts from the default command, and requires the token.
- The `plant_village` training notebook ran end to end (run by Ali): float 99.72%, QAT 99.52%, Akida 99.56%, with the Akida model converted and evaluated on the software device.
- 5 of 6 benchmark and evaluation notebooks pass. The hardware-only cells are skipped cleanly when there is no board.
- The guide's headless command (`jupyter nbconvert --to html --execute`) works as written.

**What does not work, or is missing**
- **DOC-1 (Major):** USER_GUIDE step 4 does not run after step 2. Step 2 pulls with a registry prefix and step 4 runs the short name, so `docker run` fails with "pull access denied" (exit 125). It affects every user who pulls the image.
- **NB-1 (Major):** `vww_notebook_benchmark` fails out of the box. Its dataset is not in the image or downloaded by the notebook, and the README's download URL returned 403 from the test host.
- **DOC-3, DOC-4, DOC-13 (Major):** the guide assumes a board and has no path for GPU or no-board use. It lists no host prerequisites for GPU use. The build README names notebook folders that do not exist (`akida1/notebooks/`).

**Not tested.** The PCIe/M.2 driver installer and the Secure Boot flow (the Pi already had the driver loaded), board runs on x86 hosts, the other CPU and aarch64 images (`ubuntu22.04-cpu-aarch64`, both CPU x86 images), any training notebook on the 22.04 image, the three training notebooks other than `plant_village`, power measurement, other operating systems, and long-run stability. The driver installer's own README was not supplied.

**Counts (26 items, proposed severity):** 0 blockers, 5 Major (DOC-1, DOC-3, DOC-4, DOC-13, NB-1), 16 Minor (including the new NB-4 and DOC-22), 1 Cosmetic, 3 Enhancement, and 1 checked and found fine (DOC-10).

**Acceptance criteria:** none can be called fully met yet. Criteria 1 to 3 are partial passes for the two tested GPU images. See section 2.

## 2. Acceptance criteria

| # | Criterion | Result | Evidence |
|---|-----------|--------|----------|
| 1 | Image pulled and launched successfully | Partial pass | `ubuntu24.04-gpu-x86` pulled (258 s) and launched with GPU, no board. The guide's literal `docker run` fails (DOC-1). `ubuntu22.04-gpu-x86` also pulled (261 s) and launched with GPU. The CPU and aarch64 images and a launch with a board are still to do. |
| 2 | DevHub accessible and functional | Partial pass | JupyterLab reachable on port 8888 with token auth, all 16 notebooks listed, `brainchip_utils` imports. Notebook execution still to be tested (Phase 4). |
| 3 | Akida workflow runs with no blocking issues | Partial pass | `plant_village` training notebook ran end to end (float training, PTQ, QAT, conversion to Akida, Akida evaluation), run by Ali. Option A notebooks: 5 of 6 pass, `vww` fails on a missing dataset (NB-1). A run on a board is still to do. |
| 4 | Documentation reviewed | Partial | USER_GUIDE and build README read and followed for the GPU, no-board path (section 7). The driver installer README was not supplied, and the hardware sections of the guide could not be followed. |
| 5 | Defects and enhancement requests documented | Done for what was tested | 26 items in sections 6 and 7, with fixes in section 7a. More may follow from the untested areas. |
| 6 | Feedback shared with REQ-TOOL-005 stakeholders | Not done | |

## 3. Test environment

| Item | Value |
|------|-------|
| Host | Linux 6.8.0-1047-gcp, 251 GB RAM, 276 GB free disk |
| GPUs | 2x NVIDIA A30 (24 GB), driver 595.71.05, CUDA 13.2 |
| Docker | 28.1.1, `nvidia` runtime registered (default `runc`), NVIDIA container toolkit installed |
| Akida device | None on this host |
| Secure Boot | Disabled |
| Registry used | `172.17.0.39:5000` (trusted insecure registry, probably the same as `bender:5000`). **Unconfirmed.** |
| Images under test | `akida-devhub:ubuntu24.04-gpu-x86` (ID `32f18ca7595e`, digest `sha256:b50e7eb3...aaa7e`, created 2026-10-14 07:18 UTC, 7.55 GB as shown by `docker images`), tested first and most. `akida-devhub:ubuntu22.04-gpu-x86` (ID `d6f858bed4d2`, digest `sha256:93a9f848...1e0df`, created 2026-10-14 07:30 UTC, 7.36 GB), tested next, see section 4c. |
| DevHub commit expected | `8be7c232` |

## 4. Coverage

| Area | Result | Environment | Notes |
|------|--------|-------------|-------|
| Startup and install | Partial pass | A30 host | Pull 258 s, start about 7 s, runs as non-root `akida` (UID 1000). The guide's `docker run` fails on the image name (DOC-1). |
| DevHub | Partial pass | A30 host | At the pinned commit `8be7c232`, clean tree. JupyterLab (default CMD) serves `/workspace` on 8888, and 403 without the token. 16 notebooks: 10 under `akida1/model_zoo` (arrhythmia, imagenet_akidanet, plant_village, speech_commands, vww) and 6 under `akida2/model_zoo`. `brainchip_utils` imports. Dependency conflict found (DOC-19). Notebooks run: see 4a and 4b. |
| SDK and toolchain availability | Partial pass | A30 host | akida 2.19.3, cnn2snn 2.19.3, quantizeml 1.2.5, akida_models 1.14.2, metatf 2.19.3, TensorFlow 2.19.1, Python 3.12.3. TensorFlow sees both GPUs. |
| Examples and tutorials (Akida 1 model zoo) | Partial pass | A30 host, no board | `plant_village` training notebook: pass (4a). Benchmark and evaluation notebooks: 5 of 6 pass, `vww` fails (NB-1) (4b). The other training notebooks (arrhythmia, speech_commands, vww) were not run. Not run on a board. |
| GPU training | Partial pass | A30 host | Host baseline passed (Phase 1). The `plant_village` training notebook ran with TensorFlow creating both A30s as devices, at about 21 to 22 ms per step. GPU utilisation was not captured during the run, so it is not independently confirmed. |
| Akida hardware (AKD1500 PCIe/M.2) | Partial pass | Raspberry Pi 5, `ubuntu24.04-cpu-aarch64` | Board visible in the container, narrower `--device` flags work, 5 of 6 notebooks ran their hardware cells (4d). Driver installer, Secure Boot flow and power measurement not tested. Accuracy differs from software for `speech_commands` (NB-4). |
| Documentation | Partial | A30 host, no board | USER_GUIDE and build README followed for the GPU, no-board path (section 7). Hardware sections not followed. |
| Stability and performance | Partial | A30 host | Pull 258 s, start about 7 s, `docker stop`/`start` cycle works, and no crashes or errors in about two hours of notebook runs. First runs took 5 to 35 minutes, mostly dataset downloads. No long-run or GPU-utilisation measurements were taken. |
| Cross-platform | Partial | Raspberry Pi 5 (aarch64, Ubuntu 24.04) and x86 Linux | Only Linux. aarch64 tested on one image. |
| Akida 2 examples | Out of beta scope | | Per the Jira |

## 4a. Notebook run: `akida1/model_zoo/plant_village/plant_village_notebook_training.ipynb`

**Run by Ali Kayyam** in a JupyterLab session on this host (image `ubuntu24.04-gpu-x86`, ID `32f18ca7595e`, no Akida board). The details below were checked against the executed notebook and the files it left behind. Evidence copy: scratchpad, `plant_village_evidence/executed.ipynb`.

| Item | Observation |
|------|-------------|
| Outcome | **Pass.** 15 code cells, 14 executed, 13 with outputs, **no error outputs**. |
| Dataset | Downloaded inside the container (868 MB archive, 2.6 GB in the container afterwards). The download worked, so the container had outbound internet. |
| Pretrained weights | Downloaded from `data.brainchip.com` (`akidanet_imagenet_224_alpha_50.h5`). |
| Float training | 10 epochs, 1358 steps per epoch, about 30 s per epoch (21 to 22 ms per step). Last epoch: accuracy 0.9998, val_accuracy 0.9948. |
| QAT | 2 epochs, about 50 s each (37 ms per step). Last epoch: accuracy 0.9987, val_accuracy 0.9943. |
| Results | Float **99.72%**, PTQ **34.90%**, QAT **99.52%**, Akida **99.56%**. The low PTQ figure appears to be what the notebook sets out to show before QAT recovers accuracy. It is not treated as a defect. |
| Akida conversion | `akidanet_plant_village_qat.fbz` (1.4 MB) saved. |
| Akida evaluation | 170 batches in about 16 s (about 10.6 it/s). No board is attached to this host, so this ran on the software (virtual) device. |
| GPU | The TensorFlow log shows `GPU:0` and `GPU:1` created (22393 MB each). `nvidia-smi` was not sampled during the run, so GPU utilisation is not independently confirmed. |
| Wall time | The dataset download finished at 22:12 UTC, the float model was saved at 22:17, the QAT model at 22:22, and the notebook was saved at 22:27. That is about 26 minutes from container start, including the download and time spent reading the notebook. It is not a controlled benchmark. |
| Warnings | 9 stderr stream outputs, including the `akida_models` 1.1.10 `UserWarning` quoted under DOC-19. |

## 4b. Notebook runs: Option A (benchmark and evaluation notebooks, headless)

Run in a throwaway container `akida-optA` (same image, `--gpus device=0`, not privileged, no board), one notebook at a time with `jupyter nbconvert --to notebook --execute --ExecutePreprocessor.timeout=-1`. The guide's own headless form (`--to html --execute`, default timeout) was also run once, on `plant_village`, and **worked** (433 s). The container needed outbound internet for the dataset downloads.

| Notebook | Result | Time | Notes |
|----------|--------|------|-------|
| `arrhythmia_classification/arrhythmia_notebook_benchmark` | Pass | 2097 s | Akida accuracy 0.9577, macro F1 0.8355, on 49,280 test beats. **One cell (the data load) took 2085 s**, see NB-2. |
| `imagenet_akidanet/imagenet_akidanet_notebook_benchmark` | Pass | 19 s | Prints "No hardware found - the benchmark sections below will be skipped." Mean activation sparsity 61.40%. |
| `imagenet_akidanet/imagenet_akidanet_notebook_evaluation` | Pass | 22 s | Top-1 and top-5 are 100% for float, QAT and Akida, but on a **10-image smoke test**, not the full validation set (DOC-21). |
| `plant_village/plant_village_notebook_benchmark` | Pass | 367 s | Akida accuracy 0.9943. **One cell (Akida evaluation loop) took 355 s**, see NB-3. |
| `speech_commands/speech_commands_notebook_benchmark` | Pass | 375 s | Akida accuracy (val) 0.9306. The data cell took 364 s (dataset download and preparation). |
| `vww/vww_notebook_benchmark` | **FAIL** | 7 s | `FileNotFoundError: './data/vw_coco2014_96'`. See NB-1. |
| Guide's headless command on `plant_village` benchmark | Pass | 433 s | Confirms that the command in USER_GUIDE step 7 works as written. |

Summary: 5 of 6 pass with no error cells, and the hardware-only cells were skipped cleanly on every notebook that has them. After these runs and the downloads, `akida1/model_zoo` inside the container is **14 GB** (breakdown per dataset not measured).

## 4c. Image `ubuntu22.04-gpu-x86`

The parent README lists this combination as **not validated** (DOC-14), so it was worth checking. Same host, same registry, no board, container not privileged.

| Item | 22.04 image | Same as the 24.04 image? |
|------|-------------|--------------------------|
| Pull | 261 s, ID `d6f858bed4d2`, 7.36 GB | 258 s, 7.55 GB |
| Start and user | `akida` UID/GID 1000, entrypoint `entrypoint.sh`, default CMD JupyterLab, port 8888 | Yes |
| OS and Python | Ubuntu 22.04.5, Python 3.10.12 | 24.04 and Python 3.12.3, as expected |
| DevHub | commit `8be7c232`, clean tree, `akida1` and `akida2` model zoos | Yes |
| Packages | akida 2.19.3, cnn2snn 2.19.3, metatf 2.19.3, akida_models 1.14.2, quantizeml 1.2.5, TensorFlow 2.19.1 (CUDA runtime 12.5.82, cuDNN 9.3.0.75) | Yes, except **Keras 3.12.4 here against 3.15.1 on 24.04** |
| `pip check` | Same `akida_models` 1.14.0 vs 1.14.2 conflict (DOC-19) | Yes |
| Labels | Only `org.opencontainers.image.version=22.04` (DOC-18) | Yes |
| Startup check | `TensorFlow 2.19.1 - GPUs visible: 2`, `akida 2.19.3 - Akida devices found: 0`, with the same TensorFlow warning noise (DOC-17) | Yes |
| GPU | Both A30s visible. 10x 8192x8192 fp32 matmul: about 29.4 and 28.6 TFLOPS. | Same (about 30.5 and 29.6) |
| GPU training | Small conv net, 3 epochs on synthetic data: `fit` ran on GPU:0 in 3.6 s | Not measured on 24.04, but its full notebook run (4a) is the stronger evidence |
| SDK chain (notebook steps, no data or training) | `build_plant_village_model`, `cnn2snn.quantize` (i8/w4/a4), `cnn2snn.convert` (16 layers, `IpVersion.v1`), and `akida predict` on 8 images (output shape `(8, 1, 1, 38)`, 0.07 s) all ran | Not run on 24.04 as a separate check, but the same calls ran in the training notebook |
| Pretrained files | `load_quantized_model(.h5)` and `akida.Model(.fbz)` for `plant_village` load | Yes |

**Notebook runs on this image** (container `akida-2204`, `--gpus device=0`, headless, timeout disabled), the same three that passed on 24.04:

| Notebook | Result | Time | Notes |
|----------|--------|------|-------|
| `imagenet_akidanet_notebook_benchmark` | Pass | 19 s | Hardware cells skipped. Sparsity 61.40%, as on 24.04. |
| `imagenet_akidanet_notebook_evaluation` | Pass | 21 s | 100% on the 10-image smoke test for float, QAT and Akida, as on 24.04. |
| `plant_village_notebook_benchmark` | Pass | 436 s | Akida accuracy 0.9943, the same as on 24.04. The Akida evaluation cell again took 355 s (NB-3 reproduces), and the dataset cell took 72 s. |

No error cells in any of the three. Results match the 24.04 image to the digit, despite the different Python (3.10 against 3.12) and Keras (3.12.4 against 3.15.1). The container was removed afterwards. **Not run on this image:** the training notebooks (the small GPU training check above is the only GPU training evidence for 22.04) and the other benchmark notebooks.

**Conclusion for DOC-14:** the 22.04 GPU image behaves the same as the 24.04 one in everything tested. The parent README's validated table most likely just lags behind (it lists five combinations and the image exists).

An earlier attempt of mine to build a model by hand with `akida_models.akidanet_imagenet` and convert it failed with `DepthwiseConv2D is not supported for Akida conversion`. That was my test script, which did not use the repo's model builder, so it is not reported as a defect. The notebook's own calls work.

## 4d. Raspberry Pi 5 with an AKD1500 board: image `ubuntu24.04-cpu-aarch64` (2026-10-29)

The first run with a real board. Tested over SSH on a lab Raspberry Pi 5 that Ali was given access to. The account is a normal user that the host owner had added to the `docker` group. No `sudo` was used.

| Item | Value |
|------|-------|
| Host | Raspberry Pi 5 Model B Rev 1.1, 4 cores, 7.8 GB RAM, Ubuntu 24.04 LTS, kernel 6.8.0-1007-raspi, aarch64 |
| Storage | 29 GB SD card, 22 GB free at the start |
| Docker | 27.0.3. The daemon trusts `bender:5000` as an insecure registry. |
| Board | `PCIe/AKD1500/16MB/0`, 32 NPs, ip_version `BC.A1.003.009`. Kernel module `akida_pcie` already loaded on the host. Device node `/dev/akd1500_0` (mode 666). |
| Host SDK | The host has its own `venv_akida` with `akida 2.8.0`. It is not used by the container (2.19.3). |
| Registry | `bender:5000` resolves to `172.17.0.39` on the Pi's network, so **`bender:5000` and `172.17.0.39:5000` are the same registry** (answers the open question in section 8). |
| Image | `bender:5000/akida-devhub:ubuntu24.04-cpu-aarch64`, ID `15c17289d5f5`, digest `sha256:c533329f1a9a2d0f2f0de2dba8497ca89797ee6f0a422325d72544cf859ae9d1`, 4.1 GB, pulled in 267 s |

**Inside the image** (same checks as for the x86 images): Ubuntu 24.04.5, Python 3.12.3, aarch64, user `akida` UID/GID 1000. DevHub at commit `8be7c232`, clean tree, `akida1` (`README.md`, `docs`, `model_zoo`) and `akida2` (`model_zoo`). Packages identical to the x86 image: akida 2.19.3, cnn2snn 2.19.3, quantizeml 1.2.5, akida_models 1.14.2, metatf 2.19.3, TensorFlow 2.19.1, Keras 3.15.1, jupyterlab 4.6.4. `pip check` shows the same `akida_models` 1.14.0 against 1.14.2 conflict (DOC-19). Startup prints `TensorFlow 2.19.1 - GPUs visible: 0` and `akida 2.19.3 - Akida devices found: 1`. Every notebook start also prints an onnxruntime `GPU device discovery failed ... /sys/class/drm/card1/device/vendor` warning (more noise, DOC-17).

**Device passthrough**

| Run | Flags | Board visible? |
|-----|-------|----------------|
| A, as in the guide | `--privileged -v /dev:/dev` (no `--gpus`, no `-t`, my own container name) | **Yes.** `akida devices` and `akida.devices()` show `PCIe/AKD1500/16MB/0`. |
| B, narrowest | `--device /dev/akd1500_0` only, not privileged | **Yes**, identical output. |

So the broad flags are **not needed** on this host (DOC-5 resolved, DOC-22 below).

**Notebook runs** (container `akida-rpi-nb`, `--device /dev/akd1500_0`, not privileged, headless `nbconvert --execute`, timeout disabled, one notebook at a time, evidence kept). The benchmark notebooks map the model onto the board (`akida_model.map(device, mode=AllNps, hw_only=True)`), so **the accuracy and timing numbers below are from the AKD1500**, not the software device.

| Notebook | Result | Time | Notes |
|----------|--------|------|-------|
| `imagenet_akidanet_notebook_benchmark` | Pass | 454 s | "Target Akida device found". Mean inference 142.9 ms (system clock), 133.5 ms on chip (53.4 M clocks), 117 NPs. A third mapping (HwPr, 132 NPs) gives 110.5 ms. |
| `imagenet_akidanet_notebook_evaluation` | Pass | 107 s | 100% on the 10-image smoke test (DOC-21). No hardware cells in this notebook. |
| `speech_commands_notebook_benchmark` | Pass | 1374 s | Data cell took 1281 s (dataset download and preparation). **Akida accuracy (val) 0.9024**, see NB-4. Mean inference 0.372 ms (system), 0.337 ms on chip in the first run, 0.153 and 0.114 ms in the second mapping. |
| `vww_notebook_benchmark` | **FAIL** | 13 s | `FileNotFoundError: './data/vw_coco2014_96'`. Same as NB-1, so NB-1 reproduces on aarch64. |
| `plant_village_notebook_benchmark` | Pass | 724 s | Akida accuracy 0.9943 (same as the software device on x86). Dataset cell 115 s. The `batch_size=1` evaluation loop (NB-3) took 272 s, here **on the board**. Mean inference 97.6 ms (system), 91.5 ms on chip, 49.6 and 47.1 ms in the second mapping. |
| `arrhythmia_notebook_benchmark` | Pass | 424 s | Akida accuracy 0.9577, macro F1 0.8355 (same as x86). Data cell 258 s here, against 2085 s on the A30 host, so NB-2 depends on the network and not on the image. Mean inference 2.49 ms (system), 2.44 ms on chip, then 0.668 and 0.625 ms. |

5 of 6 pass, with **no error outputs in any of the five** (checked by counting error outputs in the executed notebooks). The first benchmark run printed `MapMode=Minimal` (read for `speech_commands`, assumed the same for the others). The label of the second run was not checked in each notebook, so those numbers are listed as "second mapping" only.

**Power:** every benchmark prints "I2C INA sensor not found, running timing-only benchmark". That is expected on a Pi without the sensor, so **power measurement was not tested.**

**Disk:** free space fell from 22 GB (start) to 18 GB (after the pull) to 4.3 GB (after the six notebooks). `speech_commands` alone took about 11 GB. `/workspace` in the container was 14 GB. A 29 GB card was enough here, but a 16 GB or 32 GB card with other data on it would not be (DOC-22).

**Not measured on hardware:** `batch_size=32` for the `plant_village` loop (NB-3 was only timed with `batch_size=1` on the board), accuracy of `imagenet` on the full validation set, and anything over several hours.

### Host quirk: the test Pi kills containers on SSH login (not an image defect)

Four of the containers I started were killed, each within seconds of a new SSH login of mine, with exit code 137. The cause is a PAM hook on the host, `/etc/brainchip/ssh_notification.sh`, run on every SSH login. It stops the `lighttpd` and `jupyter-notebook` demo services and runs `docker kill` on all running containers, so that the demos do not conflict with other users of the board. On logout it restarts the services if nobody else is logged in. So: **only one SSH session at a time, and any new login (including from a colleague) ends a running test.** I worked around it by running everything inside one SSH session. This is a property of the demo machine and not of the images, but it is worth documenting for anyone testing on it. Separately: the machine already has an older `akida_demo` image and a stopped `detection_demo` container, which I did not touch.

## 5. Observations before testing

These come from reading the Jira ticket, not from running the images.

- The Jira input spec says "Ubuntu 20.04/22.04", but the images are 22.04 and 24.04. The Jira comments say 20.04 support was dropped, so the spec text looks stale.
- The PR validation table lists five combinations, but six tags exist. `ubuntu22.04-gpu-x86` is the one not listed. It was tested here and behaves like the 24.04 image (section 4c).
- `bender:5000`, the registry named in the Jira, does not resolve from the GCP test host. This is not a defect, but testers outside the corporate network need a documented way in.
- The documented `docker run` uses `--privileged -v /dev:/dev`. To be checked: whether narrower flags work, and whether the guide explains why.

## 6. Findings

Findings from the notebook runs (NB-n) are below. Findings about documents and the image are the DOC-n rows in section 7. Notebook issues belong in [AK-7601](https://brainchip.atlassian.net/browse/AK-7601).

| ID | Sev (proposed) | Area | Summary |
|----|----------------|------|---------|
| NB-1 | **Major** | Examples | `vww_notebook_benchmark` fails out of the box. The dataset is not in the image and is not downloaded by the notebook, and the README's download URL returned 403 from this host. |
| NB-2 | Minor | Examples | The first run of `arrhythmia_notebook_benchmark` takes 35 minutes in one silent cell. **Cause confirmed:** the PhysioNet download (36 min for 94 MB at about 43 KB/s from this host). The preprocessing takes 41 s, as the docstring says. |
| NB-4 | Minor (owners to assess) | Examples, hardware | `speech_commands_notebook_benchmark` reports **0.9024** Akida accuracy on the AKD1500 (Raspberry Pi 5) against **0.9306** on the software device (x86, same notebook and pretrained model). `plant_village` (0.9943) and `arrhythmia` (0.9577) match exactly. Cause not established. |
| NB-3 | Minor | Examples | The Akida evaluation loop in `plant_village_notebook_benchmark` takes 355 s on the software device because it calls `predict(batch, batch_size=1)`. The training notebook uses `batch_size=BATCH_SIZE` (32) and took about 16 s. **Cause confirmed.** |

### NB-1: `vww_notebook_benchmark` fails because the dataset is missing (Major)

```
Area:          Examples (akida1/model_zoo/vww)
Environment:   Linux host with 2x A30, Docker 28.1.1, image akida-devhub:ubuntu24.04-gpu-x86 (ID 32f18ca7595e), no Akida board
Steps:         1. Start the container. 2. Run vww_notebook_benchmark.ipynb with jupyter nbconvert --execute.
Expected:      Runs, as the Jira says ("ready to run immediately after launching the container, no setup step"), or fails with a clear message about the missing dataset.
Actual:        Fails after 7 s with FileNotFoundError: [Errno 2] No such file or directory: './data/vw_coco2014_96' (a 40-line tf_keras traceback from ImageDataGenerator.flow_from_directory). `data/` holds only a .gitignore.
Details:       The other four notebook projects download their datasets themselves (`data.brainchip.com` mirror, PhysioNet, TFDS). `vww` does not. The dataset step is only in README.md ("wget https://www.silabs.com/public/files/github/machine_learning/benchmarks/datasets/vw_coco2014_96.tar.gz") and in colab_setup.py (Colab only). The benchmark notebook never mentions it. The training notebook says "See the README for download instructions".
URL check:     That URL returns "403 Forbidden" to wget --spider and to curl from this host. Tested from this host only, so it could be an IP or bot restriction, and should be tried from another network before calling it dead.
Suggested fix: Download the dataset in `vww_data.py` as the other projects do (the `data.brainchip.com` dataset mirror), or check for the path and print the README instructions. Fix or replace the SiLabs URL if it is dead.
Where to file: AK-7601
```

### NB-2: `arrhythmia_notebook_benchmark` first run takes 35 minutes (Minor)

```
Area:          Examples (akida1/model_zoo/arrhythmia_classification)
Environment:   as NB-1, 64 CPU cores visible to the container
Steps:         Run arrhythmia_notebook_benchmark.ipynb on a fresh container.
Expected:      About a minute for the first-call data preparation, per the docstring in arrhythmia_data.py ("downloads the ~100 MB of raw ... around a minute with all cores busy").
Actual:        Cell 2 (get_test_data) took 2085 s. The other 11 cells took about 6 s in total. The cell printed about 94 KB of output with no progress indication, mostly 65 repeated TensorFlow startup warnings.
Cause:         The PhysioNet download, not the computation. Measured separately in the same container, from a clean directory:
                 wfdb.dl_database('mitdb')                     2164 s, 144 files, 94 MB (about 43 KB/s)
                 get_test_data, records already present          41 s (up to 69 Python processes, 5078% summed CPU)
                 get_test_data again (cache hit)                0.3 s
               CPU use stayed under about 75% summed (under one core) for the whole download, and the host load average stayed near 1.3. The preprocessing matches the docstring ("around a minute with all cores busy"). The docstring says nothing about the download time.
Caveat:        The download rate is for this host's route to PhysioNet only. A faster network would be much quicker, and a slower or blocked one worse. A customer behind a proxy or firewall may not reach PhysioNet at all.
Noise:         The 65 or so worker processes each import TensorFlow and print its startup warnings, which is where the 94 KB of output comes from.
Suggested fix: Print download progress (the cell is silent for 36 minutes). Say in the notebook and the guide that the first run downloads about 100 MB. Consider mirroring the MIT-BIH records on the `data.brainchip.com` dataset mirror, as is already done for the other projects. Keep TensorFlow out of the worker processes to quiet the output.
Where to file: AK-7601
```

### NB-3: slow Akida evaluation loop in `plant_village_notebook_benchmark` (Minor)

```
Area:          Examples (akida1/model_zoo/plant_village)
Observed:      Cell 5 ("Evaluating on Akida", 170 batches, software device) took 355 s. In Ali's run of the training notebook the same loop took about 16 s (10.6 it/s). The model files are the same size (1,379,293 bytes).
Cause:         The benchmark notebook calls akida_model.predict(batch, batch_size=1). The training notebook calls akida_model.predict(batch, batch_size=BATCH_SIZE) with BATCH_SIZE = 32.
Check:         On the same 32 test images, on the software device (no board), in the same container: batch_size=1 takes 2.08 s per batch (runs 2.08, 2.07, 2.08) and batch_size=32 takes 0.09 s (0.09, 0.08, 0.09). That is 23 times faster, and the predictions are identical. 170 batches x 2.08 s is about 354 s, which matches the 355 s seen.
Likely intent: batch_size=1 may be deliberate for hardware measurements, where the board processes one frame at a time. Not confirmed.
Impact:        Without a board, the evaluation cell takes 6 minutes instead of about 15 seconds. Users on a no-board machine will wait for no benefit.
Suggested fix: Use batch_size=BATCH_SIZE for the accuracy loop. Keep batch_size=1 only in the hardware benchmark cells, which need a board.
Where to file: AK-7601
```

Format used for each finding:

```
ID:            D-001
Severity:      Blocker | Major | Minor | Cosmetic | Enhancement
Area:          Startup | DevHub | SDK | Examples | Docs | GPU | Hardware
Environment:   host, Docker version, GPU/device, image tag and ID
Steps:         1. ... 2. ...
Expected:
Actual:        (include log or error text)
Suggested fix: (optional)
Where to file: AK-7557 | AK-7601 (notebook issues)
```

### NB-4: `speech_commands` accuracy differs between the board and the software device (Minor, for the owners to assess)

```
Area:          Examples (akida1/model_zoo/speech_commands), hardware
Observed:      Cell 11 of speech_commands_notebook_benchmark prints "Akida accuracy (val)".
               Raspberry Pi 5, AKD1500, image ubuntu24.04-cpu-aarch64 (model mapped to the board in cell 9, hw_only=True): 0.9024
               A30 host, no board, ubuntu24.04-gpu-x86 (software device, cell 9 printed "No connected Akida hardware device detected"): 0.9306
               Difference: 2.8 points. The same cell on plant_village (0.9943) and arrhythmia (0.9577) gives identical numbers on board and software.
Not known:     Whether this is a real hardware against software difference for this model, or a difference in the validation data. Not checked: the number of validation samples on each side, and the software and hardware accuracy in the same session on the same data.
Suggested check: in one session on the Pi, evaluate the same val_ds with the model unmapped (software) and mapped (hardware), and compare predictions sample by sample.
```

Why it matters: the benchmark notebooks are presented as showing that the hardware matches the software model. If this is a real divergence for the AKD1500, it should be known. If it is a data difference, the notebook output cannot be compared across machines. The image is probably not the cause, because the package versions are identical.

### Known issues, not counted as findings

- The eDMA driver is built from a private branch, and AK-7565 is still open.
- Secure Boot must be disabled.
- Alpine is not viable, because TensorFlow has no musl wheels.
- Image sizes are about 4.7 to 6 GB for CPU and 10.5 GB for GPU.

## 7. Documentation review

**Documents reviewed (supplied by Ali, 2026-10-14; source commit unknown):**
- `docker_user_guide.md`: 223 lines, the USER_GUIDE.
- `akida_dev_images_readme.md`: 136 lines, the build and run README for the dev images.
- `akida_pcie_driver_installer_readme.md`: 46 lines. **Despite its name, this is the parent folder README** (Structure and Validated combinations), not the driver installer's README.
- `docker_readme.md`: 23 lines. This is the older `akida_images` README (`./build.sh`, `./push.sh`, daily CI). It is internal CI documentation and **not part of the product under test**, so it is not reviewed.
- **Still missing:** the `akida_pcie_driver_installer/` README. The installer's behaviour will be judged from the USER_GUIDE and from running it only if a device host is available.

**Status:** each note below is marked *read* (visible in the documents, not run), *verify* (still to be confirmed by running the steps), or *confirmed by run*. DOC-6 and the board-dependent part of DOC-5 can't be checked without an Akida board.

| ID | Sev (proposed) | Basis | Observation |
|----|----------------|-------|-------------|
| DOC-1 | Major | **confirmed by run** (`docker run ... akida-devhub:ubuntu24.04-gpu-x86` fails with "pull access denied", exit 125) | Step 2 pulls from `<registry>/akida-devhub:...`, but step 4 runs `akida-devhub:...` with no registry prefix. Following the guide literally, `docker run` would not find the pulled image and would try Docker Hub. `<registry>` is never defined. **Why:** a pull stores the image under its full name, `<registry>/akida-devhub:<tag>`. It does not create the short name `akida-devhub:<tag>`, which Docker treats as a different image (`docker.io/library/akida-devhub`) and looks for on Docker Hub. The short name only exists after a **local build** with `gen_docker.py`, which tags it that way. So step 4 only works for locally built images, not for the pulled images the beta uses. It is unrelated to having an Akida device. |
| DOC-2 | Minor | read | Step 2 says the images are "published on the docker hub", but the beta images are on the internal registry. Wording is garbled ("pick in from the list... step 1"). |
| DOC-3 | Major | read | Everything assumes an Akida board. The title says "on a real Akida hardware", step 3 treats the driver install as mandatory, and step 6 expects a device. The GPU image exists for training, which needs no board. There is no path for users with no device, such as a virtual-device run. **Verify:** do the notebooks run with no board, and does the startup `akida devices` check fail loudly or block? **Partial result:** with no board and no `--privileged`, the container starts in about 7 s and the startup check prints `akida 2.19.3 - Akida devices found: 0` without failing. So a no-device GPU run works, but the guide never says so. **Confirmed for notebooks:** the five Akida 1 benchmark and evaluation notebooks that run (see section 4b) skip their hardware cells cleanly with no board (for example "No hardware found - the benchmark sections below will be skipped."). So the notebooks are designed for it, and the guide should say so. |
| DOC-4 | Major | read | No host prerequisites are listed for GPU use: NVIDIA driver minimum, NVIDIA container toolkit, Docker version. Step 4 only says `--gpus all`. No search hit for "nvidia" other than that flag. |
| DOC-5 | Minor | read | The `--privileged -v /dev:/dev` run command is presented as required, with no note that it is only needed for Akida device access, or about the security implications. **Partial result:** a GPU-only run without `--privileged` or `/dev` works (TensorFlow sees both A30s). So these flags are only needed for the Akida board. **Confirmed on the Raspberry Pi 5 (4d):** `--device /dev/akd1500_0` alone, with no `--privileged` and no `/dev` mount, gives the same board visibility as the guide's flags. The guide should show the narrower form and say which node name to use (`/dev/akd1500_0` here). |
| DOC-6 | Minor | read | The expected device output is `PCIe/NSoC_v2/0`, but the beta scope is AKD1500 and Tejaswini's Jira output was `PCIe/AKD1500/16MB/0`. **Verify** what actually appears. |
| DOC-7 | Minor | read | Step 7 starts Jupyter in the container shell, then lists `docker logs akida-dev` without saying it runs on the host, in a second terminal. It does not explain how to reach the notebook from a remote machine, such as an SSH tunnel for port 8888 and the token URL. The build README says the default `CMD` is JupyterLab, which the USER_GUIDE never mentions. Running without `bash` would start Jupyter directly and make `docker logs` the natural way to get the token. **Confirmed by run:** the default CMD starts JupyterLab and the token URL appears in `docker logs`. Without the token, the API returns 403. So the flow works, but the guide never describes the default-CMD route. |
| DOC-8 | Minor | read | Step 4 says there is no bind mount, so work in `/workspace` lives only in the named container. The troubleshooting step suggests `docker rm akida-dev`, which deletes it. The guide does not warn about losing notebook edits or outputs, or say how to copy them out (`docker cp`). **Observed:** the `plant_village` run downloaded an 868 MB dataset archive and extracted it into the container, making the container's writable layer 2.6 GB. Removing the container deletes the trained models and dataset, which would have to be downloaded again. |
| DOC-9 | Minor | read | The Jira comment from 2026-10-06 still shows `-v "$(pwd)/workspace:/workspace"`, which the updated guide says to avoid because it hides the baked-in DevHub. Testers following the Jira would hit this. |
| DOC-10 | None (resolved) | **checked by run** | Step 5 runs `docker start` then `docker exec` on a container created with `bash`. **Result:** a container created with `docker run -dit ... bash` stays up after `docker stop` then `docker start` (no `-ai`), and `docker exec` works afterwards. Step 5 is fine as written. |
| DOC-11 | Cosmetic | read | Typo "explicitilty"; garbled commit line (`commit_hash, 8be7c23...`); a hardcoded example container ID in step 5; step 1 line 3 reads "x86_64 or x86\|aarch64"; the `python3.12` / `gen_docker.py` build troubleshooting item belongs in the build README. |
| DOC-12 | Enhancement | read | The build README explains that each push gets a floating shape tag and an immutable `{metatf-version}-...` tag, but the USER_GUIDE does not. It gives no versioned tag (`2.19.3-ubuntu24.04-gpu-x86` exists in the registry) and does not say which to use for reproducibility. No `docker pull` size or time expectation, although the GPU image is about 10.5 GB. |
| DOC-13 | Major | **confirmed by run:** `akida1/` contains `model_zoo`, `docs` and `README.md`, with no `notebooks/`. `akida2/` contains `model_zoo`. | The build README says to run the notebooks under `akida1/notebooks/` (and `akida2/notebooks/`). The Jira and the beta scope refer to `akida1/model_zoo`. Only the build README is wrong. USER_GUIDE step 7 uses a generic `path/to/example.ipynb`, so it names no folder and would be clearer if it did. |
| DOC-14 | Minor | read | The parent README lists five validated combinations, but the build README says `build_all.sh` builds six variants, and six tags are published. `ubuntu22.04-gpu-x86` is the one not listed as validated. **Tested here (section 4c):** it works the same as the 24.04 image for everything run, so the table is probably just out of date. |
| DOC-15 | Minor | read | The image runs as UID/GID 1000. For a different host UID, the build README says to rebuild, or for a pre-built image to "request a build for your UID/GID". That is not workable for external customers. The USER_GUIDE offers `--user $(id -u):$(id -g)`. The two documents disagree. |
| DOC-16 | Minor | verify | `tensorflow` is installed unpinned next to `metatf` (for the `[and-cuda]` extra), so rebuilds are not reproducible and the TF version could drift from what `metatf` expects. **Partial result:** the image has TensorFlow 2.19.1 and Keras 3.15.1 alongside metatf 2.19.3, with CUDA runtime 12.5.82 and cuDNN 9.3.0.75 as pip packages. The versions are consistent now, and the host driver (CUDA 13.2) is newer than these, so it is fine. The drift risk remains for rebuilds. Compute on the GPU is still to be tested. |
| DOC-17 | Minor | **confirmed by run** | Every container start prints about ten lines of TensorFlow stderr, such as `E ... Unable to register cuFFT/cuDNN/cuBLAS factory` and `W ... computation placer already registered`, before the useful `TensorFlow 2.19.1 - GPUs visible: 2` and `akida 2.19.3 - Akida devices found: 0` lines. They look like errors to a new user. Suggest silencing them in the startup check (`TF_CPP_MIN_LOG_LEVEL=2`). |
| DOC-19 | Minor now, Major if notebooks fail | **confirmed by run** | `pip check` inside the image reports `brainchip-utils 0.1.0 has requirement akida_models==1.14.0, but you have akida-models 1.14.2`. DevHub's `pyproject.toml` pins `akida_models==1.14.0` (and `tensorflow==2.19.1`, which matches). The image gets 1.14.2 through `metatf 2.19.3`. So the DevHub notebooks run against a different `akida_models` than the one they pin. **Partial result:** the `plant_village` training notebook ran to completion with `akida_models` 1.14.2 and no error outputs, so the mismatch did not break that notebook. The notebook did log `UserWarning: Model akidanet_imagenet_224_alpha_50.h5 has been trained with akida_models 1.1.10 which is the last version supporting 1.0 models training. Continuing execution.` Other notebooks are still to be run. Suggest aligning the pin, or documenting the tested combination. |
| DOC-20 | Minor | **confirmed by run** | The guide never says the container needs outbound internet, or what it downloads. The notebooks download datasets and weights on first run, from `data.brainchip.com` and PhysioNet (confirmed in code and by the runs) and from the TFDS source for `speech_commands`. A customer behind a firewall or offline has no warning. The Jira says notebooks are "ready to run immediately... no setup step". After four benchmark notebooks plus one training run, `akida1/model_zoo` in the containers had grown to 14 GB. The guide gives no disk or first-run time expectation (first runs observed: 5 to 35 minutes). |
| DOC-21 | Enhancement | **confirmed by run** | The `imagenet_akidanet` notebooks report 100% top-1 and top-5 because they evaluate a 10-image sample pack unless the full ImageNet validation set is present. The notebook says so in its output, but neither the guide nor the notebook headings say how to get the full set. |
| DOC-22 | Minor | **confirmed by run** | The guide gives no disk requirement. On the Raspberry Pi 5 (29 GB card) free space fell from 22 GB to 4.3 GB after the 4.1 GB pull and six benchmark notebooks, of which `speech_commands` alone took about 11 GB. On a smaller card or a card with other data, the run would fail with a disk error. Related to DOC-20. Suggested wording: image size plus about 15 GB for datasets. |
| DOC-18 | Enhancement | **confirmed by run** | The image's only label is `org.opencontainers.image.version=24.04`. There is no label for the metatf version, DevHub commit or build date, so these can't be read without starting a container. |

## 7a. Documentation fixes requested

For the document owners. IDs refer to the table in section 7. Items marked **(verify)** are still provisional, because they have not been confirmed by running the steps.

### `USER_GUIDE.md`

| Where | Change | ID |
|-------|--------|----|
| Steps 2 and 4 | Use the same fully qualified image name in both. Either define a variable once (`REGISTRY=<registry>`) and use `${REGISTRY}/akida-devhub:<tag>` in the pull and the run, or add a `docker tag` step after the pull. Define what `<registry>` is. | DOC-1 |
| Step 2 | Fix the garbled sentence ("pick in from the list... step 1"). Say where the images are published: the internal registry for the beta, and Docker Hub only once it is live. | DOC-2 |
| Step 1 | Add host prerequisites for the GPU images: minimum NVIDIA driver, NVIDIA container toolkit, and a Docker version. Say that `--gpus all` needs them. | DOC-4 |
| Intro, steps 3 and 4 | Add a no-board path. Training and inference without a device work in the container without `--privileged` or `/dev`, and step 3 (driver install) is only for runs on real hardware. Give a command for each case. | DOC-3, DOC-5 |
| Step 4 | State that `--privileged -v /dev:/dev` is only needed for access to the Akida board, and note what it exposes. Show `--device /dev/akd1500_0` as the narrower form (confirmed on a Raspberry Pi 5, 4d), and how to find the node name on other hosts. | DOC-5 |
| Step 1 or 4 | Add a disk requirement (image size plus about 15 GB for datasets), and a note for Raspberry Pi SD cards. | DOC-22 |
| Step 4 and Troubleshooting | Warn that work in `/workspace` lives only in the named container and that `docker rm akida-dev` deletes it. Show how to copy files out (`docker cp`). | DOC-8 |
| Step 6 | Update the expected output to match the board in scope (AKD1500, e.g. `PCIe/AKD1500/16MB/0`) instead of `PCIe/NSoC_v2/0`. **(verify)** | DOC-6 |
| Step 7 | Mention that the default `CMD` starts JupyterLab. Say that `docker logs` runs on the host in a second terminal and is where the token appears. Explain remote access (SSH tunnel for port 8888). Point to `akida1/model_zoo`, where the notebooks are. | DOC-7, DOC-13 |
| Image tags | Explain the floating tag and the immutable `<metatf-version>-ubuntu...` tag, and which to use for reproducible work. Give the expected pull size and time. | DOC-12 |
| UID | Make it consistent with the build README. Offer `--user $(id -u):$(id -g)` for pulled images. | DOC-15 |
| Cosmetic | Fix "explicitilty", the garbled commit line, the hardcoded container ID, the "x86_64 or x86\|aarch64" line, and move the `python3.12` / `gen_docker.py` item to the build README. | DOC-11 |

### `akida_dev_images/README.md` (build)

| Change | ID |
|--------|----|
| Replace `akida1/notebooks/` and `akida2/notebooks/` with `akida1/model_zoo` and `akida2/model_zoo`, the paths that exist in the image. | DOC-13 |
| Reconcile the UID advice ("request a build") with the USER_GUIDE's `--user` option. | DOC-15 |
| Consider pinning `tensorflow` next to `metatf` for reproducible rebuilds, or state the tested TensorFlow version. **(verify** with GPU compute tests.) | DOC-16 |

### Parent README (`metatf_public_images`)

| Change | ID |
|--------|----|
| The validated table lists five combinations, but six variants are built and published. Add `ubuntu22.04-gpu-x86`, or say it is not validated. | DOC-14 |

### `brainchip_devhub` notebooks

| Change | ID |
|--------|----|
| `vww`: download the dataset inside `vww_data.py` like the other four projects, or check for it and print the README steps. Fix or replace the SiLabs URL if it is dead. | NB-1 |
| `arrhythmia`: print download progress, state the first-run download (about 100 MB, took 36 min from this host), and consider mirroring the records on `data.brainchip.com`. | NB-2 |
| `plant_village` benchmark: use `batch_size=BATCH_SIZE` in the accuracy loop and keep `batch_size=1` only in the hardware benchmark cells. About 23 times faster without a board. | NB-3 |
| `imagenet_akidanet`: say in the notebook how to get the full validation set, and label the 10-image results clearly. | DOC-21 |

### Image and entrypoint (not documents)

| Change | ID |
|--------|----|
| Quiet the TensorFlow stderr lines at startup (for example `TF_CPP_MIN_LOG_LEVEL=2` in the startup check) so the two useful lines stand out. | DOC-17 |
| Add OCI labels for the metatf version, DevHub commit and build date. | DOC-18 |
| Align the `akida_models` version: DevHub pins 1.14.0, the image has 1.14.2. Either bump the pin in `brainchip_devhub/pyproject.toml` or document the tested combination. | DOC-19 |

### Jira AK-7557

| Change | ID |
|--------|----|
| The 2026-10-06 comment still shows `-v "$(pwd)/workspace:/workspace"`, which the updated guide says to avoid. Add a pointer to the current guide or correct the comment. | DOC-9 |
| The input spec says "Ubuntu 20.04/22.04". The images are 22.04 and 24.04. Update the spec text. | Section 5 |

## 8. Recommendations

In priority order. Items 1 to 4 are small changes. Item 5 is testing that needs a board.

**Before handing the images to more testers or customers**
1. **Fix the image name in USER_GUIDE steps 2 and 4** (DOC-1). Use the same fully qualified name in both, or add a `docker tag` step. Every user who pulls the image hits this.
2. **Settle where the `vww` dataset comes from, and make the notebook get it** (NB-1). The README's SiLabs URL returned 403 from the test host. Please try it from another network, and ideally host the dataset on the `data.brainchip.com` mirror like the other projects.
3. **Document the GPU and no-board paths** (DOC-3, DOC-4, DOC-5). Add host prerequisites (NVIDIA driver, container toolkit), a no-board launch command without `--privileged`, and a note that step 3 (driver install) is only for real hardware.
4. **Correct stale references** (DOC-13, DOC-9, DOC-14, Section 5): the `akida1/notebooks/` paths, the old bind-mount command in the Jira, the five-versus-six validated combinations, and the "Ubuntu 20.04/22.04" spec text.
5. **Finish the board validation.** Done on a Raspberry Pi 5 (4d): device passthrough, `akida devices`, and hardware inference in five benchmark notebooks. Still to do: the driver installer, the Secure Boot flow, a board in an x86 host, and power measurement. Also look at NB-4 (`speech_commands` accuracy on the board against software).

**Second priority**
6. Set expectations for first runs (DOC-20, NB-2): the container needs outbound internet, downloads datasets on first use, and grows to many GB. The `arrhythmia` first run took 36 minutes, nearly all of it a silent PhysioNet download, so print progress or mirror the data.
7. Use `batch_size=BATCH_SIZE` in the `plant_village` accuracy loop (NB-3). It is 23 times faster without a board, with identical predictions.
8. Align the `akida_models` pin (DOC-19): DevHub pins 1.14.0 and the image has 1.14.2. The one training notebook run worked, but the mismatch is untested elsewhere.
9. Smaller improvements: quieter startup output (DOC-17), OCI labels for versions and commit (DOC-18), tag guidance (DOC-12), UID guidance (DOC-15), notebook wording (DOC-21), and the cosmetic items (DOC-11).

**Questions for the owners**
- ~~Is `172.17.0.39:5000` the same registry as `bender:5000`?~~ Answered (4d): on the Raspberry Pi's network `bender` resolves to `172.17.0.39`, so yes. Please still document a way in for testers whose network does not resolve `bender`.
- Is the `speech_commands` accuracy difference between the board (0.9024) and the software device (0.9306) expected (NB-4)?
- Where should the `vww` dataset come from?
- Is `batch_size=1` in the benchmark loop deliberate for hardware runs?
- Was `ubuntu22.04-gpu-x86` validated by the build team? It worked in these tests, but the parent README lists five combinations and six are built.
- Can the driver installer README be shared for review?

**Testing still to do:** `ubuntu22.04-cpu-aarch64` and the two CPU x86 images, the driver installer and Secure Boot flow, the other training notebooks (and any training notebook on the 22.04 image), power measurement, the NB-4 check, and longer stability runs.

## 9. Test log

_Commands run and their results will be appended here in order._

| Time | Command or action | Result |
|------|-------------------|--------|
| 2026-10-14 | Read AK-7557 (Jira) | Done |
| 2026-10-14 | Host checks: GPU, Docker, toolkit, Secure Boot, Akida device | Done |
| 2026-10-14 | Registry reachability: `bender` fails DNS, `172.17.0.39:5000` answers, tags listed | Done |
| 2026-10-14 | Fetch README and USER_GUIDE from `git.corp.brainchipinc.com` over HTTPS | Failed: no stored credential for that host (only github.com). No SSH entry either. Nothing was read. |
| 2026-10-14 | Ali supplied `docker_user_guide.md` and `docker_readme.md`; read both | Done. `docker_readme.md` was the wrong README (older `akida_images`). |
| 2026-10-14 | Ali supplied `akida_dev_images_readme.md` and `akida_pcie_driver_installer_readme.md`; read both | Done. The first is the build README. The second is actually the parent README. Driver installer README still missing. **Phase 0 complete.** |
| 2026-10-14 | Docker Hub reachability (`registry-1.docker.io`, `auth.docker.io`) | OK (401 on `/v2/` is the normal auth challenge) |
| 2026-10-14 | **Phase 1:** `docker pull nvidia/cuda:12.6.3-base-ubuntu24.04`, then `nvidia-smi -L` with `--gpus all`, `device=0`, `device=1`, and with no `--gpus` | **Pass.** `all` shows both A30s. `device=0` and `device=1` each show one A30 (UUIDs differ, and each is renumbered as GPU 0 inside the container). With no `--gpus`, `nvidia-smi` is not present in the container, so no GPU is exposed. The host GPU setup is sound, so any later GPU failure points at the Akida image. |
| 2026-10-14 | **Phase 2:** `docker pull 172.17.0.39:5000/akida-devhub:ubuntu24.04-gpu-x86` | Pass. 258 s, image ID `32f18ca7595e`, 7.55 GB, created 2026-10-14 07:18 UTC. Entrypoint `entrypoint.sh`, default CMD `jupyter lab --ip=0.0.0.0 --port=8888 --no-browser`, user `akida`, workdir `/workspace`, port 8888 exposed. |
| 2026-10-14 | Guide step 4 run literally (`docker run --gpus all --privileged -v /dev:/dev -p 8888:8888 --name akida-dev akida-devhub:ubuntu24.04-gpu-x86`, without `-it` because there is no TTY here) | **Fail:** `pull access denied for akida-devhub`, exit 125. No container left behind. Confirms DOC-1. |
| 2026-10-14 | Throwaway run with `--gpus all` only (no `--privileged`, no `/dev`) that inspects the image | Pass. Startup about 7 s. Startup check: `TensorFlow 2.19.1 - GPUs visible: 2`, `akida 2.19.3 - Akida devices found: 0`. DevHub commit `8be7c232`. Container removed on exit. |
| 2026-10-14 | **Phase 3:** `docker run -d --gpus all -p 127.0.0.1:8888:8888 --name akida-dev <image>` (default CMD, not privileged), then `docker logs` and the Jupyter API | Pass. Port 8888 was free. The server was up in under 12 s. The token URL is in `docker logs`. `/api/contents` without a token gives 403, and with the token `/lab` gives 200. Kernelspec `python3` only. Notebook list as in section 4. |
| 2026-10-14 | `pip check` and a check for requirements files in the container | `brainchip_utils` imports. `pip check` reports the `akida_models` 1.14.0 vs 1.14.2 conflict (DOC-19). There are no `requirements*.txt` files, and dependencies are in `pyproject.toml`. |
| 2026-10-14 | DOC-10: `docker run -dit ... bash`, `docker stop`, `docker start` (no `-ai`), `docker exec` | Pass. Stays up, and `docker exec` works. Throwaway container removed. |
| 2026-10-14 | Cleanup: removed `akida-dev` | Done. No akida containers left, port 8888 free again. |
| 2026-10-14 | Restarted `akida-dev` (same settings, localhost only) and gave Ali the token link to use in a browser through an SSH tunnel | Done |
| 2026-10-14 | Ali ran `plant_village_notebook_training.ipynb` in that container | Ran to completion (Ali's report, then checked against the saved notebook and files, see section 4a) |
| 2026-10-14 | Copied the executed notebook out of the container and parsed its saved outputs (JSON only, nothing executed). Then removed `akida-dev`. | Done. No akida containers left, port 8888 free. |
| 2026-10-14 | GPU compute check: TensorFlow matmul 8192x8192 fp32, 10 iterations, on GPU:0 and GPU:1 (throwaway container) | Pass. About 30.5 and 29.6 TFLOPS. Likely TF32 on Ampere. Both ran on the intended device. |
| 2026-10-14 | Read-only scan of Option A notebooks and of what each project downloads | `pretrained_models/` with `.fbz` is in every project. Benchmark notebooks guard hardware cells with `if device is not None:`. |
| 2026-10-14 | **Option A run** in container `akida-optA` (script `run_optionA.sh` in the scratchpad), 6 notebooks plus the guide's literal headless command | 5 pass, `vww` fails (exit 1, 7 s). Results in section 4b. Container still running for follow-up. |
| 2026-10-14 | `wget --spider` and `curl -I` on the README's `vw_coco2014_96.tar.gz` URL at silabs.com | `403 Forbidden` from this host (NB-1). |
| 2026-10-14 | NB-3 check: `predict` on the same 32 images with `batch_size=1` and `32`, software device, 3 runs each | 2.08 s vs 0.09 s per batch (23x), identical predictions. Cause of the 355 s cell confirmed. |
| 2026-10-14 to 15 | NB-2 check: `wfdb.dl_database` and `get_test_data` timed separately in `akida-optA`, with a process and CPU sampler every 20 s | Download 2164 s (94 MB, 144 files). Preprocessing 41 s. Cache hit 0.3 s. Download is the cause. |
| 2026-10-15 | Cleanup: removed `akida-optA` (14.3 GB writable layer, 21.9 GB virtual) | Done. No akida containers left, port 8888 free. Pulled images kept: `akida-devhub:ubuntu24.04-gpu-x86` (7.55 GB) and `nvidia/cuda:12.6.3-base-ubuntu24.04` (250 MB). |
| 2026-10-15 | `docker pull 172.17.0.39:5000/akida-devhub:ubuntu22.04-gpu-x86` | Pass. 261 s, ID `d6f858bed4d2`, 7.36 GB, created 2026-10-14 07:30 UTC. Same entrypoint, CMD, user and workdir as the 24.04 image. |
| 2026-10-15 | Inspection and checks in a throwaway container, GPU only (`check_2204.sh`): versions, DevHub commit, `pip check`, `nvidia-smi`, matmul, small GPU training, SDK chain | Pass, apart from my own first SDK-chain attempt, which failed because it built the model by hand and skipped the repo's builder (not a defect). Details in section 4c. |
| 2026-10-15 | Notebook's own steps on 22.04 (`build_plant_village_model`, `cnn2snn.quantize`, `cnn2snn.convert`, `predict`, pretrained `.h5` and `.fbz` load) | Pass. 16-layer Akida model, `IpVersion.v1`, output shape `(8, 1, 1, 38)`. |
| 2026-10-15 | Three notebooks on 22.04 in container `akida-2204` (`run_2204_nb.sh`) | 3 of 3 pass, 19 s, 21 s and 436 s. Same numbers as 24.04. NB-3 reproduces. |
| 2026-10-15 | Cleanup: removed `akida-2204` | Done. No akida containers left, port 8888 free. Images kept: both akida-devhub GPU images and the small CUDA image. |
| 2026-10-29 | Created branch `test/rpi5-aarch64-images`. SSH to the lab Raspberry Pi 5. Read-only recon: model, OS, memory, disk, Docker, `akida devices` in the host `venv_akida` | Pi 5, Ubuntu 24.04, 29 GB card, board `PCIe/AKD1500/16MB/0`. `docker` denied: the account was not in the `docker` group. |
| 2026-10-29 | After the host owner added the account to the `docker` group (no `sudo` used): recheck, registry name resolution and reachability | Docker works. `bender` resolves to `172.17.0.39`, both answer 200, the aarch64 tags are listed. `/dev/akd1500_0` present. |
| 2026-10-29 | `docker pull bender:5000/akida-devhub:ubuntu24.04-cpu-aarch64` | Pass. 267 s, ID `15c17289d5f5`, 4.1 GB. |
| 2026-10-29 | Test A: `docker run --rm --privileged -v /dev:/dev` plus `check_pi.sh` (versions, DevHub commit, `pip check`, `akida devices`, Python `akida.devices()`) | Pass. Board visible, 32 NPs, DevHub `8be7c232`, DOC-19 conflict as on x86. |
| 2026-10-29 | Test B: `docker run --rm --device /dev/akd1500_0` (not privileged) plus the same checks | Pass. Board visible, identical output (DOC-5 resolved, DOC-22). |
| 2026-10-29 | Started `sleep infinity` containers and ran more commands in new SSH sessions | Four containers were killed (exit 137), each as a new SSH session of mine opened. Root cause found by reading the login hook `/etc/brainchip/ssh_notification.sh` (and the account's shell startup files, which had nothing relevant). Nothing was changed on the host. |
| 2026-10-29 | Batch run in one SSH session (`wrapper_pi.sh`, in the scratchpad): 6 notebooks, 5400 s cap each, container `akida-rpi-nb` | 5 pass, `vww` fails (NB-1). 454, 107, 1374, 13, 724 and 424 s. Evidence bundle (executed notebooks and logs) pulled back through the same session. |
| 2026-10-29 | Analysis of the executed notebooks | Hardware cells ran. Accuracy: `plant_village` 0.9943, `arrhythmia` 0.9577, `speech_commands` 0.9024 (x86 software: 0.9306, NB-4). No error outputs. No I2C power sensor. |
| 2026-10-29 | Cleanup: removed `akida-rpi-nb` (end of the batch script). Kept the pulled image on the Pi. | Done. The older `akida_demo` image and `detection_demo` container were not touched. |
