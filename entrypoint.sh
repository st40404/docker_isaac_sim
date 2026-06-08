#!/usr/bin/env bash
set -e

ISAAC_DIR="/isaac-sim"

run_isaac() {
  cd "${ISAAC_DIR}"
  if [[ -x ./runheadless.sh ]]; then
    exec ./runheadless.sh --/renderer/active=Storm "$@"
  fi
  exec ./kit/kit ./apps/isaacsim.exp.full.streaming.kit --no-window \
    --/renderer/active=Storm "$@"
}

case "${1:-terminator}" in
  terminator)
    if [[ -z "${DISPLAY:-}" ]]; then
      echo "[entrypoint] DISPLAY 未設定，改為 headless 啟動 Isaac Sim"
      shift || true
      run_isaac "$@"
    fi
    shift || true
    exec terminator -l isaac_sim "$@"
    ;;
  isaac)
    shift
    run_isaac "$@"
    ;;
  *)
    run_isaac "$@"
    ;;
esac
