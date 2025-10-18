#!/usr/bin/env bash
set -euo pipefail

hosts_file="/etc/hosts"

declare -A host_map=(
  [cp-a]=10.240.16.10
  [cp-b]=10.240.48.10
  [cp-c]=10.240.80.10
  [worker-a]=10.240.16.20
  [worker-b]=10.240.48.20
)

for host in "${!host_map[@]}"; do
  ip="${host_map[$host]}"
  if grep -qE "^${ip}\\s+${host}(\\s|$)" "${hosts_file}"; then
    echo "[skip] ${host} already present in ${hosts_file}"
    continue
  fi
  echo "[add] ${ip} ${host}"
  printf '%s %s %s.kthw.lab\n' "${ip}" "${host}" "${host}" | sudo tee -a "${hosts_file}" >/dev/null
  if ! grep -qE "^${ip}\\s+${host}(\\s|$)" "${hosts_file}"; then
    echo "[error] failed to confirm entry for ${host}" >&2
    exit 1
  fi
  echo "[ok] added entry for ${host}"
  echo
done

echo "Done. Verify resolution with: getent hosts worker-a"
