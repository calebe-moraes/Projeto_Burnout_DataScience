terraform {
  required_version = ">= 1.6.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}

# Imagem base (baixada uma vez) e disco da VM derivado dela
resource "libvirt_volume" "base" {
  name   = "${var.vm_nome}-base.qcow2"
  pool   = var.pool_armazenamento
  source = var.imagem_base_url
  format = "qcow2"
}

resource "libvirt_volume" "disco" {
  name           = "${var.vm_nome}-disco.qcow2"
  pool           = var.pool_armazenamento
  base_volume_id = libvirt_volume.base.id
  size           = var.vm_disco_gb * 1024 * 1024 * 1024
  format         = "qcow2"
}

# cloud-init: o arquivo cloud_init.cfg e renderizado com usuario e chave publica
resource "libvirt_cloudinit_disk" "init" {
  name = "${var.vm_nome}-cloudinit.iso"
  pool = var.pool_armazenamento
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    hostname          = var.vm_nome
    usuario           = var.usuario_vm
    chave_publica_ssh = trimspace(file(pathexpand(var.chave_publica_ssh)))
  })
}

resource "libvirt_domain" "vm" {
  name   = var.vm_nome
  memory = var.vm_memoria_mb
  vcpu   = var.vm_vcpus

  cloudinit = libvirt_cloudinit_disk.init.id

  network_interface {
    network_name   = var.rede_libvirt
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.disco.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "spice"
    listen_type = "none"
  }
}

# Inventario do Ansible gerado com o IP real recebido pela VM
resource "local_file" "inventario" {
  filename        = "${path.module}/ansible/inventory.ini"
  file_permission = "0644"
  content         = <<-EOT
    [simulador]
    ${var.vm_nome} ansible_host=${libvirt_domain.vm.network_interface[0].addresses[0]}

    [simulador:vars]
    ansible_user=${var.usuario_vm}
    ansible_ssh_private_key_file=${var.chave_privada_ssh}
    ansible_python_interpreter=/usr/bin/python3
  EOT
}

output "vm_ip" {
  value = libvirt_domain.vm.network_interface[0].addresses[0]
}

output "usuario_ssh" {
  value = var.usuario_vm
}
