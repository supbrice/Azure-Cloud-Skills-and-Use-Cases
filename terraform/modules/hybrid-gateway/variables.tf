variable "name" {
  description = "VPN gateway name."
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "gateway_subnet_id" {
  description = "ID of the subnet named GatewaySubnet. NSGs are not allowed on this subnet."
  type        = string
}

variable "onprem_public_ip" {
  description = "On-premises VPN device public IP. Lab default is documentation-only."
  type        = string
}

variable "onprem_address_spaces" {
  description = "Prefixes advertised from on-prem (VLAN aggregates)."
  type        = list(string)
}

variable "shared_key" {
  description = "IPsec pre-shared key. Pass from a secret store; never commit."
  type        = string
  sensitive   = true
}

variable "sku" {
  description = "VpnGw1 is enough for a lab. VpnGw2+ if you need AZ or higher throughput."
  type        = string
  default     = "VpnGw1"
}

variable "tags" {
  type    = map(string)
  default = {}
}
