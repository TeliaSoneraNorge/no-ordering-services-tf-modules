data "aws_iam_policy_document" "security_hub_reporter_assume" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::059937321589:role/security-reporter-lambda-role",
      ]
    }
  }
}

resource "aws_iam_role" "security_hub_reporter_role" {
  name               = "security-hub-reporter"
  assume_role_policy = data.aws_iam_policy_document.security_hub_reporter_assume.json
  description        = "AIM role for access to AWS Security hub"

  tags = var.tags
}

data "aws_iam_policy_document" "security_hub_reporter_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "securityhub:Get*",
      "securityhub:List*",
      "securityhub:Describe*"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "security_hub_reporter_role_policy" {
  name   = "security-hub-reporter-policy"
  role   = aws_iam_role.security_hub_reporter_role.name
  policy = data.aws_iam_policy_document.security_hub_reporter_policy_document.json
}
