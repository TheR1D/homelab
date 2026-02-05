# How to use:
# export PROXMOX_USER=user@pve
# export PROXMOX_USER_PASSWORD=password
# export PROXMOX_TOKEN=token
# terraform apply -var="vm_name=my-vm" -var="vm_id=100" -var="node_name=proxmox"

terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.50"
    }
  }
}

provider "proxmox" {
  # Authentication via environment variables:
  # PROXMOX_VE_ENDPOINT, PROXMOX_VE_INSECURE, PROXMOX_VE_API_TOKEN
  
  ssh {
    agent    = true
    username = "root"
  }
}

# Optional VM name variable.
variable "vm_name" {
  description = "Name of the VM"
  type        = string
  default     = "terraform-vm-01"
}

# Optional VM ID variable.
variable "vm_id" {
  description = "ID of the VM (if not set, Proxmox will auto-assign)"
  type        = number
  default     = null
}

# Optional node name variable.
variable "node_name" {
  description = "Name of the Proxmox node"
  type        = string
  default     = "proxmox"
}

resource "proxmox_virtual_environment_vm" "proxmox_vm" {
  vm_id       = var.vm_id
  name        = var.vm_name
  node_name   = var.node_name
  machine     = "q35"
  scsi_hardware = "virtio-scsi-single"
  
  # It takes time to install and launch guest agent. So don't wait for it.
  # At the same time we need agent to report to host Proxmox later after launch.
  agent {
    enabled = true
    timeout = "2s"
    trim    = true
    type    = "virtio"
  }
  
  cpu {
    cores = 2
    type  = "host"
  }
  
  memory {
    dedicated = 4096
    floating  = 2048
  }

  # === Regular boot with OS installer ISO. ===
  # disk {
  #   datastore_id = "local-lvm"
  #   size         = 20
  #   interface    = "virtio0"
  #   file_format  = "raw"
  #   ssd          = true
  #   cache        = "writeback"
  #   discard      = "on"
  #   iothread     = true
  #   backup       = false
  #   aio          = "io_uring"
  # }
  
  # # Boot from CD-ROM - add your ISO here
  # cdrom {
  #   file_id = "local:iso/ubuntu-24.04.3-live-server-amd64.iso"
  # }
  
  # === Cloud init boot ===
  # Import cloud image as the main disk
  disk {
    datastore_id = "local-lvm"
    file_id      = "local:iso/noble-server-cloudimg-amd64.img"
    interface    = "scsi0"
    size         = 20
    file_format  = "raw"
    ssd          = true
    cache        = "writeback"
    discard      = "on"
    iothread     = true
    backup       = false
    aio          = "io_uring"
  }
  
  # Cloud-init configuration
  initialization {
    datastore_id      = "local-lvm"
    interface         = "scsi1"
    user_data_file_id = proxmox_virtual_environment_file.cloud_init.id
    
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  network_device {
    bridge = "vmbr0"
  }
  
  operating_system {
    type = "l26"  # Linux 2.6+ kernel
  }
  
}

# Upload cloud-init configuration file
# Should be disabled if not using cloud init boot
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node_name

  source_file {
    path = "${path.module}/../cloudinit/invoker.yml"
  }
}

output "vm_id" {
  description = "VM ID"
  value       = proxmox_virtual_environment_vm.proxmox_vm.vm_id
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.proxmox_vm.name
}
