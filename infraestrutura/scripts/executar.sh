#!/usr/bin/env bash
# Executa o simulador dentro da VM e mostra os dados gerados.
# Uso: executar.sh [quantidade_de_registros]
set -euo pipefail
source "$(dirname "$0")/_comum.sh"
QTD="${1:-20}"

ssh "${SSH_OPTS[@]}" "$VM_USER@$VM_IP" bash -s <<REMOTO
set -e
export BURNOUT_DADOS_DIR=/opt/burnout/dados
/opt/burnout/venv/bin/python /opt/burnout/simulador/simulador.py --quantidade $QTD
echo "--- cabecalho e ultimas linhas de dados_burnout.csv ---"
head -1 /opt/burnout/dados/dados_burnout.csv
tail -n 5 /opt/burnout/dados/dados_burnout.csv
REMOTO
