resource "aws_iam_policy" "cost_reporter_policy" {
  name        = "cost-reporter-policy"
  path        = "/"
  description = "Read-only actions on cost explorer for cost reporting"

  policy = data.aws_iam_policy_document.cost_reporter_policy_document.json
}

data "aws_iam_policy_document" "cost_reporter_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "ce:Describe*",
      "ce:Get*",
      "ce:List*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "cost_reporter_role" {
  name = "cost-reporter"

  assume_role_policy = data.aws_iam_policy_document.cost_reporter_assume_role_policy.json
  tags = {
    purpose = "Role assumed by cost reporter lambda for retrieving cost information"
  }
}

data "aws_iam_policy_document" "cost_reporter_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "AWS"

      identifiers = [
        # a lambda role in telia-no-neo-stage
        "arn:aws:iam::059937321589:role/cost-reporter-lambda-execution-role",
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.cost_reporter_role.name
  policy_arn = aws_iam_policy.cost_reporter_policy.arn
}