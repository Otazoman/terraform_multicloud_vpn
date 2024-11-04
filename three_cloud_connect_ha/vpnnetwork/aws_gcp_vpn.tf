//--- AWSとGCPのVPN接続 ---
# AWS
// カスタマーゲートウェイの設定
resource "aws_customer_gateway" "gcp_cgw" {
  count      = 2
  bgp_asn    = var.aws_vpn_cgw_props.bgp_google_asn
  ip_address = google_compute_ha_vpn_gateway.gcp_aws_ha_vpn.vpn_interfaces[count.index].ip_address
  type       = var.aws_vpn_cgw_props.type

  tags = {
    Name = "${var.aws_vpc.name}-gcp-cgw-${count.index + 1}"
  }
}

// サイト間のVPN接続の設定
resource "aws_vpn_connection" "gcp_vpn_connection" {
  count               = 2
  vpn_gateway_id      = aws_vpn_gateway.cmk_vgw.id
  customer_gateway_id = aws_customer_gateway.gcp_cgw[count.index].id
  type                = var.aws_vpn_cgw_props.type
  static_routes_only  = false

  tags = {
    Name = "${var.aws_vpc.name}-gcp-vpn-connection-${count.index + 1}"
  }
}


# Google Cloud
// VPNゲートウェイの設定
resource "google_compute_ha_vpn_gateway" "gcp_aws_ha_vpn" {
  name    = "${var.gcp_vpc_name}-aws-ha-vpn"
  network = var.gcp_network
}

// Cloud Routerの設定
resource "google_compute_router" "gcp_aws_router" {
  name    = "${var.gcp_vpc_name}-aws-router"
  network = var.gcp_network
  bgp {
    asn = var.aws_vpn_cgw_props.bgp_google_asn
  }
}

// 外部VPNゲートウェイの設定（AWS側のVGWを表現）
resource "google_compute_external_vpn_gateway" "aws_gateway" {
  name            = "aws-external-gateway"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  interface {
    id         = 0
    ip_address = aws_vpn_connection.gcp_vpn_connection[0].tunnel1_address
  }
  interface {
    id         = 1
    ip_address = aws_vpn_connection.gcp_vpn_connection[0].tunnel2_address
  }
  interface {
    id         = 2
    ip_address = aws_vpn_connection.gcp_vpn_connection[1].tunnel1_address
  }
  interface {
    id         = 3
    ip_address = aws_vpn_connection.gcp_vpn_connection[1].tunnel2_address
  }
}

// VPNトンネルの設定（4つ）
resource "google_compute_vpn_tunnel" "gcp_aws_vpn_tunnels" {
  count                           = 4
  name                            = "${var.gcp_vpc_name}-aws-vpn-tunnel-${count.index + 1}"
  vpn_gateway                     = google_compute_ha_vpn_gateway.gcp_aws_ha_vpn.self_link
  peer_external_gateway           = google_compute_external_vpn_gateway.aws_gateway.self_link
  peer_external_gateway_interface = count.index
  shared_secret                   = aws_vpn_connection.gcp_vpn_connection[floor(count.index / 2)]["tunnel${count.index % 2 + 1}_preshared_key"]
  router                          = google_compute_router.gcp_aws_router.name
  vpn_gateway_interface           = floor(count.index / 2)
}

// BGPピアの設定（4つ）
resource "google_compute_router_interface" "gcp_aws_router_interface" {
  count      = 4
  name       = "gcp-aws-router-interface-${count.index + 1}"
  router     = google_compute_router.gcp_aws_router.name
  ip_range   = aws_vpn_connection.gcp_vpn_connection[floor(count.index / 2)]["tunnel${count.index % 2 + 1}_inside_cidr"]
  vpn_tunnel = google_compute_vpn_tunnel.gcp_aws_vpn_tunnels[count.index].name
}
resource "google_compute_router_peer" "gcp_aws_router_peer" {
  count                     = 4
  name                      = "gcp-aws-router-peer-${count.index + 1}"
  router                    = google_compute_router.gcp_aws_router.name
  ip_address                = cidrhost("${aws_vpn_connection.gcp_vpn_connection[floor(count.index / 2)]["tunnel${count.index % 2 + 1}_vgw_inside_address"]}/30", 3)
  peer_ip_address           = aws_vpn_connection.gcp_vpn_connection[floor(count.index / 2)]["tunnel${count.index % 2 + 1}_vgw_inside_address"]
  peer_asn                  = aws_vpn_gateway.cmk_vgw.amazon_side_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.gcp_aws_router_interface[count.index].name
}
