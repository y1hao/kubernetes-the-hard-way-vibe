#!/usr/bin/env bash
set -euo pipefail

# Usage: ./enable_workers.sh <node>
# Optional env vars:
#   KTHW_SSH_KEY   - identity file (default: ../chapter1/kthw-lab)
#   KTHW_SSH_OPTS  - extra ssh/scp options (e.g. "-o StrictHostKeyChecking=no")
#   KTHW_SSH_CMD   - override ssh binary (default: ssh)
#   KTHW_SCP_CMD   - override scp binary (default: scp)

NODE=${1:-}
if [[ -z "${NODE}" ]]; then
  echo "Usage: $0 <worker-hostname>" >&2
  exit 1
fi

ARTIFACT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
BIN_DIR="$ARTIFACT_ROOT/bin"
CONFIG_DIR="$ARTIFACT_ROOT/config"
KUBECONFIG_DIR="$ARTIFACT_ROOT/kubeconfigs"
REPO_ROOT=$(cd "$ARTIFACT_ROOT/.." && pwd)
DEFAULT_KUBECTL="$REPO_ROOT/chapter5/bin/kubectl"
if [[ -x "$DEFAULT_KUBECTL" ]]; then
  KUBECTL_CMD="${KTHW_KUBECTL:-$DEFAULT_KUBECTL}"
else
  KUBECTL_CMD="${KTHW_KUBECTL:-kubectl}"
fi
IDENTITY=${KTHW_SSH_KEY:-$REPO_ROOT/chapter1/kthw-lab}
SSH_BASE=${KTHW_SSH_CMD:-ssh}
SCP_BASE=${KTHW_SCP_CMD:-scp}
read -r -a EXTRA_OPTS <<< "${KTHW_SSH_OPTS:-}"

SSH_CMD_BASE=("$SSH_BASE" -i "$IDENTITY" "${EXTRA_OPTS[@]}")
SCP_CMD_BASE=("$SCP_BASE" -i "$IDENTITY" "${EXTRA_OPTS[@]}")
REMOTE_USER=$("${SSH_CMD_BASE[@]}" "$NODE" id -un)

ssh_node() {
  "${SSH_CMD_BASE[@]}" "$NODE" "$@"
}

scp_to_node() {
  local src=$1 dst=$2
  "${SCP_CMD_BASE[@]}" "$src" "$NODE:$dst"
}

WORK_DIR="/var/tmp/kthw"

cleanup_remote() {
  ssh_node sudo rm -rf "$WORK_DIR"
}

prepare_remote() {
  ssh_node sudo mkdir -p \
    /etc/containerd \
    /etc/kubelet.d \
    /etc/kube-proxy.d \
    /var/lib/containerd \
    /var/lib/kubelet/pki \
    /var/lib/kube-proxy/pki \
    "$WORK_DIR"
  ssh_node sudo chown "$REMOTE_USER:$REMOTE_USER" "$WORK_DIR"
}

copy_artifacts() {
  echo "Copying binaries and archives"
  scp_to_node "$BIN_DIR/kubelet" "$WORK_DIR/"
  scp_to_node "$BIN_DIR/kube-proxy" "$WORK_DIR/"
  scp_to_node "$BIN_DIR/runc" "$WORK_DIR/"
  scp_to_node "$BIN_DIR/containerd.tar.gz" "$WORK_DIR/"
  scp_to_node "$BIN_DIR/crictl.tar.gz" "$WORK_DIR/"

  echo "Copying configs"
  scp_to_node "$CONFIG_DIR/containerd/config.toml" "$WORK_DIR/config.toml"
  scp_to_node "$CONFIG_DIR/kubelet/config.yaml" "$WORK_DIR/"
  scp_to_node "$CONFIG_DIR/kubelet/kubelet.env" "$WORK_DIR/"
  scp_to_node "$CONFIG_DIR/kubelet/${NODE}.env" "$WORK_DIR/node.env"
  scp_to_node "$CONFIG_DIR/kube-proxy/config.yaml" "$WORK_DIR/kube-proxy-config.yaml"
  scp_to_node "$CONFIG_DIR/kube-proxy/kube-proxy.env" "$WORK_DIR/"

  echo "Copying kubeconfigs"
  scp_to_node "$KUBECONFIG_DIR/${NODE}-kubelet.kubeconfig" "$WORK_DIR/kubelet.kubeconfig"
  scp_to_node "$KUBECONFIG_DIR/kube-proxy.kubeconfig" "$WORK_DIR/"

  echo "Copying PKI"
  scp_to_node "$REPO_ROOT/chapter3/pki/ca/ca.pem" "$WORK_DIR/ca.pem"
  scp_to_node "$REPO_ROOT/chapter3/pki/kubelet/${NODE}/kubelet.pem" "$WORK_DIR/kubelet.pem"
  scp_to_node "$REPO_ROOT/chapter3/pki/kubelet/${NODE}/kubelet-key.pem" "$WORK_DIR/kubelet-key.pem"
  scp_to_node "$REPO_ROOT/chapter3/pki/kube-proxy/kube-proxy.pem" "$WORK_DIR/kube-proxy.pem"
  scp_to_node "$REPO_ROOT/chapter3/pki/kube-proxy/kube-proxy-key.pem" "$WORK_DIR/kube-proxy-key.pem"

  echo "Copying systemd units"
  scp_to_node "$ARTIFACT_ROOT/systemd/containerd.service" "$WORK_DIR/"
  scp_to_node "$ARTIFACT_ROOT/systemd/kubelet.service" "$WORK_DIR/"
  scp_to_node "$ARTIFACT_ROOT/systemd/kube-proxy.service" "$WORK_DIR/"
}

install_remote() {
  ssh_node <<'EOSSH'
set -euo pipefail
sudo mkdir -p /usr/local/bin /usr/local/libexec
sudo tar -C /usr/local -xzf /var/tmp/kthw/containerd.tar.gz
sudo install -m 0755 /var/tmp/kthw/runc /usr/local/sbin/runc
sudo install -m 0755 /var/tmp/kthw/kubelet /usr/local/bin/kubelet
sudo install -m 0755 /var/tmp/kthw/kube-proxy /usr/local/bin/kube-proxy

sudo mkdir -p /usr/local/bin
sudo tar -C /usr/local/bin -xzf /var/tmp/kthw/crictl.tar.gz

sudo install -m 0644 /var/tmp/kthw/config.toml /etc/containerd/config.toml
sudo install -m 0640 /var/tmp/kthw/config.yaml /var/lib/kubelet/config.yaml
sudo install -m 0640 /var/tmp/kthw/kubelet.env /etc/kubelet.d/kubelet.env
sudo install -m 0640 /var/tmp/kthw/node.env /etc/kubelet.d/node.env
sudo install -m 0640 /var/tmp/kthw/kube-proxy-config.yaml /var/lib/kube-proxy/config.yaml
sudo install -m 0640 /var/tmp/kthw/kube-proxy.env /etc/kube-proxy.d/kube-proxy.env
sudo install -m 0600 /var/tmp/kthw/kubelet.kubeconfig /var/lib/kubelet/kubeconfig
sudo install -m 0600 /var/tmp/kthw/kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig
sudo install -m 0644 /var/tmp/kthw/containerd.service /etc/systemd/system/containerd.service
sudo install -m 0644 /var/tmp/kthw/kubelet.service /etc/systemd/system/kubelet.service
sudo install -m 0644 /var/tmp/kthw/kube-proxy.service /etc/systemd/system/kube-proxy.service

sudo install -m 0644 /var/tmp/kthw/ca.pem /var/lib/kubelet/pki/ca.pem
sudo install -m 0600 /var/tmp/kthw/kubelet.pem /var/lib/kubelet/pki/kubelet.pem
sudo install -m 0600 /var/tmp/kthw/kubelet-key.pem /var/lib/kubelet/pki/kubelet-key.pem
sudo install -m 0644 /var/tmp/kthw/ca.pem /var/lib/kube-proxy/pki/ca.pem
sudo install -m 0600 /var/tmp/kthw/kube-proxy.pem /var/lib/kube-proxy/pki/kube-proxy.pem
sudo install -m 0600 /var/tmp/kthw/kube-proxy-key.pem /var/lib/kube-proxy/pki/kube-proxy-key.pem

sudo systemctl daemon-reload
sudo systemctl enable --now containerd.service
sudo systemctl enable --now kubelet.service
sudo systemctl enable --now kube-proxy.service
EOSSH
}

post_checks() {
  echo "== containerd status =="
  ssh_node sudo systemctl status containerd.service --no-pager || true
  echo "-- logs --"
  ssh_node sudo journalctl -u containerd.service -n 40 --no-pager || true
  echo "== kubelet status =="
  ssh_node sudo systemctl status kubelet.service --no-pager || true
  echo "== kube-proxy status =="
  ssh_node sudo systemctl status kube-proxy.service --no-pager || true
}

prepare_remote
copy_artifacts
install_remote
post_checks
cleanup_remote

"$KUBECTL_CMD" --kubeconfig "$REPO_ROOT/chapter5/kubeconfigs/admin.kubeconfig" get nodes "$NODE"
