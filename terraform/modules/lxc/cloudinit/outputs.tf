output "ct_id" {
  description = "Container ID"
  value       = proxmox_virtual_environment_container.ct.vm_id
}

output "ct_name" {
  description = "Container name"
  value       = var.ct_name
}

output "ct_ipv4_address" {
  description = "Container IPv4 address (first address from first network interface)"
  value       = try(proxmox_virtual_environment_container.ct.initialization[0].ip_config[0].ipv4[0].address, null)
}

