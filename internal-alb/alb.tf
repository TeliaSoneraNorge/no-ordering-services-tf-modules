
locals {
  identifier = join("-", compact(tolist([var.domain_name, var.environment])))
}

resource "aws_lb" "alb" {
  name               = "${local.identifier}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.vpc_subnet_ids
  idle_timeout       = var.idle_timeout

  enable_deletion_protection = true

  access_logs {
    bucket  = var.access_logs_s3_bucket_id
    prefix  = "${local.identifier}-internal-alb"
    enabled = var.access_logs_enabled
  }

  tags = {
    Purpose = "ALB in front of an ECS cluster"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "No rules matched for this request."
      status_code  = "404"
    }
  }
}

// Created a rule for ALB health check
resource "aws_lb_listener_rule" "health_check" {
  listener_arn = aws_lb_listener.https.arn
  action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = jsonencode({ "status" : "up" })
      status_code  = "200"
    }
  }

  condition {
    host_header {
      values = [aws_route53_record.a.name]
    }
  }

  condition {
    path_pattern {
      values = ["/health", "/status"]
    }
  }
}