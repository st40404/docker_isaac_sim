#!/usr/bin/env bash
set -e

IMAGE_NAME=isaac-sim-5.1.0-tools

echo "Building image: ${IMAGE_NAME}"

docker build \
  --network=host \
  -t ${IMAGE_NAME} \
  -f Dockerfile .