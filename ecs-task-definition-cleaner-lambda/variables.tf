variable "tags" {
  description = "Tags for lambda"
  type        = map(string)
}

variable "old_revision_count" {
  description = "How many old revisions should be preserved"
  type        = string
  default     = "10"
}

#implemented in relation to the bug https://github.com/hashicorp/terraform-provider-aws/issues/29749
variable "s3_tf_state_objects" {
  description = "Terraform S3 state objects used for checking existing references, pls separate objects with comma"
  type        = string
  default     = ""
}

variable "s3_tf_state_bucket" {
  description = "Terraform S3 state bucket"
  type        = string
  default     = ""
}

variable "s3_tf_state_bucket_kms_arn" {
  description = "KMS arn for the Terraform S3 state bucket"
  type        = string
  default     = ""
}