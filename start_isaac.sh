#!/usr/bin/env bash
# Launch Isaac Sim streaming (start-isaac) with CUDA libs for pip torch 2.7.x.
set -euo pipefail

export PYTHONPATH="${PYTHONPATH:-}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"

ISAAC_DIR="${ISAAC_DIR:-/isaac-sim}"
for cuda_env in \
  "/root/work/src/docker/isaac_cuda_env.sh" \
  "/usr/local/share/isaac-sim-tools/isaac_cuda_env.sh"; do
  if [[ -f "${cuda_env}" ]]; then
    CUDA_ENV="${cuda_env}"
    break
  fi
done

if [[ -f "${CUDA_ENV:-}" ]]; then
  # shellcheck disable=SC1091
  source "${CUDA_ENV}"
elif [[ -f "${ISAAC_DIR}/setup_python_env.sh" ]]; then
  # shellcheck disable=SC1091
  source "${ISAAC_DIR}/setup_python_env.sh"
fi

cd "${ISAAC_DIR}"
if [[ -x ./runheadless.sh ]]; then
  exec ./runheadless.sh --/renderer/active=Storm "$@"
fi
exec ./kit/kit ./apps/isaacsim.exp.full.streaming.kit --no-window \
  --/renderer/active=Storm "$@"
