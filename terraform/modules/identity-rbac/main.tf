# Well-known Entra directory role template IDs (not tenant-specific).
locals {
  privileged_role_template_ids = [
    "62e90394-69f5-4237-9190-012177145e10", # Global Administrator
    "194ae4cb-b126-40b2-bd5b-6091b380977d", # Security Administrator
    "e8611ab8-c189-46e8-94e1-8229ab1aa571", # Privileged Role Administrator
    "f28a1f50-f6e7-4571-818b-6a12f2af9b32", # SharePoint Administrator (often over-privileged)
  ]
}

resource "azuread_group" "network_ops" {
  display_name     = "${var.display_name_prefix} - Network Operators"
  security_enabled = true
  description      = "Security group for scoped network operations. Assign the custom Azure role to this group, not to users."
}

resource "azurerm_role_definition" "network_operator" {
  name        = "${lower(var.display_name_prefix)}-network-operator"
  scope       = var.assignment_scope
  description = "Operate NSGs, DNS, VPN diagnostics, and Network Watcher without Owner or Contributor."

  permissions {
    actions = [
      "Microsoft.Network/networkSecurityGroups/*",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/dnsZones/*",
      "Microsoft.Network/privateDnsZones/*",
      "Microsoft.Network/virtualNetworkGateways/read",
      "Microsoft.Network/connections/read",
      "Microsoft.Network/networkWatchers/*",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
    ]
    not_actions = []
  }

  assignable_scopes = [var.assignment_scope]
}

resource "azurerm_role_assignment" "network_operator_group" {
  scope              = var.assignment_scope
  role_definition_id = azurerm_role_definition.network_operator.role_definition_resource_id
  principal_id       = azuread_group.network_ops.object_id
}

resource "azurerm_role_assignment" "network_operator_users" {
  for_each = toset(var.network_operator_object_ids)

  scope              = var.assignment_scope
  role_definition_id = azurerm_role_definition.network_operator.role_definition_resource_id
  principal_id       = each.value
}

# Default state is disabled. Enabling this without a break-glass exclusion is a lockout.
resource "azuread_conditional_access_policy" "mfa_privileged" {
  count = var.enable_conditional_access ? 1 : 0

  display_name = "${var.display_name_prefix} - MFA for privileged directory roles"
  state        = "disabled"

  conditions {
    client_app_types = ["all"]

    applications {
      included_applications = ["All"]
    }

    users {
      included_roles = local.privileged_role_template_ids
      excluded_users = var.break_glass_user_object_ids
    }
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}
