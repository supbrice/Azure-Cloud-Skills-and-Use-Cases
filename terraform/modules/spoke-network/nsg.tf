locals {
  nsg_profiles = {
    # App subnet: allow intra-VNet, deny raw Internet inbound.
    app = [
      {
        name                       = "allow-vnet-inbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "VirtualNetwork"
        source_port_range          = "*"
        destination_port_range     = "*"
      },
      {
        name                       = "allow-azure-lb"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_address_prefix      = "AzureLoadBalancer"
        destination_address_prefix = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
      },
      {
        name                       = "deny-internet-inbound"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
      }
    ]

    # Identity / management: no inbound from Internet, RDP/SSH only from VNet.
    identity = [
      {
        name                       = "allow-rdp-from-vnet"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
        source_port_range          = "*"
        destination_port_range     = "3389"
      },
      {
        name                       = "allow-ssh-from-vnet"
        priority                   = 110
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_address_prefix      = "VirtualNetwork"
        destination_address_prefix = "*"
        source_port_range          = "*"
        destination_port_range     = "22"
      },
      {
        name                       = "deny-internet-inbound"
        priority                   = 4096
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
      }
    ]

    # GatewaySubnet cannot have an NSG. Profile exists so callers fail closed in locals.
    gateway = []
  }

  subnets_with_nsg = {
    for key, s in var.subnets : key => s
    if s.create_nsg && key != "GatewaySubnet" && s.nsg_profile != "gateway"
  }
}

resource "azurerm_network_security_group" "this" {
  for_each = local.subnets_with_nsg

  name                = "${var.name}-${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = local.nsg_profiles[each.value.nsg_profile]
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = local.subnets_with_nsg

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
