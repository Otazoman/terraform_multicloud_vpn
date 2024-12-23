resource "aws_instance" "ec2_connection_test" {
  count                  = length(var.aws_subnet_ids)
  ami                    = var.ec2_instance_setting_props.instance_ami
  instance_type          = var.ec2_instance_setting_props.instance_type
  key_name               = var.ec2_instance_setting_props.key_name
  subnet_id              = var.aws_subnet_ids[count.index]
  vpc_security_group_ids = var.ec2_instance_setting_props.vpc_security_groups

  tags = {
    Name = "${var.ec2_instance_setting_props.instance_name}-${var.aws_subnet_names[count.index]}"
  }
}
