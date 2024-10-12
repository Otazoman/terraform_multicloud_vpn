# AWS
variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}
variable "aws_vpc" {
  default = {
    name       = "YOURVPCNAME"
    cidr_block = "YOURVPCCIDR"
  }
}
variable "aws_vpc_id" {
  default = "vpc-XXXXXX"
}
variable "aws_vpc_route_table_id" {
  default = "rtb-XXXX"
}
variable "aws_vpn_cgw_props" {
  default = {
    bgp_asn = 65000
    type    = "ipsec.1"
  }
}

# Azure
variable "Azure" {
  default = {
    resource_group = "YOURRESOURCEGROUPNAME"
    location       = "japaneast"
  }
}

variable "azure_vnet" {
  default = {
    name       = "YOURVNETNAME"
    cidr_block = "YOURVNETCIDR"
  }
}

variable "azure_vnet_name" {
  default = "YOURVNETNAME"
}

variable "azure_subnet_cidr" {
  default = "YOURSUBNET1CIDR"
}

variable "azure_gateway_subnet_cidr" {
  default = "YOURGETWAYSUBNETCIDR"
}

variable "azure_pip_props" {
  default = {
    alloc = "Static"
  }
}

variable "azure_vpn_props" {
  default = {
    type     = "Vpn"
    vpn_type = "RouteBased"
    sku      = "VpnGw1"
    pipalloc = "Dynamic"
  }
}

variable "azure_lng_props" {
  default = {
    type = "IPsec"
  }
}
