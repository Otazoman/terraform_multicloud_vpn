output "aws_vpc_id" {
  description = "aws vpc"
  value       = aws_vpc.my_aws_vpc.id
}

output "aws_routetable_id" {
  description = "root propagation"
  value       = data.aws_route_table.main_route_table.id
}


output "aws_subnet_ids" {
  description = "create instance"
  value       = [for subnet in aws_subnet.my_aws_subnets : subnet.id]
}

output "aws_subnet_names" {
  description = "create instance"
  value       = [for subnet in aws_subnet.my_aws_subnets : subnet.tags["Name"]]
}


output "aws_securitygroup_id" {
  description = "attach instance"
  value       = aws_security_group.multicloud_vpn_sg.id
}


output "azure_subnet_names" {
  description = "create instance"
  value       = [for subnet in azurerm_subnet.my_azure_subnets : subnet.name]
}

output "gcp_subnet_names" {
  description = "create instance"
  value       = [for subnet in google_compute_subnetwork.my_gcp_subnets : subnet.name]
}
