output "lambda_arn" {
  description = "ARN of the ecs deployment monitor lambda function"
  value       = aws_lambda_function.ecs-monitor-lambda.arn
}