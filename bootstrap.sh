#!/usr/bin/env bash
# Set Colab up for the Stein Flow trainer: apt Qt, the stein_train bundle, and a check that Colab's
# CUDA/cuDNN match what the binary needs. Run from the notebook's first cell. It only installs and
# downloads; the notebook then sets the environment in Python (env from a script does not cross into
# the kernel). Idempotent - a second run is quick.
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

echo "• CUDA / cuDNN"
# The binary was built against CUDA 13 and cuDNN 9. Colab usually ships a CUDA; if its major differs,
# the GPU libraries below show as "not found" and training would fall to no card. Say so plainly.
missing=$(LD_LIBRARY_PATH="$B/lib" ldd "$B/bin/stein_train" 2>/dev/null | awk '/not found/{print "    "$1}' || true)
if [ -n "$missing" ]; then
    echo "  some libraries are missing on this Colab (GPU may be unavailable):"
    echo "$missing"
    echo "  most are CUDA 13 / cuDNN 9. If Colab has a different CUDA, tell the owner - bootstrap will"
    echo "  install a matching toolkit here (not wired yet: it is a large download)."
else
    echo "  all libraries resolve"
fi

echo "ready — the next cell opens the Workbench"
