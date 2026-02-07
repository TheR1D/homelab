terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.50"
    }
  }
}

provider "proxmox" {
  ssh {
    agent    = true
    username = "root"
  }
}

module "example_vm" {
  source     = "./modules/vm/cloudinit"
  vm_name    = "example-vm"
  cloud_init = "${path.module}/../cloudinit/invoker.yml"
}

output "example_vm_id" {
  value = module.example_vm.vm_id
}

output "example_vm_name" {
  value = module.example_vm.vm_name
}

output "example_vm_ip" {
  value = module.example_vm.vm_ip_address
}
