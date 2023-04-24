resource "aws_dynamodb_table" "ecs_task_failing" {
  name           = var.name
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
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

  local_secondary_index {
    name            = "ServiceExecutionStoppedAtLocalIndex"
    projection_type = "KEYS_ONLY"
    range_key       = "ExecutionStoppedAt"
  }

  tags = var.tags
}
