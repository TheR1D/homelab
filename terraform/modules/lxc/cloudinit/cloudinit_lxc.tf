terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.96.0"
    }
  }
}

# Generate MAC address from container name for deterministic DHCP leases
locals {
  mac_address = "02:${join(":", regex("(..)(..)(..)(..)(..).*", md5(var.ct_name)))}"
  repacked_template_path = "${path.root}/.terraform/lxc-templates/${var.ct_name}-repacked.tar.xz"
}

# Merge cloud-init files
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

# Write user-data to temp file
resource "local_file" "user_data" {
  content  = data.cloudinit_config.config.rendered
  filename = "${path.root}/.terraform/lxc-templates/${var.ct_name}-user-data"
}

# Write meta-data to temp file
resource "local_file" "meta_data" {
  content  = "instance-id: ${var.ct_name}\nlocal-hostname: ${var.ct_name}\n"
  filename = "${path.root}/.terraform/lxc-templates/${var.ct_name}-meta-data"
}

# Download template locally and repack with cloud-init files
resource "terraform_data" "repack_template" {
  triggers_replace = [
    data.cloudinit_config.config.rendered,
    var.os_template.url,
  ]

  provisioner "local-exec" {
    command = <<-EOT
      mkdir -p "${path.root}/.terraform/lxc-templates"
      LOCAL_TEMPLATE="${path.root}/.terraform/lxc-templates/${var.os_template.file_name}"
      if [ ! -f "$LOCAL_TEMPLATE" ]; then
        curl -fSL -o "$LOCAL_TEMPLATE" "${var.os_template.url}"
      fi
      ${path.module}/../../../../proxmox/lxcc.sh \
        "$LOCAL_TEMPLATE" \
        "${local_file.user_data.filename}" \
        "${local_file.meta_data.filename}" \
        "${local.repacked_template_path}"
    EOT
  }

  depends_on = [
    local_file.user_data,
    local_file.meta_data,
  ]
}

# Upload repacked template to Proxmox
resource "proxmox_virtual_environment_file" "repacked_template" {
  content_type = "vztmpl"
  datastore_id = "local"
  node_name    = var.node_name

  source_file {
    path      = local.repacked_template_path
    file_name = "${var.ct_name}-cloudinit.tar.xz"
  }

  depends_on = [terraform_data.repack_template]
}

# Create the LXC container
resource "proxmox_virtual_environment_container" "ct" {
  vm_id         = var.ct_id
  node_name     = var.node_name
  description   = "Managed by Terraform"
  tags          = concat(["terraform"], var.tags)
  unprivileged  = var.unprivileged
  start_on_boot = var.start_on_boot
  started       = var.started

  features {
    nesting = var.nesting
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory.dedicated
    swap      = var.memory.swap
  }

  disk {
    datastore_id = var.disk.datastore_id
    size         = var.disk.size
  }

  operating_system {
    template_file_id = proxmox_virtual_environment_file.repacked_template.id
    type             = var.os_type
  }

  initialization {
    hostname = var.ct_name

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

  network_interface {
    name        = "eth0"
    bridge      = "vmbr0"
    mac_address = local.mac_address
  }

  dynamic "mount_point" {
    for_each = var.mount_points
    content {
      volume = mount_point.value.volume
      path   = mount_point.value.path
      size   = mount_point.value.size
    }
  }
}

