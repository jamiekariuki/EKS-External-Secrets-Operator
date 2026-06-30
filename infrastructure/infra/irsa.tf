# Namespace for ESO (skip this resource if it already exists / is managed elsewhere)
resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = "external-secrets"
  }
}

# The actual k8s ServiceAccount that ESO's pod will use.
# The annotation is what lets EKS's webhook inject the IRSA credentials
# (AWS_ROLE_ARN + AWS_WEB_IDENTITY_TOKEN_FILE) into the pod.
resource "kubernetes_service_account" "external_secrets" {
  metadata {
    name      = "external-secrets-sa"
    namespace = kubernetes_namespace.external_secrets.metadata[0].name

    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_secrets_irsa.arn
    }
  }
}

module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.6.1"

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