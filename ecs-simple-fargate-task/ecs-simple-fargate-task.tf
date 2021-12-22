# ------------------------------------------------------------------------------
# IAM - Task role, basic. Users of the module will append policies to this role
# when they use the module. S3, Dynamo permissions etc etc.
# ------------------------------------------------------------------------------

resource "aws_iam_role" "task" {
  name               = "${var.name_prefix}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags = merge(
  var.tags,
  {
    Purpose = "Role used for ECS task"
  }
  )
}

resource "aws_iam_role_policy" "log_agent" {
  name   = "${var.name_prefix}-log-permissions"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_permissions.json

}

resource "aws_iam_role_policy" "custom" {
  for_each = var.policy_task_role != "" ? toset(["custom_policy"]) : toset([])
  name     = "${var.name_prefix}-custom-policy"
  role     = aws_iam_role.task.id
  policy   = var.policy_task_role

}

# ------------------------------------------------------------------------------
# ECS task definition
# ------------------------------------------------------------------------------

data "aws_region" "current" {}

locals {
  task_environment = [
  for k, v in var.task_container_environment : {
    name  = k
    value = v
  }
  ]

  task_environment_secret = [
  for k, v in var.task_container_secrets : {
    name      = k
    valueFrom = v
  }
  ]

}

resource "aws_ecs_task_definition" "task" {
  family                   = var.name_prefix
  execution_role_arn       = var.task_execution_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_definition_cpu
  memory                   = var.task_definition_memory
  task_role_arn            = aws_iam_role.task.arn
  container_definitions    = <<EOF
[{
    "name": "${var.container_name != "" ? var.container_name : var.name_prefix}",
    "image": "${var.task_container_image}",
    "essential": true,
    "portMappings": [],
   "logConfiguration": {
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${var.log_group_name}",
                "awslogs-region": "${data.aws_region.current.name}",
                "awslogs-stream-prefix": "${var.name_prefix}"
            }
    },
    "stopTimeout": ${var.stop_timeout},
    "command": ${jsonencode(var.task_container_command)},
    "environment": ${jsonencode(local.task_environment)},
    "secrets": ${jsonencode(local.task_environment_secret)}
}]
EOF

  # The task definition is going to be updated from CI/CD pipelines
  lifecycle {
    ignore_changes = [container_definitions, cpu, memory]
  }

  tags = var.tags
}