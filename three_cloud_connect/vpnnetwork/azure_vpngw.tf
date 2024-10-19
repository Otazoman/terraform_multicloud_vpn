# Azure GatewaySubNetは1V-NETに1つ、同じくVPNGatewayも1つのみ

// GatewaySubnet作成
resource "azurerm_subnet" "azure_gatewaySubnet" {
  resource_group_name  = var.Azure.resource_group
  virtual_network_name = var.azure_vnet_name
  name                 = "GatewaySubnet"
  address_prefixes     = [var.azure_gateway_subnet_cidr]
}

// PublicIP取得
locals {
  public_ip_names = ["${var.azure_vnet.name}-pip-1", "${var.azure_vnet.name}-pip-2"]
}

resource "azurerm_public_ip" "azure_gw_public_ips" {
  for_each            = toset(local.public_ip_names)
  name                = each.key
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location
  allocation_method   = var.azure_pip_props.alloc
}

resource "azurerm_virtual_network_gateway" "azure_vng" {
  name                = "${var.azure_vnet.name}-vng"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location

  type     = var.azure_vpn_props.type
  vpn_type = var.azure_vpn_props.vpn_type

  active_active = true
  sku           = var.azure_vpn_props.sku

  ip_configuration {
    name                          = "vnetGatewayConfig-1"
    public_ip_address_id          = azurerm_public_ip.azure_gw_public_ips["${var.azure_vnet.name}-pip-1"].id
    private_ip_address_allocation = var.azure_vpn_props.pipalloc
    subnet_id                     = azurerm_subnet.azure_gatewaySubnet.id
  }

  ip_configuration {
    name                          = "vnetGatewayConfig-2"
    public_ip_address_id          = azurerm_public_ip.azure_gw_public_ips["${var.azure_vnet.name}-pip-2"].id
    private_ip_address_allocation = var.azure_vpn_props.pipalloc
    subnet_id                     = azurerm_subnet.azure_gatewaySubnet.id
  }
}

data "azurerm_public_ip" "pip-vgw" {
  for_each            = toset(local.public_ip_names)
  name                = each.key
  resource_group_name = var.Azure.resource_group
  depends_on = [
    azurerm_virtual_network_gateway.azure_vng
  ]
}

