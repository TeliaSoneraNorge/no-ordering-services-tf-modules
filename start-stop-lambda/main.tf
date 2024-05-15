locals {
  start_stop_lambda_name = "start-stop-lambda"
}

data "aws_iam_policy_document" "start_stop_lambda_assume" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_iam_policy_document" "start_stop_lambda_policy" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:*",
      "rds:*",
      "autoscaling:*",
      "application-autoscaling:*",
      "ssm:*",
      "cloudwatch:*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "start_stop_lambda_role_policy" {
  name   = "${local.start_stop_lambda_name}-role_policy"
  role   = aws_iam_role.start_stop_lambda_role.name
  policy = data.aws_iam_policy_document.start_stop_lambda_policy.json
}

resource "aws_iam_role" "start_stop_lambda_role" {
  name               = local.start_stop_lambda_name
  assume_role_policy = data.aws_iam_policy_document.start_stop_lambda_assume.json

  tags = merge(var.tags, {
    purpose = "IAM role for start-stop lambda function.",
  })
}

data "archive_file" "start_stop_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/start-stop-lambda.zip"
  source_dir  = "${path.module}/src"
}

resource "aws_lambda_function" "start_stop_lambda" {
  function_name = local.start_stop_lambda_name
  description   = "Lambda function for stopping/starting environment's resources to saving costs."
  filename      = data.archive_file.start_stop_lambda_zip.output_path
  memory_size   = 128
  timeout       = 900

  runtime          = "nodejs20.x"
  role             = aws_iam_role.start_stop_lambda_role.arn
  source_code_hash = data.archive_file.start_stop_lambda_zip.output_base64sha256
  handler          = "index.handler"
  architectures    = ["arm64"]

  tags = var.tags
}

resource "aws_lambda_permission" "cloudwatch_start" {
  statement_id  = "AllowExecutionFrom-${aws_cloudwatch_event_rule.start_system.name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_stop_lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.start_system.arn
}

resource "aws_cloudwatch_event_rule" "start_system" {
  name                = "start-system-lambda-rule"
  schedule_expression = "cron(${var.start_schedule_expression})"
}

resource "aws_cloudwatch_event_rule" "fail_safe_start_system" {
  count               = var.fail_safe_start_schedule_expression == "" ? 0 : 1
  name                = "fail-safe-start-system-lambda-rule"
  schedule_expression = "cron(${var.fail_safe_start_schedule_expression})"
}

resource "aws_cloudwatch_event_target" "start_lambda" {
  target_id = aws_lambda_function.start_stop_lambda.function_name
  rule      = aws_cloudwatch_event_rule.start_system.name
  arn       = aws_lambda_function.start_stop_lambda.arn
  input     = "{\"action\":\"start\"}"
}

resource "aws_lambda_permission" "cloudwatch_stop" {
  statement_id  = "AllowExecutionFrom-${aws_cloudwatch_event_rule.stop_system.name}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_stop_lambda.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.stop_system.arn
}

resource "aws_cloudwatch_event_rule" "stop_system" {
  name                = "stop-system-lambda-rule"
  schedule_expression = "cron(${var.stop_schedule_expression})"
}

resource "aws_cloudwatch_event_target" "stop_lambda" {
  target_id = aws_lambda_function.start_stop_lambda.function_name
  rule      = aws_cloudwatch_event_rule.stop_system.name
  arn       = aws_lambda_function.start_stop_lambda.arn
  input     = "{\"action\":\"stop\"}"
}
