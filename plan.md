# Beta Test Plan: Official Akida Docker Containers (REQ-TOOL-005)

- **Jira:** [AK-7557](https://brainchip.atlassian.net/browse/AK-7557)
- **Testers:** Ali Kayyam, Douglas McLelland (requested by Tharak Krishnan)
- **Built by:** Tejaswini Dasika, Kevin Tsiknos
- **Repo:** `brainchipSW/akida_docker/tree/main/metatf_public_images`
- **Scope:** Docker images with DevHub pre-installed, plus the README and user guide

## Objectives

1. Validate the container install and startup experience.
2. Verify DevHub is available and works inside the container.
3. Run representative Akida development workflows.
4. Review the README and user guide for completeness and accuracy.
5. Find usability issues, bugs, missing dependencies and documentation gaps.
6. Send consolidated feedback to the dev team and REQ-TOOL-005 stakeholders.

## Acceptance criteria

| # | Criterion                                      | Status      |
| - | ---------------------------------------------- | ----------- |
| 1 | Image pulled and launched successfully         | Not started |
| 2 | DevHub accessible and functional               | Not started |
| 3 | Akida workflow runs with no blocking issues    | Not started |
| 4 | Documentation reviewed                         | Not started |
| 5 | Defects and enhancement requests documented    | Not started |
| 6 | Feedback shared with REQ-TOOL-005 stakeholders | Not started |

## Test environment

### This machine (GPU host, Linux on GCP)

Checked read-only on 2026-10-14:

| Item                     | Value                                                           |
| ------------------------ | --------------------------------------------------------------- |
| GPUs                     | 2x NVIDIA A30 (24 GB each), idle                                |
| Driver / CUDA            | 595.71.05 / CUDA 13.2                                           |
| Docker                   | 28.1.1, `nvidia` runtime registered, default runtime `runc` |
| NVIDIA container toolkit | `nvidia-ctk` installed                                        |
| Disk / RAM               | 276 GB free / 251 GB                                            |
| Akida device             | None seen on this host (to confirm)                             |

Use `--gpus all` explicitly, because the default runtime is `runc`.

### Akida hardware host (to be identified)

Needed for the PCIe passthrough and hardware inference tests. Until one is available, the hardware criteria are reported as **not tested**, not as passed.

## Facts from AK-7557 (read 2026-10-14)

- **Registry:** `bender:5000` (internal in-house registry). Not on Docker Hub yet.
- **Images:** `bender:5000/akida-devhub:<tag>`, with tags `ubuntu{22.04,24.04}-{gpu,cpu}-x86` and `ubuntu{22.04,24.04}-cpu-aarch64`.
- **Driver installer:** `bender:5000/akida-pcie-driver-installer:ubuntu{22.04,24.04}`. This is a one-time install per host and needs Secure Boot disabled.
- **DevHub:** `brainchip_devhub` is baked into the image at `/workspace/brainchip_devhub`, pinned to commit `8be7c232`. The images were re-pushed on 2026-10-14 under the same tags, and PR #45 was merged the same day. Make sure the pulled image is the new one.
- **Docs:** `metatf_public_images/akida_dev_images/README.md` (build) and `metatf_public_images/USER_GUIDE.md` (use), both in the internal repo `git.corp.brainchipinc.com/brainchipSW/akida_docker`.
- **Stated beta scope:** AKD1500 PCIe/M.2 and the **Akida 1** model zoo examples only. Akida 2 is not in the beta scope.
- **Where to report:** notebook issues go in subtask [AK-7601](https://brainchip.atlassian.net/browse/AK-7601). Everything else goes in AK-7557.
- **Known issues, so don't report them as new:**
  - The eDMA driver is built from a private branch, and AK-7565 is still In Progress.
  - Secure Boot must be disabled.
  - Alpine was rejected, because TensorFlow has no musl wheels.
  - Image sizes are about 4.7 to 6 GB for CPU and 10.5 GB for GPU. Tharak raised size as a concern.
- **Earlier GPU validation:** Tejaswini tested GPU training on an RTX 2080 ("Hawkeye"). The A30s here (Ampere) are new coverage.
- **Documented commands:**
  ```
  docker pull bender:5000/akida-devhub:ubuntu24.04-gpu-x86
  docker run -it --gpus all --privileged -v /dev:/dev \
      -p 8888:8888 -v "$(pwd)/workspace:/workspace" \
      bender:5000/akida-devhub:ubuntu24.04-gpu-x86 bash
  ```

## Things to verify early

- [X] Registry reachability (checked 2026-10-14): `bender` does not resolve from this host. Docker already trusts `172.17.0.39:5000` as an insecure registry. It answers, and it holds `akida-devhub` and `akida-pcie-driver-installer` with every tag listed in the Jira, plus `2.19.3-` prefixed copies of each. **Likely bender, but unconfirmed.**
- [ ] Confirm that `172.17.0.39:5000` is bender (ask Tejaswini or Kevin). If it is, use it in place of `bender:5000` in all commands.
- [ ] `git.corp.brainchipinc.com` resolves and answers (HTTPS 302 to login). Reading it needs credentials, which are present on this host, so Ali must approve their use. Otherwise Ali exports the README and USER_GUIDE.
- [X] Akida device: none on this host (no PCI device, no kernel module). Secure Boot is already disabled here. The beta scope is AKD1500, so the hardware phases need a PCIe or M.2 card on another machine.
- [ ] Which part Douglas is covering.
- [ ] Report format and destination: Jira comment on AK-7557, or markdown or Word.

## Notes to raise in the report

- Jira's input spec says "Ubuntu 20.04/22.04", but the images are 22.04/24.04. Kevin said 20.04 support was dropped, so the spec text is stale.
- The documented `docker run` uses `--privileged -v /dev:/dev`. This is broad, so check whether narrower `--device` flags work and whether the guide explains why.
- The PR table lists five validated combinations, but six tags are on `bender`. Check that `ubuntu22.04-gpu-x86` was validated.

## Phases

### Phase 0: Gather inputs (read-only)

1. Read AK-7557 and its comments for the image name, tag and any known issues.
2. Read the README and user guide in the repo path above.
3. Confirm host details: `docker info`, `nvidia-smi`, `lspci`, disk and RAM.

### Phase 1: Host GPU baseline

Separate host setup problems from image problems.

1. Run `nvidia-smi` in a small public CUDA image with `--gpus all`.
2. Confirm both A30s are visible, and that `--gpus device=0` and `--gpus device=1` each select one GPU.

### Phase 2: Install and startup

1. Follow the USER_GUIDE exactly as written. Log every command and every deviation.
2. Pull `bender:5000/akida-devhub:ubuntu24.04-gpu-x86` first, then `ubuntu22.04-gpu-x86`. Record the image size, pull time and image ID, and confirm that `/workspace/brainchip_devhub` is at commit `8be7c232`.
3. Launch the container and check the entrypoint, default user, volume mounts and port mapping.
4. Launch with `--gpus all` and check that `nvidia-smi` works inside it.

### Phase 3: DevHub

1. Check that DevHub is installed, starts and is reachable.
2. Check login or setup, if the flow has one.
3. Exercise the functions the guide describes, such as model and dataset access.
4. Record any missing dependencies or unclear first-run steps.

### Phase 4: Akida SDK and workflow

1. Record versions: Akida, MetaTF, cnn2snn, quantizeml, TensorFlow/Keras, Python and CUDA/cuDNN.
2. Check that TensorFlow sees the GPUs with `tf.config.list_physical_devices('GPU')`. Compare the CUDA and cuDNN versions in the image with the host (CUDA 13.2), because a mismatch is a likely finding.
3. Run a representative workflow: build or load a model, quantize, convert and run inference on the **virtual device**.
4. Run a short GPU training or quantization job. Watch for errors and memory use.
5. Run the shipped examples and tutorials. Note failures and missing dependencies.
6. Repeat on GPU 0, GPU 1 and both together.

### Phase 5: Hardware (needs an Akida device)

1. Follow the README device instructions: `--device`, privileges, drivers and udev rules.
2. Check that the container enumerates the device.
3. Run the same inference workflow on hardware and compare it with the virtual device.

### Phase 6: Stability and performance

1. Restart the container and check that data in mounted volumes persists.
2. Run a longer job and watch CPU, RAM and GPU memory for leaks or crashes.
3. Record image size, startup time and any slow steps.
4. Cross-platform (Windows, macOS): mark **not tested** unless a machine is available.

### Phase 7: Documentation review

Compare the README and guide with what actually happened:

- Steps that failed or were missing
- Wrong versions or commands
- Unstated prerequisites (host driver, Docker version, GPU runtime, ports)
- Unclear wording

### Phase 8: Report

1. Record everything in [report.md](report.md): the acceptance table, coverage, findings, documentation review and test log. Update it as testing goes, not only at the end.
2. Draft the feedback for AK-7557 and the stakeholders from report.md.
3. **Review the draft with Ali before anything is posted or sent.**

## Findings log (template)

Record each defect as:

```
ID:            D-001
Severity:      Blocker | Major | Minor | Cosmetic
Area:          Startup | DevHub | SDK | Examples | Docs | GPU | Hardware
Environment:   host, Docker version, GPU/device, image tag
Steps:         1. ... 2. ...
Expected:
Actual:        (include log or error text)
Suggested fix: (optional)
```

Enhancement requests use the same format with `Severity: Enhancement`.

## Results summary (fill in at the end)

| Area                    | Result | Environment | Notes |
| ----------------------- | ------ | ----------- | ----- |
| Startup                 |        |             |       |
| DevHub                  |        |             |       |
| SDK availability        |        |             |       |
| Examples and tutorials  |        |             |       |
| GPU                     |        |             |       |
| Akida hardware          |        |             |       |
| Documentation           |        |             |       |
| Stability / performance |        |             |       |
| Cross-platform          |        |             |       |

## Ground rules

- Read-only checks run freely. Pulling images and running containers on this host needs Ali's go-ahead.
- Nothing is posted to Jira or sent by email without Ali's explicit approval.
- Anything not tested is reported as **not tested**, never as passed.
