#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SRC="$(cd "${SCRIPT_DIR}/.." && pwd)"
ISAAC_LAB_LOGS="${LOCAL_SRC}/isaac-lab-logs"

mkdir -p "${ISAAC_LAB_LOGS}"

IMAGE_NAME=isaac-sim-5.1.0-tools
# 若自訂 image 仍有問題，可改回官方 image：
# IMAGE_NAME=nvcr.io/nvidia/isaac-sim:5.1.0

CONTAINER_NAME=isaac-sim-webrtc

allow_x11() {
  if command -v xhost >/dev/null 2>&1; then
    xhost +local:docker >/dev/null 2>&1 || xhost +local:root >/dev/null 2>&1 || true
  fi
}

docker_common() {
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
    -v "${ISAAC_LAB_LOGS}:/root/work/IsaacLab/logs" \
    "${IMAGE_NAME}"
}

allow_x11

case "${1:-}" in
  --isaac|--here)
    echo "[run.sh] 直接啟動 Isaac Sim（不開 Terminator）"
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
      -v "${LOCAL_SRC}:/root/work/src" \
      -v "${ISAAC_LAB_LOGS}:/root/work/IsaacLab/logs" \
      --entrypoint /entrypoint.sh \
      "${IMAGE_NAME}" isaac
    ;;
  -h|--help)
    cat <<EOF
用法:
  ./run.sh              開啟 Terminator 並自動啟動 Isaac Sim（上: Isaac / 下: Shell）
  ./run.sh --isaac      不開 Terminator，直接 headless 啟動 Isaac Sim

Terminator 下方 Shell 也可手動執行:
  start-isaac

看 3D 畫面（主機）:
  cd ~/isaac_sim_ws/src/squashfs-root && ./AppRun --no-sandbox

首次請先: ./build.sh
主機請先: xhost +local:docker
EOF
    ;;
  *)
    echo "[run.sh] 啟動 Terminator 並自動執行 start-isaac"
    docker_common
    ;;
esac
