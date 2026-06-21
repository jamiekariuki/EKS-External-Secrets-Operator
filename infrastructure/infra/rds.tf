locals {
  db_username = "crudapp"
  db_name     = "crud"
  db_port     = 5432
}

resource "random_password" "rds" {
  length  = 32
  special = false
}

module "rds_crud" {
  source  = "terraform-aws-modules/rds/aws"
  version = "7.1.0"

  identifier = "${local.name_prefix}-postgres"

  engine         = "postgres"
  engine_version = "14"
  family         = "postgres14"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = local.db_name
  username = local.db_username
  port     = local.db_port

  manage_master_user_password = false
  password_wo                 = random_password.rds.result
  password_wo_version         = 1

  create_db_subnet_group = true
  subnet_ids             = module.vpc.private_subnets
  db_subnet_group_name   = "${local.name_prefix}-postgres"

  vpc_security_group_ids = [module.db_sg.security_group_id]
  publicly_accessible    = false

  parameters = [
    {
      name         = "rds.force_ssl"
      value        = "1"
      apply_method = "pending-reboot"
    }
  ]

  create_db_option_group = false

  multi_az          = false
  availability_zone = "${var.region}a"

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  enabled_cloudwatch_logs_exports        = ["postgresql"]
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 30

  deletion_protection = var.ENV_PREFIX == "prod" ? true : false
  skip_final_snapshot = var.ENV_PREFIX == "prod" ? false : true

  final_snapshot_identifier_prefix = "${local.name_prefix}-final"
  delete_automated_backups         = false

  tags = local.common_tags
}

output "rds_endpoint" {
  description = "RDS hostname"
  value       = module.rds_kobo.db_instance_address
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds_kobo.db_instance_port
}