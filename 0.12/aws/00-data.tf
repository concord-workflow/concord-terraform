# These are shared data resources that several of the modules need

data "aws_vpc" "selected" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnet_ids" "selected" {
  vpc_id = data.aws_vpc.selected.id
}

data "aws_subnet_ids" "selected_public_subnets" {
  vpc_id = data.aws_vpc.selected.id

  filter {
    name   = "map-public-ip-on-launch"
    values = [true]
  }
}

data "aws_security_groups" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  # We want to retrieve the default security group only. This prevents picking
  # up security groups that may be too restrictive for our tests to run
  filter {
    name   = "group-name"
    values = [var.security_group_name_filter]
  }
}
