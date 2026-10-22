#!/usr/bin/env bash
# Kit runtime paths for start-isaac / Isaac Lab.
# Isaac Lab 3.x repoints pip_prebundle torch at /opt/isaaclab-venv.
# The ml_archive symlink only exists on the Isaac Sim 5.1 layout.
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

# 6.2 把 libcarb.env.shim.so 寫進 /etc/ld.so.preload。再 LD_PRELOAD libcarb.so 會互相覆蓋。
if [[ -f /etc/ld.so.preload ]] && grep -q 'libcarb.env.shim.so' /etc/ld.so.preload 2>/dev/null; then
  :
elif [[ -f "${ISAAC_DIR}/kit/libcarb.so" ]]; then
  export LD_PRELOAD="${LD_PRELOAD:-${ISAAC_DIR}/kit/libcarb.so}"
fi

kit_python_site() {
  local match
  match="$(echo "${ISAAC_DIR}/kit/python/lib"/python3.*/site-packages)"
  if [[ -d "${match}" ]]; then
    printf '%s\n' "${match}"
  fi
}

setup_torch_cuda_layout() {
  local site ml pkg name target py_site
  py_site="$(kit_python_site)" || true
  [[ -n "${py_site}" ]] || return 0
  site="${py_site}/nvidia"
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
  local nvidia_root libdir py_site
  py_site="$(kit_python_site)" || true
  for nvidia_root in \
    ${py_site:+"${py_site}/nvidia"} \
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
