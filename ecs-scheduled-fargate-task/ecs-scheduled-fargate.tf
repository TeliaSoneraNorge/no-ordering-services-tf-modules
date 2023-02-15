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
# ECS task scheduling configuration
# ------------------------------------------------------------------------------

resource "aws_iam_role" "ecs_events" {
  name               = "ecs_events"
  tags               = var.tags
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
}

resource "aws_iam_role_policy" "ecs_events_run_task_with_any_role" {
  name   = "ecs_events_run_task_with_any_role"
  role   = aws_iam_role.ecs_events.id
  policy = data.aws_iam_policy_document.run_ecs_task.json
}

resource "aws_cloudwatch_event_rule" "scheduled-event-rule" {
  name                = "${var.name_prefix}-rule"
  schedule_expression = var.task_schedule_expression
  tags                = var.tags
  //  lifecycle {
  //    ignore_changes = [schedule_expression]
  //  }
}

resource "aws_cloudwatch_event_target" "ecs_scheduled_task" {
  target_id = var.name_prefix
  rule      = aws_cloudwatch_event_rule.scheduled-event-rule.name
  arn       = var.cluster_arn
  role_arn  = aws_iam_role.ecs_events.arn
  ecs_target {
    task_count          = var.task_count
    task_definition_arn = aws_ecs_task_definition.task.arn
    launch_type         = "FARGATE"
    network_configuration {
      subnets         = var.private_subnet_ids
      security_groups = var.security_groups_ids
    }
  }
  lifecycle {
    ignore_changes = [ecs_target, input]
  }
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

