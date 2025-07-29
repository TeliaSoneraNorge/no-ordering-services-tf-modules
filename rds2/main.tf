locals {
  identifier  = join("-", compact(tolist([var.domain, var.environment, var.local_identifier])))
  db_password = var.database_password == "" ? random_password.generated_db_password.result : var.database_password
}

resource "random_password" "generated_db_password" {
  length  = 16
  upper   = true
  lower   = true
  numeric = true
  special = var.password_use_special
}

data "aws_db_snapshot" "manual" {
  count = var.manual_db_snapshot_identifier == "" ? 0 : 1

  most_recent            = true
  snapshot_type          = "manual"
  db_snapshot_identifier = var.manual_db_snapshot_identifier
}

######
# RDS
######

resource "aws_iam_role" "enhanced_monitoring" {
  count = var.create_monitoring_role == true || var.monitoring_interval > 0 ? 1 : 0

  name_prefix        = var.monitoring_role_name
  assume_role_policy = file("${path.module}/policy/enhancedmonitoring.json")
  tags = merge(
    var.tags,
    {
      Purpose = "Role created for enhanced_monitoring"
    }
  )
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = var.create_monitoring_role == true || var.monitoring_interval > 0 ? 1 : 0

  role       = join("", aws_iam_role.enhanced_monitoring.*.name)
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_parameter_group" "custom_parameters" {
  count       = length(var.parameters) == 0 ? 0 : 1
  name_prefix = "${local.identifier}-parameters"
  family      = var.family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = var.tags
}

resource "aws_db_instance" "rds" {
  depends_on                = [aws_db_subnet_group.rds]
  identifier                = "${local.identifier}-db"
  db_name                   = var.database_name
  username                  = var.database_username
  password                  = local.db_password
  port                      = var.database_port
  engine                    = var.engine
  engine_version            = var.engine_version
  option_group_name         = var.option_group_name
  parameter_group_name      = length(var.parameters) == 0 ? "" : aws_db_parameter_group.custom_parameters[0].id
  instance_class            = var.instance_class
  storage_type              = "gp3"
  allocated_storage         = var.allocated_storage
  snapshot_identifier       = join("", data.aws_db_snapshot.manual.*.db_snapshot_arn)
  final_snapshot_identifier = "${local.identifier}-final"
  skip_final_snapshot       = true
  publicly_accessible       = false
  vpc_security_group_ids    = [aws_security_group.main.id]
  multi_az                  = var.multi_az
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  monitoring_interval       = var.monitoring_interval
  monitoring_role_arn       = var.create_monitoring_role == true || var.monitoring_interval > 0 ? join("", aws_iam_role.enhanced_monitoring.*.arn) : ""
  license_model             = var.license_model
  storage_encrypted         = var.storage_encrypted
  kms_key_id                = var.kms_key_id
  deletion_protection       = var.deletion_protection
  ca_cert_identifier        = var.ca_cert_identifier

  apply_immediately = var.apply_immediately

  # New params
  domain                                = var.domain
  allow_major_version_upgrade           = false
  auto_minor_version_upgrade            = true
  copy_tags_to_snapshot                 = var.copy_tags_to_snapshot
  max_allocated_storage                 = var.max_allocated_storage
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled == true ? var.performance_insights_retention_period : null
  delete_automated_backups              = false

  # NOTE: This is duplicated because subnet_group does not return the name.
  db_subnet_group_name = "${local.identifier}-subnet-group"

  tags = merge(var.tags, { "Name" = "${local.identifier}-db" })
}

resource "aws_db_subnet_group" "rds" {
  name        = "${local.identifier}-subnet-group"
  description = "Subnet group for ${local.identifier} RDS instance"
  subnet_ids  = var.database_subnets

  tags = merge(var.tags, { "Name" = "${local.identifier}-subnet-group" })
}