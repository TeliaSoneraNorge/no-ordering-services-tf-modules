resource "aws_iam_policy" "cost_reporter_policy" {
  name        = "cost-reporter-policy"
  path        = "/"
  description = "Read-only actions on cost explorer for cost reporting"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ce:Describe*",
          "ce:Get*",
          "ce:List*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "cost_reporter_reporter" {
  name = "cost-reporter"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          # a lambda role in telia-no-neo-stage 
          AWS = "arn:aws:iam::059937321589:role/cost-reporter-lambda-execution-role"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role       = aws_iam_role.cost_reporter_reporter.name
  policy_arn = aws_iam_policy.cost_reporter_policy.arn
}