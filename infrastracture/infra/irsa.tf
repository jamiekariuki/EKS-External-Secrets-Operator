# eso-sa, running in the "external-secrets" namespace, assumes this role and
# can read exactly one secret: the RDS credentials above. Nothing else.


module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 5.0"

  name = "external-secrets-irsa"

  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = [module.secret_rds_credentials.secret_arn]

  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets-sa"]
    }
  }

  tags = local.common_tags
}

 output "irsa_arn" {
  value = module.external_secrets_irsa.arn
}