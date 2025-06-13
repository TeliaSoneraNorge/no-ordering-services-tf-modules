resource "aws_security_group" "alb" {
  name        = "${local.identifier}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each          = var.https_source_cidr_blocks
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = each.value
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
  description = "Allow HTTPS from given CIDR block. See terrafom variables for details."
}


resource "aws_vpc_security_group_ingress_rule" "alb_icmp" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = -1
  to_port     = -1
  ip_protocol = "icmp"
  description = "Allow ping from anywhere"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  to_port     = 65535
  ip_protocol = "tcp"
  description = "Allow all outbound traffic"
}