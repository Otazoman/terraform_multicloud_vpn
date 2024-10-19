//--- AWSとAzureのVPN接続 ---
# AWS
// カスタマーゲートウェイの設定
resource "aws_customer_gateway" "azure_cmk_cgws" {
  count      = 2
  bgp_asn    = var.aws_vpn_cgw_props.bgp_asn
  ip_address = element([data.azurerm_public_ip.pip-vgw["${var.azure_vnet.name}-pip-1"].ip_address, data.azurerm_public_ip.pip-vgw["${var.azure_vnet.name}-pip-2"].ip_address], count.index)
  type       = var.aws_vpn_cgw_props.type

  tags = {
    Name = "${var.aws_vpc.name}-azure-cgw-${count.index + 1}"
  }
}

// サイト間のVPN接続の設定
resource "aws_vpn_connection" "azure_cmk_vpncs" {
  count               = 2
  vpn_gateway_id      = aws_vpn_gateway.cmk_vgw.id
  customer_gateway_id = aws_customer_gateway.azure_cmk_cgws[count.index].id
  type                = var.aws_vpn_cgw_props.type
  static_routes_only  = true

  tags = {
    Name = "${var.aws_vpc.name}-azure-vpn-connection-${count.index + 1}"
  }
}

// Azure側へのルート設定
resource "aws_vpn_connection_route" "azure_route" {
  count                  = 2
  destination_cidr_block = var.azure_vnet.cidr_block
  vpn_connection_id      = aws_vpn_connection.azure_cmk_vpncs[count.index].id
}

// localGatewayとトンネル作成
locals {
  vpn_tunnels = {
    tunnel1 = {
      address    = aws_vpn_connection.azure_cmk_vpncs[0].tunnel1_address
      shared_key = aws_vpn_connection.azure_cmk_vpncs[0].tunnel1_preshared_key
    },
    tunnel2 = {
      address    = aws_vpn_connection.azure_cmk_vpncs[1].tunnel2_address
      shared_key = aws_vpn_connection.azure_cmk_vpncs[1].tunnel2_preshared_key
    }
  }
}

resource "azurerm_local_network_gateway" "aws_local_gateways" {
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
  virtual_network_gateway_id = azurerm_virtual_network_gateway.azure_vng.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws_local_gateways[each.key].id

  shared_key = each.value.shared_key
}
