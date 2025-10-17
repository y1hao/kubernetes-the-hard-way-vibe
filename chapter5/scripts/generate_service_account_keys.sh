#!/usr/bin/env bash
# Generate service account signing keys for the Kubernetes API server.
#
# Outputs:
#   - chapter5/pki/service-account.key
#   - chapter5/pki/service-account.pub
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PKI_DIR="${REPO_ROOT}/chapter5/pki"

mkdir -p "${PKI_DIR}"

if [[ -f "${PKI_DIR}/service-account.key" ]]; then
  echo "[INFO] Service account key already exists at ${PKI_DIR}/service-account.key; skipping." >&2
  exit 0
fi

openssl genrsa -out "${PKI_DIR}/service-account.key" 4096
openssl rsa -in "${PKI_DIR}/service-account.key" -pubout -out "${PKI_DIR}/service-account.pub"

chmod 600 "${PKI_DIR}/service-account.key"
chmod 644 "${PKI_DIR}/service-account.pub"

echo "[INFO] Generated service account key pair in ${PKI_DIR}" >&2
