#!/usr/bin/env bash
# Transfere o simulador da maquina hospedeira para a VM via SCP (SSH).
set -euo pipefail
source "$(dirname "$0")/_comum.sh"

echo ">> Copiando simulador/ para $VM_USER@$VM_IP:/opt/burnout/"
scp "${SSH_OPTS[@]}" -r "$RAIZ/simulador/." "$VM_USER@$VM_IP:/opt/burnout/simulador/"

echo ">> Arquivos no destino:"
ssh "${SSH_OPTS[@]}" "$VM_USER@$VM_IP" "ls -l /opt/burnout/simulador"
