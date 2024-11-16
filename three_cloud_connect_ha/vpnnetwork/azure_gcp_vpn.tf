//--- AzureとGoogle CloudのVPN接続 ---
# Google Cloud
// VPNゲートウェイの設定
resource "google_compute_ha_vpn_gateway" "gcp_azure_ha_vpn" {
  name    = "${var.gcp_vpc_name}-azure-ha-vpn"
  network = var.gcp_network
}

// Cloud Routerの設定
resource "google_compute_router" "gcp_azure_router" {
  name    = "${var.gcp_vpc_name}-azure-router"
  network = var.gcp_network
  bgp {
    asn = var.aws_vpn_cgw_props.bgp_google_asn
  }
}

// 外部VPNゲートウェイの設定（Azure側のVGWを表現）
resource "google_compute_external_vpn_gateway" "azure_gateway" {
  name            = "azure-external-gateway"
  redundancy_type = "TWO_IPS_REDUNDANCY"
  interface {
    id         = 0
    ip_address = data.azurerm_public_ip.pip-vgw["${var.azure_vnet.name}-pip-1"].ip_address
  }

  interface {
    id         = 1
    ip_address = data.azurerm_public_ip.pip-vgw["${var.azure_vnet.name}-pip-2"].ip_address
  }
}

// VPNトンネルの設定（2つ）
resource "google_compute_vpn_tunnel" "gcp_azure_vpn_tunnels" {
  count                           = 2
  name                            = "${var.gcp_vpc_name}-azure-vpn-tunnel-${count.index + 1}"
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_azure_ha_vpn.self_link
  peer_external_gateway           = google_compute_external_vpn_gateway.azure_gateway.self_link
  peer_external_gateway_interface = count.index
  shared_secret                   = var.gcp_azure_shared_secret
  router                          = google_compute_router.gcp_azure_router.name
  vpn_gateway_interface           = count.index
}

// BGPピアの設定
resource "google_compute_router_interface" "gcp_azure_interfaces" {
  count      = 2
  name       = "gcp-azure-interface-${count.index + 1}"
  router     = google_compute_router.gcp_azure_router.name
  vpn_tunnel = google_compute_vpn_tunnel.gcp_azure_vpn_tunnels[count.index].name
}
resource "google_compute_router_peer" "gcp_azure_peers" {
  count                     = 2
  name                      = "gcp-azure-peer-${count.index + 1}"
  router                    = google_compute_router.gcp_azure_router.name
  ip_address                = cidrhost(var.gcp_vpn_setting_props["gcp_gw_ip${count.index + 1}_cidr1"], 1)
  peer_ip_address           = cidrhost(var.gcp_vpn_setting_props["gcp_gw_ip${count.index + 1}_cidr1"], 2)
  peer_asn                  = var.azure_vpn_props.azure_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp_azure_interfaces[count.index].name
}


# Azure
// localGatewayとトンネル作成
locals {
  vpn_gcp_azure_tunnels = {
    gcp_azure_tunnel1 = {
      address             = google_compute_ha_vpn_gateway.gcp_azure_ha_vpn.vpn_interfaces[0].ip_address
      bgp_peering_address = cidrhost(var.gcp_vpn_setting_props["gcp_gw_ip1_cidr1"], 1)
      shared_key          = var.gcp_azure_shared_secret
    },
    gcp_azure_tunnel2 = {
      address             = google_compute_ha_vpn_gateway.gcp_azure_ha_vpn.vpn_interfaces[1].ip_address
      bgp_peering_address = cidrhost(var.gcp_vpn_setting_props["gcp_gw_ip2_cidr1"], 1)
      shared_key          = var.gcp_azure_shared_secret
    },
  }
}

resource "azurerm_local_network_gateway" "gcp_local_gateways" {
  for_each            = local.vpn_gcp_azure_tunnels
  name                = "${var.azure_vnet.name}-gcp-lng-${each.key}"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location
  gateway_address     = each.value.address
  address_space       = [var.gcp_vpc_cidr]

  bgp_settings {
    asn                 = var.aws_vpn_cgw_props.bgp_google_asn
    bgp_peering_address = each.value.bgp_peering_address
  }
  depends_on = [azurerm_virtual_network_gateway.azure_vng]
}

// VPN接続の設定
resource "azurerm_virtual_network_gateway_connection" "azure_to_gcp" {
  for_each            = local.vpn_gcp_azure_tunnels
  name                = "${var.azure_vnet.name}-gcp-lng-${each.key}-connection"
  resource_group_name = var.Azure.resource_group
  location            = var.Azure.location

  type                       = var.azure_lng_props.type
  enable_bgp                 = true
  virtual_network_gateway_id = azurerm_virtual_network_gateway.azure_vng.id
  local_network_gateway_id   = azurerm_local_network_gateway.gcp_local_gateways[each.key].id
  shared_key                 = each.value.shared_key
}
