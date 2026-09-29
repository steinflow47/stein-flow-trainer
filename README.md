# Stein Flow — Trainer for Colab

Train Stein Flow models on Google Colab's GPU, free, from a dataset you labelled in Stein Flow.
Label and train for nothing; what you get back — a sealed `.stmd` model — opens in Stein Flow's
Detect.

**Flint** · steinflow47@users.noreply.github.com

## Open in Colab

- **Train Detect** — [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/steinflow47/stein-flow-trainer/blob/main/Train_Detect.ipynb)
- **Train Classify** — coming soon.

In Stein Flow: the labeler's **More → Export for notebook (.zip)**. Open a notebook above, run the
**Setup** cell, then the **Workbench** cell, and upload that zip.

## What is here

- `Train_Detect.ipynb` — the Colab notebook (Setup cell + the Workbench).
- `bootstrap.sh` — what the Setup cell runs on Colab: apt Qt 5, the `stein_train` bundle, a
  CUDA/cuDNN check. It downloads the prebuilt binary bundle from this repo's **Releases**.
- `images/` — the logo and icons the notebooks show.

The trainer needs Colab's GPU (Runtime → Change runtime type → GPU). It was built for Ubuntu 24.04,
which Colab runs, with CUDA 13 and cuDNN 9.

---
© Flint. All rights reserved. Stein Flow is proprietary; this repository holds only the
Colab launcher, never the source.
