output "resource_group_name" {
  value = azurerm_resource_group.lab.name
}

output "hub_vnet_id" {
  value = module.hub.vnet_id
}

output "hub_subnet_ids" {
  value = module.hub.subnet_ids
}

output "network_ops_group_object_id" {
  value = module.identity.network_ops_group_object_id
}

output "log_analytics_workspace_id" {
  value = module.monitor.workspace_id
}

output "log_analytics_customer_id" {
  value = module.monitor.workspace_customer_id
}

output "vpn_gateway_public_ip" {
  description = "Null unless enable_vpn_gateway is true."
  value       = try(module.vpn[0].gateway_public_ip, null)
}

output "private_dns_zone_name" {
  value = azurerm_private_dns_zone.internal.name
}
