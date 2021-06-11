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
# LB Target groups
# ------------------------------------------------------------------------------

# blue TG is used always, either in ECS standard deployment or canary deployment
resource "aws_lb_target_group" "blue" {
  name                 = "${var.name_prefix}-blue"
  vpc_id               = var.vpc_id
  protocol             = var.task_container_protocol
  port                 = var.task_container_port
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay
  dynamic "health_check" {
    for_each = [var.health_check]
    content {
      enabled             = lookup(health_check.value, "enabled", true)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", 2)
      interval            = lookup(health_check.value, "interval", 30)
      matcher             = lookup(health_check.value, "matcher", 200)
      path                = lookup(health_check.value, "path", "/system/monitoring/common/ping")
      port                = lookup(health_check.value, "port", "traffic-port")
      protocol            = lookup(health_check.value, "protocol", "HTTP")
      timeout             = lookup(health_check.value, "timeout", 15)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", 5)
    }

  }

  # NOTE: TF is unable to destroy a target group while a listener is attached,
  # therefor we have to create a new one before destroying the old. This also means
  # we have to let it have a random name, and then tag it with the desired name.
  //  lifecycle {
  //    create_before_destroy = true
  //  }
  tags = merge(
    var.tags,
    {
      Purpose = "Target group used for ECS service. The blue TG is used always either in ECS standard deployment or canary deployment",
      Name    = "${var.name_prefix}-target-${var.task_container_port}"
    }
  )
}

# green TG is used only in canary deployment
resource "aws_lb_target_group" "green" {
  for_each             = var.deployment_controller_type == "CODE_DEPLOY" ? toset(["canary"]) : toset([])
  name                 = "${var.name_prefix}-green"
  vpc_id               = var.vpc_id
  protocol             = var.task_container_protocol
  port                 = var.task_container_port
  target_type          = "ip"
  deregistration_delay = var.deregistration_delay
  dynamic "health_check" {
    for_each = [var.health_check]
    content {
      enabled             = lookup(health_check.value, "enabled", true)
      healthy_threshold   = lookup(health_check.value, "healthy_threshold", 2)
      interval            = lookup(health_check.value, "interval", 30)
      matcher             = lookup(health_check.value, "matcher", 200)
      path                = lookup(health_check.value, "path", "/system/monitoring/common/ping")
      port                = lookup(health_check.value, "port", "traffic-port")
      protocol            = lookup(health_check.value, "protocol", "HTTP")
      timeout             = lookup(health_check.value, "timeout", 15)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", 5)
    }
  }

  # NOTE: TF is unable to destroy a target group while a listener is attached,
  # therefor we have to create a new one before destroying the old. This also means
  # we have to let it have a random name, and then tag it with the desired name.
  //  lifecycle {
  //    create_before_destroy = true
  //  }

  tags = merge(
    var.tags,
    {
      Purpose = "Target group used for ECS service. The green TG is used only in canary deployment",
      Name    = "${var.name_prefix}-target-${var.task_container_port}"
    }
  )
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
    "portMappings": [
        {
            "containerPort": ${var.task_container_port},
            "hostPort": ${var.task_container_port},
            "protocol":"tcp"
        }
    ],
   "logConfiguration": {
        %{if var.use_splunk_log_driver}
            "logDriver": "splunk",
            "options": {
                "splunk-url": "${var.splunk-url}",
                "splunk-index": "${var.splunk-index}",
                "splunk-source": "${var.splunk-source}",
                "splunk-sourcetype": "${var.splunk-sourcetype}",
                "splunk-gzip": "${var.splunk-gzip}",
                "splunk-format": "${var.splunk-format}",
                "splunk-insecureskipverify": "${var.splunk-insecureskipverify}"
            },
            "secretOptions": [
              {
                "name": "splunk-token",
                "valueFrom": "arn:aws:ssm:eu-west-1:${var.account_id}:parameter/common/splunk-hec-token"
              }
            ]
        %{else}
            "logDriver": "awslogs",
            "options": {
                "awslogs-group": "${var.log_group_name}",
                "awslogs-region": "${data.aws_region.current.name}",
                "awslogs-stream-prefix": "${var.name_prefix}"
            }
        %{endif}
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

# ------------------------------------------------------------------------------
# Service routing
# ------------------------------------------------------------------------------

data "aws_route53_zone" "this" {
  for_each = var.listener_rule_enable_host_based_routing == true ? toset(["zone"]) : toset([])
  name     = var.route53_zone_name
}

data "aws_alb" "this" {
  for_each = var.listener_rule_enable_host_based_routing == true ? toset(["alb"]) : toset([])
  arn      = var.alb_arn
}

resource "aws_route53_record" "a" {
  for_each = var.listener_rule_enable_host_based_routing == true ? toset(["service_host"]) : toset([])
  zone_id  = data.aws_route53_zone.this["zone"].id
  name     = join(".", compact(list(var.application, var.route53_zone_name)))
  type     = "A"

  allow_overwrite = true

  alias {
    name                   = data.aws_alb.this["alb"].dns_name
    zone_id                = data.aws_alb.this["alb"].zone_id
    evaluate_target_health = true
  }

}

resource "aws_lb_listener_rule" "rule" {
  listener_arn = var.alb_https_listener_arns[0]

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }

  dynamic "condition" {
    for_each = length(var.listener_rule_paths) == 0 ? [] : [1]

    content {
      path_pattern {
        values = var.listener_rule_paths
      }
    }
  }

  dynamic "condition" {
    for_each = var.listener_rule_enable_host_based_routing == true ? [1] : []

    content {
      host_header {
        values = [aws_route53_record.a["service_host"].name]
      }
    }
  }

  # Section is ignored because of the changes which come from canary/deployment (switching blue to green and vice versa)
  lifecycle {
    ignore_changes = [action, condition]
  }

}

# ------------------------------------------------------------------------------
# ECS service
# ------------------------------------------------------------------------------

resource "aws_ecs_service" "service" {
  depends_on                         = [aws_lb_listener_rule.rule]
  name                               = var.name_prefix
  cluster                            = var.cluster_arn
  task_definition                    = aws_ecs_task_definition.task.arn
  desired_count                      = var.desired_count
  launch_type                        = "FARGATE"
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  health_check_grace_period_seconds  = var.alb_arn == "" ? null : var.health_check_grace_period_seconds

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = var.security_groups_ids
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.alb_arn == "" ? [] : [1]
    content {
      container_name   = var.container_name != "" ? var.container_name : var.name_prefix
      container_port   = var.task_container_port
      target_group_arn = aws_lb_target_group.blue.arn
    }
  }

  deployment_controller {
    # The deployment controller type to use. Valid values: CODE_DEPLOY, ECS.
    type = var.deployment_controller_type
  }

  # Autoscaling is adjusting the value automatically so there is a need to ignore the desired_count
  # task_definition is ignored because deployment from CI/CD (Github Actions)
  # load_balancer section is ignored because of the changes which come from canary/deployment (switching blue to green and vice versa )
  # There is not possible yet to implement it in a dynamic way https://github.com/hashicorp/terraform/issues/24188
  lifecycle {
    ignore_changes = [desired_count, task_definition, load_balancer]
  }

  tags = var.tags
}

# HACK: The workaround used in ecs/service does not work for some reason in this module, this fixes the following error:
# "The target group with targetGroupArn arn:aws:elasticloadbalancing:... does not have an associated load balancer."
# see https://github.com/hashicorp/terraform/issues/12634.
#     https://github.com/terraform-providers/terraform-provider-aws/issues/3495
# Service depends on this resources which prevents it from being created until the LB is ready

//resource "null_resource" "lb_exists" {
//  triggers = var.lb_arn == "" ? {} : { alb_name = var.lb_arn }
//}
//



