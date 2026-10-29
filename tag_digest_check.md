# Tag check: floating tags vs `2.19.3-` versioned tags

REQ-TOOL-005 / AK-7557. Tester: Ali Kayyam. Date: 2026-10-29.
Method: registry API only (manifests and config blobs of `akida-devhub` on `172.17.0.39:5000`). **No image was pulled or run.**

## Question

The Jira says each push gets a floating tag and an immutable `{metatf-version}-ubuntu...` copy. Are the two tags the same image?

## Result: no. In all six pairs they are different builds.

| Image | Floating tag built | `2.19.3-` tag built | Layers (floating / versioned) | Shared layers |
|-------|--------------------|---------------------|-------------------------------|---------------|
| `ubuntu24.04-gpu-x86` | 2026-10-14 | 2026-10-06 | 9 / 8 | 1 |
| `ubuntu22.04-gpu-x86` | 2026-10-14 | 2026-10-05 | 9 / 8 | 1 |
| `ubuntu24.04-cpu-x86` | 2026-10-14 | 2026-10-05 | 9 / 8 | 1 |
| `ubuntu22.04-cpu-x86` | 2026-10-14 | 2026-10-05 | 9 / 8 | 1 |
| `ubuntu24.04-cpu-aarch64` | 2026-10-14 | 2026-10-06 | 9 / 8 | 1 |
| `ubuntu22.04-cpu-aarch64` | 2026-10-14 | 2026-10-06 | 9 / 8 | 1 |

Digests (first 19 characters), floating then versioned:

| Image | Floating | Versioned |
|-------|----------|-----------|
| `ubuntu24.04-gpu-x86` | `sha256:b50e7eb348b` | `sha256:70f96911d5e` |
| `ubuntu22.04-gpu-x86` | `sha256:93a9f848efb` | `sha256:df3245b5e5c` |
| `ubuntu24.04-cpu-x86` | `sha256:5f32c655c49` | `sha256:cb25f5ab120` |
| `ubuntu22.04-cpu-x86` | `sha256:15ab7207217` | `sha256:84d98fa6f55` |
| `ubuntu24.04-cpu-aarch64` | `sha256:c533329f1a9` | `sha256:825859a3852` |
| `ubuntu22.04-cpu-aarch64` | `sha256:9604ab4f2b9` | `sha256:7b80f62a5e4` |

The floating digests for `ubuntu24.04-gpu-x86` and `ubuntu24.04-cpu-aarch64` match the images that were pulled and tested in `report.md`.

## What differs (checked on `ubuntu24.04-gpu-x86`, from the build history)

- The floating tag has an extra last layer (363 MB): `git clone https://github.com/Brainchip-Inc/brainchip_devhub.git`, using build argument `DEVHUB_COMMIT=8be7c232...`.
- The `2.19.3-` tag has **no DevHub clone step** and no `DEVHUB_COMMIT` argument in its history. It is the SDK image from before DevHub was added.
- The Python environment layer is also slightly different (3095 MB against 3093 MB).
- Entrypoint, CMD, user, workdir and the version label are the same in both.

The history of the other five pairs was not read. They show the same pattern (9 against 8 layers, 1 shared layer, same date gap), but I only confirmed the cause on `ubuntu24.04-gpu-x86`.

## Finding

**DOC-23 (proposed Major, to be confirmed):** the version-pinned tags do not appear to contain DevHub, which is the point of REQ-TOOL-005. Only the floating tags carry it. Anyone who pins `2.19.3-ubuntu...` for reproducible work (the purpose the Jira gives it, and what DOC-12 asks the guide to explain) would get an image without `brainchip_devhub`. The tag is also not immutable in practice, because it is a different build from the floating one.

**Not yet confirmed:** the history shows no DevHub layer, but I did not pull a `2.19.3-` image to check that `/workspace/brainchip_devhub` is missing. That would take about 4 minutes and 7 GB (or 4 GB for aarch64).

## Questions for the owners

- Is the `2.19.3-` tag meant to be a copy of the floating tag at push time? If so, the last push did not update it.
- Should a new versioned tag, with DevHub, be published?
- Does `push_all.sh` create the versioned tag from the build, or retag an older image?
