#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

CA_PATH="${CA_PATH:-$REPO_ROOT/chapter3/pki/ca/ca.pem}"
CLIENT_CERT="${CLIENT_CERT:-$REPO_ROOT/chapter3/pki/metrics-server/metrics-server.pem}"
CLIENT_KEY="${CLIENT_KEY:-$REPO_ROOT/chapter3/pki/metrics-server/metrics-server-key.pem}"
KUBECONFIG="${KUBECONFIG:-$REPO_ROOT/chapter9/kubeconfigs/metrics-server.kubeconfig}"
OUTPUT="${OUTPUT:-$REPO_ROOT/chapter9/manifests/metrics-server-secrets.yaml}"

usage() {
  cat <<'EOF'
Usage: generate_metrics_server_secrets.sh [--ca path] [--client-cert path] [--client-key path] [--kubeconfig path] [--output path]

Environment overrides:
  CA_PATH       (default: chapter3/pki/ca/ca.pem)
  CLIENT_CERT   (default: chapter3/pki/metrics-server/metrics-server.pem)
  CLIENT_KEY    (default: chapter3/pki/metrics-server/metrics-server-key.pem)
  KUBECONFIG    (default: chapter9/kubeconfigs/metrics-server.kubeconfig)
  OUTPUT        (default: chapter9/manifests/metrics-server-secrets.yaml)
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
    --client-cert)
      [[ $# -lt 2 ]] && usage
      CLIENT_CERT="$2"
      shift 2
      ;;
    --client-key)
      [[ $# -lt 2 ]] && usage
      CLIENT_KEY="$2"
      shift 2
      ;;
    --kubeconfig)
      [[ $# -lt 2 ]] && usage
      KUBECONFIG="$2"
      shift 2
      ;;
    --output)
      [[ $# -lt 2 ]] && usage
      OUTPUT="$2"
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

for path in "$CA_PATH" "$CLIENT_CERT" "$CLIENT_KEY" "$KUBECONFIG"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
done

echo "Writing metrics-server secrets manifest to $OUTPUT"

cat > "$OUTPUT" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: metrics-server-client-cert
  namespace: kube-system
type: Opaque
data:
  ca.crt: $(base64 -w0 < "$CA_PATH")
  client.crt: $(base64 -w0 < "$CLIENT_CERT")
  client.key: $(base64 -w0 < "$CLIENT_KEY")
---
apiVersion: v1
kind: Secret
metadata:
  name: metrics-server-kubeconfig
  namespace: kube-system
type: Opaque
data:
  kubeconfig: $(base64 -w0 < "$KUBECONFIG")
EOF

echo "Done. Apply with: kubectl apply -f $OUTPUT"
