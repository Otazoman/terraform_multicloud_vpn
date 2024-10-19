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
  gcp_azure_forwarding_rules = var.gcp_forwarding_rules
  gcp_azure_tunnels = {
    gcp-azure-tunnel1 = {
      peer_ip       = data.azurerm_public_ip.pip-vgw["${var.azure_vnet.name}-pip-1"].ip_address
      shared_secret = var.gcp_azure_shared_secret
    },
    gcp-azure-tunnel2 = {
      peer_ip       = data.azurerm_public_ip.pip-vgw["${var.azure_vnet.name}-pip-2"].ip_address
      shared_secret = var.gcp_azure_shared_secret
    }
  }
}

// パケット転送ルールの設定
resource "google_compute_forwarding_rule" "gcp_azure_vpn_rule" {
  for_each    = local.gcp_azure_forwarding_rules
  name        = "fr-azure-${local.gcp_azure_vpn_gateway_name}-${each.key}-1"
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
  depends_on              = [google_compute_forwarding_rule.gcp_azure_vpn_rule]
}

// ルートのローカル設定
locals {
  azure_routes = {
    tunnel1 = {
      dest_range = var.azure_vnet.cidr_block
      tunnel     = google_compute_vpn_tunnel.gcp_azure_cmk_vpn_gcp_azure_tunnels["gcp-azure-tunnel1"].self_link
    },
    tunnel2 = {
      dest_range = var.azure_vnet.cidr_block
      tunnel     = google_compute_vpn_tunnel.gcp_azure_cmk_vpn_gcp_azure_tunnels["gcp-azure-tunnel2"].self_link
    }
  }
}

// Azureへのルート設定
resource "google_compute_route" "route_to_azure" {
  for_each            = local.azure_routes
  name                = "${var.gcp_vpc_name}-route-to-azure-${each.key}"
  network             = var.gcp_network
  dest_range          = each.value.dest_range
  next_hop_vpn_tunnel = each.value.tunnel
}


# Azure
// localGatewayとトンネル作成
locals {
  azure_gcp_vpn_gcp_azure_tunnels = {
    gcp_azure_tunnel1 = {
      address    = google_compute_address.gcp_azure_cmk_vgw_address.address
      shared_key = var.gcp_azure_shared_secret
    },
    gcp_azure_tunnel2 = {
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
  virtual_network_gateway_id = azurerm_virtual_network_gateway.azure_vng.id
  local_network_gateway_id   = azurerm_local_network_gateway.gcp_local_gateway[each.key].id

  shared_key = each.value.shared_key
}
