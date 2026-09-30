# Variaveis compartilhadas pelos scripts (carregado com "source")
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INV="$RAIZ/infraestrutura/ansible/inventory.ini"
VM_IP="$(grep -m1 ansible_host "$INV" | sed -E 's/.*ansible_host=([^ ]+).*/\1/')"
VM_USER="$(grep -m1 '^ansible_user=' "$INV" | cut -d= -f2)"
CHAVE="$(grep -m1 '^ansible_ssh_private_key_file=' "$INV" | cut -d= -f2)"
CHAVE="${CHAVE/#\~/$HOME}"
SSH_OPTS=(-i "$CHAVE" -o StrictHostKeyChecking=accept-new)
