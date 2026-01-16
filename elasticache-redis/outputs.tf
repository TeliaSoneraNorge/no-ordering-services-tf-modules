output "ssm_secret_name" {
  description = "The name of key in parameter store pointing to Redis password"
  value       = aws_ssm_parameter.secret.name
}