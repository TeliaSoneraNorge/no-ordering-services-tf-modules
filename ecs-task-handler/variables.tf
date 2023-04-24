variable "cluster_arn" {
  description = "Arn of the cluster used in CW pattern matching"
  type = string
}

variable "cluster_name" {
  description = "Name of the cluster used in CW pattern matching"
  type        = string
}

variable "name" {
  description = "Name used by all resources created byt this module."
  type = string
}

variable "reserved_concurrent_executions" {
  description = "Amount of reserved concurrent executions for this lambda function."
  type = number
  default = -1
}

variable "failing_interval_in_minutes" {
  description = "Interval used to count task fails."
  type = number
  default = 15
}

variable "max_failing_count" {
  description = "Maximum number of task fails within the failing_interval_in_minutes to evaluate whether number of service tasks shall be set to 0."
  type = number
  default = 3
}

variable "dynamodb_items_ttl_in_hours" {
  description = "Amount of hours till records are automatically deleted"
  type = number
  default = 24
}

variable "enable_strong_consistence_read" {
  description = "If true, local secondary index will be created"
  type = bool
  default = false
}

variable "sns_arn" {
  description = "SNS to be used when error occurs"
  type = string
}

variable "tags" {
  description = "Mandatory tags."
  type = map(string)
}
