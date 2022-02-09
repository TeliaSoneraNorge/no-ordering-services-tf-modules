data "aws_elb_service_account" "this" {}

# Create a bucket for s3 bucket activity logging
locals {
  bucket = "${var.global_name}-logs-${var.aws_region}"

  logs_bucket_tags = merge(
    var.logs_bucket_tags,
    tomap({ "Name" = var.global_name }),
    tomap({ "Project" = var.global_project }),
    tomap({ "Environment" = var.local_environment })
  )
}

data "aws_iam_policy_document" "logs" {
  statement {
    sid = "AllowToPutLoadBalancerLogsToS3Bucket"

    actions = [
      "s3:PutObject",
    ]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.this.arn]
    }

    resources = [
      "arn:aws:s3:::${local.bucket}/*",
    ]
  }
}

resource "aws_s3_bucket" "logs" {
  for_each = var.create_logs_bucket ? toset(["logs_bucket"]) : toset([])

  bucket        = local.bucket
  acl           = "private"
  policy        = data.aws_iam_policy_document.logs.json
  force_destroy = var.force_destroy

  lifecycle_rule {
    enabled = var.enable_lifecycle

    expiration {
      days = var.lifecycle_expire_after
    }
  }

  tags = local.logs_bucket_tags
}

resource "aws_s3_bucket_public_access_block" "logs" {
  for_each = aws_s3_bucket.logs

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}
