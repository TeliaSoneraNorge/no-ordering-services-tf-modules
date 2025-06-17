output "this_security_group_id" {
  description = "The security group ID of Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "this_alb_arn" {
  description = "Suffix of ARN of the ALB. Useful for passing to cloudwatch Metric dimension."
  value       = aws_lb.alb.arn
}

output "this_alb_https_listener_arn" {
  description = "The ARNs of the HTTPS load balancer listeners created."
  value       = aws_lb_listener.https.arn
}

output "this_alb_arn_suffix" {
  description = "Suffix of ARN of the ALB. Useful for passing to cloudwatch Metric dimension."
  value       = aws_lb.alb.arn_suffix
}

output "full_url" {
  description = "Full URL of the environment"
  value       = "https://${aws_route53_record.a.fqdn}"
}
