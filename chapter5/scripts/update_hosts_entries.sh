#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HOSTS_FILE="/etc/hosts"
KEY_PATH="${KEY_PATH:-${REPO_ROOT}/chapter1/kthw-lab}"
SSH_USER="${SSH_USER:-ubuntu}"

if [[ ! -f "${KEY_PATH}" ]]; then
  echo "[error] SSH key not found at ${KEY_PATH}. Set KEY_PATH before running." >&2
  exit 1
fi

declare -A HOST_MAP=(
  [cp-a]=10.240.16.10
  [cp-b]=10.240.48.10
  [cp-c]=10.240.80.10
  [worker-a]=10.240.16.20
  [worker-b]=10.240.48.20
)

add_local_entries() {
  echo "[info] Ensuring entries in ${HOSTS_FILE} on bastion"
  for host in "${!HOST_MAP[@]}"; do
    ip="${HOST_MAP[${host}]}"
    line="${ip} ${host} ${host}.kthw.lab"
    if grep -qE "^${ip}[[:space:]]+${host}([[:space:]]|$)" "${HOSTS_FILE}"; then
      echo "  [skip] ${host} already present"
    else
      echo "  [add] ${line}"
      printf '%s\n' "${line}" | sudo tee -a "${HOSTS_FILE}" >/dev/null
    fi
  done
}

add_remote_entries() {
  echo "[info] Ensuring entries on cluster nodes"
  for target_host in "${!HOST_MAP[@]}"; do
    target_ip="${HOST_MAP[${target_host}]}"
    echo "  [node] ${target_host} (${target_ip})"
    for entry_host in "${!HOST_MAP[@]}"; do
      entry_ip="${HOST_MAP[${entry_host}]}"
      line="${entry_ip} ${entry_host} ${entry_host}.kthw.lab"
      escaped_line=$(printf '%q' "${line}")
      ssh -i "${KEY_PATH}" -o BatchMode=yes -o StrictHostKeyChecking=no \
        "${SSH_USER}@${target_ip}" "grep -qE '^${entry_ip}[[:space:]]+${entry_host}([[:space:]]|$)' /etc/hosts || printf '%s\\n' ${escaped_line} | sudo tee -a /etc/hosts >/dev/null" >/dev/null 2>&1 && \
        echo "    [ok] ensured ${entry_host}" || \
        echo "    [warn] could not update ${target_host} for entry ${entry_host}" >&2
    done
  done
}

add_local_entries
add_remote_entries

echo "[done] Hostname entries configured. Test with: getent hosts worker-a"
