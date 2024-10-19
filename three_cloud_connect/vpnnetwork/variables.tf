variable "ike_version" {}
# AWS
variable "aws_vpc" {}
variable "aws_vpc_id" {}
variable "aws_vpc_route_table_id" {}
variable "aws_vpn_cgw_props" {}
# GCP
variable "gcp_network" {}
variable "gcp_vpc_name" {}
variable "gcp_vpc_cidr" {}
variable "gcp_forwarding_rules" {}
variable "gcp_azure_shared_secret" {}
# Azure
variable "Azure" {}
variable "azure_vnet" {}
variable "azure_vnet_name" {}
variable "azure_gateway_subnet_cidr" {}
variable "azure_pip_props" {}
variable "azure_vpn_props" {}
variable "azure_lng_props" {}

