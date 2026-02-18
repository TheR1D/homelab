variable "ct_name" {
  description = "Name of the container"
  type        = string
}

variable "ct_id" {
  description = "ID of the container (if not set, Proxmox will auto-assign)"
  type        = number
  default     = null
}

variable "node_name" {
  description = "Name of the Proxmox node"
  type        = string
  default     = "proxmox"
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory configuration"
  type = object({
    dedicated = number
    swap      = optional(number, 0)
  })
  default = {
    dedicated = 512
    swap      = 0
  }
}

variable "disk" {
  description = "Disk configuration"
  type = object({
    datastore_id = optional(string, "local-lvm")
    size         = optional(number, 4)
  })
  default = {
    datastore_id = "local-lvm"
    size         = 4
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

variable "os_template" {
  description = "OS template configuration for the container (LXC template URL)"
  type = object({
    url       = string
    file_name = string
  })
}

variable "os_type" {
  description = "OS type (ubuntu, debian, alpine, etc.)"
  type        = string
  default     = "ubuntu"
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

variable "dns" {
  description = "DNS configuration (domain and servers)"
  type = object({
    domain  = optional(string)
    servers = optional(list(string))
  })
  default = null
}

variable "tags" {
  description = "Additional tags to apply to the container"
  type        = list(string)
  default     = []
}

variable "unprivileged" {
  description = "Whether the container runs as unprivileged"
  type        = bool
  default     = true
}

variable "nesting" {
  description = "Enable nesting feature for the container"
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Automatically start container when the host system boots"
  type        = bool
  default     = true
}

variable "started" {
  description = "Whether to start the container after creation"
  type        = bool
  default     = true
}

variable "mount_points" {
  description = "Mount points for the container"
  type = list(object({
    volume = string
    path   = string
    size   = optional(string)
  }))
  default = []
}

