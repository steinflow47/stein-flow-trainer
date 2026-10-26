# Stein Flow — Trainer for Colab

Train Stein Flow models on Google Colab's GPU, free, from a dataset you labelled in Stein Flow.
Label and train for nothing; what you get back — a `.stmd`, `.stmc`, `.stms` or `.stmi` model — opens in Stein Flow's Detect, Classify, Segment or I·Segment.

**Flint** · steinflow47@users.noreply.github.com

## Open in Colab

| Notebook | |
|---|---|
| **Train Detect** | [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/steinflow47/stein-flow-trainer/blob/main/Train_Detect.ipynb) |
| **Train Classify** | [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/steinflow47/stein-flow-trainer/blob/main/Train_Classify.ipynb) |
| **Train Segment** | [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/steinflow47/stein-flow-trainer/blob/main/Train_Segment.ipynb) |
| **Train Sound** | [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/steinflow47/stein-flow-trainer/blob/main/Train_Sound.ipynb) |
| **Train Sound Classify** | [![Open In Colab](https://colab.research.google.com/assets/colab-badge.svg)](https://colab.research.google.com/github/steinflow47/stein-flow-trainer/blob/main/Train_Sound_Classify.ipynb) |

In Stein Flow, in the Train node's window: **File → Export to zip…** (and **File → Train on Google Colab…** opens
its notebook here) - Train Detect's for a detector, Train Classify's for a classifier and Train Segment's (its masks and polygons; the architecture you choose says whether it trains a
semantic or an instance segmenter), Train Sound's for a sound event detector (its sounds and boxes), Train Sound Classify's for a sound classifier (a folder of sounds per class). Open
the notebook above, press
▶ (it installs the trainer the first time and opens the Workbench), and choose that zip.

**Use of the trainer is subject to [TERMS.txt](TERMS.txt)** - free for learning and for commercial
training; a model it trains is for use in Stein Flow.

## What is here

- `Train_Detect.ipynb`, `Train_Classify.ipynb`, `Train_Segment.ipynb`, `Train_Sound.ipynb`, `Train_Sound_Classify.ipynb` — the Colab notebooks: one cell that installs the trainer and opens the Workbench.
- `bootstrap.sh` — what the notebook runs first on Colab: apt Qt 5, the `stein_train` bundle, a
  CUDA/cuDNN check. It downloads the prebuilt binary bundle from this repo's **Releases**.
- `TERMS.txt` — the terms of use (also packed with the trainer).
- `images/` — the icons the notebooks show.

The trainer needs Colab's GPU (Runtime → Change runtime type → GPU). It was built for Ubuntu 24.04,
which Colab runs, with CUDA 13 and cuDNN 9.

---
© Flint. All rights reserved. Stein Flow is proprietary; this repository holds only the
Colab launcher, never the source.
