output "gateway_id" {
  description = "Virtual network gateway resource ID."
  value       = azurerm_virtual_network_gateway.s2s.id
}

output "gateway_public_ip" {
  description = "Public IP the on-prem device must peer with."
  value       = azurerm_public_ip.gw.ip_address
}

output "connection_id" {
  description = "IPsec connection resource ID."
  value       = azurerm_virtual_network_gateway_connection.s2s.id
}

output "local_network_gateway_id" {
  value = azurerm_local_network_gateway.onprem.id
}
