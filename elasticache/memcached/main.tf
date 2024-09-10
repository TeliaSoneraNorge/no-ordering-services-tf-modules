resource "aws_elasticache_cluster" "memcached" {
  cluster_id           = "${var.cache_prefix}-cache-cluster"
  engine               = "memcached"
  node_type            = var.node_type
  num_cache_nodes      = var.number_cache_nodes
  parameter_group_name = var.parameter_group_name
  port                 = var.port
  security_group_ids   = [aws_security_group.memcached.id]
  subnet_group_name    = aws_elasticache_subnet_group.memcached.name
  apply_immediately    = var.apply_immediately
  maintenance_window   = var.maintenance_window
  tags                 = var.tags
}

resource "aws_security_group" "memcached" {
  name        = "${var.cache_prefix}_cache_cluster_sg"
  description = "${var.cache_prefix} cache cluster SG"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "TCP"
    security_groups = var.cluster_security_group_ids
  }
  tags = var.tags
}

resource "aws_elasticache_subnet_group" "memcached" {
  name       = "${var.cache_prefix}-subnet-group"
  subnet_ids = var.private_subnet_ids
}
