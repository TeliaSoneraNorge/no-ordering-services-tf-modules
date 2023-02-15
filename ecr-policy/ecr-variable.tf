variable "number_of_images_to_retain" {
  description = "Number of images maintained in repository"
  default     = 5
  type        = number
}

variable "ecr_repositories" {
  description = "List of repositories where the policy will be applied"
  type        = list(any)
}