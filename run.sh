#!/usr/bin/env bash
set -e

IMAGE_NAME=isaac-sim-5.1.0-tools
CONTAINER_NAME=isaac-sim-webrtc

# 這裡請確認路徑正確
# 我們掛載整個 description 資料夾，這樣內部的 mesh (stl/dae) 才能被找到
LOCAL_ROBOT_DIR="/home/ron/isaac_sim_ws/src/robot_description/HU_D04_description"
LOCAL_SCRIPT="/home/ron/isaac_sim_ws/src/robot_description/scripts"

docker run --rm -it \
  --name ${CONTAINER_NAME} \
  --user root \
  --gpus all \
  --network host \
  --ipc host \
  --init \
  -e ACCEPT_EULA=Y \
  -e PRIVACY_CONSENT=Y \
  -v ${LOCAL_ROBOT_DIR}:/root/work/HU_D04_description \
  -v ${LOCAL_SCRIPT}:/root/work/scripts \
  ${IMAGE_NAME}
  # ./python.sh /root/scripts/load_robot.py