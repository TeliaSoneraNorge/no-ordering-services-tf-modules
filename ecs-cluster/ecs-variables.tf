
variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "log_retention_in_days" {
  description = "Number of days the logs will be retained in CloudWatch."
  default     = 30
  type        = number
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "alb_security_group_ids" {
  description = "The security group IDs of Application Load Balancers"
  type        = list(string)
}

variable "sg_custom_ports" {
  description = "Custom ports that should be accepted in the service SGs"
  type        = list(string)
  default     = []
}


