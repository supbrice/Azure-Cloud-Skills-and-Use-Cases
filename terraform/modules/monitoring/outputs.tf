output "workspace_id" {
  description = "Log Analytics workspace resource ID."
  value       = azurerm_log_analytics_workspace.ops.id
}

output "workspace_customer_id" {
  description = "Workspace GUID used by query APIs."
  value       = azurerm_log_analytics_workspace.ops.workspace_id
}

output "action_group_id" {
  value = azurerm_monitor_action_group.ops.id
}

output "failed_signin_alert_id" {
  value = azurerm_monitor_scheduled_query_rules_alert_v2.failed_signins.id
}
