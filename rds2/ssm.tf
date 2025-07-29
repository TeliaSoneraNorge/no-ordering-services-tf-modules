resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.environment}/${local.identifier}/${var.database_name}/db/url"
  value = aws_db_instance.rds.endpoint
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