 //kms encryption for eks secrets in etcd
resource "aws_kms_key" "k8s_encryption" {
  description             = "KMS key for encrypting EKS secrets"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}


//eks
module "eks" {
 // depends_on = [ module.aws-iam-identity-center ]
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = local.name_prefix
  kubernetes_version = "1.33"

  addons = {
    coredns                = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy             = {}
    vpc-cni                = {
      before_compute = true
    }
  }

  encryption_config = {
    provider_key_arn = aws_kms_key.k8s_encryption.arn
    resources        = ["secrets"]
  }
  
  endpoint_public_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    example = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3a.xlarge", "t3.xlarge", "t3a.2xlarge"]

      capacity_type = "SPOT"

      min_size     = 1
      max_size     = 3
      desired_size = 1
    }
  }

  access_entries = {
/*    github = {
      principal_arn = aws_iam_role.github_oidc_provider_aws.arn
    }
*/
    # One access entry with a policy associated
    example = {
      principal_arn = var.iam_user

      policy_associations = {
        example = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }  

  tags = local.common_tags
}



//helm resource for argocd  (installing argocd)
 resource "helm_release" "argocd" {
  depends_on = [ module.eks ]
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.1.4"
  namespace        = "argocd"
  create_namespace = true

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }
      }
    })
  ]  
} 


