# Kong Gateway configuration for VMs
# Add VMs to this map to register them with Kong
# Currenly there is no easy way to get VM IP address from Proxmox provider.
locals {
  kong_services = {
    "proxmox" = {
      name = "proxmox"
      host = var.proxmox_ip
      port = 8006
    }
    # Add more services here as needed:
    # "another-vm" = {
    #   name = "another-vm"
    #   host = module.another_vm.vm_ip_address
    #   port = 80
    # }
  }
}

output "kong_services_debug" {
  value = local.kong_services
}

resource "kong-gateway_service" "services" {
  depends_on = [module.kong_vm]

  for_each = local.kong_services

  name     = each.value.name
  protocol = "http"
  host     = each.value.host
  port     = each.value.port
}

resource "kong-gateway_route" "routes" {
  depends_on = [module.kong_vm]

  for_each = local.kong_services

  name      = "${each.value.name}-route"
  protocols = ["http", "https"]
  hosts     = ["${each.value.name}.${var.cert_domain}"]

  service = {
    id = kong-gateway_service.services[each.key].id
  }
}
