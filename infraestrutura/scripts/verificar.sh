#!/usr/bin/env bash
# Comprova que o cloud-init foi aplicado na VM.
set -euo pipefail
source "$(dirname "$0")/_comum.sh"

ssh "${SSH_OPTS[@]}" "$VM_USER@$VM_IP" '
  echo "hostname : $(hostname)"
  echo "usuario  : $(whoami)"
  echo "sudo     : $(sudo -n true && echo ok)"
  echo "--- /etc/burnout-cloud-init.txt ---"; cat /etc/burnout-cloud-init.txt
  echo "--- cloud-init status ---"; cloud-init status
  echo "--- PasswordAuthentication ---"; sudo sshd -T | grep -i "^passwordauthentication"
'
