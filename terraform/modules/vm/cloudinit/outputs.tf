output "vm_id" {
  description = "VM ID"
  value       = proxmox_virtual_environment_vm.vm.vm_id
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.vm.name
}

# TODO: probably not gonna work.
output "vm_ip_address" {
  description = "VM IP address (first IPv4 from first network interface)"
  value       = try(proxmox_virtual_environment_vm.vm.ipv4_addresses[1][0], null)
}

