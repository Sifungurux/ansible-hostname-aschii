#!/usr/bin/env bash
set -euo pipefail

INSTANCE="hostname-ascii-test"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROLE_DIR="$(dirname "${SCRIPT_DIR}")"
TMPINV=$(mktemp /tmp/ansible-inventory.XXXXXX)

trap 'rm -f "${TMPINV}"' EXIT

# --- Start or resume Lima instance ------------------------------------------
STATUS=$(limactl list --format '{{.Name}} {{.Status}}' 2>/dev/null \
    | awk -v n="${INSTANCE}" '$1==n {print $2}')

if [[ -z "${STATUS}" ]]; then
    echo "==> Creating Lima instance '${INSTANCE}'"
    limactl start --name="${INSTANCE}" "${SCRIPT_DIR}/debian12.yaml"
elif [[ "${STATUS}" == "Stopped" ]]; then
    echo "==> Starting Lima instance '${INSTANCE}'"
    limactl start "${INSTANCE}"
else
    echo "==> Lima instance '${INSTANCE}' is ${STATUS}"
fi

# --- Read SSH connection details from Lima's generated ssh.config ------------
SSH_CONFIG="${HOME}/.lima/${INSTANCE}/ssh.config"
PORT=$(awk '/^[[:space:]]*Port /{print $2; exit}' "${SSH_CONFIG}")
USER=$(awk '/^[[:space:]]*User /{print $2; exit}' "${SSH_CONFIG}")
KEY=$(awk '/^[[:space:]]*IdentityFile /{print $2; exit}' "${SSH_CONFIG}" \
    | sed "s|~|${HOME}|")

# --- Build a temporary inventory --------------------------------------------
cat > "${TMPINV}" << EOF
[test]
${INSTANCE} ansible_host=127.0.0.1 ansible_port=${PORT} ansible_user=${USER} ansible_ssh_private_key_file=${KEY} ansible_ssh_extra_args="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

[test:vars]
motd_env=PRE-PRODUCTION
motd_warn=Think before you act on this machine
motd_note=Test VM — not for production use
EOF

# --- Run playbook ------------------------------------------------------------
echo "==> Running playbook against ${INSTANCE} (port ${PORT}, user ${USER})"
ansible-playbook \
    -i "${TMPINV}" \
    --extra-vars "ansible_roles_path=${ROLE_DIR}/.." \
    "${SCRIPT_DIR}/main.yml"
