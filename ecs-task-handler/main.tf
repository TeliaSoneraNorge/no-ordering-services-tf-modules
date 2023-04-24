
resource "aws_cloudwatch_event_rule" "ecs_task_failing" {
  name        = var.name
  description = "Captures ECS failing tasks by status"

  event_pattern = jsonencode({
    source = ["aws.ecs"],
    detail = {
      clusterArn = [var.cluster_arn],
      desiredStatus = ["STOPPED"],
      lastStatus= ["STOPPED"]
    }
  })
}


resource "aws_cloudwatch_log_group" "ecs_task_failing" {
  name              = "/aws/events/${var.name}"
  retention_in_days = 3
}

data "aws_iam_policy_document" "ecs_task_failing" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream"
    ]

    resources = [
      "${aws_cloudwatch_log_group.ecs_task_failing.arn}:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.ecs_task_failing.arn}:*:*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }

    condition {
      test     = "ArnEquals"
      values   = [aws_cloudwatch_event_rule.ecs_task_failing.arn]
      variable = "aws:SourceArn"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "ecs_task_failing" {
  policy_document = data.aws_iam_policy_document.ecs_task_failing.json
  policy_name     = var.name
}

resource "aws_cloudwatch_event_target" "ecs_task_failing" {
  rule = aws_cloudwatch_event_rule.ecs_task_failing.name
  arn  = aws_cloudwatch_log_group.ecs_task_failing.arn
}
