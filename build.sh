#!/usr/bin/env bash
set -e

# Image config
IMAGE_NAME=isaac-sim-5.1.0-tools
DOCKERFILE=Dockerfile
CONTEXT_DIR=$(dirname "$(readlink -f "$0")")

echo "Building image: ${IMAGE_NAME}"

docker build \
  --network=host \
  -t ${IMAGE_NAME} \
  -f ${CONTEXT_DIR}/${DOCKERFILE} \
  ${CONTEXT_DIR}