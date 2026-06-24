variable "aws_account_id" {
  type = string
}

variable "region" {
  type = string
}

variable "project" {
  type = string
  default = "crud"
}

variable "iam_user" {
  type = string
}

variable "ENV_PREFIX" {
    type = string

    validation {
      condition = contains(["dev", "stage", "prod"], var.ENV_PREFIX)
      error_message = "provide an environment"
    }

    default = "dev"
}