//--- AWSとAzureのVPN接続 ---
# AWS
// 仮想プライベートゲートウェイの設定
resource "aws_vpn_gateway" "azure_cmk_vgw" {
  vpc_id = var.aws_vpc_id
  tags = {
    Name = "${var.aws_vpc.name}-azure-vgw"
  }
}

// 仮想プライベートゲートウェイのルート伝播の設定
resource "aws_vpn_gateway_route_propagation" "azure_cmk_vgw_rp" {
  vpn_gateway_id = aws_vpn_gateway.azure_cmk_vgw.id
  route_table_id = var.aws_vpc_route_table_id
}

// カスタマーゲートウェイの設定
resource "aws_customer_gateway" "azure_cmk_cgw" {
  bgp_asn    = var.aws_vpn_cgw_props.bgp_asn
  ip_address = data.azurerm_public_ip.pip-vgw.ip_address
  type       = var.aws_vpn_cgw_props.type

  tags = {
    Name = "${var.aws_vpc.name}-azure-cgw"
  }
}

// サイト間のVPN接続の設定
resource "aws_vpn_connection" "azure_cmk_vpnc" {
  vpn_gateway_id      = aws_vpn_gateway.azure_cmk_vgw.id
  customer_gateway_id = aws_customer_gateway.azure_cmk_cgw.id
  type                = var.aws_vpn_cgw_props.type
  static_routes_only  = true
  tags = {
    Name = "${var.aws_vpc.name}-azure-vpn-connection"
  }
}

// Azure側へのルート設定
resource "aws_vpn_connection_route" "gazure_route" {
  destination_cidr_block = var.azure_subnet_cidr
  vpn_connection_id      = aws_vpn_connection.azure_cmk_vpnc.id
}


# Azure
// GatewaySubnet作成
resource "azurerm_subnet" "azure_gatewaySubnet" {
  resource_group_name  = var.Azure.resource_group
  virtual_network_name = var.azure_vnet_name
  name                 = "GatewaySubnet"
  address_prefixes     = [var.azure_gateway_subnet_cidr]
}

// PublicIP取得
resource "azurerm_public_ip" "aws_azure_gw_public_ip" {
  name                = "${var.azure_vnet.name}-aws-pip"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location
  allocation_method   = var.azure_pip_props.alloc
}

// VPNGateway作成
resource "azurerm_virtual_network_gateway" "aws_azure_vng" {
  name                = "${var.azure_vnet.name}-aws-vng"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location

  type     = var.azure_vpn_props.type
  vpn_type = var.azure_vpn_props.vpn_type

  active_active = false
  enable_bgp    = false
  sku           = var.azure_vpn_props.sku

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.aws_azure_gw_public_ip.id
    private_ip_address_allocation = var.azure_vpn_props.pipalloc
    subnet_id                     = azurerm_subnet.azure_gatewaySubnet.id
  }
}
// https://qiita.com/hidekko/items/374e65d30a726c87899c#aws_customer_gatewaytf
data "azurerm_public_ip" "pip-vgw" {
  name                = azurerm_public_ip.aws_azure_gw_public_ip.name
  resource_group_name = var.Azure.resource_group
  depends_on = [
    azurerm_virtual_network_gateway.aws_azure_vng
  ]
}

//　localGatewayとトンネル作成
locals {
  vpn_tunnels = {
    tunnel1 = {
      address    = aws_vpn_connection.azure_cmk_vpnc.tunnel1_address
      shared_key = aws_vpn_connection.azure_cmk_vpnc.tunnel1_preshared_key
    },
    tunnel2 = {
      address    = aws_vpn_connection.azure_cmk_vpnc.tunnel2_address
      shared_key = aws_vpn_connection.azure_cmk_vpnc.tunnel2_preshared_key
    }
  }
}

resource "azurerm_local_network_gateway" "aws_local_gateway" {
  for_each            = local.vpn_tunnels
  name                = "${var.azure_vnet.name}-aws-lng-${each.key}"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location
  gateway_address     = each.value.address
  address_space       = [var.aws_vpc.cidr_block]
}

resource "azurerm_virtual_network_gateway_connection" "azure_to_aws" {
  for_each            = local.vpn_tunnels
  name                = "${var.azure_vnet.name}-aws-lng-${each.key}-connection"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location

  type                       = var.azure_lng_props.type
  virtual_network_gateway_id = azurerm_virtual_network_gateway.aws_azure_vng.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws_local_gateway[each.key].id

  shared_key = each.value.shared_key
}
