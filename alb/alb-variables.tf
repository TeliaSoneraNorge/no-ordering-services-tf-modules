

variable "domain_name" {
  description = " Domain name, values is used in the ALB name"
  type        = string
}

variable "environment" {
  description = "Local name of this environment (eg, prod, stage, dev, feature1), value is used in the ALB name"
  type        = string
}

variable "alb_prefix" {
  description = "ALB prefix to append to name (hint: start with '-' or leave empty)"
  type        = string
}

variable "alb_is_internal" {
  description = "Boolean to specify if ALB is internal"
  type        = bool
}

variable "route53_record_prefix" {
  description = "Route53 record prefix (hint: leave empty to use directly the zone name)"
  default     = ""
  type        = string
}

variable "route53_zone_name" {
  description = "Route53 zone name to assign to this ALB"
  type        = string
}


variable "assign_route53_private_zone" {
  description = "Assign Route53 private zone to this ALB"
  type        = string
}

variable "tags" {
  description = "Map of tags to assign to ALB"
  type        = map(string)
  default     = {}
}

# VPC variables

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_private_subnets" {
  description = "List of IDs of private subnets"
  type        = list(string)
}

variable "vpc_public_subnets" {
  description = "List of IDs of public subnets"
  type        = list(string)
  default     = []
}


variable "cidr_blocks" {
  description = "CIDR block list"
  type        = list(string)
}

# S3 log bucket

variable "logs_s3_bucket_id" {
  description = "The name of logs bucket"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
  default     = ""
}

variable "idle_timeout" {
  description = "The number of seconds before the load balancer determines the connection is idle and closes it."
  type        = number
  default     = 150
}

variable "enabled_fixed_rule_is_aws" {
  description = "Enable fixed rule (path based routing) for paths */actuator/aws* and return true in JSON format. Can be used to find if a traffic goes through AWS ALB"
  type        = bool
  default     = false
}

