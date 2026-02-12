terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.95.0"
    }
  }
}
# Generate MAC address from VM name, useful for static DHCP leases.
# Basically the idea is to generate deterministic MAC address from VM 
# name so we can set static DHCP lease for it on DHCP server.
# echo "02:$(echo -n 'kong' | md5sum | cut -c1-10 | sed 's/../&:/g' | sed 's/:$//')"
locals {
  mac_address = "02:${join(":", regex("(..)(..)(..)(..)(..).*", md5(var.vm_name)))}"
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
  description   = "Managed by Terraform"
  tags          = concat(["terraform"], var.tags)
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

    dynamic "dns" {
      for_each = var.dns != null ? [var.dns] : []
      content {
        domain  = dns.value.domain
        servers = dns.value.servers
      }
    }

    ip_config {
      ipv4 {
        address = var.ip_config.address
        gateway = var.ip_config.gateway
      }
    }
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = local.mac_address
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

