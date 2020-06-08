resource "aws_instance" "main" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.ec2_instance_type
  vpc_security_group_ids      = [aws_security_group.main.id]
  # Take the first subnet in the set of public subnets available
  # Seems like you have to specify the subnet_id if you want a non-default vpc, it doesn't inspect the subnet
  # of the security group and try to determine anything
  subnet_id                   = element(tolist(data.aws_subnet_ids.selected_public_subnets.ids), 0)
  key_name                    = var.ec2_keypair
  associate_public_ip_address = var.ec2_instance_public
  user_data                   = fileexists(var.ec2_user_data) ? filebase64(var.ec2_user_data) : ""
  tags                        = merge({ Name = var.ec2_instance_name }, var.tags)
  iam_instance_profile        = var.ec2_instance_profile

  root_block_device {
    volume_type = var.ec2_root_block_device_type
    volume_size = var.ec2_root_block_device_size
    delete_on_termination = var.ec2_root_block_device_delete_on_termination
  }
}

# How to select the subnet_id that the compute should be provisioned in
# - specify a specific subnet_id
# - pick a public subnet?
# - pick a private subnet?
# - how to let it choose decently?

resource "aws_security_group" "main" {
  name = var.ec2_instance_name
  vpc_id = data.aws_vpc.selected.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = var.ec2_ssh_port
    to_port   = var.ec2_ssh_port
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
