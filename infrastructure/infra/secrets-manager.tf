# Single secret holding everything an app needs to connect to RDS.
# ESO syncs this whole JSON blob into a Kubernetes Secret — see eso.tf.

module "secret_rds_credentials" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name                    = "${local.name_prefix}/rds/credentials"
  description             = "RDS connection credentials for ${local.name_prefix}"
  recovery_window_in_days = var.ENV_PREFIX == "prod" ? 30 : 0

  secret_string = jsonencode({
    username     = local.db_username
    password     = random_password.rds.result
    host         = module.rds_crud.db_instance_address
    port         = local.db_port
    dbname       = local.db_name
    engine       = "postgres"
    database_url = "postgresql://${local.db_username}:${random_password.rds.result}@${module.rds_crud.db_instance_address}:${local.db_port}/${local.db_name}"
  })

  ignore_secret_changes = false
  tags                   = local.common_tags
}

output "rds_secret_arn" {
  value     = module.secret_rds_credentials.secret_arn
  sensitive = false # the ARN itself isn't sensitive, the value inside it is
}