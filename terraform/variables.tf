# Terraform will ask for this value if not provided via -var or TF_VAR_
variable "user_password" {
  description = "Password for the VM/LXC user"
  type        = string
  sensitive   = true
}

variable "username" {
  description = "Username for the VM/LXC user"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for the VM/LXC"
  type        = string
}

variable "timezone" {
  description = "Timezone for the VM/LXC"
  type        = string
}

variable "local_subnet" {
  description = "Local subnet CIDR for firewall rules (e.g., 192.168.0.0/24)"
  type        = string
}

variable "vpn_subnet" {
  description = "VPN subnet CIDR for firewall rules (e.g., 10.255.255.0/24)"
  type        = string
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "proxmox"
}
