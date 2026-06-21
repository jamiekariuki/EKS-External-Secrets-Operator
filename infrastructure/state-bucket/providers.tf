terraform {
  # No backend block here this folder uses local state intentionally.
  # Storing bootstrap state in the bucket it creates would be circular.
  # The state file for this folder is tiny (2 resources) and safe to keep locally.

  required_version = ">= 1.11.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.34"
    }
  }
}

provider "aws" {
  region              = var.region
  allowed_account_ids = [var.aws_account_id]
}
