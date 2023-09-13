locals {
  desired_task_numbers_lambda_name = "ecs-desired-task-number-lambda"
}


data "archive_file" "desired_ecs_task_number_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/src"
  output_path = "${path.module}/${local.desired_task_numbers_lambda_name}.zip"
}

data "aws_iam_policy_document" "desired_ecs_task_number_lambda_assume" {
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


data "aws_iam_policy_document" "desired_task_numbers_lambda" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:UpdateService",
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

resource "aws_iam_role" "desired_task_lambda" {
  name               = local.desired_task_numbers_lambda_name
  assume_role_policy = data.aws_iam_policy_document.desired_ecs_task_number_lambda_assume.json

  tags = merge(var.common_tags, {
    purpose = "Role for dedicated for lambda ${local.desired_task_numbers_lambda_name}"
  })
}

resource "aws_iam_role_policy" "scale_in_lambda" {
  name   = "${local.desired_task_numbers_lambda_name}-_policy"
  role   = aws_iam_role.desired_task_lambda.name
  policy = data.aws_iam_policy_document.desired_task_numbers_lambda.json
}

resource "aws_lambda_function" "desired_task_lambda" {
  function_name = local.desired_task_numbers_lambda_name
  description   = "Lambda dedicated for setting desired task number for ECS service in ${var.local_environment}"
  filename      = data.archive_file.desired_ecs_task_number_lambda_zip.output_path
  memory_size   = 128
  timeout       = 900

  runtime          = "nodejs16.x"
  role             = aws_iam_role.desired_task_lambda.arn
  source_code_hash = data.archive_file.desired_ecs_task_number_lambda_zip.output_base64sha256
  handler          = "index.handler"
  architectures    = ["arm64"]

  tags = merge(var.common_tags, {
    purpose = "Setting desired task number for ECS service"
  })
}

