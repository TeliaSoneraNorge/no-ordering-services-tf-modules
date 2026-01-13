# Task role assume policy
data "aws_iam_policy_document" "task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Task logging privileges
data "aws_iam_policy_document" "task_permissions" {
  statement {
    effect = "Allow"

    resources = [
      var.log_group_arn
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  # Allow access to all parameter store parameters with the specified prefix
  statement {
    effect = "Allow"

    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${var.account_id}:parameter/${var.name_prefix}/*"
    ]

    actions = [
      "ssm:GetParametersByPath",
      "ssm:GetParameter"
    ]
  }
}

data "aws_iam_policy_document" "ecs_exec_for_debugging" {
  statement {
    effect = "Allow"

    resources = [
      "*"
    ]

    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel",
    ]
  }
}

