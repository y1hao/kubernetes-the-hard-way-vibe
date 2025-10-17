#!/usr/bin/env bash
# Convenience wrapper to distribute Chapter 5 assets using the shared manifest.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="${REPO_ROOT}/chapter5/manifest.yaml"
DISTRIBUTOR="${REPO_ROOT}/chapter3/scripts/distribute_pki.py"

if [[ ! -f "${MANIFEST}" ]]; then
  echo "[ERROR] Manifest not found at ${MANIFEST}" >&2
  exit 1
fi

exec python3 "${DISTRIBUTOR}" --manifest "${MANIFEST}" "$@"
