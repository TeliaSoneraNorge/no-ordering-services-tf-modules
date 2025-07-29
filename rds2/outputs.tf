##############

output "this_db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = module.rds.arn
}

output "this_db_instance_endpoint" {
  description = "The connection endpoint"
  value       = module.rds.endpoint
}

output "this_db_instance_id" {
  description = "The RDS instance ID"
  value       = module.rds.id
}

output "resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = module.rds.resource_id
}

output "this_db_instance_name" {
  description = "The database name"
  value       = module.rds.database_name
}

output "this_db_instance_username" {
  description = "The master username for the database"
  value       = module.rds.username
}

output "this_db_instance_port" {
  description = "The database port"
  value       = module.rds.port
}

output "this_db_parameter_group_id" {
  description = "The db parameter group id"
  value       = join("", aws_db_parameter_group.custom_parameters.*.id)
}

output "this_db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = join("", aws_db_parameter_group.custom_parameters.*.arn)
}

output "this_db_subnet_group_id" {
  description = "The db subnet group name"
  value       = module.rds.subnet_group_id
}

output "this_db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = module.rds.subnet_group_arn
}
