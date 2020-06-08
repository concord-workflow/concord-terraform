resource "aws_launch_template" "main" {
  name          = var.launch_template_name
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.launch_template_instance_type

  iam_instance_profile {
    name = var.launch_template_instance_profile
  }

  credit_specification {
    cpu_credits = var.launch_template_cpu_credits
  }

  # We add the security groups to the network_interfaces and omit the
  # "vpc_security_group_ids" parameter as it causes:
  #
  # https://github.com/terraform-providers/terraform-provider-aws/issues/4570
  #
  # InvalidQueryParameter: Invalid launch template: When a network interface is provided, the security groups must be a part of it
  #
  # This suggestion in the comments fixes the issue:
  # https://github.com/terraform-providers/terraform-provider-aws/issues/4570#issuecomment-456624525
  #
  # The example in the Terraform docs is wrong
  #
  #vpc_security_group_ids = [aws_security_group.main.id]

  key_name               = var.launch_template_keypair
  user_data              = filebase64(var.launch_template_user_data)

  network_interfaces {
    subnet_id                   = element(tolist(data.aws_subnet_ids.selected_public_subnets.ids), 0)  
    associate_public_ip_address = var.launch_template_associate_public_ip
    security_groups             = [aws_security_group.main.id]
    delete_on_termination       = true # not sure why you would ever want this to be false, otherwise the SG won't delete
  }

  monitoring {
    enabled = var.launch_template_monitoring
  }

  ebs_optimized = var.launch_template_ebs_optimized

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.launch_template_volume_size
      volume_type           = var.launch_template_volume_type
      delete_on_termination = var.launch_template_delete_on_termination
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge({Name = var.launch_template_name}, var.launch_template_instance_tags)
  }
}

# For a launch template that might be used with an ASG or compute, it's almost
# always the case you want to create a customized security groups for the set
# of computes that are being created.

resource "aws_security_group" "main" {
  name = var.launch_template_name
  vpc_id = data.aws_vpc.selected.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
