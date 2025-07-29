variable "aws_region" {
  description = "AWS region to use for all resources"
  type        = string
}

variable "domain" {
  description = "Domain name in which the RDS operates"
  type        = string
}

variable "environment" {
  description = "Local name of this environment (eg, prod, stage, dev, feature1)"
  type        = string
}

variable "local_identifier" {
  description = "Identifier of the RDS"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage size"
  type        = string
}

variable "max_allocated_storage" {
  description = "Specifies the value for Storage Autoscaling"
  type        = number
  default     = 0
}

variable "instance_class" {
  description = "DB instance class"
  type        = string
}

variable "engine_version" {
  description = "DB engine version"
  type        = string
}

variable "manual_db_snapshot_identifier" {
  description = "ID of manually created DB snapshot to boot from"
  type        = string
  default     = ""
}

variable "database_name" {
  description = "The database name"
  type        = string
}

variable "database_username" {
  description = "The database username"
  type        = string
}

variable "database_password" {
  description = "The database password"
  type        = string
  default     = ""
}

variable "database_port" {
  description = "The database port"
  type        = string
}

variable "tags" {
  description = "Map of tags to assign to RDS"
  type        = map(string)
  default     = {}
}

variable "multi_az" {
  description = "Specifies if the database should be deployed with standby replica in a different AZ"
  type        = bool
  default     = false
}

variable "maintenance_window" {
  description = "Maintenance window. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'. Eg: 'Mon:00:00-Mon:03:00'"
  default     = "Mon:00:00-Mon:03:00"
  type        = string
}

variable "backup_window" {
  description = "The daily time range (in UTC) during which automated backups are created if they are enabled. Example: '09:46-10:16'. Must not overlap with maintenance_window"
  default     = "03:00-06:00"
  type        = string
}

variable "backup_retention_period" {
  description = "The days to retain backups for"
  default     = 7
  type        = number
}

variable "monitoring_interval" {
  description = "Monitoring interval for RDS modules"
  default     = 0
  type        = number
}

variable "engine" {
  description = "Engine of RDS"
  default     = "postgres"
  type        = string
}

variable "family" {
  description = "DB parameter group"
  default     = "postgres9.6"
  type        = string
}

variable "ingress_rule" {
  description = "Ingress rule to open the ports towards VPC"
  default     = "postgresql-tcp"
  type        = string
}

variable "parameters" {
  description = "List of parameters for RDS parameter group"
  type = list(object({
    name         = string
    value        = string
    apply_method = string
  }))
  default = []
}

variable "license_model" {
  description = "License model information for this DB instance. Optional, but required for some DB engines, i.e. Oracle SE1"
  default     = ""
  type        = string
}

variable "monitoring_role_name" {
  description = "Name of the IAM role which will be created when create_monitoring_role is enabled."
  default     = "rds-monitoring-role"
  type        = string
}

variable "create_monitoring_role" {
  description = "Create IAM role with a defined name that permits RDS to send enhanced monitoring metrics to CloudWatch Logs."
  default     = false
  type        = bool
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted."
  default     = false
  type        = bool
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN."
  type        = string
  default     = ""
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

# VPC related

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "database_subnets" {
  description = "List of IDs of database subnets"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  type        = string
}

variable "custom_cidr_blocks" {
  description = "The custom blocks to allow for RDS"
  type        = set(string)
  default     = []
}

variable "password_use_special" {
  description = "Use special characters in RDS password definition"
  default     = false
}

variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled. The database can't be deleted when this value is set to true."
  type        = bool
  default     = false
}

variable "option_group_name" {
  description = "Name of the DB option group to associate."
  type        = string
  default     = ""
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "The amount of time in days to retain Performance Insights data. Either 7 (7 days) or 731 (2 years)."
  type        = number
  default     = 7
}

variable "create_dashboard" {
  description = "True/False if rds dashboard shall be created"
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "On delete, copy all Instance tags to the final snapshot (if final_snapshot_identifier is specified)"
  type        = bool
  default     = false
}

variable "ca_cert_identifier" {
  description = "Specifies the identifier of the CA certificate for the DB instance."
  type        = string
  default     = "rds-ca-rsa2048-g1"
}
