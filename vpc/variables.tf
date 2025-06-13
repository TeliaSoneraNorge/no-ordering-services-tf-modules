variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "subnets" {
  description = "A map of subnets to create in the VPC"
  type = map(object({
    az   = string
    cidr = string
  }))
}

variable "name_prefix" {
  description = "A prefix for the name of resources"
  type        = string
}

variable "transit_gateway_id" {
  description = "ID of the transift gateway to attach"
  type        = string
}