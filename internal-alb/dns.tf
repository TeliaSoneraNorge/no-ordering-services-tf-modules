data "aws_route53_zone" "this" {
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "a" {
  zone_id         = data.aws_route53_zone.this.id
  name            = join(".", compact(tolist([var.route53_record_prefix, var.route53_zone_name])))
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }

}

resource "aws_route53_record" "aaaa" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = join(".", compact(tolist([var.route53_record_prefix, data.aws_route53_zone.this.name])))
  type    = "AAAA"

  allow_overwrite = true

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}