#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
HOSTS_FILE="/etc/hosts"
KEY_PATH="${KEY_PATH:-${REPO_ROOT}/chapter1/kthw-lab}"
SSH_USER="${SSH_USER:-ubuntu}"

if [[ ! -f "${KEY_PATH}" ]]; then
  echo "[error] SSH key not found at ${KEY_PATH}. Set KEY_PATH=/path/to/key." >&2
  exit 1
fi

read -r -d '' ENTRY_BLOCK <<'ENTRIES'
10.240.16.10 cp-a
10.240.48.10 cp-b
10.240.80.10 cp-c
10.240.16.20 worker-a
10.240.48.20 worker-b
ENTRIES

ensure_local() {
  echo "[info] Updating ${HOSTS_FILE} on bastion"
  while read -r ip host; do
    [[ -z "${ip}" || -z "${host}" ]] && continue
    line="${ip} ${host} ${host}.kthw.lab"
    if grep -qE "^${ip}\\s+${host}(\\s|$)" "${HOSTS_FILE}"; then
      echo "  [skip] ${host} already present"
    else
      echo "  [add] ${line}"
      printf '%s\n' "${line}" | sudo tee -a "${HOSTS_FILE}" >/dev/null
    fi
  done <<<"${ENTRY_BLOCK}"
}

ensure_remote() {
  echo "[info] Propagating entries to cluster nodes"
  encoded_entries="$(printf '%s' "${ENTRY_BLOCK}" | base64)"
  remote_script=$(cat <<'REMOTE'
set -euo pipefail
ENTRY_BLOCK=$(printf '%s' "__ENTRY_BLOCK__" | base64 --decode)
while read -r rip rhost; do
  if [[ -z "$rip" || -z "$rhost" ]]; then
    continue
  fi
  line="$rip $rhost $rhost.kthw.lab"
  if grep -qE "^$rip\\s+$rhost(\\s|$)" /etc/hosts; then
    echo "  [skip] $rhost already present" >&2
  else
    echo "  [add] $line" >&2
    printf '%s\n' "$line" | sudo tee -a /etc/hosts >/dev/null
  fi
done <<<"$ENTRY_BLOCK"
REMOTE
)
  remote_script="${remote_script/__ENTRY_BLOCK__/${encoded_entries}}"
  while read -r ip host; do
    [[ -z "${ip}" || -z "${host}" ]] && continue
    echo "  [node] ${host} (${ip})"
    ssh -i "${KEY_PATH}" -o BatchMode=yes -o StrictHostKeyChecking=no \
      "${SSH_USER}@${ip}" "bash -s" <<<"${remote_script}" || {
        echo "    [warn] SSH connection to ${host} failed" >&2
        continue
      }
  done <<<"${ENTRY_BLOCK}"
}

ensure_local
ensure_remote

echo
echo "[done] Hosts entries ensured. Test with: getent hosts worker-a"
