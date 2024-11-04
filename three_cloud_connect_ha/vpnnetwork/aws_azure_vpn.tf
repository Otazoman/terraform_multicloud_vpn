//--- AWSとAzureのVPN接続 ---
# AWS
// カスタマーゲートウェイの設定
resource "aws_customer_gateway" "azure_cmk_cgws" {
  count      = 2
  bgp_asn    = var.azure_vpn_props.azure_asn
  ip_address = element([data.azurerm_public_ip.pip-vgw["${var.azure_vnet.name}-pip-1"].ip_address, data.azurerm_public_ip.pip-vgw["${var.azure_vnet.name}-pip-2"].ip_address], count.index)
  type       = var.aws_vpn_cgw_props.type

  tags = {
    Name = "${var.aws_vpc.name}-azure-cgw-${count.index + 1}"
  }
  depends_on = [azurerm_virtual_network_gateway.azure_vng]
}

// サイト間のVPN接続の設定
resource "aws_vpn_connection" "azure_cmk_vpncs" {
  count               = 2
  vpn_gateway_id      = aws_vpn_gateway.cmk_vgw.id
  customer_gateway_id = aws_customer_gateway.azure_cmk_cgws[count.index].id
  type                = var.aws_vpn_cgw_props.type
  static_routes_only  = false

  tunnel1_inside_cidr = var.azure_vpn_props["aws_gw_ip${count.index + 1}_cidr1"]
  tunnel2_inside_cidr = var.azure_vpn_props["aws_gw_ip${count.index + 1}_cidr2"]

  tags = {
    Name = "${var.aws_vpc.name}-azure-vpn-connection-${count.index + 1}"
  }
}

# Azure
// localGatewayとトンネル作成
locals {
  vpn_tunnels = {
    tunnel1 = {
      address    = aws_vpn_connection.azure_cmk_vpncs[0].tunnel1_address
      shared_key = aws_vpn_connection.azure_cmk_vpncs[0].tunnel1_preshared_key
      cidrhost   = cidrhost(var.azure_vpn_props.aws_gw_ip1_cidr1, 1)
      asn        = aws_vpn_connection.azure_cmk_vpncs[0].tunnel1_bgp_asn
    },
    tunnel2 = {
      address    = aws_vpn_connection.azure_cmk_vpncs[0].tunnel2_address
      shared_key = aws_vpn_connection.azure_cmk_vpncs[0].tunnel2_preshared_key
      cidrhost   = cidrhost(var.azure_vpn_props.aws_gw_ip1_cidr2, 1)
      asn        = aws_vpn_connection.azure_cmk_vpncs[0].tunnel2_bgp_asn
    },
    tunnel3 = {
      address    = aws_vpn_connection.azure_cmk_vpncs[1].tunnel1_address
      shared_key = aws_vpn_connection.azure_cmk_vpncs[1].tunnel1_preshared_key
      cidrhost   = cidrhost(var.azure_vpn_props.aws_gw_ip2_cidr1, 1)
      asn        = aws_vpn_connection.azure_cmk_vpncs[1].tunnel1_bgp_asn
    },
    tunnel4 = {
      address    = aws_vpn_connection.azure_cmk_vpncs[1].tunnel2_address
      shared_key = aws_vpn_connection.azure_cmk_vpncs[1].tunnel2_preshared_key
      cidrhost   = cidrhost(var.azure_vpn_props.aws_gw_ip2_cidr2, 1)
      asn        = aws_vpn_connection.azure_cmk_vpncs[1].tunnel2_bgp_asn
    }
  }
}

resource "azurerm_local_network_gateway" "aws_local_gateways" {
  for_each            = local.vpn_tunnels
  name                = "${var.azure_vnet.name}-aws-lng-${each.key}"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location
  gateway_address     = each.value.address

  bgp_settings {
    asn                 = each.value.asn
    bgp_peering_address = each.value.cidrhost
  }
  depends_on = [azurerm_virtual_network_gateway.azure_vng]
}

resource "azurerm_virtual_network_gateway_connection" "azure_to_aws" {
  for_each            = local.vpn_tunnels
  name                = "${var.azure_vnet.name}-aws-lng-${each.key}-connection"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location

  type                       = var.azure_lng_props.type
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.azure_vng.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws_local_gateways[each.key].id

  shared_key = each.value.shared_key
}
