resource "azurerm_resource_group" "lab" {
  name     = "rg-${var.name_prefix}-architect"
  location = var.location
  tags     = var.tags
}

module "hub" {
  source = "../modules/spoke-network"

  name                = "${var.name_prefix}-hub-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.lab.name
  address_space       = ["10.10.0.0/16"]
  tags                = var.tags

  # Custom DNS empty = Azure-provided. In hybrid, point this at AD DS or a DNS private resolver.
  dns_servers = []

  subnets = {
    GatewaySubnet = {
      address_prefixes = ["10.10.0.0/27"]
      nsg_profile      = "gateway"
      create_nsg       = false
    }
    identity = {
      address_prefixes = ["10.10.2.0/24"]
      nsg_profile      = "identity"
    }
    shared = {
      address_prefixes = ["10.10.1.0/24"]
      nsg_profile      = "app"
    }
  }
}

module "identity" {
  source = "../modules/identity-rbac"

  display_name_prefix         = "LAB"
  assignment_scope            = azurerm_resource_group.lab.id
  enable_conditional_access   = var.enable_conditional_access
  break_glass_user_object_ids = var.break_glass_user_object_ids
}

module "monitor" {
  source = "../modules/monitoring"

  name                = "${var.name_prefix}-law"
  location            = var.location
  resource_group_name = azurerm_resource_group.lab.name
  alert_email         = var.alert_email
  nsg_ids             = module.hub.nsg_ids
  tags                = var.tags
}

module "vpn" {
  count  = var.enable_vpn_gateway ? 1 : 0
  source = "../modules/hybrid-gateway"

  name                  = "${var.name_prefix}-hub-vng"
  location              = var.location
  resource_group_name   = azurerm_resource_group.lab.name
  gateway_subnet_id     = module.hub.subnet_ids["GatewaySubnet"]
  onprem_public_ip      = var.onprem_public_ip
  onprem_address_spaces = var.onprem_address_spaces
  shared_key            = var.vpn_shared_key
  tags                  = var.tags
}

resource "azurerm_private_dns_zone" "internal" {
  name                = "internal.lab.example"
  resource_group_name = azurerm_resource_group.lab.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  name                  = "${var.name_prefix}-hub-pdns-link"
  resource_group_name   = azurerm_resource_group.lab.name
  private_dns_zone_name = azurerm_private_dns_zone.internal.name
  virtual_network_id    = module.hub.vnet_id
  registration_enabled  = true
  tags                  = var.tags
}
