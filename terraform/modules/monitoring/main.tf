resource "azurerm_log_analytics_workspace" "ops" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}

resource "azurerm_monitor_action_group" "ops" {
  name                = "${var.name}-ag"
  resource_group_name = var.resource_group_name
  short_name          = "labops"
  tags                = var.tags

  email_receiver {
    name                    = "ops-mailbox"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg" {
  for_each = var.nsg_ids

  name                       = "${var.name}-${each.key}-diag"
  target_resource_id         = each.value
  log_analytics_workspace_id = azurerm_log_analytics_workspace.ops.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_scheduled_query_rules_alert_v2" "failed_signins" {
  name                 = "${var.name}-failed-signins"
  resource_group_name  = var.resource_group_name
  location             = var.location
  evaluation_frequency = "PT15M"
  window_duration      = "PT15M"
  scopes               = [azurerm_log_analytics_workspace.ops.id]
  severity             = 2
  description          = "Failed Entra sign-ins in a 15-minute window. Wire Entra diagnostics to this workspace before trusting the count."
  enabled              = true
  tags                 = var.tags

  criteria {
    query                   = <<-KQL
      SigninLogs
      | where ResultType != 0
      | summarize FailedCount = count()
    KQL
    time_aggregation_method = "Total"
    metric_measure_column   = "FailedCount"
    threshold               = var.failed_signin_threshold
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.ops.id]
  }
}
