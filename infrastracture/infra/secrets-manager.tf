module "secret_rds_password" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name                    = "${local.name_prefix}/rds/password"
  description             = "RDS master password"
  recovery_window_in_days = var.ENV_PREFIX == "prod" ? 30 : 0
  secret_string           = random_password.rds.result
  ignore_secret_changes   = false
  tags                    = local.common_tags
}