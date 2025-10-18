#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLIENT_CA_PATH="${CLIENT_CA_PATH:-$REPO_ROOT/chapter3/pki/ca/ca.pem}"
PROXY_CA_PATH="${PROXY_CA_PATH:-$REPO_ROOT/chapter3/pki/front-proxy/front-proxy-ca.pem}"
KUBECTL_BIN="${KUBECTL_BIN:-${KUBECTL:-kubectl}}"

usage() {
  cat <<'EOF'
Usage: ensure_requestheader_configmap.sh [--client-ca <path-to-ca.pem>] [--proxy-ca <path-to-ca.pem>] [--kubectl <kubectl>]

Create or update the kube-system/extension-apiserver-authentication ConfigMap
with the front-proxy and client CA bundles.

Environment variables:
  CLIENT_CA_PATH  Override default client CA (chapter3/pki/ca/ca.pem)
  PROXY_CA_PATH   Override default front-proxy CA (chapter3/pki/front-proxy/front-proxy-ca.pem)
  KUBECTL_BIN  Override kubectl command (defaults to kubectl)
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --client-ca)
      [[ $# -lt 2 ]] && usage
      CLIENT_CA_PATH="$2"
      shift 2
      ;;
    --proxy-ca)
      [[ $# -lt 2 ]] && usage
      PROXY_CA_PATH="$2"
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

if [[ ! -f "$CLIENT_CA_PATH" ]]; then
  echo "Client CA bundle not found at: $CLIENT_CA_PATH" >&2
  exit 2
fi

if [[ ! -f "$PROXY_CA_PATH" ]]; then
  echo "Front-proxy CA bundle not found at: $PROXY_CA_PATH" >&2
  exit 2
fi

echo "Using client CA bundle: $CLIENT_CA_PATH"
echo "Using front-proxy CA bundle: $PROXY_CA_PATH"
echo "Using kubectl: $KUBECTL_BIN"

if ! command -v "$KUBECTL_BIN" >/dev/null 2>&1; then
  echo "kubectl binary not found: $KUBECTL_BIN" >&2
  exit 3
fi

$KUBECTL_BIN create configmap extension-apiserver-authentication \
  --namespace kube-system \
  --from-file=client-ca-file="$CLIENT_CA_PATH" \
  --from-file=requestheader-client-ca-file="$PROXY_CA_PATH" \
  --from-literal=requestheader-allowed-names='["front-proxy-client"]' \
  --from-literal=requestheader-username-headers='["X-Remote-User"]' \
  --from-literal=requestheader-group-headers='["X-Remote-Group"]' \
  --from-literal=requestheader-extra-headers-prefix='["X-Remote-Extra-"]' \
  --dry-run=client -o yaml | $KUBECTL_BIN apply -f -

echo "ConfigMap extension-apiserver-authentication applied."
