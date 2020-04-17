# Create VPC Peering connection to each VPC id provided.
resource "aws_vpc_peering_connection" "vpc_peer_conn" {
  for_each      = toset(var.vpc_pcx_vpc_ids)
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = each.value
  peer_owner_id = data.aws_caller_identity.current.account_id
  auto_accept   = true
  tags = {
    Name = "pcx-${aws_vpc.main.id}-to-${each.value}"
  }
}

# # Generate route table entries for all combinations of private routes and VPC Peering connections.
data "aws_vpc_peering_connection" "vpc_peering_conn_data" {
  for_each   = aws_vpc_peering_connection.vpc_peer_conn
  id         = each.value.id
  depends_on = [aws_vpc_peering_connection.vpc_peer_conn]
}
locals {
  pcx_routings = flatten([
    for route_table in values(aws_route_table.private_routes) : [
      for vpc_peering_data in values(data.aws_vpc_peering_connection.vpc_peering_conn_data) : [
        {
          route_table      = route_table
          vpc_peering_data = vpc_peering_data
        }
      ]
    ]
  ])
}
resource "aws_route" "vpc_peer_route" {
  count                     = length(local.pcx_routings)
  route_table_id            = local.pcx_routings[count.index].route_table.id
  destination_cidr_block    = local.pcx_routings[count.index].vpc_peering_data.peer_cidr_block
  vpc_peering_connection_id = local.pcx_routings[count.index].vpc_peering_data.id
  depends_on                = [aws_route_table.private_routes, data.aws_vpc_peering_connection.vpc_peering_conn_data]
}
