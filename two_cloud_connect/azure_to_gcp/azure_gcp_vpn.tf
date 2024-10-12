//--- AzureとGoogle CloudのVPN接続 ---

# Google Cloud
// 外部IPアドレスの設定
resource "google_compute_address" "gcp_azure_cmk_vgw_address" {
  name = "${var.gcp_vpc_name}-azure-vgw-ip"
}

// VPNゲートウェイの設定
resource "google_compute_vpn_gateway" "gcp_azure_cmk_vgw" {
  name    = "${var.gcp_vpc_name}-azure-vgw"
  network = var.gcp_network
}

// フォワーディングとトンネルのforeach用設定
locals {
  gcp_azure_vpn_gateway_name = google_compute_vpn_gateway.gcp_azure_cmk_vgw.name
  gcp_azure_forwarding_rules = {
    esp     = { protocol = "ESP", port = null }
    udp500  = { protocol = "UDP", port = "500" }
    udp4500 = { protocol = "UDP", port = "4500" }
  }
  gcp_azure_tunnels = {
    gcp_azure_tunnel1 = {
      peer_ip       = data.azurerm_public_ip.gcp_azure_pip_vgw.ip_address
      shared_secret = var.gcp_azure_shared_secret
    }
  }
}

// パケット転送ルールの設定
resource "google_compute_forwarding_rule" "gcp_azure_vpn_rules" {
  for_each    = local.gcp_azure_forwarding_rules
  name        = "fr-azure-${local.gcp_azure_vpn_gateway_name}-${each.key}"
  ip_protocol = each.value.protocol
  port_range  = each.value.port
  ip_address  = google_compute_address.gcp_azure_cmk_vgw_address.address
  target      = google_compute_vpn_gateway.gcp_azure_cmk_vgw.self_link
}

// VPNトンネルの設定
resource "google_compute_vpn_tunnel" "gcp_azure_cmk_vpn_gcp_azure_tunnels" {
  for_each                = local.gcp_azure_tunnels
  name                    = "${var.gcp_vpc_name}-azure-vgw-${each.key}"
  peer_ip                 = each.value.peer_ip
  shared_secret           = each.value.shared_secret
  target_vpn_gateway      = google_compute_vpn_gateway.gcp_azure_cmk_vgw.self_link
  local_traffic_selector  = [var.gcp_vpc_cidr]
  remote_traffic_selector = [var.azure_vnet.cidr_block]
  ike_version             = var.ike_version
  depends_on              = [google_compute_forwarding_rule.gcp_azure_vpn_rules]
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
resource "azurerm_public_ip" "gcp_azure_gw_public_ip" {
  name                = "${var.azure_vnet.name}-gcp-pip"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location
  allocation_method   = var.azure_pip_props.alloc
}

// VPNGateway作成
resource "azurerm_virtual_network_gateway" "gcp_azure_vng" {
  name                = "${var.azure_vnet.name}-gcp-vng"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location

  type     = var.azure_vpn_props.type
  vpn_type = var.azure_vpn_props.vpn_type

  active_active = false
  enable_bgp    = false
  sku           = var.azure_vpn_props.sku

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.gcp_azure_gw_public_ip.id
    private_ip_address_allocation = var.azure_vpn_props.pipalloc
    subnet_id                     = azurerm_subnet.azure_gatewaySubnet.id
  }
}
// https://qiita.com/hidekko/items/374e65d30a726c87899c#aws_customer_gatewaytf
data "azurerm_public_ip" "gcp_azure_pip_vgw" {
  name                = azurerm_public_ip.gcp_azure_gw_public_ip.name
  resource_group_name = var.Azure.resource_group
  depends_on = [
    azurerm_virtual_network_gateway.gcp_azure_vng
  ]
}

//　localGatewayとトンネル作成
locals {
  azure_gcp_vpn_gcp_azure_tunnels = {
    gcp_azure_tunnel1 = {
      address    = google_compute_address.gcp_azure_cmk_vgw_address.address
      shared_key = var.gcp_azure_shared_secret
    },
  }
}

resource "azurerm_local_network_gateway" "gcp_local_gateway" {
  for_each            = local.azure_gcp_vpn_gcp_azure_tunnels
  name                = "${var.azure_vnet.name}-gcp-lng-${each.key}"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location
  gateway_address     = each.value.address
  address_space       = [var.gcp_vpc_cidr]
}

resource "azurerm_virtual_network_gateway_connection" "azure_to_gcp" {
  for_each            = local.azure_gcp_vpn_gcp_azure_tunnels
  name                = "${var.azure_vnet.name}-gcp-lng-${each.key}-connection"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location

  type                       = var.azure_lng_props.type
  virtual_network_gateway_id = azurerm_virtual_network_gateway.gcp_azure_vng.id
  local_network_gateway_id   = azurerm_local_network_gateway.gcp_local_gateway[each.key].id

  shared_key = each.value.shared_key
}
