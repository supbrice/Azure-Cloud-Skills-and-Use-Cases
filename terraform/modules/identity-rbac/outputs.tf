output "network_ops_group_object_id" {
  description = "Object ID of the Network Operators Entra security group."
  value       = azuread_group.network_ops.object_id
}

output "network_operator_role_id" {
  description = "Resource ID of the custom Azure RBAC role definition."
  value       = azurerm_role_definition.network_operator.role_definition_resource_id
}

output "conditional_access_policy_id" {
  description = "CA policy object ID when created; null otherwise."
  value       = try(azuread_conditional_access_policy.mfa_privileged[0].id, null)
}
