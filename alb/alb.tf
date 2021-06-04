
locals {
  subnets    = var.alb_is_internal ? var.vpc_private_subnets : var.vpc_public_subnets
  identifier = join("-", compact(list(var.domain_name, var.environment)))
}

module "alb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.0.0"

  name        = "${local.identifier}-alb"
  description = "Security group with HTTP port open from VPC"
  vpc_id      = var.vpc_id


  ingress_cidr_blocks = var.cidr_blocks
  ingress_rules       = ["https-443-tcp"]
  egress_rules        = ["all-all"]
  tags = merge(
    var.tags,
    {
      Purpose = "Load balancer security group"
    }
  )
}

module "alb" {
  source          = "terraform-aws-modules/alb/aws"
  version         = "~> 6.1.0"
  name            = "${local.identifier}${var.alb_prefix}"
  internal        = var.alb_is_internal
  vpc_id          = var.vpc_id
  subnets         = local.subnets
  security_groups = [module.alb_security_group.security_group_id]
  idle_timeout    = var.idle_timeout

  target_groups = [
    {
      name_prefix      = "def"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = []

  https_listeners = [
    {
      port               = 443
      protocol           = "HTTPS"
      certificate_arn    = var.acm_certificate_arn
      target_group_index = 0
    }
  ]

  access_logs = {
    bucket  = var.logs_s3_bucket_id
    prefix  = "alb"
    enabled = true
  }

  tags = merge(
    var.tags,
  )

}

data "aws_route53_zone" "this" {
  name         = var.route53_zone_name
  private_zone = var.assign_route53_private_zone
}

resource "aws_route53_record" "a" {
  zone_id         = data.aws_route53_zone.this.id
  name            = join(".", compact(list(var.route53_record_prefix, var.route53_zone_name)))
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
    evaluate_target_health = true
  }

}

resource "aws_route53_record" "aaaa" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = join(".", compact(list(var.route53_record_prefix, data.aws_route53_zone.this.name)))
  type    = "AAAA"

  allow_overwrite = true

  alias {
    name                   = module.alb.lb_dns_name
    zone_id                = module.alb.lb_zone_id
    evaluate_target_health = true
  }
}
