terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

# Upload cloud-init configuration file
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node_name

  source_file {
    path = var.cloud_init
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  vm_id         = var.vm_id
  name          = var.vm_name
  node_name     = var.node_name
  machine       = "q35"
  scsi_hardware = "virtio-scsi-single"

  agent {
    enabled = true
    timeout = var.agent_timeout
    trim    = true
    type    = "virtio"
  }

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.ram.dedicated
    floating  = var.ram.floating
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = var.disk.file_id
    interface    = "scsi0"
    size         = var.disk.size
    file_format  = "raw"
    ssd          = true
    cache        = "writeback"
    discard      = "on"
    iothread     = true
    backup       = var.disk.backup
    aio          = "io_uring"
  }

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
    type = "l26"
  }
}

