# ── ECR Repository ─────────────────────────────────────────────
# Shared across dev and prod — created once, never re-created.
# CI pushes tagged images here; both dev and prod ECS pull from this repo.


module "ecr_frontend" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.2.0"


  repository_name = "${var.project}-frontend"

  # MUTABLE — allows pushing new version tags and updating "latest".
  repository_image_tag_mutability = "MUTABLE"

  # Scan every image on push for CVEs.
  repository_image_scan_on_push = true

  # Never force-delete — this repo holds production images.
  repository_force_delete = false

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        # Keep last 30 tagged releases — covers multiple sprints of rollback history.
        rulePriority = 1
        description  = "Keep last 30 tagged releases for rollback"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest", "sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = { type = "expire" }
      },
      {
        # Untagged images are failed CI build artifacts — delete after 1 day.
        rulePriority = 2
        description  = "Delete untagged build artifacts after 1 day"
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
# CI pushes tagged images here; both dev and prod ECS pull from this repo.


module "ecr_backend" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.2.0"


  repository_name = "${var.project}-backend"

  # MUTABLE — allows pushing new version tags and updating "latest".
  repository_image_tag_mutability = "MUTABLE"

  # Scan every image on push for CVEs.
  repository_image_scan_on_push = true

  # Never force-delete — this repo holds production images.
  repository_force_delete = false

  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        # Keep last 30 tagged releases — covers multiple sprints of rollback history.
        rulePriority = 1
        description  = "Keep last 30 tagged releases for rollback"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "latest", "sha-"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = { type = "expire" }
      },
      {
        # Untagged images are failed CI build artifacts — delete after 1 day.
        rulePriority = 2
        description  = "Delete untagged build artifacts after 1 day"
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