variable "identifier" {
  description = "Identifier for the environment, used in resource names"
  type        = string
  default     = "ecs-monitor"
}

variable "common_tags" {
  description = "Common tags to all resources in environment"
  type        = map(string)
  default     = {}
}

variable "env_region" {
  description = "The AWS region for lambda installation"
}

variable "account_id" {
  description = "The AWS Account ID number of the account."
}

variable "lambda_log_retention" {
  description = "Lambda cloud watch log retention in days"
  default     = 14
  type        = number
}

variable "param_store_base64_basicauth" {
  description = "Base64 client:secret value location"
}

variable "rmtool_host" {
  description = "RMTool host with port"
}