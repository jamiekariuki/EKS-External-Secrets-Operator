
// Security Group for RDS
module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.ENV_PREFIX}-db-sg"
  description = "PostgreSQL security group"
  vpc_id      = module.vpc.vpc_id  # MUST match DB subnets

  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block 
    }
  ]

  tags = {
    Environment = var.ENV_PREFIX
    Terraform   = "true"
  }
}