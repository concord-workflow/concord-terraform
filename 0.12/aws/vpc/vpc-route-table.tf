resource "aws_route_table" "private_routes" {
  vpc_id   = aws_vpc.main.id
  for_each = aws_subnet.private
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = lookup(aws_nat_gateway.nat-gateway, each.key).id
  }
  tags = merge({ Name = "${var.vpc_name}-private-${index(var.private_subnet_list, each.value.availability_zone)}-route" }, var.tags)
  depends_on = [aws_subnet.private]
}

locals  {
  pcx_routings = flatten([
    for route_table in values(aws_route_table.private_routes) : [
      for peer_conn in values(data.aws_vpc_peering_connection.vpc_peer_conn_data) : [
        {
          route_table = route_table
          peer_conn   = peer_conn
        }
      ]
    ]
  ])
}

resource "aws_route" "vpc_peer_route" {
  count                     = length(local.pcx_routings)
  route_table_id            = local.pcx_routings[count.index].route_table.id
  destination_cidr_block    = local.pcx_routings[count.index].peer_conn.peer_cidr_block
  vpc_peering_connection_id = local.pcx_routings[count.index].peer_conn.id
  depends_on = [aws_route_table.private_routes, data.aws_vpc_peering_connection.vpc_peer_conn_data]
}

resource "aws_route_table_association" "private_route_association" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = lookup(aws_route_table.private_routes, each.key).id
  depends_on = [aws_route_table.private_routes]
}
