variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}

variable "start_schedule_expression" {
  description = "Start system schedule expression, can be in crontab"
  type        = string
}

variable "stop_schedule_expression" {
  description = "Stop system schedule expression, can be in crontab"
  type        = string
}

variable "route53_record_prefix" {
  description = "Route53 record prefix for API Gateway"
  type        = string
}

variable "route53_domain_name" {
  description = "Route53 domain name to assign to API Gateway"
  type        = string
}