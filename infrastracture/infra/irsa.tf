//iam policy for allowing read access to secrets from secret manager
module "iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "read-secretes-iam"
  path        = "/"
  description = "iam policy for allowing access to secrets from secret manager"

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:ListSecrets"
          ],
          "Effect": "Allow",
          "Resource": "${module.db.db_instance_master_user_secret_arn}"
        }
      ]
    }
  EOF

  tags = {
    Environment = var.ENV_PREFIX
    Terraform   = "true"
  }
}

// iam role for service account (irsa) for eso
module "external_secrets_irsa" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"

  name = "external-secrets-irsa"

  attach_external_secrets_policy        = false
  external_secrets_secrets_manager_arns = ["${module.db.db_instance_master_user_secret_arn}"]
 
  oidc_providers = {
    this = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:eso-sa}"] 
    }
  }

  policies = {
    additional = module.iam_policy.arn
  }
  
} 
  