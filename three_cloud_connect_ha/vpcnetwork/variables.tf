# AWS
variable "aws_region" {}
variable "aws_vpc" {}
// Subnets list
variable "aws_subnet_map_list" {}
variable "aws_sg_map_list" {}

# GCP
variable "googleCloud" {}
variable "gcp_vpc_name" {}
// Subnets list
variable "gcp_subnet_map_list" {}
variable "fw_ingress_map_list" {}
variable "fw_egress_map_list" {}

# Azure
variable "Azure" {}
variable "azure_vnet" {}
// Subnets list
variable "azure_subnet_map_list" {}
variable "azure_nsg_rules_list" {}
