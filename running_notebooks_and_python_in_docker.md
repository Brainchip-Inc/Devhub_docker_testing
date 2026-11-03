# Running notebooks and Python code in the Akida Docker image

This guide shows how to start the Akida Docker image and run code in it: the example notebooks (in your browser or from the command line), your own Python scripts, and the example scripts that ship with DevHub. You do not need to install the Akida software on your machine. It is all inside the image.

## What you need

- **Docker** on your machine (Linux).
- **The image** that matches your machine (see the table in step 1). Pull it with its full name, `<registry>/akida-devhub:<tag>`. Your BrainChip contact will tell you what `<registry>` is.
- **Internet access** from the container. The notebooks download datasets and pretrained files the first time you run them.
- **Disk space:** the image is 4 to 8 GB, and the notebooks add up to about 15 GB of datasets on top. Plan for 25 GB free.
- **Optional:** an NVIDIA GPU (for training), or an Akida board (for running on hardware). Everything below also works with neither.

## 1. Start the container

Pick the image that matches your machine:

| Your machine | Image tag | Use it for |
|--------------|-----------|------------|
| x86 PC with an NVIDIA GPU | `ubuntu24.04-gpu-x86` or `ubuntu22.04-gpu-x86` | Training and inference |
| x86 PC, no GPU | `ubuntu24.04-cpu-x86` or `ubuntu22.04-cpu-x86` | Inference only |
| Raspberry Pi 5 | `ubuntu24.04-cpu-aarch64` or `ubuntu22.04-cpu-aarch64` | Inference only |

The Ubuntu version is the one inside the container, so pick the one you want your code to run on. If you are not sure, use 24.04.

Set the image name once, then start the container. This is the basic command (no GPU, no board):

```bash
mkdir -p work                                           # your own files go here
IMAGE=<registry>/akida-devhub:ubuntu24.04-cpu-x86      # use the full name, as pulled

docker run -d --name akida-dev \
    -p 127.0.0.1:8888:8888 \
    -v "$PWD/work:/workspace/work" \
    $IMAGE
```

What the options do:

- `--name akida-dev` gives the container a name that the later commands use.
- `-p 127.0.0.1:8888:8888` makes JupyterLab reachable from your own machine only.
- `-v "$PWD/work:/workspace/work"` makes a folder called `work` next to you appear inside the container. Put your own scripts and data there. Create it first, as in the command above, or Docker creates it owned by root. Do not mount over `/workspace` itself, because the DevHub examples live there.

Add one of these, depending on your setup:

| If you have | Add to the `docker run` command |
|-------------|----------------------------------|
| An NVIDIA GPU | `--gpus all`. Your host needs the NVIDIA driver and the NVIDIA Container Toolkit. |
| An Akida board | `--device /dev/akd1500_0`. The Akida PCIe driver must already be installed on the host. Check that the device file exists with `ls /dev \| grep akd`, and use the name you see. |

You do not need `--privileged` for any of this.

**If you see `pull access denied`:** you used the short name `akida-devhub:<tag>`. Use the full name, including the registry, in both `docker pull` and `docker run`.

## 2. Check that it works

```bash
docker exec akida-dev python -c "import akida; print(akida.__version__, akida.devices())"
```

You should see the Akida version followed by a list of devices:

- `2.19.3 []` means the software is working and there is no board. Your code runs on the software device.
- A version followed by a list that is not empty means the container can see your board.

If you have a board and you see `[]`, go to Troubleshooting.

The container prints some TensorFlow warnings at startup. They are normal.

## 3. Option A: JupyterLab in your browser

The container starts JupyterLab by default. It asks for a token, which is printed in the container's log:

```bash
docker logs akida-dev 2>&1 | grep "token="
```

Open the link that starts with `http://127.0.0.1:8888/lab?token=...` in your browser. If you run Docker on another machine, create an SSH tunnel first (`ssh -L 8888:127.0.0.1:8888 user@that-machine`), then use the same link on your own machine.

In the file browser on the left, open `brainchip_devhub`, then `akida1`, then `model_zoo`. Each folder is one example. Open a notebook and use **Run > Run All Cells**.

Good notebooks to start with:

| Notebook (under `brainchip_devhub/akida1/model_zoo/`) | What it does | Time on our test machines |
|--------------------------------------------------------|--------------|---------------------------|
| `imagenet_akidanet/imagenet_akidanet_notebook_evaluation` | Quick check of the float, quantized and Akida versions of one model, on a small sample | under 2 minutes |
| `plant_village/plant_village_notebook_benchmark` | Evaluates a pretrained model and benchmarks it. On a board it also measures latency. | 6 to 12 minutes the first time (it downloads the dataset) |
| `speech_commands/speech_commands_notebook_benchmark` | The same for a keyword-spotting model | 6 to 23 minutes the first time |
| `arrhythmia_classification/arrhythmia_notebook_benchmark` | The same for an ECG model | 7 to 35 minutes the first time, depending on your network |
| `plant_village/plant_village_notebook_training` | Trains a model, quantizes it, converts it to Akida. Use a GPU image. | longer, depends on your GPU |

The notebooks check whether a board is present. If there is none, the cells that need hardware are skipped, and the rest runs on the software device.

Known issue: `vww/vww_notebook_benchmark` fails with `FileNotFoundError: './data/vw_coco2014_96'` unless you download that dataset yourself first. The README in the `vww` folder says where to get it.

## 4. Option B: run a notebook from the command line

This runs a notebook without a browser, and saves the executed copy with its outputs:

```bash
docker exec -w /workspace akida-dev jupyter nbconvert --to notebook --execute \
    --ExecutePreprocessor.timeout=-1 --output-dir /tmp/executed \
    brainchip_devhub/akida1/model_zoo/imagenet_akidanet/imagenet_akidanet_notebook_evaluation.ipynb
```

`--ExecutePreprocessor.timeout=-1` stops it giving up on a slow cell. Then copy the result out of the container:

```bash
docker cp akida-dev:/tmp/executed/. ./executed
```

Use `--to html` instead of `--to notebook` to get a web page you can open without Jupyter.

## 5. Option C: run Python scripts

**One line:**

```bash
docker exec akida-dev python -c "import akida; print(akida.devices())"
```

**A script of your own.** Put it in the `work` folder you mounted in step 1, and run it from outside the container:

```bash
docker exec akida-dev python /workspace/work/my_script.py
```

Or send a script from your machine without mounting anything:

```bash
docker exec -i akida-dev python - < my_script.py
```

**An interactive shell:**

```bash
docker exec -it akida-dev bash
python          # then type Python as usual
```

Python inside the container is Python 3.12 (Ubuntu 24.04 images) or 3.10 (22.04 images), with the Akida packages (`akida`, `cnn2snn`, `quantizeml`, `akida_models`, `metatf`) and TensorFlow already installed.

**Example script.** This loads a pretrained Akida model that ships in the image and runs a few inputs through it. It uses the board if there is one, and the software device otherwise. Save it as `work/predict_demo.py`:

```python
import numpy as np
import akida

model = akida.Model("/workspace/brainchip_devhub/akida1/model_zoo/plant_village/pretrained_models/akidanet_plant_village_qat.fbz")
print("layers:", len(model.layers), "| input shape:", model.input_shape, "| output shape:", model.output_shape)

devices = akida.devices()
if devices:
    model.map(devices[0], mode=akida.MapMode.AllNps, hw_only=True)
    print("running on:", devices[0].desc)
else:
    print("no board found, running on the software device")

# Random noise images, so the class ids below mean nothing. Use real images of the right size.
images = np.random.randint(0, 256, size=(4,) + tuple(model.input_shape), dtype=np.uint8)
out = model.predict(images)
print("predictions (class ids):", out.squeeze().argmax(axis=-1))
```

Run it with `docker exec akida-dev python /workspace/work/predict_demo.py`. The output starts with `layers: 16 | input shape: [224, 224, 3] | output shape: [1, 1, 38]`.

**The example scripts in DevHub.** Each project folder also has scripts you can run directly. For example, to evaluate the pretrained PlantVillage model:

```bash
docker exec -w /workspace/brainchip_devhub/akida1/model_zoo/plant_village akida-dev \
    python plant_village_eval.py -l pretrained_models/akidanet_plant_village_qat.fbz
```

It downloads the dataset on its first run (about a minute and a half in our test) and prints the accuracy of the Akida model, `Akida accuracy: 0.9943`. The project's own `README.md` (in the same folder) describes the other scripts, including `plant_village_train.sh`, which runs the whole training pipeline, and its options. Use a GPU image for training.

## 6. Writing files, saving work, and cleaning up

**Files your code writes to the mounted `work` folder** can fail with `PermissionError`. The container runs as user ID 1000, and your host folder belongs to you. Either of these fixes it:

- Run the command as yourself: `docker exec -u "$(id -u):$(id -g)" akida-dev python /workspace/work/my_script.py`
- Or make the folder writable for all users on the host: `chmod a+rwx work`. This also covers files saved from JupyterLab.

**Stopping and restarting.** Stopping keeps everything you did inside the container:

```bash
docker stop akida-dev
docker start akida-dev
docker logs akida-dev 2>&1 | grep "token="     # to find the current JupyterLab link
```

**Copying files out** (for anything not in the mounted folder):

```bash
docker cp akida-dev:/workspace/brainchip_devhub/akida1/model_zoo/plant_village/models ./models    # where the training scripts save models
```

**Removing the container** deletes everything inside it, including downloaded datasets and anything you saved outside the mounted folder. Copy out what you need first.

```bash
docker rm -f akida-dev
```

## Troubleshooting

| Problem | What to do |
|---------|------------|
| `pull access denied` when you run the container | Use the full image name, including the registry, in `docker run`. |
| `docker: Error ... Conflict. The container name "/akida-dev" is already in use` | A container with that name exists. Use `docker start akida-dev`, or remove it with `docker rm -f akida-dev` and run again. |
| Port 8888 is already in use | Use another port on the left side: `-p 127.0.0.1:8889:8888`, then open `http://127.0.0.1:8889`. |
| Docker rejects `--gpus all` | The NVIDIA driver or the NVIDIA Container Toolkit is not set up on the host. Fix that, or use a CPU image. |
| `akida.devices()` is `[]` but you have a board | On the host, check that the driver is loaded (`lsmod \| grep akida`), that the board is detected (`lspci \| grep -i brainchip`), and that the device file exists (`ls /dev \| grep akd`). Then start the container again with `--device /dev/<that name>`. |
| `PermissionError` when writing to the `work` folder | See section 6. |
| A notebook seems stuck for many minutes | The first run downloads datasets, and some cells print nothing until they finish. Let it run, and check `docker stats akida-dev` or your network use. |
| `FileNotFoundError: './data/vw_coco2014_96'` | The `vww` dataset must be downloaded separately. See section 3. |
| Disk fills up | The datasets are large (one notebook alone needs about 11 GB). Use `docker system df` to see usage, and `docker rm -f akida-dev` when you are done. |
