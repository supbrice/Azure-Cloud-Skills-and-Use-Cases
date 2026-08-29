variable "display_name_prefix" {
  description = "Prefix for Entra group and CA policy display names."
  type        = string
  default     = "LAB"
}

variable "assignment_scope" {
  description = "Azure RBAC scope (management group, subscription, or resource group)."
  type        = string
}

variable "network_operator_object_ids" {
  description = "Entra object IDs that receive the custom network-operator role. Empty is valid for a plan-only lab."
  type        = list(string)
  default     = []
}

variable "enable_conditional_access" {
  description = "Create a disabled CA policy. Requires Entra ID P1 and permission to manage CA."
  type        = bool
  default     = false
}

variable "break_glass_user_object_ids" {
  description = "Users excluded from the CA policy. Always exclude at least one break-glass account before enabling."
  type        = list(string)
  default     = []
}
