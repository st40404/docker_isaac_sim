#!/usr/bin/env bash

set -e

IMAGE_NAME=isaac-sim-5.1.0-tools
CONTAINER_NAME=isaac-sim-webrtc

# Workspace on host
WS_PATH=${HOME}/isaac_sim_ws

docker run -it --rm \
  --name ${CONTAINER_NAME} \
  --gpus all \
  --network host \
  --ipc=host \
  -e ACCEPT_EULA=Y \
  -e PRIVACY_CONSENT=Y \
  -v ${WS_PATH}:/workspace \
  ${IMAGE_NAME} \
  ./runheadless.webrtc.sh