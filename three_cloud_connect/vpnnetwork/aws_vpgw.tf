# AWS 仮想プライベートゲートウェイは1VPCに1つのみ
// 仮想プライベートゲートウェイの設定
resource "aws_vpn_gateway" "cmk_vgw" {
  vpc_id = var.aws_vpc_id
  tags = {
    Name = "${var.aws_vpc.name}-vgw"
  }
}

// 仮想プライベートゲートウェイのルート伝播の設定
resource "aws_vpn_gateway_route_propagation" "cmk_vge_rp" {
  vpn_gateway_id = aws_vpn_gateway.cmk_vgw.id
  route_table_id = var.aws_vpc_route_table_id
}
