# Create VPC Peering connection to each VPC id provided.
resource "aws_vpc_peering_connection" "vpc_peer_conn" {
  count         = length(var.vpc_pcxs)
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = var.vpc_pcxs[count.index].vpc_id
  peer_owner_id = data.aws_caller_identity.current.account_id
  auto_accept   = true
  tags = {
    Name = "pcx-${aws_vpc.main.id}-to-${var.vpc_pcxs[count.index].vpc_id}"
  }
}

# # Generate route table entries for all combinations of private routes and VPC Peering connections.
data "aws_vpc_peering_connection" "vpc_peering_conn_data" {
  count      = length(var.vpc_pcxs)
  id         = aws_vpc_peering_connection.vpc_peer_conn[count.index].id
  depends_on = [aws_vpc_peering_connection.vpc_peer_conn]
}
locals {
  pcx_private_routings = flatten([
    for route_table in values(aws_route_table.private_routes) : [
      for vpc_peering_data in data.aws_vpc_peering_connection.vpc_peering_conn_data : [
        {
          route_table_id   = route_table.id
          vpc_peering_data = vpc_peering_data
        }
      ]
    ]
  ])
  vpc_data = data.aws_vpc_peering_connection.vpc_peering_conn_data
  pcx_reverse_routings = flatten([
    for index in(length(var.vpc_pcxs) > 0 ? range(length(var.vpc_pcxs)) : []) : [
      for route_table_id in(length(local.vpc_data) > 0 ? var.vpc_pcxs[index].peer_route_ids : []) : [
        {
          route_table_id   = route_table_id
          vpc_peering_data = local.vpc_data[index]
        }
      ]
    ]
  ])
}

resource "aws_route" "vpc_peer_route" {
  count                     = length(local.pcx_private_routings)
  route_table_id            = local.pcx_private_routings[count.index].route_table_id
  destination_cidr_block    = local.pcx_private_routings[count.index].vpc_peering_data.peer_cidr_block
  vpc_peering_connection_id = local.pcx_private_routings[count.index].vpc_peering_data.id
  depends_on                = [aws_route_table.private_routes, data.aws_vpc_peering_connection.vpc_peering_conn_data]
}

resource "aws_route" "vpc_peer_def_route" {
  count                     = length(local.pcx_private_routings) > 0 ? 0 : length(data.aws_vpc_peering_connection.vpc_peering_conn_data)
  route_table_id            = aws_vpc.main.main_route_table_id
  destination_cidr_block    = data.aws_vpc_peering_connection.vpc_peering_conn_data[count.index].peer_cidr_block
  vpc_peering_connection_id = data.aws_vpc_peering_connection.vpc_peering_conn_data[count.index].id
  depends_on                = [aws_route_table.private_routes, data.aws_vpc_peering_connection.vpc_peering_conn_data]
}

resource "aws_route" "vpc_peer_reverse_route" {
  count                     = length(local.pcx_reverse_routings)
  route_table_id            = local.pcx_reverse_routings[count.index].route_table_id
  destination_cidr_block    = local.pcx_reverse_routings[count.index].vpc_peering_data.cidr_block
  vpc_peering_connection_id = local.pcx_reverse_routings[count.index].vpc_peering_data.id
  depends_on                = [aws_route_table.private_routes, data.aws_vpc_peering_connection.vpc_peering_conn_data]
}
