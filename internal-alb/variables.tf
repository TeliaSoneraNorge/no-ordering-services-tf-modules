variable "domain_name" {
  description = " Domain name, values is used in the ALB name"
  type        = string
}

variable "environment" {
  description = "Local name of this environment (eg, prod, stage, dev, feature1), value is used in the ALB name"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "List of IDs of private subnets"
  type        = list(string)
}

variable "route53_zone_name" {
  description = "Route53 zone name in which a record will be created for this ALB"
  type        = string
}

variable "route53_record_prefix" {
  description = "Route53 record prefix (hint: leave empty to use directly the zone name)"
  default     = ""
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the SSL certificate"
  type        = string
}

variable "https_source_cidr_blocks" {
  description = "CIDR block list of allowed sources for HTTPS traffic to the ALB"
  type        = set(string)
}

variable "idle_timeout" {
  description = "The number of seconds before the load balancer determines the connection is idle and closes it."
  type        = number
  default     = 150
}

variable "access_logs_s3_bucket_id" {
  description = "The name of bucket for ALB access logs"
  type        = string
}

variable "access_logs_enabled" {
  description = "Enable ALB access logging to S3 bucket"
  default     = false
  type        = bool
}