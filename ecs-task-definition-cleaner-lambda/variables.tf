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

#implemented in relation to the bug https://github.com/hashicorp/terraform-provider-aws/issues/29749
variable "s3_tf_state_files_for_checking_ref" {
  description = "Terraform S3 state files URI used for checking existing references, pls separate files with comma"
  type        = string
  default     = ""
}

variable "s3_tf_state_buckets" {
  description = "Terraform S3 state buckets (used by IAM)"
  type        = list(string)
  default     = []
}

