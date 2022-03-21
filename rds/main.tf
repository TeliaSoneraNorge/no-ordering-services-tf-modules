locals {
  identifier  = join("-", compact(tolist([var.domain, var.environment, var.local_identifier])))
  db_password = var.database_password == "" ? random_password.generated_db_password.result : var.database_password
}

resource "random_password" "generated_db_password" {
  length  = 16
  upper   = true
  lower   = true
  number  = true
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

module "rds" {
  source  = "telia-oss/rds-instance/aws"
  version = "4.1.0"

  name_prefix           = local.identifier
  tags                  = var.tags
  multi_az              = var.multi_az
  engine                = var.engine
  engine_version        = var.engine_version
  instance_type         = var.instance_class
  database_name         = var.database_name
  username              = var.database_username
  password              = local.db_password
  port                  = var.database_port
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  snapshot_identifier   = join("", data.aws_db_snapshot.manual.*.db_snapshot_arn)
  parameter_group_name  = length(var.parameters) == 0 ? "" : aws_db_parameter_group.custom_parameters[0].id
  option_group_name       = var.option_group_name
  monitoring_interval      = var.monitoring_interval
  monitoring_role_arn      = var.create_monitoring_role == true || var.monitoring_interval > 0 ? join("", aws_iam_role.enhanced_monitoring.*.arn) : ""
  license_model            = var.license_model
  maintenance_window       = var.maintenance_window
  backup_window            = var.backup_window
  backup_retention_period  = var.backup_retention_period
  vpc_id                   = var.vpc_id
  subnet_ids               = var.database_subnets
  storage_encrypted        = var.storage_encrypted
  kms_key_id               = var.kms_key_id
  apply_immediately        = var.apply_immediately
  delete_automated_backups = false
  deletion_protection      = var.deletion_protection
}

resource "aws_security_group_rule" "allow_vpc_subnets" {
  type        = "ingress"
  from_port   = var.database_port
  to_port     = var.database_port
  protocol    = "tcp"
  cidr_blocks = [var.vpc_cidr_block]

  security_group_id = module.rds.security_group_id
}

resource "aws_security_group_rule" "allow_custom_subnets" {
  for_each          = length(var.custom_cidr_blocks) > 0 ? toset(["custom"]) : toset([])
  type              = "ingress"
  from_port         = var.database_port
  to_port           = var.database_port
  protocol          = "tcp"
  cidr_blocks       = var.custom_cidr_blocks
  security_group_id = module.rds.security_group_id
}

######
# SSM
######
resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.environment}/${local.identifier}/${var.database_name}/db/url"
  value = module.rds.endpoint
  type  = "String"
  tags  = var.tags
}

resource "aws_ssm_parameter" "database_username" {
  name  = "/${var.environment}/${local.identifier}/${var.database_name}/db/username"
  value = var.database_username
  type  = "String"
  tags  = var.tags
}

resource "aws_ssm_parameter" "database_password" {
  name  = "/${var.environment}/${local.identifier}/${var.database_name}/db/password"
  value = local.db_password
  type  = "SecureString"
  tags  = var.tags

  lifecycle {
    ignore_changes = [value]
  }

}

