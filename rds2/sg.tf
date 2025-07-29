resource "aws_security_group" "main" {
  name        = "${local.identifier}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_custom_subnets" {
  for_each          = var.custom_cidr_blocks
  security_group_id = aws_security_group.main.id

  cidr_ipv4   = each.value
  from_port   = var.database_port
  to_port     = var.database_port
  ip_protocol = "tcp"

  description = "Allow DB port from given CIDR block. See terrafom variables for details."
}

resource "aws_vpc_security_group_ingress_rule" "allow_vpc_subnets" {
  security_group_id = aws_security_group.main.id

  cidr_ipv4   = var.vpc_cidr_block
  from_port   = var.database_port
  to_port     = var.database_port
  ip_protocol = "tcp"
  
  description = "Allow DB port access from within the VPC"
}

resource "aws_vpc_security_group_egress_rule" "rds_egress" {
  security_group_id = aws_security_group.main.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  to_port     = 65535
  ip_protocol = "tcp"
  description = "Allow all outbound traffic"
}