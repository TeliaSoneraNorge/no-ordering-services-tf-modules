locals {
  ecs_monitor_lambda_name = var.identifier
}

data "archive_file" "ecs-monitor-lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/${local.ecs_monitor_lambda_name}.zip"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${local.ecs_monitor_lambda_name}"
  retention_in_days = var.lambda_log_retention

  tags = merge(var.common_tags, {
    group   = "ECS deployment",
    purpose = "CW log group setup for deploy ecs monitor lambda",
  })
}

data "aws_iam_policy_document" "ecs-monitor-lambda_assume" {
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

resource "aws_iam_role" "ecs-monitor-lambda" {
  name               = local.ecs_monitor_lambda_name
  assume_role_policy = data.aws_iam_policy_document.ecs-monitor-lambda_assume.json

  tags = merge(var.common_tags, {
    group   = "ECS deployment",
    purpose = "AIM role for deploy ecs monitor lambda",
  })
}

resource "aws_iam_role_policy" "ecs-monitor-lambda" {
  name   = "${local.ecs_monitor_lambda_name}-lambda_policy"
  role   = aws_iam_role.ecs-monitor-lambda.name
  policy = data.aws_iam_policy_document.ecs-monitor-lambda.json
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecs-monitor-lambda" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:*",
      "codedeploy:*",
      "cloudwatch:*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
      "arn:aws:codedeploy:*:*:deploymentgroup:*",
      "arn:aws:ecs:*:*:*"
    ]
  }

  statement {
    effect    = "Allow"
    resources = formatlist("arn:aws:ssm:%s:%s:parameter%s", var.env_region, data.aws_caller_identity.current.account_id, var.param_store_base64_basicauth)
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]
  }
}

resource "aws_ssm_parameter" "rmtool_basicauth" {
  name  = var.param_store_base64_basicauth
  value = "changeit"
  type  = "SecureString"

  lifecycle {
    ignore_changes = [value]
  }

  tags = merge(var.common_tags, {
    group   = "ECS deployment",
    purpose = "IFE BASE64 client:secret for Basic Auth",
  })
}

resource "aws_lambda_function" "ecs-monitor-lambda" {
  function_name = local.ecs_monitor_lambda_name
  description   = "ECS deploy monitor lambda"
  filename      = data.archive_file.ecs-monitor-lambda_zip.output_path
  memory_size   = 128
  timeout       = 900

  runtime          = "nodejs20.x"
  role             = aws_iam_role.ecs-monitor-lambda.arn
  source_code_hash = data.archive_file.ecs-monitor-lambda_zip.output_base64sha256
  handler          = "src/handlers/ecs-deploy-monitor.monitorHandler"
  architectures    = ["arm64"]

  environment {
    variables = {
      ENV_CLIENT_SECRET_BASE64_PARAM_PATH = var.param_store_base64_basicauth
      ENV_RMTOOL_HOST                     = var.rmtool_host
    }
  }

  tags = merge(var.common_tags, {
    group   = "ECS deployment",
    purpose = "Deployment Monitor Lambda to notify RMtool",
  })
}


