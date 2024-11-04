# AWS Variables
// Common
variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}
variable "aws_vpc" {
  default = {
    name       = "multicloud-vpn-aws"
    cidr_block = "172.20.0.0/16"
  }
}
variable "aws_vpc_name" {
  default = "multicloud-vpn-aws-vpc"
}
// Subnets list
variable "aws_subnet_map_list" {
  type = list(object({
    name    = string
    cidr    = string
    az_name = string
  }))
  default = [
    # {
    #   name    = "public-1a",
    #   cidr    = "172.20.10.0/24",
    #   az_name = "ap-northeast-1a"
    # },
    {
      name    = "private-1a",
      cidr    = "172.20.110.0/24",
      az_name = "ap-northeast-1a"
    },
    # {
    #   name    = "public-1b",
    #   cidr    = "172.20.20.0/24",
    #   az_name = "ap-northeast-1b"
    # },
    # {
    #   name    = "private-1b",
    #   cidr    = "172.20.120.0/24",
    #   az_name = "ap-northeast-1b"
    # },
    # {
    #   name    = "public-1c",
    #   cidr    = "172.20.30.0/24",
    #   az_name = "ap-northeast-1c"
    # },
    {
      name    = "private-1c",
      cidr    = "172.20.130.0/24",
      az_name = "ap-northeast-1c"
    },
  ]
}
// Securitygroup
variable "aws_sg_map_list" {
  type = list(object({
    cidr        = string
    description = string
  }))
  default = [
    {
      cidr        = "172.20.0.0/16",
      description = "aws local"
    },
    {
      cidr        = "172.21.0.0/16",
      description = "from gcp"
    },
    {
      cidr        = "172.22.0.0/16",
      description = "from azure"
    },
  ]
}
// AWS-VPN
variable "aws_vpn_cgw_props" {
  default = {
    bgp_google_asn = 65000
    type           = "ipsec.1"
  }
}

# Google Cloud Variables
// Common
variable "googleCloud" {
  default = {
    project         = "YOURPROJECTNAME"
    credentials     = "YOURSERVICEACCOUNT_CREDENTIAL_PATH"
    service_account = "YOURSERVICE@PROJECTNAME.iam.gserviceaccount.com"
    region          = "asia-northeast1"
  }
}
variable "gcp_vpc_name" {
  default = "multicloud-vpn-gcp"
}
// Subnets list
variable "gcp_subnet_map_list" {
  type = list(object({
    name   = string
    cidr   = string
    region = string
  }))
  default = [
    # {
    #   name   = "public-subnet",
    #   cidr   = "172.21.10.0/24",
    #   region = "asia-northeast1"
    # },
    {
      name   = "private-subnet",
      cidr   = "172.21.110.0/24",
      region = "asia-northeast1"
    },
  ]
}
// firewall
variable "fw_ingress_map_list" {
  type = list(object({
    name          = string
    source_ranges = list(string)
    priority      = number
  }))
  default = [
    {
      name          = "vpn-ingress-aws-allow-rule",
      source_ranges = ["172.20.0.0/16"],
      priority      = 1001
    },
    {
      name          = "vpn-ingress-gcp-allow-rule",
      source_ranges = ["172.21.0.0/16"],
      priority      = 1001
    },
    {
      name          = "vpn-ingress-az-allow-rule",
      source_ranges = ["172.22.0.0/16"],
      priority      = 1001
    },
  ]
}
variable "fw_egress_map_list" {
  type = list(object({
    name               = string
    source_ranges      = list(string)
    destination_ranges = list(string)
    priority           = number
  }))
  default = [
    {
      name               = "vpn-egress-aws-allow-rule",
      source_ranges      = ["172.21.0.0/16"],
      destination_ranges = ["172.20.0.0/16"],
      priority           = 1002
    },
    {
      name               = "vpn-egress-az-allow-rule",
      source_ranges      = ["172.21.0.0/16"],
      destination_ranges = ["172.22.0.0/16"],
      priority           = 1001
    },
  ]
}
// VPN
variable "ike_version" {
  default = 2
}
variable "gcp_network" {
  default = "multicloud-vpn-gcp-vpc"
}
variable "gcp_vpc_cidr" {
  default = "172.21.0.0/16"
}
variable "gcp_azure_shared_secret" {
  default = "test#01"
}
variable "gcp_vpn_setting_props" {
  default = {
    gcp_gw_ip1_cidr1 = "169.254.21.8/30"
    gcp_gw_ip2_cidr1 = "169.254.22.8/30"
  }
}
// GCE
variable "gce_setting_props" {
  default = {
    name         = "multicloud-gcp-instance"
    machine_type = "e2-micro"
    zone         = "asia-northeast1-a"
    tags         = ["multicloud"]
    boot_disk = {
      image       = "projects/ubuntu-os-cloud/global/images/ubuntu-2404-noble-amd64-v20240701a"
      size        = 10
      type        = "pd-standard"
      device_name = "test-instance"
    }
    service_account_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }
}

# Azure Variables
// Common
variable "Azure" {
  default = {
    resource_group = "YOURRESOURCEGROUPNAME"
    location       = "japaneast"
  }
}
// VNET
variable "azure_vnet" {
  default = {
    name       = "multicloud-vpn-azure"
    cidr_block = "172.22.0.0/16"
  }
}
// Subnets list
variable "azure_subnet_map_list" {
  type = list(object({
    name = string
    cidr = string
  }))
  default = [
    # {
    #   name = "public-subnet"
    #   cidr = "172.22.10.0/24"
    # },
    {
      name = "private-subnet"
      cidr = "172.22.110.0/24"
    },
  ]
}
// Network Security Group
variable "azure_nsg_rules_list" {
  type = list(object({
    name                       = string,
    priority                   = number,
    direction                  = string,
    access                     = string,
    protocol                   = string,
    source_port_range          = string,
    destination_port_range     = string,
    source_address_prefix      = string,
    destination_address_prefix = string,
  }))
  default = [
    {
      name                       = "AllowVnetInBound",
      priority                   = 100,
      direction                  = "Inbound",
      access                     = "Allow",
      protocol                   = "*",
      source_port_range          = "*",
      destination_port_range     = "*",
      source_address_prefix      = "VirtualNetwork",
      destination_address_prefix = "VirtualNetwork",
    },
    {
      name                       = "AllowAzureLoadBalancerInBound",
      priority                   = 101
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
    {
      name                       = "DenyAllInBound",
      priority                   = 4096,
      direction                  = "Inbound",
      access                     = "Deny",
      protocol                   = "*",
      source_port_range          = "*",
      destination_port_range     = "*",
      source_address_prefix      = "*",
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowVnetOutBound",
      priority                   = 100,
      direction                  = "Outbound",
      access                     = "Allow",
      protocol                   = "*",
      source_port_range          = "*",
      destination_port_range     = "*",
      source_address_prefix      = "VirtualNetwork",
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowAllOutBound",
      priority                   = 4095,
      direction                  = "Outbound",
      access                     = "Allow",
      protocol                   = "*",
      source_port_range          = "*",
      destination_port_range     = "*",
      source_address_prefix      = "*",
      destination_address_prefix = "*"
    },
    {
      name                       = "DenyAllOutBound",
      priority                   = 4096,
      direction                  = "Outbound",
      access                     = "Deny",
      protocol                   = "*",
      source_port_range          = "*",
      destination_port_range     = "*",
      source_address_prefix      = "*",
      destination_address_prefix = "*"
    }
  ]
}
// VPN
variable "azure_vnet_name" {
  default = "multicloud-vpn-azure-vnet"
}
variable "azure_gateway_subnet_cidr" {
  default = "172.22.255.0/24"
}
variable "azure_pip_props" {
  default = {
    alloc = "Static"
  }
}
variable "azure_vpn_props" {
  default = {
    type             = "Vpn"
    vpn_type         = "RouteBased"
    sku              = "VpnGw1"
    pipalloc         = "Dynamic"
    azure_asn        = 65515
    aws_gw_ip1_cidr1 = "169.254.21.0/30"
    aws_gw_ip1_cidr2 = "169.254.21.4/30"
    aws_gw_ip2_cidr1 = "169.254.22.0/30"
    aws_gw_ip2_cidr2 = "169.254.22.4/30"
  }
}
variable "azure_lng_props" {
  default = {
    type = "IPsec"
  }
}
// Azure VM
variable "azure_vm_nic_props" {
  default = "Dynamic"
}
variable "azure_ssh_private_key_props" {
  default = {
    algorithm = "RSA"
    rsa_bits  = 4096
  }
}
variable "azurevm_setting_props" {
  default = {
    name           = "multicloud-azure-vm"
    size           = "Standard_B1ls"
    admin_username = "azureuser"
    os_disk = {
      caching              = "ReadWrite"
      storage_account_type = "StandardSSD_LRS"
    }
    //https://documentation.ubuntu.com/azure/en/latest/azure-how-to/instances/find-ubuntu-images/
    source_image_reference = {
      publisher = "Canonical"
      offer     = "ubuntu-24_04-lts"
      sku       = "server"
      version   = "latest"
    }
  }
}
