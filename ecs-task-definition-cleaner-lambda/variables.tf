variable "tags" {
  description = "Tags for lambda"
  type        = map(string)
}

variable "lambda_layers" {
  description = "Lambda layers attached cleaner lambda"
  type        = list(any)
  default     = []
}

variable "old_revision_count" {
  description = "How many old revisions should be preserved"
  type        = string
  default     = "10"
}
