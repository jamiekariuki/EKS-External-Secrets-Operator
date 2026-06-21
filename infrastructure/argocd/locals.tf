locals {
  name_prefix = "${var.project}-${var.ENV_PREFIX}"

  common_tags = {
    Project     = var.project
    Environment = var.ENV_PREFIX
    Terraform   = "true"
    ManagedBy   = "terraform"
  }
}  