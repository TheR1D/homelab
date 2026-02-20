resource "proxmox_virtual_environment_hardware_mapping_dir" "docker-data" {
  name    = "docker-data"
  comment = "Docker data directory mapping for VirtIO-FS"

  map = [
    {
      node = var.proxmox_node
      path = "/var/lib/vz/docker-data"
    }
  ]
}

module "docker_vm" {
  source           = "./modules/vm/cloudinit"
  vm_name          = "docker"
  cloud_init_files = [
    "${path.module}/../cloudinit/base.yml",
    "${path.module}/../cloudinit/docker.yml",
  ]
  agent_timeout    = "2m"
  cpu_cores = 8
  ram = {
    dedicated = 8192
    floating = 0
  }
  disk = {
    size   = 40
    backup = false
  }
  cloudinit_vars = {
    username        = var.username
    user_password   = var.user_password
    ssh_public_key  = var.ssh_public_key
    local_subnet    = var.local_subnet
    vpn_subnet      = var.vpn_subnet
    hostname        = "docker"
    timezone        = var.timezone
    virtiofs_folder = proxmox_virtual_environment_hardware_mapping_dir.docker-data.name
  }
  os_image = {
    url                = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
    # checksum           = "3c5d83863fd3d624c8c628ed69520ccee62c1aba8101d0a3f9b16dbc80766943"
    # checksum_algorithm = "sha256"
    file_name          = "noble-server-cloudimg-amd64.qcow2"
  }
  virtiofs = [
    {
      mapping = proxmox_virtual_environment_hardware_mapping_dir.docker-data.name
    }
  ]
}

resource "null_resource" "docker_compose" {
  depends_on = [module.docker_vm]

  triggers = {
    docker_dir_hash = sha1(join("", [for f in fileset("${path.module}/../docker", "**") : filemd5("${path.module}/../docker/${f}")]))
  }

  connection {
    type  = "ssh"
    host  = module.docker_vm.vm_ip_address
    user  = var.username
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "mkdir -p /home/${var.username}/docker"
    ]
  }

  provisioner "file" {
    source      = "${path.module}/../docker/"
    destination = "/home/${var.username}/docker"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/${var.username}/docker",
      "sudo docker compose up -d --remove-orphans"
    ]
  }
}
