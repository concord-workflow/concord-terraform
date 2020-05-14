# VPC
output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc" {
  value = aws_vpc.main
}

# Subnets
output "private_subnets" {
  value = local.private_subnets_map
}

output "public_subnets" {
  value = aws_subnet.public
}

# VPC Peering
output "vpc_pcxs" {
  value = aws_vpc_peering_connection.vpc_peer_conn
}

output "vpc_pcxs_routing" {
  value = aws_route.vpc_peer_route
}

output "vpc_pcxs_reverse_routing" {
  value = aws_route.vpc_peer_reverse_route
}

# NAT
output "nat-eips" {
  value = aws_eip.eips
}

output "nat-gw" {
  value = aws_nat_gateway.nat-gateway
}

output "region" {
  value = var.aws_region
}

output "tags" {
  value = var.tags
}
