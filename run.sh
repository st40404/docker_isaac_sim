#!/usr/bin/env bash
set -e

IMAGE_NAME=isaac-sim-5.1.0-tools
CONTAINER_NAME=isaac-sim-webrtc

docker run --rm \
  --name ${CONTAINER_NAME} \
  --gpus all \
  --network host \
  --ipc host \
  --init \
  -e ACCEPT_EULA=Y \
  -e PRIVACY_CONSENT=Y \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  ${IMAGE_NAME}