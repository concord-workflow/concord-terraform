# Create public subnet in VPC for each defined Availability Zone
resource "aws_subnet" "public" {
  for_each          = var.vpc_availability_zones
  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = each.value.public_subnet_cidr
  tags              = merge({ Name = "${var.vpc_name}-${each.key}-public" }, var.tags, each.value.tags)
  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because eks adds bunch of tags
      tags,
    ]
  }
  depends_on = [aws_vpc.main, var.vpc_availability_zones]
}

# Associate public subnet with VPC main route table
resource "aws_route_table_association" "public-subnet-to-main" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.main.id
  depends_on     = [aws_route_table.main]
}

# Create EIP's for ech public subnet to assing to NAT Gateway
resource "aws_eip" "eips" {
  for_each   = aws_subnet.public
  vpc        = true
  tags       = merge({ Name = "${var.vpc_name}" }, var.tags, var.vpc_tags)
  depends_on = [aws_internet_gateway.main]
}

# Crate NAT Gateway 
resource "aws_nat_gateway" "nat-gateway" {
  for_each      = aws_eip.eips
  allocation_id = each.value.id
  subnet_id     = lookup(aws_subnet.public, each.key).id
  tags          = merge({ Name = "${var.vpc_name}-${lookup(aws_subnet.public, each.key).availability_zone}-nat" }, var.tags)
  depends_on    = [aws_internet_gateway.main, aws_subnet.public, aws_eip.eips]
}
