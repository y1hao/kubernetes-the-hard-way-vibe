#!/usr/bin/env bash
# Bootstrap etcd on a control plane node after files have been distributed.
#
# Performs the following actions (idempotent where practical):
#   - Ensures the `etcd` system user/group exist.
#   - Creates data/config directories with the correct ownership.
#   - Normalises permissions for TLS material and environment files.
#   - Reloads systemd, enables, and starts the etcd service.
#   - Executes optional etcdctl health checks when the helper env file is present.
#
# Usage: sudo ./bootstrap_etcd_node.sh
set -euo pipefail

readonly ETCD_USER="etcd"
readonly ETCD_GROUP="etcd"
readonly ETCD_HOME="/var/lib/etcd"
readonly ETCD_CONF_DIR="/etc/etcd"
readonly ETCD_PKI_DIR="${ETCD_CONF_DIR}/pki"
readonly ETCD_ENV_FILE="${ETCD_CONF_DIR}/etcd.env"
readonly ETCDCTL_ENV_FILE="${ETCD_CONF_DIR}/etcdctl.env"
readonly REQUIRED_BINARIES=(/usr/local/bin/etcd /usr/local/bin/etcdctl)

need_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "[ERROR] Run this script as root (sudo)." >&2
    exit 1
  fi
}

ensure_group() {
  if ! getent group "${ETCD_GROUP}" >/dev/null; then
    groupadd --system "${ETCD_GROUP}"
    echo "[INFO] Created ${ETCD_GROUP} system group"
  fi
}

ensure_user() {
  if ! getent passwd "${ETCD_USER}" >/dev/null; then
    useradd --system --home "${ETCD_HOME}" --shell /usr/sbin/nologin --gid "${ETCD_GROUP}" "${ETCD_USER}"
    echo "[INFO] Created ${ETCD_USER} system user"
  fi
}

ensure_directories() {
  mkdir -p "${ETCD_HOME}" "${ETCD_PKI_DIR}"
  chown -R "${ETCD_USER}:${ETCD_GROUP}" "${ETCD_HOME}" "${ETCD_CONF_DIR}"
  chmod 750 "${ETCD_HOME}"
}

fix_permissions() {
  if [[ -f "${ETCD_ENV_FILE}" ]]; then
    chown "${ETCD_USER}:${ETCD_GROUP}" "${ETCD_ENV_FILE}"
    chmod 640 "${ETCD_ENV_FILE}"
  fi

  if [[ -f "${ETCDCTL_ENV_FILE}" ]]; then
    chown "${ETCD_USER}:${ETCD_GROUP}" "${ETCDCTL_ENV_FILE}"
    chmod 640 "${ETCDCTL_ENV_FILE}"
  fi

  if [[ -d "${ETCD_PKI_DIR}" ]]; then
    find "${ETCD_PKI_DIR}" -type d -exec chown "${ETCD_USER}:${ETCD_GROUP}" {} +
    find "${ETCD_PKI_DIR}" -type f -name "*-key.pem" -exec chown "${ETCD_USER}:${ETCD_GROUP}" {} +
    find "${ETCD_PKI_DIR}" -type f -name "*-key.pem" -exec chmod 600 {} +
    find "${ETCD_PKI_DIR}" -type f \( -name "*.pem" -o -name "*.crt" \) ! -name "*-key.pem" -exec chown "${ETCD_USER}:${ETCD_GROUP}" {} +
    find "${ETCD_PKI_DIR}" -type f \( -name "*.pem" -o -name "*.crt" \) ! -name "*-key.pem" -exec chmod 640 {} +
  fi
}

verify_binaries() {
  local missing=()
  for bin in "${REQUIRED_BINARIES[@]}"; do
    if [[ ! -x "${bin}" ]]; then
      missing+=("${bin}")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    printf '[ERROR] Missing required binaries: %s\n' "${missing[*]}" >&2
    exit 1
  fi
}

reload_systemd() {
  systemctl daemon-reload
  systemctl enable --now etcd
  systemctl status --no-pager etcd
}

run_health_checks() {
  if [[ -f "${ETCDCTL_ENV_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${ETCDCTL_ENV_FILE}"
    if command -v etcdctl >/dev/null; then
      echo "[INFO] etcdctl endpoint status"
      etcdctl endpoint status --cluster || true
      echo "[INFO] etcdctl endpoint health"
      etcdctl endpoint health || true
    fi
  else
    echo "[WARN] Skipping etcdctl checks; ${ETCDCTL_ENV_FILE} not found"
  fi
}

main() {
  need_root
  verify_binaries
  mkdir -p "${ETCD_CONF_DIR}" "${ETCD_PKI_DIR}"
  ensure_group
  ensure_user
  ensure_directories
  fix_permissions
  reload_systemd
  run_health_checks
}

main "$@"
