variable "subscription_id" {
  description = "Target subscription. Required by azurerm 4.x."
  type        = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "name_prefix" {
  description = "Short prefix used in resource names ({env}-{region})."
  type        = string
  default     = "lab-eus"
}

variable "alert_email" {
  description = "Mailbox for the lab action group."
  type        = string
}

variable "enable_vpn_gateway" {
  description = "VPN Gateway takes 30-45 minutes and bills while allocated. Leave false unless you need the tunnel."
  type        = bool
  default     = false
}

variable "enable_conditional_access" {
  description = "Create a disabled CA policy. Requires Entra ID P1."
  type        = bool
  default     = false
}

variable "onprem_public_ip" {
  description = "On-prem VPN public IP. Unused unless enable_vpn_gateway is true."
  type        = string
  default     = "203.0.113.10"
}

variable "onprem_address_spaces" {
  description = "On-prem prefixes (treat as VLAN aggregates)."
  type        = list(string)
  default     = ["10.50.0.0/16"]
}

variable "vpn_shared_key" {
  description = "IPsec PSK. Override from a secret store when enable_vpn_gateway is true."
  type        = string
  sensitive   = true
  default     = "ReplaceMe-NotARealKey"
}

variable "break_glass_user_object_ids" {
  type    = list(string)
  default = []
}

variable "tags" {
  type = map(string)
  default = {
    env        = "lab"
    project    = "azure-architect-labs"
    managed-by = "terraform"
  }
}
