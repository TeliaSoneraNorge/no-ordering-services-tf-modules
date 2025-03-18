output "alb_target_group_blue_arn_suffix" {
  description = "TG arn suffix"
  value       = aws_lb_target_group.blue.arn_suffix
}

output "ecs_service" {
  value = aws_ecs_service.service
}

output "ecs_task_definition" {
  value = aws_ecs_task_definition.task
}

output "ecs_task_role_arn" {
  value = aws_iam_role.task.arn
}
