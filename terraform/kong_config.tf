# TODO: Implement
# Get list of VMs with "kong" tag
data "proxmox_virtual_environment_vms" "kong_vms" {
  tags = ["kong"]
}

# Query each VM individually to get IP addresses
data "proxmox_virtual_environment_vm" "kong_vm_details" {
  for_each  = { for vm in data.proxmox_virtual_environment_vms.kong_vms.vms : vm.vm_id => vm }
  node_name = each.value.node_name
  vm_id     = each.value.vm_id
}

resource "kong-gateway_service" "services" {
  depends_on = [module.kong_vm]

  for_each = data.proxmox_virtual_environment_vm.kong_vm_details

  name     = each.value.name
  protocol = "http"
  host     = try(each.value.ipv4_addresses[1][0], null)
  port     = 80
}

resource "kong-gateway_route" "routes" {
  depends_on = [module.kong_vm]

  for_each = data.proxmox_virtual_environment_vm.kong_vm_details

  name      = "${each.value.name}-route"
  protocols = ["http", "https"]
  hosts     = ["${each.value.name}.${var.cert_domain}"]

  service = {
    id = kong-gateway_service.services[each.key].id
  }
}
