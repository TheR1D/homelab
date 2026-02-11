terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.95.0"
    }
    kong-gateway = {
      source = "kong/kong-gateway"
    }
  }
}

provider "proxmox" {
  ssh {
    agent    = true
    username = "root"
  }
}

provider "kong-gateway" {
  server_url = "http://${module.kong_vm.vm_ip_address}:8001"
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
