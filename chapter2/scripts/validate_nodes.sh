#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/../.." && pwd)

INVENTORY_PATH="${INVENTORY:-${REPO_ROOT}/chapter2/inventory.yaml}"
SSH_KEY_PATH="${SSH_KEY_PATH:-${REPO_ROOT}/chapter1/kthw-lab}"
SSH_USER_ENV="${SSH_USER:-}"

if [[ ! -f "${INVENTORY_PATH}" ]]; then
  echo "[validate_nodes] inventory file not found: ${INVENTORY_PATH}" >&2
  exit 1
fi

if [[ ! -f "${SSH_KEY_PATH}" ]]; then
  echo "[validate_nodes] SSH key not found: ${SSH_KEY_PATH}" >&2
  exit 1
fi

PARSER_OUTPUT=$(python3 - "$INVENTORY_PATH" <<'PY'
import sys
from pathlib import Path

try:
    import yaml
except ImportError as exc:
    sys.stderr.write("[validate_nodes] Missing dependency: PyYAML. Install it with 'pip install PyYAML'.\n")
    sys.exit(1)

inventory_path = Path(sys.argv[1])
try:
    data = yaml.safe_load(inventory_path.read_text())
except Exception as exc:  # noqa: BLE001
    sys.stderr.write(f"[validate_nodes] Failed to load inventory: {exc}\n")
    sys.exit(1)

metadata = data.get("metadata", {})
ssh_user = metadata.get("ssh_user", "ubuntu")
print(f"META\tssh_user\t{ssh_user}")

for section in ("control_planes", "workers"):
    for host in data.get(section, []) or []:
        name = host.get("name", "")
        ip = host.get("private_ip", "")
        role = host.get("role", section.rstrip('s'))
        az = host.get("az_suffix", "")
        if not name or not ip:
            continue
        print(f"HOST\t{name}\t{role}\t{ip}\t{az}")
PY
)

IFS=$'\n' read -r -d '' -a PARSED_LINES < <(printf '%s\0' "${PARSER_OUTPUT}") || true

SSH_USER_RESOLVED="${SSH_USER_ENV}"
declare -a HOST_ROWS=()
for line in "${PARSED_LINES[@]}"; do
  IFS=$'\t' read -r kind value1 value2 value3 value4 <<<"${line}"
  case "${kind}" in
    META)
      if [[ -z "${SSH_USER_RESOLVED}" && "${value1}" == "ssh_user" ]]; then
        SSH_USER_RESOLVED="${value2}"
      fi
      ;;
    HOST)
      HOST_ROWS+=("${value1}\t${value2}\t${value3}\t${value4}")
      ;;
  esac
done

if [[ -z "${SSH_USER_RESOLVED}" ]]; then
  SSH_USER_RESOLVED="ubuntu"
fi

if [[ ${#HOST_ROWS[@]} -eq 0 ]]; then
  echo "[validate_nodes] No hosts found in inventory." >&2
  exit 1
fi

SSH_COMMON_OPTS=(
  -i "${SSH_KEY_PATH}"
  -o BatchMode=yes
  -o StrictHostKeyChecking=accept-new
  -o UserKnownHostsFile="${REPO_ROOT}/chapter2/.ssh_known_hosts"
  -o ConnectTimeout=10
)

mkdir -p "${REPO_ROOT}/chapter2"
touch "${REPO_ROOT}/chapter2/.ssh_known_hosts"

OVERALL_STATUS=0

for row in "${HOST_ROWS[@]}"; do
  IFS=$'\t' read -r NAME ROLE IP AZ_SUFFIX <<<"${row}"
  echo "==> ${NAME} (${ROLE}) @ ${IP} [${AZ_SUFFIX}]"

  ssh "${SSH_COMMON_OPTS[@]}" "${SSH_USER_RESOLVED}@${IP}" "bash -s" <<'REMOTE'
set -euo pipefail

status_ok() {
  printf '  [OK]  %s\n' "$1"
}

status_fail() {
  printf '  [FAIL] %s\n' "$1"
  exit 1
}

if sudo swapon --show | grep -qE '\S'; then
  status_fail 'swap is still enabled'
else
  status_ok 'swap disabled'
fi

missing_modules=()
for module in overlay br_netfilter nf_conntrack; do
  if ! lsmod | awk '{print $1}' | grep -qx "$module"; then
    missing_modules+=("$module")
  fi
done

if ((${#missing_modules[@]} > 0)); then
  status_fail "missing kernel modules: ${missing_modules[*]}"
else
  status_ok 'kernel modules present'
fi

required_sysctls=(
  net.bridge.bridge-nf-call-iptables=1
  net.bridge.bridge-nf-call-ip6tables=1
  net.ipv4.ip_forward=1
  vm.swappiness=0
)

for entry in "${required_sysctls[@]}"; do
  key="${entry%%=*}"
  expected="${entry##*=}"
  value="$(sudo sysctl -n "$key" 2>/dev/null || echo '__missing__')"
  if [[ "$value" == "$expected" ]]; then
    status_ok "sysctl ${key}=${value}"
  else
    status_fail "sysctl ${key} expected ${expected}, found ${value}"
  fi
done

status_ok 'base validation complete'
REMOTE

  if [[ $? -ne 0 ]]; then
    OVERALL_STATUS=1
    echo "[validate_nodes] validation failed for ${NAME}." >&2
  fi
  echo
done

exit ${OVERALL_STATUS}
