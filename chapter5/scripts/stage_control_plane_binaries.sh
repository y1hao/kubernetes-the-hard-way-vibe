#!/usr/bin/env bash
# Download and stage Kubernetes control plane binaries for Chapter 5.
#
# The script fetches the upstream kubernetes-server tarball for the requested
# version, performs an optional SHA-256 checksum validation, and copies the
# required binaries into chapter5/bin/ for later distribution.
#
# Usage: ./stage_control_plane_binaries.sh [VERSION]
#
# Environment variables:
#   K8S_SKIP_DOWNLOAD=yes   Skip the download step and only extract from an
#                           existing archive under chapter5/artifacts/.
#   K8S_SHA256=<checksum>   Expected SHA-256 for the tarball. If omitted, the
#                           checksum validation is skipped.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ARTIFACT_DIR="${REPO_ROOT}/chapter5/artifacts"
BIN_DIR="${REPO_ROOT}/chapter5/bin"
DEFAULT_VERSION="v1.31.1"
ARCHIVE_NAME="kubernetes-server-linux-amd64.tar.gz"
VERSION="${1:-${DEFAULT_VERSION}}"
DOWNLOAD_URL="https://dl.k8s.io/release/${VERSION}/${ARCHIVE_NAME}"
TARBALL_PATH="${ARTIFACT_DIR}/${ARCHIVE_NAME}"
REQUIRED_BINARIES=(kube-apiserver kube-controller-manager kube-scheduler kubectl)

mkdir -p "${ARTIFACT_DIR}" "${BIN_DIR}"

should_download() {
  [[ "${K8S_SKIP_DOWNLOAD:-no}" != "yes" ]]
}

fetch_tarball() {
  if should_download; then
    echo "[INFO] Downloading ${DOWNLOAD_URL}" >&2
    curl -L --fail --output "${TARBALL_PATH}" "${DOWNLOAD_URL}"
  elif [[ ! -f "${TARBALL_PATH}" ]]; then
    echo "[ERROR] ${TARBALL_PATH} not found and download skipped." >&2
    exit 1
  else
    echo "[INFO] Reusing existing tarball at ${TARBALL_PATH}" >&2
  fi
}

verify_checksum() {
  if [[ -n "${K8S_SHA256:-}" ]]; then
    echo "[INFO] Verifying SHA-256 checksum" >&2
    local actual
    actual="$(sha256sum "${TARBALL_PATH}" | awk '{print $1}')"
    if [[ "${actual}" != "${K8S_SHA256}" ]]; then
      echo "[ERROR] Checksum mismatch: expected ${K8S_SHA256}, got ${actual}" >&2
      exit 1
    fi
  else
    echo "[WARN] K8S_SHA256 not provided; skipping checksum validation" >&2
  fi
}

extract_binaries() {
  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "${temp_dir}"' EXIT

  tar -C "${temp_dir}" -xzf "${TARBALL_PATH}"

  local src_dir="${temp_dir}/kubernetes/server/bin"
  for bin in "${REQUIRED_BINARIES[@]}"; do
    if [[ ! -f "${src_dir}/${bin}" ]]; then
      echo "[ERROR] Required binary ${bin} not found in archive." >&2
      exit 1
    fi
    install -m 0755 "${src_dir}/${bin}" "${BIN_DIR}/${bin}"
  done

  echo "[INFO] Staged binaries in ${BIN_DIR}" >&2
}

main() {
  fetch_tarball
  verify_checksum
  extract_binaries
}

main "$@"
