variable "ike_version" {
  default = 2
}

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


# Google Cloud
variable "googleCloud" {
  default = {
    project         = "YOURPROJECTNAME"
    credentials     = "YOURSERVICEACCOUNT_CREDENTIAL_PATH"
    service_account = "YOURSERVICE@PROJECTNAME.iam.gserviceaccount.com"
    region          = "asia-northeast1"
  }
}
variable "gcp_network" {
  default = "YOURGCPVPC"
}
variable "gcp_vpc_name" {
  type    = string
  default = "YOURGCPVPCNAME"
}
variable "gcp_vpc_cidr" {
  default = "YOURGCPVPCCIDR"
}
