resource "random_string" "password" {
  length  = 20
  special = false
}

resource "aws_ssm_parameter" "secret" {
  name  = "/${var.env}/${var.component_id}/redis/auth/token"
  type  = "SecureString"
  value = random_string.password.result
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_elasticache_replication_group" "redis" {
  depends_on                 = [aws_security_group.redis]
  automatic_failover_enabled = var.automatic_failover_enabled
  replication_group_id       = var.replication_group_id
  description                = var.description
  engine                     = "redis"
  engine_version             = var.engine_version
  node_type                  = var.node_type
  num_cache_clusters         = var.num_cache_clusters
  parameter_group_name       = var.parameter_group_name
  port                       = var.port
  security_group_ids         = [aws_security_group.redis.id]
  subnet_group_name          = aws_elasticache_subnet_group.subnet_group.name
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = aws_ssm_parameter.secret.value
  tags                       = var.tags
}

resource "aws_security_group" "redis" {
  name        = "${var.env}_${var.component_id}_cache_cluster_sg"
  description = "${var.env} ${var.component_id} cache Redis cluster SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "TCP"
    security_groups = var.cluster_security_group_ids
    cidr_blocks     = var.custom_cidr_blocks
  }
  tags = var.tags
}

resource "aws_elasticache_subnet_group" "subnet_group" {
  name       = var.subnet_group_name
  subnet_ids = var.private_subnet_ids
}

