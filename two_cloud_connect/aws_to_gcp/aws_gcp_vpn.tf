//--- AWSとGCPのVPN接続 ---
# AWS
// 仮想プライベートゲートウェイの設定
resource "aws_vpn_gateway" "gcp_cmk_vgw" {
  vpc_id = var.aws_vpc_id
  tags = {
    Name = "${var.aws_vpc.name}-gcp-vgw"
  }
}

// 仮想プライベートゲートウェイのルート伝播の設定
resource "aws_vpn_gateway_route_propagation" "gcp_cmk_vge_rp" {
  vpn_gateway_id = aws_vpn_gateway.gcp_cmk_vgw.id
  route_table_id = var.aws_vpc_route_table_id
}

// カスタマーゲートウェイの設定
resource "aws_customer_gateway" "gcp_cmk_cgw" {
  bgp_asn    = var.aws_vpn_cgw_props.bgp_asn
  ip_address = google_compute_address.gcp_cmk_vgw_address.address
  type       = var.aws_vpn_cgw_props.type

  tags = {
    Name = "${var.aws_vpc.name}-gcp-cgw"
  }
}

// サイト間のVPN接続の設定
resource "aws_vpn_connection" "gcp_cmk_vpnc" {
  vpn_gateway_id      = aws_vpn_gateway.gcp_cmk_vgw.id
  customer_gateway_id = aws_customer_gateway.gcp_cmk_cgw.id
  type                = var.aws_vpn_cgw_props.type
  static_routes_only  = true
  tags = {
    Name = "${var.aws_vpc.name}-gcp-vpn-connection"
  }
}

# GCP側へのルート設定
resource "aws_vpn_connection_route" "gcp_route" {
  destination_cidr_block = var.gcp_vpc_cidr
  vpn_connection_id      = aws_vpn_connection.gcp_cmk_vpnc.id
}


# Google Cloud
// 外部IPアドレスの設定
resource "google_compute_address" "gcp_cmk_vgw_address" {
  name = "${var.gcp_vpc_name}-aws-vgw-ip"
}

// VPNゲートウェイの設定
resource "google_compute_vpn_gateway" "gcp_cmk_vgw" {
  name    = "${var.gcp_vpc_name}-aws-vgw"
  network = var.gcp_network
}

// 記述が冗長になるのでフォワーディングとトンネルのforeach用設定をここで宣言
locals {
  vpn_gateway_name = google_compute_vpn_gateway.gcp_cmk_vgw.name
  forwarding_rules = {
    esp     = { protocol = "ESP", port = null }
    udp500  = { protocol = "UDP", port = "500" }
    udp4500 = { protocol = "UDP", port = "4500" }
  }
  tunnels = {
    tunnel1 = {
      peer_ip       = aws_vpn_connection.gcp_cmk_vpnc.tunnel1_address
      shared_secret = aws_vpn_connection.gcp_cmk_vpnc.tunnel1_preshared_key
    }
    tunnel2 = {
      peer_ip       = aws_vpn_connection.gcp_cmk_vpnc.tunnel2_address
      shared_secret = aws_vpn_connection.gcp_cmk_vpnc.tunnel2_preshared_key
    }
  }
}

// パケット転送ルールの設定
resource "google_compute_forwarding_rule" "vpn_rules" {
  for_each    = local.forwarding_rules
  name        = "fr-aws-${local.vpn_gateway_name}-${each.key}"
  ip_protocol = each.value.protocol
  port_range  = each.value.port
  ip_address  = google_compute_address.gcp_cmk_vgw_address.address
  target      = google_compute_vpn_gateway.gcp_cmk_vgw.self_link
}

// VPNトンネルの設定
resource "google_compute_vpn_tunnel" "cmk_vpn_tunnels" {
  for_each                = local.tunnels
  name                    = "${var.gcp_vpc_name}-aws-vgw-${each.key}"
  peer_ip                 = each.value.peer_ip
  shared_secret           = each.value.shared_secret
  target_vpn_gateway      = google_compute_vpn_gateway.gcp_cmk_vgw.self_link
  local_traffic_selector  = [var.gcp_vpc_cidr]
  remote_traffic_selector = [var.aws_vpc.cidr_block]
  ike_version             = var.ike_version
  depends_on              = [google_compute_forwarding_rule.vpn_rules]
}
