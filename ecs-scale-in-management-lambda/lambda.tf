locals {
  scale_in_lambda_name = "ecs-scale-in-management"
}

data "archive_file" "scale-in-lambda-zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src"
  output_path = "${path.module}/${local.scale_in_lambda_name}.zip"
}

data "aws_iam_policy_document" "scale_in_lambda_assume" {
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

data "aws_iam_policy_document" "scale_in_lambda" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:*",
      "application-autoscaling:*",
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

resource "aws_iam_role" "scale_in_lambda" {
  name               = local.scale_in_lambda_name
  assume_role_policy = data.aws_iam_policy_document.scale_in_lambda_assume.json

  tags = merge(var.common_tags, {
    purpose = "Role for dedicated for lambda ${local.scale_in_lambda_name}"
  })
}

resource "aws_iam_role_policy" "scale_in_lambda" {
  name   = "${local.scale_in_lambda_name}-lambda_policy"
  role   = aws_iam_role.scale_in_lambda.name
  policy = data.aws_iam_policy_document.scale_in_lambda.json
}

resource "aws_lambda_function" "scale_in_lambda" {
  function_name = local.scale_in_lambda_name
  description   = "Lambda dedicated for disabling scaling-in for ECS services"
  filename      = data.archive_file.scale-in-lambda-zip.output_path
  memory_size   = 128
  timeout       = 900

  runtime          = "nodejs12.x"
  role             = aws_iam_role.scale_in_lambda.arn
  source_code_hash = data.archive_file.scale-in-lambda-zip.output_base64sha256
  handler          = "app.lambdaHandler"
  architectures    = ["arm64"]

  tags = merge(var.common_tags, {
    purpose = "Disabling scale in activity of auto-scaling"
  })
}
