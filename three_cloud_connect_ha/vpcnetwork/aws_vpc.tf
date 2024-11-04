# provider "aws" {
#   region = var.aws_region
# }

resource "aws_vpc" "my_aws_vpc" {
  cidr_block = var.aws_vpc.cidr_block

  tags = {
    Name = "${var.aws_vpc.name}-vpc"
  }
}

// Add tag Routetable
data "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.my_aws_vpc.id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}

resource "aws_ec2_tag" "main_route_table_tag" {
  resource_id = data.aws_route_table.main_route_table.id
  key         = "Name"
  value       = "${var.aws_vpc.name}-vpc-routetable"
}

// Create Subnets
resource "aws_subnet" "my_aws_subnets" {
  for_each = { for i in var.aws_subnet_map_list : i.name => i }

  vpc_id            = aws_vpc.my_aws_vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az_name
  tags = {
    Name = "${var.aws_vpc.name}-${each.value.name}"
  }
}

// SecurityGroup
resource "aws_security_group" "multicloud_vpn_sg" {
  name        = "${var.aws_vpc.name}-sg"
  description = "Security group for VPN"
  vpc_id      = aws_vpc.my_aws_vpc.id
  tags = {
    Name = "${var.aws_vpc.name}-sg"
  }
}

// ingressRule
resource "aws_vpc_security_group_ingress_rule" "rule_ingress" {
  for_each = { for i in var.aws_sg_map_list : i.cidr => i }

  security_group_id = aws_security_group.multicloud_vpn_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = each.value.cidr
  description       = each.value.description
}

// egressRule
resource "aws_vpc_security_group_egress_rule" "rule_egress" {
  security_group_id = aws_security_group.multicloud_vpn_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
