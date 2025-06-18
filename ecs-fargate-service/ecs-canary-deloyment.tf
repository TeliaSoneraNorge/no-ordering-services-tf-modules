resource "aws_codedeploy_app" "code_deploy_app" {
  for_each         = var.deployment_controller_type == "CODE_DEPLOY" ? toset(["code_deploy"]) : toset([])
  depends_on       = [aws_ecs_service.service]
  compute_platform = "ECS"
  name             = var.name_prefix
}

resource "aws_codedeploy_deployment_group" "deployment_group_canary" {
  for_each               = var.deployment_controller_type == "CODE_DEPLOY" ? toset(["code_deploy_dg"]) : toset([])
  depends_on             = [aws_ecs_service.service]
  app_name               = aws_codedeploy_app.code_deploy_app["code_deploy"].name
  deployment_config_name = var.deployment_config_name
  deployment_group_name  = var.name_prefix
  service_role_arn       = var.code_deploy_role_arn

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = var.deployment_termination_wait_time_in_minutes
    }

  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  ecs_service {
    cluster_name = var.cluster_name
    service_name = var.name_prefix
  }


  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [var.alb_https_listener_arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green["canary"].name
      }

    }
  }

}
