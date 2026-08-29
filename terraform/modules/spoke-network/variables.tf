variable "name" {
  description = "Virtual network name. Prefer {env}-{region}-{role}-vnet."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{3,64}$", var.name))
    error_message = "Use lowercase letters, numbers, and hyphens (3-64 chars)."
  }
}

variable "location" {
  description = "Azure region for the VNet and NSGs."
  type        = string
}

variable "resource_group_name" {
  description = "Existing resource group that owns this VNet."
  type        = string
}

variable "address_space" {
  description = "VNet CIDR list. Must not overlap on-prem or other spokes."
  type        = list(string)
}

variable "dns_servers" {
  description = "Custom DNS (on-prem AD / Azure DNS private resolver). Empty = Azure-provided DNS."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Map of subnet key => address prefixes and optional NSG mode."
  type = map(object({
    address_prefixes  = list(string)
    nsg_profile       = optional(string, "app")
    create_nsg        = optional(bool, true)
    service_endpoints = optional(list(string), [])
  }))
}

variable "tags" {
  description = "Cost and ownership tags. Do not store secrets here."
  type        = map(string)
  default     = {}
}
