variable "tags" {
  description = "Tags for lambda"
  type        = map(string)
}

variable "lambda_layers" {
  description = "Lambda layers attached cleaner lambda"
  type        = list(any)
  default = []
}

