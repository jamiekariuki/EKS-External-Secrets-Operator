variable "aws_account_id" {
  type = string
}

variable "region" {
  type = string
}



variable "project" {
  type = string
}


//database
variable "db_username" {
  type = string
  sensitive = true
}

variable "db_name" {
  type = string
  sensitive = true
}



variable "ENV_PREFIX" {
    type = string

    validation {
      condition = contains(["dev", "stage", "prod"], var.ENV_PREFIX)
      error_message = "provide an environment"
    }

    default = "dev"
}