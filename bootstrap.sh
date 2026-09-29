#!/usr/bin/env bash
# Set Colab up for the Stein Flow trainer: apt Qt, the stein_train bundle, its starting weights, and
# the CUDA 13 runtime it was built with. Run by the notebook. Idempotent - a second run is quick.
#
# Everything that is fetched is fetched at once - apt, the two tarballs and each CUDA wheel in its
# own process - so the wait is the longest of them, not their sum. Then it is unpacked in order.
set -euo pipefail

REPO="${REPO:-steinflow47/stein-flow-trainer}"
BUNDLE_URL="${BUNDLE_URL:-https://github.com/$REPO/releases/latest/download/stein-trainer-linux-x86_64.tar.gz}"
# The pretrained weights (~300 MB) are a separate asset on a fixed Release tag, so a trainer update
# does not re-download them and re-runs skip them once they are here.
PRETRAINED_TAG="${PRETRAINED_TAG:-pretrained}"
PRETRAINED_URL="${PRETRAINED_URL:-https://github.com/$REPO/releases/download/$PRETRAINED_TAG/stein-trainer-pretrained.tar.gz}"
ROOT="${ROOT:-/content/stein-trainer}"
B="$ROOT/stein_trainer"
NV="$ROOT/nvidia"
DL="$ROOT/.download"
# The trainer is built with CUDA 13.3, cuBLAS 13.6, cuRAND 10.4 and cuDNN 9.26; Colab carries CUDA 12.
# NVIDIA's own wheels, pinned to those versions, go in a folder of their own (not Colab's Python, so
# nothing of PyTorch's CUDA 12 changes), and their libraries are linked into the bundle's lib/, which
# the trainer looks in first.
CUDA_WHEELS="nvidia-cuda-runtime==13.3.29 nvidia-cublas==13.6.0.2 nvidia-curand==10.4.3.29 nvidia-cudnn-cu13==9.26.0.51"

need_qt=0; ldconfig -p | grep -q 'libQt5Core\.so\.5' || need_qt=1
need_bundle=0; [ -x "$B/bin/stein_train" ] || need_bundle=1
# darknet19.conv.23 is the marker: if it is here, the pack is already unpacked.
need_weights=0; [ -f "$B/share/stein_dnn_darknet/pretrained/darknet19.conv.23" ] || need_weights=1
need_cuda=0; [ -e "$B/lib/libcudart.so.13" ] || need_cuda=1

rm -rf "$DL"
mkdir -p "$DL/wheels" "$DL/logs"
pids=(); names=()
fetch() {   # fetch <name> <command...>: in the background, its output in a log of its own
    local name=$1; shift
    "$@" > "$DL/logs/$name.log" 2>&1 &
    pids+=($!); names+=("$name")
}
[ $need_qt = 1 ] && fetch "Qt 5" bash -c 'sudo apt-get -qq update && sudo apt-get -qq install -y libqt5core5t64'   # Ubuntu 24.04 name
[ $need_bundle = 1 ] && fetch "trainer" curl -fSL "$BUNDLE_URL" -o "$DL/trainer.tar.gz"
[ $need_weights = 1 ] && fetch "weights" curl -fSL "$PRETRAINED_URL" -o "$DL/weights.tar.gz"
if [ $need_cuda = 1 ]; then
    for w in $CUDA_WHEELS; do
        fetch "${w%%==*}" python3 -m pip download -q --no-deps --only-binary=:all: --no-cache-dir \
            --disable-pip-version-check -d "$DL/wheels" "$w"
    done
fi

# Each as it finishes (wait -n, bash 5.1+), only over those still running: a pid already waited
# for is no longer a child, and waiting on it again would read as a failure.
total=${#pids[@]} failed=()
declare -A running=()
for i in "${!pids[@]}"; do running[${pids[$i]}]=$i; done
[ "$total" -gt 0 ] && echo "• downloading ${total} at once (0 of ${total} done)"
while [ ${#running[@]} -gt 0 ]; do
    finished=""
    if wait -n -p finished "${!running[@]}"; then ok=1; else ok=0; fi
    [ -n "$finished" ] || { echo "lost track of a download" >&2; exit 1; }
    i=${running[$finished]}
    unset "running[$finished]"
    [ $ok = 1 ] || failed+=("${names[$i]}")
    echo "  ${names[$i]}: $([ $ok = 1 ] && echo done || echo FAILED)"
    if [ ${#running[@]} -gt 0 ]; then echo "• downloading ${total} at once ($((total - ${#running[@]})) of ${total} done)"; fi
done
if [ ${#failed[@]} -gt 0 ]; then
    for n in "${failed[@]}"; do
        echo "--- $n"
        tail -n 15 "$DL/logs/$n.log"
    done
    exit 1
fi

echo "• unpacking"
mkdir -p "$ROOT"
[ $need_bundle = 1 ] && tar -C "$ROOT" -xzf "$DL/trainer.tar.gz"
echo "  trainer $(cat "$B/VERSION" 2>/dev/null || echo '?')"
[ $need_weights = 1 ] && tar -C "$ROOT" -xzf "$DL/weights.tar.gz" && echo "  starting weights"
if [ $need_cuda = 1 ]; then
    python3 -m pip install -q --no-deps --no-index --disable-pip-version-check --target "$NV" "$DL"/wheels/*.whl
    find "$NV" -name 'lib*.so*' | while read -r f; do ln -sf "$f" "$B/lib/$(basename "$f")"; done
    echo "  CUDA 13 runtime"
fi
rm -rf "$DL"

missing=$(ldd "$B/bin/stein_train" 2>/dev/null | awk '/not found/{print "    "$1}' | sort -u || true)
if [ -n "$missing" ]; then
    echo "  libraries the trainer cannot find:"
    echo "$missing"
    exit 1
fi
echo "ready"
