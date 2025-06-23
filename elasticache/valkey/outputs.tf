output "ssm_secret_name" {
  description = "The name of key in parameter store pointing to Valkey password"
  value       = aws_ssm_parameter.secret.name
}