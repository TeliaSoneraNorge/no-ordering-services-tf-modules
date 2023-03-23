output "lambda_arn" {
  description = "The ARN of the cleaner lambda"
  value       = aws_lambda_function.ecs_cleaner_lambda.arn
}