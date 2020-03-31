resource "aws_vpc_peering_connection" "vpc_peer_conn" {
  for_each      = toset(var.private_subnet_pcx_vpcs != null ? var.private_subnet_pcx_vpcs : [])
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = each.value
  peer_owner_id = data.aws_caller_identity.current.account_id
  auto_accept   = true
  tags = {
    Name = "pcx-${aws_vpc.main.id}-to-${each.value}"
  }
}

data "aws_vpc_peering_connection" "vpc_peer_conn_data" {
  for_each        = aws_vpc_peering_connection.vpc_peer_conn
  id              = each.value.id
  depends_on = [aws_vpc_peering_connection.vpc_peer_conn]
}
