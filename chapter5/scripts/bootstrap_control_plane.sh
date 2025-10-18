#!/usr/bin/env bash
# Bootstrap Kubernetes control plane services on a node after files are distributed.
set -euo pipefail

REQUIRED_BINARIES=(/usr/local/bin/kube-apiserver /usr/local/bin/kube-controller-manager /usr/local/bin/kube-scheduler /usr/local/bin/kube-proxy)
SERVICE_USERS=(kube-apiserver kube-controller-manager kube-scheduler)

need_root() {
  if [[ $(id -u) -ne 0 ]]; then
    echo "[ERROR] Run this script as root." >&2
    exit 1
  fi
}

ensure_user() {
  local user="$1"
  local home="/var/lib/${user}"
  if ! id "${user}" &>/dev/null; then
    useradd --system --home "${home}" --shell /usr/sbin/nologin --create-home "${user}"
    echo "[INFO] Created system user ${user}"
  fi
}

ensure_directories() {
  mkdir -p /var/lib/kubernetes
  chmod 755 /var/lib/kubernetes
  chown root:root /var/lib/kubernetes

  mkdir -p /etc/kubernetes/kube-apiserver /etc/kubernetes/kube-controller-manager /etc/kubernetes/kube-scheduler
  mkdir -p /etc/kube-proxy.d /var/lib/kube-proxy/pki
  mkdir -p /etc/containerd /etc/kubelet.d /var/lib/kubelet/pki /var/lib/kubelet/manifests /run/containerd
}

copy_etcd_ca() {
  local src="/etc/etcd/pki/ca.pem"
  local dest="/var/lib/kubernetes/etcd-ca.pem"
  if [[ -f "${src}" ]]; then
    cp "${src}" "${dest}"
    chown kube-apiserver:kube-apiserver "${dest}"
    chmod 644 "${dest}"
  else
    echo "[WARN] etcd CA not found at ${src}; kube-apiserver may fail to start" >&2
  fi
}

verify_files() {
  local missing=()
  for bin in "${REQUIRED_BINARIES[@]}"; do
    [[ -x "${bin}" ]] || missing+=("${bin}")
  done

  local required_files=(
    /etc/kubernetes/kube-apiserver/kube-apiserver.env
    /etc/kubernetes/kube-apiserver/node.env
    /etc/kubernetes/kube-controller-manager/kube-controller-manager.env
    /etc/kubernetes/kube-scheduler/kube-scheduler.env
    /var/lib/kubernetes/ca.pem
    /var/lib/kubernetes/ca-key.pem
    /var/lib/kubernetes/apiserver.pem
    /var/lib/kubernetes/apiserver-key.pem
    /var/lib/kubernetes/controller-manager.pem
    /var/lib/kubernetes/controller-manager-key.pem
    /var/lib/kubernetes/kube-controller-manager.kubeconfig
    /var/lib/kubernetes/kube-scheduler.pem
    /var/lib/kubernetes/kube-scheduler-key.pem
    /var/lib/kubernetes/kube-scheduler.kubeconfig
    /var/lib/kubernetes/kube-controller-manager.kubeconfig
    /var/lib/kubernetes/kube-scheduler.kubeconfig
    /var/lib/kubernetes/admin.kubeconfig
    /var/lib/kubernetes/service-account.key
    /var/lib/kubernetes/service-account.pub
    /var/lib/kubernetes/encryption-config.yaml
    /etc/kube-proxy.d/kube-proxy.env
    /var/lib/kube-proxy/config.yaml
    /var/lib/kube-proxy/kubeconfig
    /var/lib/kube-proxy/pki/ca.pem
    /var/lib/kube-proxy/pki/kube-proxy.pem
    /var/lib/kube-proxy/pki/kube-proxy-key.pem
    /etc/containerd/config.toml
    /var/lib/kubernetes/containerd.tar.gz
    /var/lib/kubernetes/crictl.tar.gz
    /etc/kubelet.d/kubelet.env
    /etc/kubelet.d/node.env
    /var/lib/kubelet/config.yaml
    /var/lib/kubelet/kubeconfig
    /var/lib/kubelet/pki/ca.pem
    /var/lib/kubelet/pki/kubelet.pem
    /var/lib/kubelet/pki/kubelet-key.pem
  )

  for file in "${required_files[@]}"; do
    [[ -f "${file}" ]] || missing+=("${file}")
  done

  if (( ${#missing[@]} > 0 )); then
    printf '[ERROR] Missing required assets:\n - %s\n' "${missing[@]}" >&2
    exit 1
  fi
}

install_runtime_stack() {
  local containerd_tar="/var/lib/kubernetes/containerd.tar.gz"
  local crictl_tar="/var/lib/kubernetes/crictl.tar.gz"

  if [[ -f "${containerd_tar}" ]]; then
    tar -C /usr/local -xzf "${containerd_tar}"
  fi

  if [[ -f "${crictl_tar}" ]]; then
    tar -C /usr/local/bin -xzf "${crictl_tar}"
  fi
}

render_kube_apiserver_env() {
  local node_env="/etc/kubernetes/kube-apiserver/node.env"
  local apiserver_env="/etc/kubernetes/kube-apiserver/kube-apiserver.env"
  if [[ ! -f "${node_env}" || ! -f "${apiserver_env}" ]]; then
    echo "[ERROR] kube-apiserver environment files missing" >&2
    exit 1
  fi

  local node_ip
  node_ip="$(grep -E '^NODE_INTERNAL_IP=' "${node_env}" | tail -n1 | cut -d'=' -f2- | tr -d '"')"
  if [[ -z "${node_ip}" ]]; then
    echo "[ERROR] NODE_INTERNAL_IP not set in ${node_env}" >&2
    exit 1
  fi

  sed -i "s/{{NODE_INTERNAL_IP}}/${node_ip}/g" \
    /etc/kubernetes/kube-apiserver/kube-apiserver.env

  ensure_api_hostname "${node_ip}"
}

ensure_api_hostname() {
  local node_ip="$1"
  local hosts_entry
  hosts_entry="${node_ip} api.kthw.lab"

  if ! grep -q "api.kthw.lab" /etc/hosts; then
    echo "${hosts_entry}" >> /etc/hosts
  fi
}

fix_permissions() {
  chmod 640 /etc/kubernetes/kube-apiserver/*.env /etc/kubernetes/kube-controller-manager/*.env /etc/kubernetes/kube-scheduler/*.env

  if [[ -f /etc/etcd/pki/ca.pem ]]; then
    chmod 644 /etc/etcd/pki/ca.pem
  fi

  chown kube-apiserver:kube-apiserver /var/lib/kubernetes/apiserver.pem /var/lib/kubernetes/apiserver-key.pem
  chmod 640 /var/lib/kubernetes/apiserver.pem
  chmod 600 /var/lib/kubernetes/apiserver-key.pem

  chown kube-apiserver:kube-controller-manager /var/lib/kubernetes/service-account.key
  chmod 640 /var/lib/kubernetes/service-account.key
  chown kube-controller-manager:kube-controller-manager /var/lib/kubernetes/service-account.pub
  chmod 640 /var/lib/kubernetes/service-account.pub

  chown kube-controller-manager:kube-controller-manager /var/lib/kubernetes/controller-manager.pem /var/lib/kubernetes/controller-manager-key.pem /var/lib/kubernetes/kube-controller-manager.kubeconfig /var/lib/kubernetes/ca-key.pem
  chmod 640 /var/lib/kubernetes/controller-manager.pem
  chmod 600 /var/lib/kubernetes/controller-manager-key.pem /var/lib/kubernetes/kube-controller-manager.kubeconfig /var/lib/kubernetes/ca-key.pem

  chown kube-scheduler:kube-scheduler /var/lib/kubernetes/kube-scheduler.pem /var/lib/kubernetes/kube-scheduler-key.pem /var/lib/kubernetes/kube-scheduler.kubeconfig
  chmod 640 /var/lib/kubernetes/kube-scheduler.pem
  chmod 600 /var/lib/kubernetes/kube-scheduler-key.pem /var/lib/kubernetes/kube-scheduler.kubeconfig

  chown kube-apiserver:kube-apiserver /var/lib/kubernetes/admin.kubeconfig /var/lib/kubernetes/encryption-config.yaml
  chmod 600 /var/lib/kubernetes/admin.kubeconfig /var/lib/kubernetes/encryption-config.yaml

  chmod 640 /etc/kube-proxy.d/kube-proxy.env /var/lib/kube-proxy/config.yaml
  chmod 600 /var/lib/kube-proxy/kubeconfig /var/lib/kube-proxy/pki/kube-proxy.pem /var/lib/kube-proxy/pki/kube-proxy-key.pem
  chmod 644 /var/lib/kube-proxy/pki/ca.pem

  chmod 640 /etc/kubelet.d/kubelet.env /var/lib/kubelet/config.yaml
  chmod 640 /etc/kubelet.d/node.env || true
  chmod 600 /var/lib/kubelet/kubeconfig /var/lib/kubelet/pki/kubelet.pem /var/lib/kubelet/pki/kubelet-key.pem
  chmod 644 /var/lib/kubelet/pki/ca.pem
}

start_services() {
  systemctl daemon-reload
  systemctl enable --now kube-apiserver.service
  systemctl enable --now kube-controller-manager.service
  systemctl enable --now kube-scheduler.service
  systemctl enable --now containerd.service
  systemctl enable --now kubelet.service
  systemctl enable --now kube-proxy.service
}

main() {
  need_root
  ensure_directories
  for user in "${SERVICE_USERS[@]}"; do
    ensure_user "${user}"
  done
  verify_files
  copy_etcd_ca
  install_runtime_stack
  render_kube_apiserver_env
  fix_permissions
  start_services
  echo "[INFO] Control plane services started"
}

main "$@"
