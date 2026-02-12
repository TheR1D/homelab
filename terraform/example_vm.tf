module "example_vm" {
  source           = "./modules/vm/cloudinit"
  vm_name          = "example-vm"
  cloud_init_files = ["${path.module}/../cloudinit/base.yml"]
  tags             = ["kong"]
  agent_timeout    = "2m"
  cloudinit_vars = {
    username       = var.username
    user_password  = var.user_password
    ssh_public_key = var.ssh_public_key
    local_subnet   = var.local_subnet
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
