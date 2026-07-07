#!/usr/bin/env bash
# Idempotent BeyondMimic (whole_body_tracking) setup for the Isaac Sim container.
# Source lives on the host mount: /root/work/src/whole_body_tracking
set -euo pipefail

ISAACLAB_PATH="${ISAACLAB_PATH:-/root/work/IsaacLab}"
SRC_ROOT="${SRC_ROOT:-/root/work/src}"
WBT_ROOT="${WBT_ROOT:-${SRC_ROOT}/whole_body_tracking}"
WBT_PKG="${WBT_PKG:-${WBT_ROOT}/source/whole_body_tracking}"
UNITREE_DIR="${WBT_PKG}/whole_body_tracking/assets/unitree_description"
UNITREE_URL="https://storage.googleapis.com/qiayuanl_robot_descriptions/unitree_description.tar.gz"

QUIET=0
FORCE_PIP=0
DOWNLOAD_UNITREE="auto"

usage() {
  cat <<'EOF'
Usage: setup_beyondmimic.sh [options]

Install whole_body_tracking into Isaac Lab's Python (editable) and optionally
fetch Unitree robot description assets for the official G1 examples.

Options:
  --quiet              Print only warnings/errors
  --force-pip          Re-run pip install -e even if already linked
  --download-unitree   Always download/extract unitree_description
  --skip-unitree       Do not download unitree_description
  -h, --help           Show this help

Environment:
  SKIP_BEYONDMIMIC_SETUP=1   Skip when invoked from entrypoint.sh
EOF
}

log() {
  if [[ "${QUIET}" -eq 0 ]]; then
    echo "[setup_beyondmimic] $*"
  fi
}

warn() {
  echo "[setup_beyondmimic] WARN: $*" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet) QUIET=1; shift ;;
    --force-pip) FORCE_PIP=1; shift ;;
    --download-unitree) DOWNLOAD_UNITREE=yes; shift ;;
    --skip-unitree) DOWNLOAD_UNITREE=no; shift ;;
    -h|--help) usage; exit 0 ;;
    *) warn "Unknown option: $1"; usage; exit 2 ;;
  esac
done

if [[ ! -d "${ISAACLAB_PATH}" || ! -x "${ISAACLAB_PATH}/isaaclab.sh" ]]; then
  warn "Isaac Lab not found at ${ISAACLAB_PATH}"
  exit 1
fi

if [[ ! -f "${WBT_PKG}/pyproject.toml" ]]; then
  log "whole_body_tracking not found at ${WBT_PKG}; skip (clone to ${WBT_ROOT})"
  exit 0
fi

pip_install_needed() {
  if [[ "${FORCE_PIP}" -eq 1 ]]; then
    return 0
  fi
  if ! "${ISAACLAB_PATH}/isaaclab.sh" -p -m pip show whole_body_tracking >/dev/null 2>&1; then
    return 0
  fi
  "${ISAACLAB_PATH}/isaaclab.sh" -p -m pip show whole_body_tracking 2>/dev/null \
    | grep -Fq "Editable project location: ${WBT_PKG}"
}

install_extension() {
  if pip_install_needed; then
    log "pip install -e ${WBT_PKG}"
    "${ISAACLAB_PATH}/isaaclab.sh" -p -m pip install -e "${WBT_PKG}"
  else
    log "whole_body_tracking already installed (editable -> ${WBT_PKG})"
  fi
}

maybe_download_unitree() {
  local do_download=no
  case "${DOWNLOAD_UNITREE}" in
    yes) do_download=yes ;;
    no) do_download=no ;;
    auto)
      if [[ ! -f "${UNITREE_DIR}/package.xml" ]]; then
        do_download=yes
      fi
      ;;
    *)
      warn "Invalid DOWNLOAD_UNITREE=${DOWNLOAD_UNITREE}"
      return 1
      ;;
  esac

  if [[ "${do_download}" != "yes" ]]; then
    log "unitree_description present; skip download"
    return 0
  fi

  log "Downloading unitree_description assets..."
  local tmp
  tmp="$(mktemp /tmp/unitree_description.XXXXXX.tar.gz)"
  curl -fsSL "${UNITREE_URL}" -o "${tmp}"
  mkdir -p "${WBT_PKG}/whole_body_tracking/assets"
  tar -xzf "${tmp}" -C "${WBT_PKG}/whole_body_tracking/assets/"
  rm -f "${tmp}"
  log "unitree_description installed to ${UNITREE_DIR}"
}

install_extension
maybe_download_unitree
log "done"
