variable "aws_account_id" {
  type        = string
  description = "AWS account ID used to restrict bucket access to this account only"
}

variable "region" {
  type        = string
  description = "AWS region where the state bucket and lock table will be created"
}

variable "tf_state_bucket" {
  type        = string
  description = "S3 bucket name for Terraform remote state. Must be globally unique."
}

variable "tf_lock_table" {
  type        = string
  description = "DynamoDB table name for Terraform state locking"
}
