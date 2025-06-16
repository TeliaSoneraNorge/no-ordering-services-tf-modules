resource "aws_ec2_transit_gateway_vpc_attachment" "tga" {
  subnet_ids         = values(aws_subnet.private)[*].id
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.vpc.id

  tags = {
    Name = "transit-gateway-dc"
  }
}
# default route to transit gateway
# the attachment needs to be accepted before the route can be created
resource "aws_route" "tgw_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.tga]
}