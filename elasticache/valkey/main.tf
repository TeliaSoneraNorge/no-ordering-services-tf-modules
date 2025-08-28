resource "random_string" "password" {
  length  = 20
  special = false
  upper   = true
  lower   = true
  numeric = true
}

resource "aws_ssm_parameter" "secret" {
  name  = "/${var.env}/${var.component_id}/valkey/auth/token"
  type  = "SecureString"
  value = random_string.password.result
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_elasticache_replication_group" "valkey" {
  depends_on                 = [aws_security_group.valkey]
  automatic_failover_enabled = var.automatic_failover_enabled
  replication_group_id       = var.replication_group_id
  description                = var.description
  engine                     = "valkey"
  engine_version             = var.engine_version
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_clusters
  parameter_group_name       = var.parameter_group_name
  port                       = var.port
  security_group_ids         = [aws_security_group.valkey.id]
  subnet_group_name          = aws_elasticache_subnet_group.subnet_group.name
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = aws_ssm_parameter.secret.value
  tags                       = var.tags
}

resource "aws_security_group" "valkey" {
  name        = "${var.env}_${var.component_id}_valkey_cache_cluster_sg"
  description = "${var.env} ${var.component_id} cache Valkey cluster SG"
  vpc_id      = var.vpc_id

  # Allow from security groups (e.g., app layer)
  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.cluster_security_group_ids
  }

  # Allow from specific CIDRs (e.g., admin access)
  dynamic "ingress" {
    for_each = length(var.custom_cidr_blocks) > 0 ? [1] : []
    content {
      from_port   = var.port
      to_port     = var.port
      protocol    = "tcp"
      cidr_blocks = var.custom_cidr_blocks
    }
  }

  tags = var.tags
}

resource "aws_elasticache_subnet_group" "subnet_group" {
  name       = var.subnet_group_name
  subnet_ids = var.private_subnet_ids
}