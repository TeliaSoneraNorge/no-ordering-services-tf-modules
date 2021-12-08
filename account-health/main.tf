
# AWS Personal Health Dashboard events to SNS (Slack)

resource "aws_cloudwatch_event_rule" "account_health_event" {
  name        = "personal-health-dashboard-events"
  description = "Capture personal health events"

  event_pattern = <<EOF
{
  "source": ["aws.health"]
}
EOF
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.account_health_event.name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn
}
