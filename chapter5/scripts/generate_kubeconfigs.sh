#!/usr/bin/env bash
# Render kubeconfig files for Chapter 5 control plane components.
#
# The script assembles kubeconfigs for the controller-manager, scheduler, and
# cluster admin user using the certificates generated in Chapter 3. Outputs are
# written to chapter5/kubeconfigs/.
#
# Usage: ./generate_kubeconfigs.sh
#
# Prerequisites:
#   - `kubectl` binary staged in chapter5/bin/
#   - Certificates available under chapter3/pki/
#   - Control plane endpoint (DNS or IP) exported via K8S_API_ENDPOINT
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STAGED_KUBECTL="${REPO_ROOT}/chapter5/bin/kubectl"
HOST_KUBECTL="$(command -v kubectl 2>/dev/null || true)"
KUBECONFIG_DIR="${REPO_ROOT}/chapter5/kubeconfigs"
PKI_ROOT="${REPO_ROOT}/chapter3/pki"
API_ENDPOINT="${K8S_API_ENDPOINT:-api.kthw.lab:6443}"
CLUSTER_NAME="kthw-lab"
SERVICE_CLUSTER_IP="10.32.0.1"

mkdir -p "${KUBECONFIG_DIR}"

require_binary() {
  if [[ "$(uname -s)" == "Linux" ]]; then
    if [[ ! -x "${STAGED_KUBECTL}" ]]; then
      echo "[ERROR] kubectl not staged at ${STAGED_KUBECTL}." >&2
      exit 1
    fi
    KUBECTL="${STAGED_KUBECTL}"
  else
    if [[ -x "${HOST_KUBECTL}" ]]; then
      echo "[WARN] Using host kubectl at ${HOST_KUBECTL}" >&2
      KUBECTL="${HOST_KUBECTL}"
    elif [[ -x "${STAGED_KUBECTL}" ]]; then
      echo "[WARN] Host is $(uname -s); staged kubectl may not be executable." >&2
      KUBECTL="${STAGED_KUBECTL}"
    else
      echo "[ERROR] No usable kubectl found. Install kubectl locally or stage a platform-specific binary." >&2
      exit 1
    fi
  fi
}

create_kubeconfig() {
  local name="$1"
  local cert="$2"
  local key="$3"
  local output="$4"

  "${KUBECTL}" config set-cluster "${CLUSTER_NAME}" \
    --certificate-authority="${PKI_ROOT}/ca/ca.pem" \
    --embed-certs=true \
    --server="https://${API_ENDPOINT}" \
    --kubeconfig="${output}"

  "${KUBECTL}" config set-credentials "${name}" \
    --client-certificate="${cert}" \
    --client-key="${key}" \
    --embed-certs=true \
    --kubeconfig="${output}"

  "${KUBECTL}" config set-context "${name}@${CLUSTER_NAME}" \
    --cluster="${CLUSTER_NAME}" \
    --user="${name}" \
    --kubeconfig="${output}"

  "${KUBECTL}" config use-context "${name}@${CLUSTER_NAME}" \
    --kubeconfig="${output}"
}

main() {
  require_binary

  create_kubeconfig \
    kube-controller-manager \
    "${PKI_ROOT}/controller-manager/kube-controller-manager.pem" \
    "${PKI_ROOT}/controller-manager/kube-controller-manager-key.pem" \
    "${KUBECONFIG_DIR}/kube-controller-manager.kubeconfig"

  create_kubeconfig \
    kube-scheduler \
    "${PKI_ROOT}/scheduler/kube-scheduler.pem" \
    "${PKI_ROOT}/scheduler/kube-scheduler-key.pem" \
    "${KUBECONFIG_DIR}/kube-scheduler.kubeconfig"

  create_kubeconfig \
    admin \
    "${PKI_ROOT}/admin/admin.pem" \
    "${PKI_ROOT}/admin/admin-key.pem" \
    "${KUBECONFIG_DIR}/admin.kubeconfig"

  echo "[INFO] Generated kubeconfigs in ${KUBECONFIG_DIR}" >&2
}

main "$@"
