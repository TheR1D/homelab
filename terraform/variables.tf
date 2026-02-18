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

variable "cf_api_token" {
  description = "Cloudflare API token for DNS challenge (Zone:DNS:Edit permission)"
  type        = string
  sensitive   = true
}

variable "cert_domain" {
  description = "Domain for SSL certificate (e.g., example.com)"
  type        = string
}

variable "cert_email" {
  description = "Email for Let's Encrypt registration"
  type        = string
}

variable "local_subnet" {
  description = "Local subnet CIDR for firewall rules (e.g., 192.168.0.0/24)"
  type        = string
}

variable "proxmox_ip" {
  description = "Proxmox server IP address"
  type        = string
}

variable "kong_admin_url" {
  description = "Kong Gateway Admin API URL"
  type        = string
  default     = null
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "proxmox"
}
