#!/usr/bin/env bash
# Bootstrap Kubernetes control plane services on a node after files are distributed.
set -euo pipefail

REQUIRED_BINARIES=(/usr/local/bin/kube-apiserver /usr/local/bin/kube-controller-manager /usr/local/bin/kube-scheduler)
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
  )

  for file in "${required_files[@]}"; do
    [[ -f "${file}" ]] || missing+=("${file}")
  done

  if (( ${#missing[@]} > 0 )); then
    printf '[ERROR] Missing required assets:\n - %s\n' "${missing[@]}" >&2
    exit 1
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
}

start_services() {
  systemctl daemon-reload
  systemctl enable --now kube-apiserver.service
  systemctl enable --now kube-controller-manager.service
  systemctl enable --now kube-scheduler.service
}

main() {
  need_root
  ensure_directories
  for user in "${SERVICE_USERS[@]}"; do
    ensure_user "${user}"
  done
  verify_files
  render_kube_apiserver_env
  fix_permissions
  start_services
  echo "[INFO] Control plane services started"
}

main "$@"
