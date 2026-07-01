# ── ECR Repository ─────────────────────────────────────────────
# Shared across dev and prod — created once, never re-created.
# CI pushes "latest" here; both dev and prod ECS pull from this repo.


module "ecr_frontend" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.2.0"

  repository_name = "${var.project}-frontend"

  # MUTABLE — every push overwrites "latest".
  repository_image_tag_mutability = "MUTABLE"

  # Scan every image on push for CVEs.
  repository_image_scan_on_push = true

  # Never force-delete — this repo holds production images.
  repository_force_delete = false

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        # Each push overwrites "latest" and orphans the previous image
        # (it becomes untagged). Clean those up after 1 day.
        rulePriority = 1
        description  = "Delete untagged (superseded) images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      }
    ]
  })

  tags = {
    Project   = var.project
    Terraform = "true"
    ManagedBy = "terraform"
    Shared    = "true"
  }
}


# ── ECR Repository ─────────────────────────────────────────────
# Shared across dev and prod — created once, never re-created.
# CI pushes "latest" here; both dev and prod ECS pull from this repo.


module "ecr_backend" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.2.0"

  repository_name = "${var.project}-backend"

  # MUTABLE — every push overwrites "latest".
  repository_image_tag_mutability = "MUTABLE"

  # Scan every image on push for CVEs.
  repository_image_scan_on_push = true

  # Never force-delete — this repo holds production images.
  repository_force_delete = false

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        # Each push overwrites "latest" and orphans the previous image
        # (it becomes untagged). Clean those up after 1 day.
        rulePriority = 1
        description  = "Delete untagged (superseded) images after 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      }
    ]
  })

  tags = {
    Project   = var.project
    Terraform = "true"
    ManagedBy = "terraform"
    Shared    = "true"
  }
}


output "frontend_repository_url" {
  value = module.ecr_frontend.repository_url
}

output "backend_repository_url" {
  value = module.ecr_backend.repository_url
}