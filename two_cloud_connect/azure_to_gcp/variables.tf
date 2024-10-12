variable "ike_version" {
  default = 2
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
variable "gcp_azure_shared_secret" {
  default = "SHEAREDSECRET"
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
