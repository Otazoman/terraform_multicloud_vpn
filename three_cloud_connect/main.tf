module "vpc_network" {
  source = "./vpcnetwork"
  # AWS
  aws_region          = var.aws_region
  aws_vpc             = var.aws_vpc
  aws_subnet_map_list = var.aws_subnet_map_list
  aws_sg_map_list     = var.aws_sg_map_list
  # GCP
  googleCloud         = var.googleCloud
  gcp_vpc_name        = var.gcp_vpc_name
  gcp_subnet_map_list = var.gcp_subnet_map_list
  fw_ingress_map_list = var.fw_ingress_map_list
  fw_egress_map_list  = var.fw_egress_map_list
  # Azure
  Azure                 = var.Azure
  azure_vnet            = var.azure_vnet
  azure_subnet_map_list = var.azure_subnet_map_list
  azure_nsg_rules_list  = var.azure_nsg_rules_list
}

module "vpn_network" {
  source      = "./vpnnetwork"
  ike_version = var.ike_version
  # AWS
  aws_vpc                = var.aws_vpc
  aws_vpc_id             = module.vpc_network.aws_vpc_id
  aws_vpc_route_table_id = module.vpc_network.aws_routetable_id
  aws_vpn_cgw_props      = var.aws_vpn_cgw_props
  # Google Cloud
  gcp_network             = var.gcp_network
  gcp_vpc_name            = var.gcp_vpc_name
  gcp_vpc_cidr            = var.gcp_vpc_cidr
  gcp_forwarding_rules    = var.gcp_forwarding_rules
  gcp_azure_shared_secret = var.gcp_azure_shared_secret
  # Azure
  Azure                     = var.Azure
  azure_vnet                = var.azure_vnet
  azure_vnet_name           = var.azure_vnet_name
  azure_gateway_subnet_cidr = var.azure_gateway_subnet_cidr
  azure_pip_props           = var.azure_pip_props
  azure_vpn_props           = var.azure_vpn_props
  azure_lng_props           = var.azure_lng_props
  depends_on                = [module.vpc_network]
}

module "vmcreate" {
  source = "./vmcreate"
  # AWS
  aws_subnet_ids   = module.vpc_network.aws_subnet_ids
  aws_subnet_names = module.vpc_network.aws_subnet_names
  ec2_instance_setting_props = {
    instance_name       = "aws-connection-test"
    instance_ami        = "ami-0b20f552f63953f0e"
    instance_type       = "t3.micro"
    key_name            = "multicloud_test"
    vpc_security_groups = [module.vpc_network.aws_securitygroup_id]
  }
  # Google Cloud
  googleCloud         = var.googleCloud
  gcp_vpc_name        = var.gcp_vpc_name
  gcp_subnet_map_list = var.gcp_subnet_map_list
  gce_setting_props   = var.gce_setting_props
  # Azure
  Azure                       = var.Azure
  azure_vnet                  = var.azure_vnet
  azure_vnet_name             = var.azure_vnet_name
  azure_subnet_map_list       = var.azure_subnet_map_list
  azure_vm_nic_props          = var.azure_vm_nic_props
  azure_ssh_private_key_props = var.azure_ssh_private_key_props
  azurevm_setting_props       = var.azurevm_setting_props
  depends_on                  = [module.vpc_network, module.vpn_network]
}

output "tls_private_key" {
  value     = module.vmcreate.tls_private_key
  sensitive = true
}
