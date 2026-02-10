terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}

data "cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  dynamic "part" {
    for_each = var.cloud_init_files
    content {
      content_type = "text/cloud-config"
      content      = templatefile(part.value, var.cloudinit_vars)
    }
  }
}

# Download the OS image if URL is provided
resource "proxmox_virtual_environment_download_file" "image" {
  content_type       = "import"
  datastore_id       = "local"
  node_name          = var.node_name
  url                = var.os_image.url
  checksum           = var.os_image.checksum
  checksum_algorithm = var.os_image.checksum_algorithm
  file_name          = var.os_image.file_name
}

# Upload merged cloud-init configuration
resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node_name

  source_raw {
    data      = data.cloudinit_config.config.rendered
    file_name = "${var.vm_name}-cloud-init.yml"
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
    import_from  = proxmox_virtual_environment_download_file.image.id
    interface    = "scsi0"
    size         = var.disk.size
    file_format  = var.disk.file_format
    ssd          = true
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
        # TODO: Move into cloud init.
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

  # TODO: Will OVMF (UEFI) provide some benefits?

  # Fix kernel panic on first boot with Debian cloud images + expanded disk
  # See: https://forum.proxmox.com/threads/160125/
  dynamic "serial_device" {
    for_each = var.serial_device ? [1] : []
    content {
      device = "socket"
    }
  }

  dynamic "virtiofs" {
    for_each = var.virtiofs
    content {
      mapping   = virtiofs.value.mapping
      cache     = virtiofs.value.cache
      direct_io = virtiofs.value.direct_io
    }
  }
}

