# Create VPC 
resource "aws_vpc" "main" {
  cidr_block                       = var.vpc_cidr
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = var.vpc_assign_ipv6_cidr
  tags                             = merge({ Name = "${var.vpc_name}" }, var.tags, var.vpc_tags)
  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because eks adds bunch of tags
      tags,
    ]
  }
}

# Create Internet Gateway wihing VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge({ Name = "${var.vpc_name}-igw" }, var.tags, var.vpc_tags)
}

# Create Main Routing table and point trafic to Internet Gateway
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags       = merge({ Name = "${var.vpc_name}-public-route" }, var.tags, var.vpc_tags)
  depends_on = [aws_internet_gateway.main]
}
