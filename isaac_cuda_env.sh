#!/usr/bin/env bash
# Isaac Sim kit needs CUDA 12 libs visible under site-packages/nvidia/* for torch 2.7.x.
ISAAC_DIR="${ISAAC_DIR:-/isaac-sim}"

# setup_python_env.sh expands $PYTHONPATH / $LD_LIBRARY_PATH; must be defined under set -u.
export PYTHONPATH="${PYTHONPATH:-}"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:-}"

if [[ -f "${ISAAC_DIR}/setup_python_env.sh" ]]; then
  # shellcheck disable=SC1091
  source "${ISAAC_DIR}/setup_python_env.sh"
fi

# python.sh also exports these; kit launch needs them for consistent plugin loading.
export CARB_APP_PATH="${CARB_APP_PATH:-${ISAAC_DIR}/kit}"
export ISAAC_PATH="${ISAAC_PATH:-${ISAAC_DIR}}"
export EXP_PATH="${EXP_PATH:-${ISAAC_DIR}/apps}"
export LD_PRELOAD="${LD_PRELOAD:-${ISAAC_DIR}/kit/libcarb.so}"

setup_torch_cuda_layout() {
  local site ml pkg name target
  site="${ISAAC_DIR}/kit/python/lib/python3.11/site-packages/nvidia"
  ml="${ISAAC_DIR}/exts/omni.isaac.ml_archive/pip_prebundle/nvidia"
  [[ -d "${ml}" ]] || return 0

  mkdir -p "${site}"
  for pkg in "${ml}"/*; do
    name="$(basename "${pkg}")"
    [[ "${name}" == "__init__.py" ]] && continue
    [[ -d "${pkg}" ]] || continue
    target="${site}/${name}"
  if [[ ! -e "${target}" ]]; then
      ln -sfn "${pkg}" "${target}"
    fi
  done
}

append_nvidia_ld_paths() {
  local nvidia_root libdir
  for nvidia_root in \
    "${ISAAC_DIR}/kit/python/lib/python3.11/site-packages/nvidia" \
    "${ISAAC_DIR}/exts/omni.isaac.ml_archive/pip_prebundle/nvidia"; do
    [[ -d "${nvidia_root}" ]] || continue
    for libdir in "${nvidia_root}"/*/lib; do
      [[ -d "${libdir}" ]] || continue
      case ":${LD_LIBRARY_PATH}:" in
        *":${libdir}:"*) ;;
        *) export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${libdir}" ;;
      esac
    done
  done
}

setup_torch_cuda_layout
append_nvidia_ld_paths
