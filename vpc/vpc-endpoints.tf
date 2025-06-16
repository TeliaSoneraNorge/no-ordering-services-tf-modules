data "aws_region" "current" {}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssm_vpc_endpoint_sg.id,
  ]

  subnet_ids = values(aws_subnet.private)[*].id

  private_dns_enabled = true

  tags = {
    Purpose = "SSM VPC endpoint forces traffic to SSM services going over internal AWS network"
  }
}

resource "aws_security_group" "ssm_vpc_endpoint_sg" {
  name        = "ssm_vpc_endpoint_sg"
  description = "Security group intended for SSM VPC endpoint"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}