variable "application" {
  description = "Application name"
  type        = string
}

variable "cluster_name" {
  description = "the ECS cluster name"
  type        = string
}

variable "cluster_arn" {
  description = "Cluster ARN"
  type        = string
}

variable "log_group_arn" {
  description = "Log group arn"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "account_id" {
  description = "The account ID"
  type        = string
}

variable "name_prefix" {
  description = "A prefix used for naming resources."
  type        = string
}

variable "task_container_port" {
  description = "Port that the container exposes."
  type        = number
  default     = 8080
}

variable "task_container_protocol" {
  description = "Protocol that the container exposes."
  default     = "HTTP"
  type        = string
}

variable "health_check" {
  description = "A health block containing health check settings for the target group. Overrides the defaults."
  type        = map(string)
  default     = {}
}

variable "health_check_grace_period_seconds" {
  default     = 300
  description = "Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown, up to 7200. Only valid for services configured to use load balancers."
  type        = number
}

variable "tags" {
  description = "A map of tags (key-value pairs) passed to resources."
  type        = map(string)
  default     = {}
}

variable "task_execution_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the task execution role."
  type        = string
}

variable "code_deploy_role_arn" {
  description = "Code deploy role ARN"
  type        = string
}

variable "task_definition_cpu" {
  description = "Amount of CPU to reserve for the task."
  default     = 256
  type        = number
}

variable "task_definition_memory" {
  description = "The soft limit (in MiB) of memory to reserve for the container."
  default     = 512
  type        = number
}

variable "container_name" {
  description = "Optional name for the container to be used instead of name_prefix. Useful when when constructing an imagedefinitons.json file for continuous deployment using Codepipeline."
  default     = ""
  type        = string
}

variable "task_container_image" {
  description = "The image used to start a container."
  type        = string
}

variable "log_group_name" {
  description = "The name of the Cloudwatch log group."
  type        = string
}

variable "use_splunk_log_driver" {
  description = "True/false if splunk log driver is used"
  type        = bool
}

variable "splunk-url" {
  description = "The URL of splunk http endpoint collector or ALB forwarder"
  type        = string
  default     = ""
}

variable "splunk-index" {
  description = "Splunk index where logs are delivered"
  type        = string
  default     = ""
}

variable "splunk-source" {
  description = "Splunk log source identifying environment"
  type        = string
  default     = ""
}

variable "splunk-sourcetype" {
  description = "Splunk log source type serves as a idnetification for all logs coming from AWS"
  type        = string
  default     = ""
}

variable "splunk-gzip" {
  description = "True/false if log compression is used"
  type        = bool
  default     = true
}

variable "splunk-format" {
  description = "Splunk log format: json, raw, inline"
  type        = string
  default     = "json"
}

variable "splunk-insecureskipverify" {
  description = "True/false if certificate is validation is skipped"
  type        = bool
  default     = true
}


variable "stop_timeout" {
  description = "Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own. On Fargate the maximum value is 120 seconds."
  default     = 30
}

variable "task_container_command" {
  description = "The command that is passed to the container."
  default     = []
  type        = list(string)
}

variable "task_container_environment" {
  description = "The environment variables to pass to a container."
  default     = {}
  type        = map(string)
}

variable "task_container_secrets" {
  description = "The secrets environment variables to pass to a container."
  default     = {}
  type        = map(string)
}

# Service


variable "desired_count" {
  description = "The number of instances of the task definitions to place and keep running."
  default     = 1
  type        = number
}

variable "deployment_minimum_healthy_percent" {
  default     = 50
  description = "The lower limit of the number of running tasks that must remain running and healthy in a service during a deployment"
  type        = number
}

variable "deployment_maximum_percent" {
  default     = 200
  description = "The upper limit of the number of running tasks that can be running in a service during a deployment"
  type        = number
}

variable "alb_arn" {
  default     = ""
  description = "Arn for the LB for which the service should be attach to."
  type        = string
}

variable "private_subnet_ids" {
  description = "A list of private subnets inside the VPC"
  type        = list(string)
}

variable "security_groups_ids" {
  description = "Security groups IDs"
  type        = list(string)
}

variable "deployment_controller_type" {
  default     = "ECS"
  type        = string
  description = "Type of deployment controller. Valid values: CODE_DEPLOY, ECS. If CODE_DEPLOY is selected, module creates an additional resources: codedeploy_app, aws_codedeploy_deployment_group"
}


variable "alb_https_listener_arns" {
  description = "HTTPS listeners ARNs"
  type        = list(string)
}

//variable "alb_routing_priority" {
//  description = "Alb routing priority"
//  type = number
//}

variable "listener_rule_paths" {
  description = "Paths that will be used in routing to the service in path based routing"
  type        = list(string)
  default     = []
}

variable "listener_rule_enable_host_based_routing" {
  description = "Enable host base routing, add appropriate record to Route53"
  type        = bool
  default     = false
}

variable route53_zone_name {
  description = "Zone name where service is going to be registered"
  type        = string
  default     = ""
}

variable "service_ignore_changes" {
  description = ""
  type        = list(string)
  default     = []
}

variable "deployment_config_name" {
  description = "https://docs.aws.amazon.com/AmazonECS/latest/userguide/deployment-type-bluegreen.html"
  type        = string
  default     = "CodeDeployDefault.ECSLinear10PercentEvery1Minutes"
}

variable "deployment_termination_wait_time_in_minutes" {
  description = "How many minutes ECS should wait until will terminate the not used instances"
  type        = number
  default     = 10
}

variable "policy_task_role" {
  description = "A policy document for the task role. Task role has already another policy with logs:CreateLogStream, logs:PutLogEvents. This variable should be used when you need something more"
  type        = string
  default     = ""
}

variable "deregistration_delay" {
  description = "The amount of time for Elastic Load Balancing to wait before deregistering a target."
  type        = number
  default     = 300
}