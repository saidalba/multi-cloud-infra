#!/usr/bin/env bash
# Generates an Ansible inventory file for a provider from its Terraform outputs.
# Usage: generate-inventory.sh <provider>
set -euo pipefail

PROVIDER="${1:?Usage: generate-inventory.sh <provider>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIVE_DIR="${REPO_ROOT}/terraform/live/${PROVIDER}"
INVENTORY_DIR="${REPO_ROOT}/ansible/inventory"
INVENTORY_FILE="${INVENTORY_DIR}/${PROVIDER}.ini"

if [[ ! -d "${LIVE_DIR}" ]]; then
  echo "error: unknown provider '${PROVIDER}' (no ${LIVE_DIR})" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required but not installed" >&2
  exit 1
fi

OUTPUT_JSON="$(terraform -chdir="${LIVE_DIR}" output -json)"

PUBLIC_IP="$(jq -r '.public_ip.value' <<<"${OUTPUT_JSON}")"
SSH_USER="$(jq -r '.ssh_user.value' <<<"${OUTPUT_JSON}")"

if [[ -z "${PUBLIC_IP}" || "${PUBLIC_IP}" == "null" ]]; then
  echo "error: no public_ip output found for provider '${PROVIDER}' -- did you run terraform apply?" >&2
  exit 1
fi

mkdir -p "${INVENTORY_DIR}"

cat >"${INVENTORY_FILE}" <<EOF
[all]
${PUBLIC_IP} ansible_user=${SSH_USER}
EOF

echo "wrote ${INVENTORY_FILE}"
