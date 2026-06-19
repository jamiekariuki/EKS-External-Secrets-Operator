variable "aws_account_id" {
  type        = string
  description = "AWS account ID"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "project" {
  type        = string
  default = "crud"
}