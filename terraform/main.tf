terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.76"
    }
  }
}

provider "proxmox" {
  ssh {
    agent    = true
    username = "root"
  }
}

# Hardware mapping for VirtIO-FS: /mnt/nas -> tag "nas"
resource "proxmox_virtual_environment_hardware_mapping_dir" "nas" {
  name    = "nas"
  comment = "NAS directory mapping for VirtIO-FS"

  map = [
    {
      node = "proxmox"
      path = "/mnt/nas"
    }
  ]
}

module "example_vm" {
  source           = "./modules/vm/cloudinit"
  vm_name          = "example-vm"
  cloud_init_files = ["${path.module}/../cloudinit/base.yml"]
  cloudinit_vars = {
    username       = var.username
    user_password  = var.user_password
    ssh_public_key = var.ssh_public_key
    hostname       = "example-vm"
    timezone       = var.timezone
  }
  os_image = {
    url                = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    checksum           = "3c5d83863fd3d624c8c628ed69520ccee62c1aba8101d0a3f9b16dbc80766943"
    checksum_algorithm = "sha256"
    file_name          = "noble-server-cloudimg-amd64.qcow2"
  }
}

module "nas_vm" {
  source           = "./modules/vm/cloudinit"
  vm_name          = "nas-vm"
  serial_device    = true
  cloud_init_files = [
    "${path.module}/../cloudinit/base.yml",
    "${path.module}/../cloudinit/nas.yml",
  ]
  cloudinit_vars = {
    username       = "nasuser"
    user_password  = var.user_password
    ssh_public_key = var.ssh_public_key
    timezone       = var.timezone
    hostname       = "nas-server"
    nas_storage    = "nas"
  }
  os_image = {
    url                = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    checksum           = "3c5d83863fd3d624c8c628ed69520ccee62c1aba8101d0a3f9b16dbc80766943"
    checksum_algorithm = "sha256"
    file_name          = "noble-server-cloudimg-amd64.qcow2"
  }
  virtiofs = [
    {
      mapping = proxmox_virtual_environment_hardware_mapping_dir.nas.name
    }
  ]
  # TODO: Mikrotik make DHCP address static for this VM.
}

output "example_vm" {
  value = module.example_vm
}

output "nas_vm" {
  value = module.nas_vm
}
