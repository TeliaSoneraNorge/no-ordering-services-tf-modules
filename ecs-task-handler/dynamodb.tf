resource "aws_dynamodb_table" "ecs_task_failing" {
  name           = var.name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Service"
  range_key      = "ExecutionStoppedAt"

  attribute {
    name = "Service"
    type = "S"
  }

  attribute {
    name = "ExecutionStoppedAt"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  tags = var.tags
}
