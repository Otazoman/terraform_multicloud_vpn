# provider "azurerm" {
#   features {}
# }

resource "azurerm_virtual_network" "my_azure_vnet" {
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location
  name                = "${var.azure_vnet.name}-vnet"
  address_space       = [var.azure_vnet.cidr_block]
}

# Private subnet
resource "azurerm_subnet" "my_azure_subnets" {
  for_each = { for i in var.azure_subnet_map_list : i.name => i }

  resource_group_name  = var.Azure.resource_group
  virtual_network_name = azurerm_virtual_network.my_azure_vnet.name
  name                 = "${var.azure_vnet.name}-${each.value.name}"
  address_prefixes     = [each.value.cidr]
}

# Network security group
resource "azurerm_network_security_group" "multicloud_vpn_nsg" {
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location
  name                = "${var.azure_vnet.name}-nsg"
}

# Rules
resource "azurerm_network_security_rule" "multicloud_vpn_nsg_rules" {
  for_each = { for i in var.azure_nsg_rules_list : i.name => i }

  resource_group_name         = var.Azure.resource_group
  network_security_group_name = azurerm_network_security_group.multicloud_vpn_nsg.name
  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
}

# Connect nsg to subnet
resource "azurerm_subnet_network_security_group_association" "multicloud_vpn_nsg_to_subnet" {
  for_each = { for i in azurerm_subnet.my_azure_subnets : i.name => i }

  subnet_id                 = each.value.id
  network_security_group_id = azurerm_network_security_group.multicloud_vpn_nsg.id
}
