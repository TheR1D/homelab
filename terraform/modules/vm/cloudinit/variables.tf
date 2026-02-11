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
    size        = number
    file_id     = optional(string)
    import_from = optional(string)
    file_format = optional(string)
    backup      = bool
  })
  default = {
    size        = 20
    file_format = "raw"
    backup      = false
  }
}

variable "cloud_init_files" {
  description = "List of cloud-init file paths to merge"
  type        = list(string)
}

variable "cloudinit_vars" {
  description = "Variables to pass to cloud-init templates"
  type        = map(any)
  default     = {}
}

variable "os_image" {
  description = "OS image configuration for the VM"
  type = object({
    url                = string
    checksum           = optional(string)
    checksum_algorithm = optional(string)
    file_name          = optional(string)
  })
}

variable "serial_device" {
  description = "Enable serial device (socket). Useful for kernel panic fix on Debian cloud images."
  type        = bool
  default     = false
}

variable "virtiofs" {
  description = "VirtIO-FS share configurations"
  type = list(object({
    mapping   = string
    cache     = optional(string)
    direct_io = optional(bool)
  }))
  default = []
}

variable "ip_config" {
  description = "Use 'dhcp' for DHCP or CIDR notation for static (e.g., '192.168.0.10/24')"
  type = object({
    address = string
    gateway = optional(string)
  })
  default = {
    address = "dhcp"
  }
}

variable "dns_servers" {
  description = "List of DNS servers for the VM"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "tags" {
  description = "Additional tags to apply to the VM"
  type        = list(string)
  default     = []
}
