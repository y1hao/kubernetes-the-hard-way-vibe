#!/usr/bin/env bash
set -euo pipefail

# Usage: ./enable_workers.sh <node>
# Expects ssh/scp configured (e.g. via bastion SSH config) and Chapter 3/7 artifacts staged locally.

NODE=${1:-}
if [[ -z "${NODE}" ]]; then
  echo "Usage: $0 <worker-hostname>" >&2
  exit 1
fi

ARTIFACT_ROOT=$(cd "$(dirname "$0")/.." && pwd)
BIN_DIR="$ARTIFACT_ROOT/bin"
CONFIG_DIR="$ARTIFACT_ROOT/config"
KUBECONFIG_DIR="$ARTIFACT_ROOT/kubeconfigs"
MANIFEST="$ARTIFACT_ROOT/manifest.yaml"

WORK_DIR="/var/tmp/kthw"
SSH="ssh ${NODE}"
SCP="scp"

cleanup_remote() {
  $SSH sudo rm -rf "$WORK_DIR"
}

prepare_remote() {
  $SSH sudo mkdir -p \
    /etc/containerd \
    /etc/kubelet.d \
    /etc/kube-proxy.d \
    /var/lib/containerd \
    /var/lib/kubelet/pki \
    /var/lib/kube-proxy/pki \
    "$WORK_DIR"
}

copy_artifacts() {
  echo "Copying binaries and archives"
  $SCP "$BIN_DIR/kubelet" "$NODE:$WORK_DIR/"
  $SCP "$BIN_DIR/kube-proxy" "$NODE:$WORK_DIR/"
  $SCP "$BIN_DIR/runc" "$NODE:$WORK_DIR/"
  $SCP "$BIN_DIR/containerd.tar.gz" "$NODE:$WORK_DIR/"
  $SCP "$BIN_DIR/crictl.tar.gz" "$NODE:$WORK_DIR/"

  echo "Copying configs"
  $SCP "$CONFIG_DIR/containerd/config.toml" "$NODE:$WORK_DIR/"
  $SCP "$CONFIG_DIR/kubelet/config.yaml" "$NODE:$WORK_DIR/"
  $SCP "$CONFIG_DIR/kubelet/kubelet.env" "$NODE:$WORK_DIR/"
  $SCP "$CONFIG_DIR/kubelet/${NODE}.env" "$NODE:$WORK_DIR/node.env"
  $SCP "$CONFIG_DIR/kube-proxy/config.yaml" "$NODE:$WORK_DIR/kube-proxy-config.yaml"
  $SCP "$CONFIG_DIR/kube-proxy/kube-proxy.env" "$NODE:$WORK_DIR/"

  echo "Copying kubeconfigs"
  $SCP "$KUBECONFIG_DIR/${NODE}-kubelet.kubeconfig" "$NODE:$WORK_DIR/kubelet.kubeconfig"
  $SCP "$KUBECONFIG_DIR/kube-proxy.kubeconfig" "$NODE:$WORK_DIR/"

  echo "Copying PKI"
  $SCP chapter3/pki/ca/ca.pem "$NODE:$WORK_DIR/ca.pem"
  $SCP chapter3/pki/kubelet/${NODE}/kubelet.pem "$NODE:$WORK_DIR/kubelet.pem"
  $SCP chapter3/pki/kubelet/${NODE}/kubelet-key.pem "$NODE:$WORK_DIR/kubelet-key.pem"
  $SCP chapter3/pki/kube-proxy/kube-proxy.pem "$NODE:$WORK_DIR/kube-proxy.pem"
  $SCP chapter3/pki/kube-proxy/kube-proxy-key.pem "$NODE:$WORK_DIR/kube-proxy-key.pem"

  echo "Copying systemd units"
  $SCP "$ARTIFACT_ROOT/systemd/containerd.service" "$NODE:$WORK_DIR/"
  $SCP "$ARTIFACT_ROOT/systemd/kubelet.service" "$NODE:$WORK_DIR/"
  $SCP "$ARTIFACT_ROOT/systemd/kube-proxy.service" "$NODE:$WORK_DIR/"
}

install_remote() {
  $SSH <<'EOSSH'
set -euo pipefail
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
  $SSH sudo systemctl status containerd.service --no-pager
  $SSH sudo systemctl status kubelet.service --no-pager
  $SSH sudo systemctl status kube-proxy.service --no-pager
}

prepare_remote
copy_artifacts
install_remote
post_checks
cleanup_remote

kubectl --kubeconfig chapter5/kubeconfigs/admin.kubeconfig get nodes "$NODE"
