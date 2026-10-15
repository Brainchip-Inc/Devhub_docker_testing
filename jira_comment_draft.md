**Beta test feedback: Akida Docker images (REQ-TOOL-005), from Ali Kayyam**

Thanks Tejaswini and Kevin for the images. Summary of my testing so far. The full report, with evidence and the documentation fixes, is attached (report.md).

**Tested:** `akida-devhub:ubuntu24.04-gpu-x86` (in depth) and `ubuntu22.04-gpu-x86`, from `172.17.0.39:5000`, on a Linux host with 2x NVIDIA A30 and **no Akida board**. DevHub was at the pinned commit `8be7c232` in both images. Douglas McLelland's testing is not included here.

**Result: works for GPU training and no-board use with workarounds, but not ready for external users as documented.**

What works
- Pull (about 260 s each) and start (about 7 s) as a non-root user. GPU access works without `--privileged`, and both A30s are used by TensorFlow.
- JupyterLab starts from the default command and needs the token.
- `plant_village` training notebook ran end to end (float 99.72%, QAT 99.52%, Akida 99.56% on the software device).
- 5 of 6 benchmark and evaluation notebooks pass on 24.04, and the 3 I repeated on 22.04 gave identical results. Hardware cells are skipped cleanly when there is no board.

Major issues (proposed severity)
1. **USER_GUIDE steps 2 and 4 don't match.** Step 2 pulls `<registry>/akida-devhub:<tag>`, but step 4 runs `akida-devhub:<tag>`. A pull doesn't create the short name, so `docker run` fails with "pull access denied" (exit 125). It only works for locally built images.
2. **`vww_notebook_benchmark` fails out of the box** with `FileNotFoundError: './data/vw_coco2014_96'`. The other projects download their data, and `vww` needs a manual download. The README's SiLabs URL returned 403 from my host (one network only, so please try it from another).
3. **The guide has no no-board or GPU path.** It assumes a board, and lists no host prerequisites for `--gpus all` (NVIDIA driver, container toolkit).
4. **The build README points to `akida1/notebooks/`.** The folder in the image is `akida1/model_zoo`.

Smaller items (details in the report)
- The first `arrhythmia` run took 36 minutes, nearly all of it a silent PhysioNet download (about 43 KB/s from my host). The preprocessing takes 41 s.
- The `plant_village` benchmark's Akida evaluation loop uses `batch_size=1` and takes 355 s on the software device. With `batch_size=32` it takes about 15 s, with identical predictions.
- DevHub pins `akida_models==1.14.0` but the image has 1.14.2 (`pip check` reports it). No notebook failed because of it.
- The container needs outbound internet and grows to about 14 GB after the notebooks. The guide doesn't say so.
- Noisy TensorFlow warnings at every start, and no version or commit labels on the images.
- The parent README's validated list has 5 combinations, but 6 images are published. `ubuntu22.04-gpu-x86` worked in my tests.

Not tested
- Anything needing an Akida board: driver installer, device passthrough, Secure Boot flow, hardware inference.
- The CPU and aarch64 images, any training notebook other than `plant_village`, and long-run stability.
- The driver installer README was not shared with me.

Questions
- Is `172.17.0.39:5000` the same registry as `bender:5000`? (`bender` didn't resolve from my host.)
- Where should the `vww` dataset come from?
- Is `batch_size=1` in the benchmark loop deliberate, for hardware runs?

Notebook issues (NB-1 to NB-3 in the report) can go in AK-7601 if you prefer. I can split them out.
