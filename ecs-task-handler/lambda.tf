locals {
  ecs_task_failing_handler_lambda_name = "${var.name}_lambda"
}


resource "aws_lambda_permission" "allow_event_bridge_rule_trigger" {
  statement_id  = "InvokeLambdaFunction"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecs_task_failing_handler_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_task_failing.arn
}

data "archive_file" "ecs_task_failing_handler_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src"
  output_path = "${path.module}/${local.ecs_task_failing_handler_lambda_name}.zip"
}

resource "aws_lambda_function" "ecs_task_failing_handler_lambda" {
  filename      = data.archive_file.ecs_task_failing_handler_lambda_zip.output_path
  function_name = local.ecs_task_failing_handler_lambda_name
  role          = aws_iam_role.ecs_task_failing_handler_lambda.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.9"
  architectures    = ["arm64"]
  reserved_concurrent_executions = var.reserved_concurrent_executions
  source_code_hash = data.archive_file.ecs_task_failing_handler_lambda_zip.output_base64sha256


  environment {
    variables = {
      DYNAMO_DB_TABLE = aws_dynamodb_table.ecs_task_failing.name
      FAILING_INTERVAL_IN_MINUTES = var.failing_interval_in_minutes,
      MAX_FAILING_COUNT = var.max_failing_count
      DYNAMODB_ITEMS_TTL = var.dynamodb_items_ttl_in_hours
      SNS_ARN = var.sns_arn
    }
  }

  tags = var.tags
}

resource "aws_iam_role" "ecs_task_failing_handler_lambda" {
  name = local.ecs_task_failing_handler_lambda_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_cloudwatch_event_target" "ecs_task_failing_handler_lambda" {
  rule = aws_cloudwatch_event_rule.ecs_task_failing.id
  arn  = aws_lambda_function.ecs_task_failing_handler_lambda.arn
}

resource "aws_cloudwatch_log_group" "ecs_task_failing_handler_lambda" {
  name              = "/aws/lambda/${local.ecs_task_failing_handler_lambda_name}"
  retention_in_days = 3
}

data "aws_iam_policy_document" "ecs_task_failing_handler_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"
    actions = ["dynamodb:*"]
    resources = [aws_dynamodb_table.ecs_task_failing.arn]
  }

  statement {
    effect = "Allow"
    actions = ["ecs:UpdateService"]
    resources = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/${var.cluster_name}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      var.sns_arn
    ]
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "ecs_task_failing_handler_lambda" {
  name        = local.ecs_task_failing_handler_lambda_name
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.ecs_task_failing_handler_lambda.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_failing_handler_lambda" {
  role       = aws_iam_role.ecs_task_failing_handler_lambda.name
  policy_arn = aws_iam_policy.ecs_task_failing_handler_lambda.arn
}
