variable "vm_name" {
  description = "Name of the VM"
  type        = string
}

variable "vm_id" {
  description = "ID of the VM (if not set, Proxmox will auto-assign)"
  type        = number
  default     = null
}

variable "node_name" {
  description = "Name of the Proxmox node"
  type        = string
  default     = "proxmox"
}

variable "agent_timeout" {
  description = "Timeout for QEMU guest agent"
  type        = string
  default     = "2s"
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "ram" {
  description = "RAM configuration"
  type = object({
    dedicated = number
    floating  = number
  })
  default = {
    dedicated = 4096
    floating  = 2048
  }
}

variable "disk" {
  description = "Disk configuration"
  type = object({
    size    = number
    file_id = string
    backup  = bool
  })
  default = {
    size    = 20
    file_id = "local:iso/noble-server-cloudimg-amd64.img"
    backup  = false
  }
}

variable "cloud_init" {
  description = "Path to cloud-init configuration file (e.g., ../cloudinit/invoker.yml)"
  type        = string
}

