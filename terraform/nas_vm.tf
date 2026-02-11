module "nas_vm" {
  source        = "./modules/vm/cloudinit"
  vm_name       = "nas"
  serial_device = true
  cloud_init_files = [
    "${path.module}/../cloudinit/base.yml",
    "${path.module}/../cloudinit/nas.yml",
  ]
  cloudinit_vars = {
    username       = "nasuser"
    user_password  = var.user_password
    ssh_public_key = var.ssh_public_key
    timezone       = var.timezone
    local_subnet   = var.local_subnet
    hostname       = "nas"
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
}

