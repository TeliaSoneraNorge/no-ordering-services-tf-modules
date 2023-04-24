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

  dynamic "local_secondary_index" {
    for_each = var.enable_strong_consistence_read == true ? [1] : []
    content {
        name            = "ServiceExecutionStoppedAtLocalIndex"
        projection_type = "KEYS_ONLY"
        range_key       = "ExecutionStoppedAt"
    }
  }


  tags = var.tags
}
