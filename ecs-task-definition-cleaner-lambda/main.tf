locals {
  ecs_cleaner_lambda_name = "ecs-task-definition-cleaner-lambda"
}

data "aws_iam_policy_document" "ecs_cleaner_lambda_assume" {
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

resource "aws_iam_role" "ecs_cleaner_lambda_role" {
  name               = "${local.ecs_cleaner_lambda_name}-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_cleaner_lambda_assume.json
  description        = "AIM role for ${local.ecs_cleaner_lambda_name}"

  tags = var.tags
}

data "aws_iam_policy_document" "ecs_cleaner_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "cloudwatch:*",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ssm:GetParameter"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ecs:*"
    ]

    resources = [
      "*",
    ]
  }

  dynamic "statement" {
    for_each = var.s3_tf_state_buckets
    content {
      statement {
        effect = "Allow"

        actions = [
          "s3:ListBucket"
        ]
        resources = ["arn:aws:s3:::${each.value}"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.s3_tf_state_buckets
    content {
      statement {
        effect = "Allow"

        actions = [
          "s3:GetObject"
        ]
        resources = ["arn:aws:s3:::${each.value}/*"]
      }
    }
  }
}

resource "aws_iam_role_policy" "ecs_cleaner_role_policy" {
  name   = "${local.ecs_cleaner_lambda_name}-policy"
  role   = aws_iam_role.ecs_cleaner_lambda_role.name
  policy = data.aws_iam_policy_document.ecs_cleaner_policy_document.json
}

data "archive_file" "ecs_cleaner_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/${local.ecs_cleaner_lambda_name}.zip"
}

resource "aws_lambda_function" "ecs_cleaner_lambda" {
  function_name = local.ecs_cleaner_lambda_name
  description   = "ECS task definition cleaner lambda"
  filename      = data.archive_file.ecs_cleaner_lambda_zip.output_path
  memory_size   = 1024
  timeout       = 300

  runtime          = "python3.9"
  role             = aws_iam_role.ecs_cleaner_lambda_role.arn
  source_code_hash = data.archive_file.ecs_cleaner_lambda_zip.output_base64sha256
  handler          = "main.lambda_handler"
  architectures    = ["arm64"]


  environment {
    variables = {
      OLD_REVISION_COUNT                 = "10"
      S3_TF_STATE_FILES_FOR_CHECKING_REF = var.s3_tf_state_files_for_checking_ref
    }
  }

  tags = merge(var.tags, {
    Name = "ECS tasks artifacts cleaner lambda"
  })

}
