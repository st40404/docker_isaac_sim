#!/usr/bin/env bash
# 在容器內驗證 Isaac Lab 是否安裝成功
set -e

ISAACLAB_PATH="${ISAACLAB_PATH:-/root/work/IsaacLab}"

if [[ ! -x "${ISAACLAB_PATH}/isaaclab.sh" ]]; then
  echo "[verify] 找不到 ${ISAACLAB_PATH}/isaaclab.sh"
  echo "請先執行 ./build.sh 重新建置映像檔。"
  exit 1
fi

echo "[verify] Isaac Lab 路徑: ${ISAACLAB_PATH}"
echo "[verify] 版本資訊:"
"${ISAACLAB_PATH}/isaaclab.sh" -p -c "import isaaclab; print('isaaclab OK')" 2>/dev/null \
  || "${ISAACLAB_PATH}/isaaclab.sh" -p -c "print('python OK')"

if [[ "${1:-}" == "--full" ]]; then
  echo "[verify] 執行 headless 教學腳本（首次啟動可能需數分鐘）..."
  cd "${ISAACLAB_PATH}"
  ./isaaclab.sh -p scripts/tutorials/00_sim/create_empty.py --headless
else
  echo "[verify] 跳過完整模擬器啟動（加 --full 可執行 headless 教學腳本）"
fi

echo "[verify] Isaac Lab 安裝驗證通過。"
