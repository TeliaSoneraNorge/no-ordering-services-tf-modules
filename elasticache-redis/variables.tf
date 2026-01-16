variable "cluster_security_group_ids" {
  description = "ID of ECS cluster's security group"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of VPC"
  type        = string
}

variable "subnet_group_name" {
  description = "Name of subnet group."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "custom_cidr_blocks" {
  description = "The custom blocks to allow for Redis"
  type        = list(string)
  default     = []
}

variable "replication_group_id" {
  description = "ID of replication group."
  type        = string
}

variable "description" {
  description = "User-created description for the replication group."
  type        = string
}

variable "engine_version" {
  description = "Version of Redis engine"
  type        = string
}

variable "node_type" {
  description = "Type of node"
  type        = string
}

variable "parameter_group_name" {
  description = "Name of parameter group"
  type        = string
}

variable "env" {
  description = "Environment"
  type        = string
}

variable "component_id" {
  description = "Short name of component"
  type        = string
}

variable "port" {
  description = "Port used by Redis cluster"
  type        = string
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (primary and replicas)."
  type        = number
}

variable "automatic_failover_enabled" {
  description = "Specifies whether a read-only replica will be automatically promoted to read/write primary if the existing primary fails"
  type        = bool
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}
