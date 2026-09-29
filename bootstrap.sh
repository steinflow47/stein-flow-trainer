#!/usr/bin/env bash
# Set Colab up for the Stein Flow trainer: apt Qt, the stein_train bundle, its starting weights, and
# the CUDA 13 runtime it was built with. Run by the notebook. Idempotent - a second run is quick.
set -euo pipefail

REPO="${REPO:-steinflow47/stein-flow-trainer}"
BUNDLE_URL="${BUNDLE_URL:-https://github.com/$REPO/releases/latest/download/stein-trainer-linux-x86_64.tar.gz}"
# The pretrained weights (~300 MB) are a separate asset on a fixed Release tag, so a trainer update
# does not re-download them and re-runs skip them once they are here.
PRETRAINED_TAG="${PRETRAINED_TAG:-pretrained}"
PRETRAINED_URL="${PRETRAINED_URL:-https://github.com/$REPO/releases/download/$PRETRAINED_TAG/stein-trainer-pretrained.tar.gz}"
ROOT="${ROOT:-/content/stein-trainer}"
B="$ROOT/stein_trainer"

echo "• Qt 5 (apt)"
if ! ldconfig -p | grep -q 'libQt5Core\.so\.5'; then
    sudo apt-get -qq update
    sudo apt-get -qq install -y libqt5core5t64 >/dev/null   # Ubuntu 24.04 name; pulls libicu, pcre2, glib
fi

echo "• stein_train bundle"
if [ ! -x "$B/bin/stein_train" ]; then
    mkdir -p "$ROOT"
    curl -fSL "$BUNDLE_URL" -o /tmp/stein-trainer.tar.gz
    tar -C "$ROOT" -xzf /tmp/stein-trainer.tar.gz
fi
echo "  version $(cat "$B/VERSION" 2>/dev/null || echo '?')"

echo "• pretrained weights"
# Its own download so a trainer update need not re-ship ~300 MB. darknet19.conv.23 is the marker: if
# it is here, the pack is already unpacked (a re-run, or extracted with the bundle).
if [ ! -f "$B/share/stein_dnn_darknet/pretrained/darknet19.conv.23" ]; then
    mkdir -p "$ROOT"
    curl -fSL "$PRETRAINED_URL" -o /tmp/stein-pretrained.tar.gz
    tar -C "$ROOT" -xzf /tmp/stein-pretrained.tar.gz
    echo "  downloaded"
else
    echo "  already present"
fi

echo "• CUDA 13 runtime (NVIDIA, from PyPI)"
# The trainer is built with CUDA 13.3, cuBLAS 13.6, cuRAND 10.4 and cuDNN 9.26; Colab carries CUDA 12.
# NVIDIA's own wheels, pinned to those versions, go in a folder of their own (not Colab's Python, so
# nothing of PyTorch's CUDA 12 changes), and their libraries are linked into the bundle's lib/, which
# the trainer looks in first.
NV="$ROOT/nvidia"
if [ ! -e "$B/lib/libcudart.so.13" ]; then
    python3 -m pip install -q --no-deps --disable-pip-version-check --target "$NV" \
        nvidia-cuda-runtime==13.3.29 nvidia-cublas==13.6.0.2 nvidia-curand==10.4.3.29 \
        nvidia-cudnn-cu13==9.26.0.51
    find "$NV" -name 'lib*.so*' | while read -r f; do ln -sf "$f" "$B/lib/$(basename "$f")"; done
    echo "  installed"
else
    echo "  already present"
fi

missing=$(ldd "$B/bin/stein_train" 2>/dev/null | awk '/not found/{print "    "$1}' | sort -u || true)
if [ -n "$missing" ]; then
    echo "  libraries the trainer cannot find:"
    echo "$missing"
    exit 1
fi
echo "ready"
