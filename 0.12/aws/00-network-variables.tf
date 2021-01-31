# TODO: this needs to be moved to a common 00-data.tf
data "aws_caller_identity" "current" {}

variable "vpc_name" {
  type = string
}

variable "vpc_public" {
  default = true
}

variable "security_group_name_filter" {
  type = string
  default = "**"
  description = "Can be a name or an expression"
}
