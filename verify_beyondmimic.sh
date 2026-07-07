#!/usr/bin/env bash
# Smoke-test BeyondMimic (whole_body_tracking) on Isaac Lab 2.3.x + Isaac Sim 5.1.
set -euo pipefail

ISAACLAB_PATH="${ISAACLAB_PATH:-/root/work/IsaacLab}"
WBT_ROOT="${WBT_ROOT:-/root/work/src/whole_body_tracking}"
TRAIN_PY="${WBT_ROOT}/scripts/rsl_rl/train.py"
CUDA_ENV="/root/work/src/docker/isaac_cuda_env.sh"
FULL_SIM=1

usage() {
  cat <<'EOF'
Usage: verify_beyondmimic.sh [--quick]

  --quick   只檢查 pip / 檔案 / train.py 修補，不啟動 Isaac Sim（數秒）
  (default) 另啟動 headless Sim 驗證任務註冊（約 1–2 分鐘；勿與 start-isaac 同時跑）
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quick) FULL_SIM=0; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[verify_beyondmimic] unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -f "${CUDA_ENV}" ]]; then
  # shellcheck disable=SC1091
  source "${CUDA_ENV}"
fi

if [[ ! -x "${ISAACLAB_PATH}/isaaclab.sh" ]]; then
  echo "[verify_beyondmimic] 找不到 ${ISAACLAB_PATH}/isaaclab.sh"
  exit 1
fi

echo "[verify_beyondmimic] 1/3 pip 安裝"
"${ISAACLAB_PATH}/isaaclab.sh" -p -m pip show whole_body_tracking | grep -E "^(Name|Version|Editable)"

UNITREE_XML="${WBT_ROOT}/source/whole_body_tracking/whole_body_tracking/assets/unitree_description/package.xml"
if [[ -f "${UNITREE_XML}" ]]; then
  echo "[verify_beyondmimic] unitree_description OK"
else
  echo "[verify_beyondmimic] WARN: 缺少 unitree_description，G1 任務可能無法載入"
  echo "  執行: /root/work/src/docker/setup_beyondmimic.sh --download-unitree"
fi

echo "[verify_beyondmimic] 2/3 train.py 相容 Isaac Lab 2.3"
if grep -q 'dump_pickle' "${TRAIN_PY}" 2>/dev/null; then
  echo "[verify_beyondmimic] FAIL: train.py 仍使用已移除的 dump_pickle"
  exit 1
fi
echo "[verify_beyondmimic] train.py OK（僅 dump_yaml）"

if [[ "${FULL_SIM}" -eq 1 ]]; then
  echo "[verify_beyondmimic] 3/3 headless Sim 任務註冊（約 1–2 分鐘）"
  cd "${ISAACLAB_PATH}"
  "${ISAACLAB_PATH}/isaaclab.sh" -p -c "
from isaaclab.app import AppLauncher
import argparse
parser = argparse.ArgumentParser()
AppLauncher.add_app_launcher_args(parser)
args, _ = parser.parse_known_args(['--headless'])
launcher = AppLauncher(args)
import whole_body_tracking.tasks  # noqa: F401
import gymnasium as gym
ids = sorted(s.id for s in gym.registry.values() if s.id.startswith('Tracking-'))
print('tracking tasks:', ids)
launcher.app.close()
" --headless
else
  echo "[verify_beyondmimic] 3/3 跳過 Sim 啟動（--quick）"
fi

echo
echo "[verify_beyondmimic] 通過。"
echo "完整訓練仍需 WandB motion registry，例如："
echo "  ./isaaclab.sh -p ${TRAIN_PY} --task=Tracking-Flat-G1-v0 \\"
echo "    --registry_name YOUR_ORG/wandb-registry-motions/MOTION_NAME \\"
echo "    --headless --max_iterations 1 --num_envs 1"
