resource "azurerm_public_ip" "gw" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway" "s2s" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.sku
  generation          = "Generation1"
  tags                = var.tags

  ip_configuration {
    name                          = "gwipconfig"
    public_ip_address_id          = azurerm_public_ip.gw.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }
}

resource "azurerm_local_network_gateway" "onprem" {
  name                = "${var.name}-lng"
  location            = var.location
  resource_group_name = var.resource_group_name
  gateway_address     = var.onprem_public_ip
  address_space       = var.onprem_address_spaces
  tags                = var.tags
}

resource "azurerm_virtual_network_gateway_connection" "s2s" {
  name                       = "${var.name}-s2s"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.s2s.id
  local_network_gateway_id   = azurerm_local_network_gateway.onprem.id
  shared_key                 = var.shared_key
  tags                       = var.tags
}
