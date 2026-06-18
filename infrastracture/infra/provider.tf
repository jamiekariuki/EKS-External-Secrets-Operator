provider "aws" {
  region              = var.region
  allowed_account_ids = [var.aws_account_id]
}

terraform {

  required_version = ">= 1.11.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.34"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.7"
    }
  }
}
