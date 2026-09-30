variable "libvirt_uri" {
  description = "URI do libvirt na maquina hospedeira"
  type        = string
  default     = "qemu:///system"
}

variable "vm_nome" {
  description = "Nome da VM (e hostname)"
  type        = string
  default     = "burnout-vm"
}

variable "vm_memoria_mb" {
  type    = number
  default = 2048
}

variable "vm_vcpus" {
  type    = number
  default = 2
}

variable "vm_disco_gb" {
  type    = number
  default = 15
}

variable "imagem_base_url" {
  description = "Imagem cloud (qcow2) usada como base da VM"
  type        = string
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

variable "pool_armazenamento" {
  description = "Storage pool do libvirt"
  type        = string
  default     = "default"
}

variable "rede_libvirt" {
  description = "Rede do libvirt (NAT) a que a VM sera conectada"
  type        = string
  default     = "default"
}

variable "usuario_vm" {
  description = "Usuario administrador criado pelo cloud-init"
  type        = string
  default     = "burnout"
}

variable "chave_publica_ssh" {
  description = "Caminho da chave PUBLICA SSH autorizada na VM (a privada nunca vai ao repositorio)"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "chave_privada_ssh" {
  description = "Caminho da chave PRIVADA, usado apenas no inventario do Ansible gerado localmente"
  type        = string
  default     = "~/.ssh/id_ed25519"
}
