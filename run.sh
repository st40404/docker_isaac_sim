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
# 第 7 張卡，nvidia-smi 編號 GPU 6。換卡時改這個數字。
GPU_DEVICE="${ISAAC_GPU:-6}"

docker_run() {
  local mode="$1"
  shift || true
  docker run --rm -it \
    --name "${CONTAINER_NAME}" \
    --gpus "device=${GPU_DEVICE}" \
    --network host \
    --init \
    --shm-size=8g \
    --ulimit memlock=-1 \
    --ulimit stack=67108864 \
    -e ACCEPT_EULA=Y \
    -e PRIVACY_CONSENT=Y \
    -e OMNI_ENV_PRIVACY_CONSENT=Y \
    -e OMNI_KIT_ALLOW_ROOT=1 \
    -e NVIDIA_VISIBLE_DEVICES="${GPU_DEVICE}" \
    -v "${LOCAL_SRC}:/root/work/src" \
    -v "${ISAAC_LAB_LOGS}:/root/work/IsaacLab/logs" \
    --entrypoint /entrypoint.sh \
    "${IMAGE_NAME}" "${mode}" "$@"
}

case "${1:-}" in
  --isaac|--here)
    echo "[run.sh] GPU ${GPU_DEVICE}：headless Isaac Sim（不開 Terminator）"
    docker_run isaac
    ;;
  --terminator)
    echo "[run.sh] GPU ${GPU_DEVICE}：開啟 Terminator"
    docker run --rm -it \
      --name "${CONTAINER_NAME}" \
      --gpus "device=${GPU_DEVICE}" \
      --network host \
      --init \
      --shm-size=8g \
      --ulimit memlock=-1 \
      --ulimit stack=67108864 \
      -e ACCEPT_EULA=Y \
      -e PRIVACY_CONSENT=Y \
      -e OMNI_ENV_PRIVACY_CONSENT=Y \
      -e OMNI_KIT_ALLOW_ROOT=1 \
      -e NVIDIA_VISIBLE_DEVICES="${GPU_DEVICE}" \
      -e DISPLAY="${DISPLAY:-:0}" \
      -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
      -v "${LOCAL_SRC}:/root/work/src" \
      -v "${ISAAC_LAB_LOGS}:/root/work/IsaacLab/logs" \
      --entrypoint /entrypoint.sh \
      "${IMAGE_NAME}" terminator
    ;;
  -h|--help)
    cat <<EOF
用法:
  ./run.sh              進入容器 shell，使用第 7 張卡（GPU ${GPU_DEVICE}），不開 Terminator
  ./run.sh --isaac      同一張卡，headless 啟動 Isaac Sim
  ./run.sh --terminator 同一張卡，開啟 Terminator（需要 X11）

換卡: ISAAC_GPU=3 ./run.sh
看 3D 畫面（主機）:
  cd ~/isaac_sim_ws/src/squashfs-root && ./AppRun --no-sandbox

首次請先: ./build.sh
EOF
    ;;
  *)
    echo "[run.sh] GPU ${GPU_DEVICE}：進入 shell（不開 Terminator）"
    docker_run bash
    ;;
esac
