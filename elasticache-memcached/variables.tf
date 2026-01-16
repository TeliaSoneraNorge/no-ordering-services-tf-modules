variable "cluster_security_group_ids" {
  description = "ID of ECS cluster's security group"
  type        = list(string)
}

variable "vpc_id" {
  description = "ID of VPC"
}

variable "private_subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "node_type" {
  description = "Compute size type of node (cache.m4.large). "
}

variable "parameter_group_name" {
  description = "Name of parameter group"
}

variable "cache_prefix" {
  description = "Prefix used for identification."
}

variable "port" {
  description = "The port number on which each of the cache nodes will accept connections."
}

variable "number_cache_nodes" {
  description = "Number of nodes in cache cluster."
}

variable "maintenance_window" {
  description = "Maintenance window timeframe."
  default     = "Tue:02:00-Tue:03:00"
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window."
  default     = false
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}
