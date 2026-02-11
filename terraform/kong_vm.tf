module "kong_vm" {
  source        = "./modules/vm/cloudinit"
  vm_name       = "kong"
  serial_device = true
  cpu_cores     = 2
  agent_timeout = "120s"
  ram = {
    dedicated = 4096
    floating  = 2048
  }
  cloud_init_files = [
    "${path.module}/../cloudinit/base.yml",
    "${path.module}/../cloudinit/kong.yml",
  ]
  cloudinit_vars = {
    username       = var.username
    user_password  = var.user_password
    ssh_public_key = var.ssh_public_key
    hostname       = "kong-gateway"
    timezone       = var.timezone
    cf_api_token   = var.cf_api_token
    cert_domain    = var.cert_domain
    cert_email     = var.cert_email
    local_subnet   = var.local_subnet
  }
  os_image = {
    url                = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    checksum           = "3c5d83863fd3d624c8c628ed69520ccee62c1aba8101d0a3f9b16dbc80766943"
    checksum_algorithm = "sha256"
    file_name          = "noble-server-cloudimg-amd64.qcow2"
  }
}

