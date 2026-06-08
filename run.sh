#!/usr/bin/env bash
set -e

IMAGE_NAME=isaac-sim-5.1.0-tools
# 若自訂 image 仍有問題，可改回官方 image：
# IMAGE_NAME=nvcr.io/nvidia/isaac-sim:5.1.0

CONTAINER_NAME=isaac-sim-webrtc
LOCAL_SRC="/home/ron/isaac_sim_ws/src"

docker run --rm -it \
  --name ${CONTAINER_NAME} \
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
  -v ${LOCAL_SRC}:/root/work/src \
  ${IMAGE_NAME} \
  --/renderer/active=Storm
