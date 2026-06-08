#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SRC="$(cd "${SCRIPT_DIR}/.." && pwd)"

IMAGE_NAME=isaac-sim-5.1.0-tools
# 若自訂 image 仍有問題，可改回官方 image：
# IMAGE_NAME=nvcr.io/nvidia/isaac-sim:5.1.0

CONTAINER_NAME=isaac-sim-webrtc

allow_x11() {
  if command -v xhost >/dev/null 2>&1; then
    xhost +local:docker >/dev/null 2>&1 || xhost +local:root >/dev/null 2>&1 || true
  fi
}

MODE="${1:-terminator}"
if [[ "${1:-}" == "--isaac" ]] || [[ "${1:-}" == "--here" ]]; then
  MODE="isaac"
fi

allow_x11

echo "[run.sh] 啟動模式: ${MODE}（Terminator 版面: 上 Isaac Sim / 下 Shell）"

docker run --rm -it \
  --name "${CONTAINER_NAME}" \
  --gpus all \
  --network host \
  --init \
  --shm-size=8g \
  --ulimit memlock=-1 \
  --ulimit stack=67108864 \
  -e ACCEPT_EULA=Y \
  -e PRIVACY_CONSENT=Y \
  -e OMNI_ENV_PRIVACY_CONSENT=Y \
  -e OMNI_KIT_ALLOW_ROOT=1 \
  -e DISPLAY="${DISPLAY:-:0}" \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v "${LOCAL_SRC}:/root/work/src" \
  "${IMAGE_NAME}" \
  "${MODE}"
