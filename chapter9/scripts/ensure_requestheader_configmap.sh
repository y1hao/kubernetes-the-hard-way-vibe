#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CA_PATH="${CA_PATH:-$REPO_ROOT/chapter3/pki/ca/ca.pem}"
KUBECTL_BIN="${KUBECTL_BIN:-${KUBECTL:-kubectl}}"

usage() {
  cat <<'EOF'
Usage: ensure_requestheader_configmap.sh [--ca <path-to-ca.pem>] [--kubectl <kubectl>]

Create or update the kube-system/extension-apiserver-authentication ConfigMap
with requestheader trust settings derived from the Chapter 3 CA bundle.

Environment variables:
  CA_PATH      Override default CA location (chapter3/pki/ca/ca.pem)
  KUBECTL_BIN  Override kubectl command (defaults to kubectl)
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --ca)
      [[ $# -lt 2 ]] && usage
      CA_PATH="$2"
      shift 2
      ;;
    --kubectl)
      [[ $# -lt 2 ]] && usage
      KUBECTL_BIN="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      ;;
  esac
done

if [[ ! -f "$CA_PATH" ]]; then
  echo "CA bundle not found at: $CA_PATH" >&2
  exit 2
fi

echo "Using CA bundle: $CA_PATH"
echo "Using kubectl: $KUBECTL_BIN"

if ! command -v "$KUBECTL_BIN" >/dev/null 2>&1; then
  echo "kubectl binary not found: $KUBECTL_BIN" >&2
  exit 3
fi

$KUBECTL_BIN create configmap extension-apiserver-authentication \
  --namespace kube-system \
  --from-file=requestheader-client-ca-file="$CA_PATH" \
  --from-literal=requestheader-allowed-names='["front-proxy-client"]' \
  --from-literal=requestheader-username-headers='["X-Remote-User"]' \
  --from-literal=requestheader-group-headers='["X-Remote-Group"]' \
  --from-literal=requestheader-extra-headers-prefix='["X-Remote-Extra-"]' \
  --dry-run=client -o yaml | $KUBECTL_BIN apply -f -

echo "ConfigMap extension-apiserver-authentication applied."
