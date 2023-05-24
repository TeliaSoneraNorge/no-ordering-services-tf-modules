variable "log_group_name" {
  description = "Log group name"
  type        = string

}

variable "sns_topic_arn" {
  description = "Arn of SNS topic for notifications"
  type        = string
}

variable "env_description" {
  description = "Short environment description"
  type        = string
  default     = "()"
}


variable "datapoints_to_alarm" {
  type = number
  description = "The number of datapoints that must be breaching to trigger the alarm"
  default = 10
}

variable "evaluation_periods" {
  type = number
  description = "The number of periods over which data is compared to the specified threshold"
  default = 10
}

variable "metric_query_period" {
  type = number
  description = "The number of periods over which data is compared to the specified threshold"
  default = 900
}

variable "metric_query_band" {
  type = number
  description = "Anomaly detection, based on a standard deviation. Higher number means thicker band, lower number means thinner band."
  default = 7
}
