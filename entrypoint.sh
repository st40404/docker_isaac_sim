#!/usr/bin/env bash
set -e

ISAAC_DIR="/isaac-sim"

setup_isaac_cuda_env() {
  local env_script="/root/work/src/docker/isaac_cuda_env.sh"
  if [[ -f "${env_script}" ]]; then
    # shellcheck disable=SC1091
    source "${env_script}"
    return 0
  fi
  if [[ -f "${ISAAC_DIR}/setup_python_env.sh" ]]; then
    # shellcheck disable=SC1091
    source "${ISAAC_DIR}/setup_python_env.sh"
  fi
  local nvidia_site="${ISAAC_DIR}/kit/python/lib/python3.11/site-packages/nvidia"
  if [[ -d "${nvidia_site}" ]]; then
    local libdir
    for libdir in "${nvidia_site}"/*/lib; do
      if [[ -d "${libdir}" ]]; then
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${libdir}"
      fi
    done
  fi
}

run_beyondmimic_setup() {
  if [[ "${SKIP_BEYONDMIMIC_SETUP:-}" == "1" ]]; then
    return 0
  fi
  local setup_script="/root/work/src/docker/setup_beyondmimic.sh"
  if [[ -x "${setup_script}" ]]; then
    "${setup_script}" --quiet || echo "[entrypoint] BeyondMimic setup failed (non-fatal); run ${setup_script} manually"
  fi
}

run_isaac() {
  local launcher
  for launcher in \
    "/root/work/src/docker/start_isaac.sh" \
    "/usr/local/bin/start-isaac" \
    "/usr/local/share/isaac-sim-tools/start_isaac.sh"; do
    if [[ -x "${launcher}" ]]; then
      exec "${launcher}" "$@"
    fi
  done
  setup_isaac_cuda_env
  cd "${ISAAC_DIR}"
  if [[ -x ./runheadless.sh ]]; then
    exec ./runheadless.sh --/renderer/active=Storm "$@"
  fi
  exec ./kit/kit ./apps/isaacsim.exp.full.streaming.kit --no-window \
    --/renderer/active=Storm "$@"
}

case "${1:-terminator}" in
  terminator)
    run_beyondmimic_setup
    if [[ -z "${DISPLAY:-}" ]]; then
      echo "[entrypoint] DISPLAY 未設定，改為 headless 啟動 Isaac Sim"
      shift || true
      run_isaac "$@"
    fi
    shift || true
    exec terminator -l isaac_sim "$@"
    ;;
  isaac)
    run_beyondmimic_setup
    shift
    run_isaac "$@"
    ;;
  bash|shell)
    run_beyondmimic_setup
    shift || true
    exec bash -l "$@"
    ;;
  *)
    run_beyondmimic_setup
    run_isaac "$@"
    ;;
esac
