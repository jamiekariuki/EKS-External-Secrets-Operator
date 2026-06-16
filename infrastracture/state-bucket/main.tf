# Terraform State bucket Bootstrap 
# This folder is applied ONCE before anything else, in its own pipeline step.
# It creates the S3 bucket and DynamoDB table that the main kobo-terraform
# folder uses as its remote backend.
#
# Apply order:
#   1. cd state-bucket && terraform apply   ← this folder
#   2. cd infrastrucuture && terraform init && terraform apply
#
# IMPORTANT: This folder itself uses local state (no backend block).
# Its own state file is small — just 2 resources — and stored locally or
# committed to the repo. Do not try to store this state in the bucket it creates.

# S3 bucket for Terraform state 
resource "aws_s3_bucket" "state" { 
  bucket        = var.tf_state_bucket
  force_destroy = false # Never allow accidental deletion of state

  tags = {
    Name      = var.tf_state_bucket
    Purpose   = "Terraform remote state"
    ManagedBy = "terraform"
  }
}

# Block all public access 
# State contains passwords, keys, and connection strings in plaintext.
# This must never be publicly readable under any circumstances.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encryption at rest 
# AES-256 SSE-S3 — no extra cost, protects state if someone gains S3 access.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Versioning 
# Critical. If a terraform apply corrupts state, versioning lets you roll back
# to the last known-good version. Without versioning, a corrupted state file
# means manually rebuilding everything.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket ownership 
resource "aws_s3_bucket_ownership_controls" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Enforce HTTPS only 
# Deny any request that does not use TLS. Prevents state being read or written
# over an unencrypted connection.
resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id

  # Must wait for public access block to be applied first
  depends_on = [aws_s3_bucket_public_access_block.state]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${var.tf_state_bucket}",
          "arn:aws:s3:::${var.tf_state_bucket}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "DenyNonAccountAccess"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::${var.tf_state_bucket}",
          "arn:aws:s3:::${var.tf_state_bucket}/*"
        ]
        Condition = {
          StringNotEquals = {
            "aws:PrincipalAccount" = var.aws_account_id
          }
        }
      }
    ]
  })
}

# Lifecycle clean up old state versions 
# Keep the last 90 days of state versions. Beyond that, old versions are
# deleted automatically to prevent unbounded storage growth.
# The current (latest) version is NEVER deleted by this rule.
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  # Must wait for versioning to be enabled first
  depends_on = [aws_s3_bucket_versioning.state]

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# DynamoDB table for state locking
# When two engineers (or two CI jobs) run terraform apply at the same time,
# Terraform writes a lock record here before making any changes.
# The second apply reads the lock and waits. This prevents state corruption
# from concurrent applies.
#
# Pay-per-request billing — stores 1-2 records at a time.
# Cost: ~$0.25/month regardless of team size or apply frequency.
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.tf_lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Protect the lock table from accidental deletion
  deletion_protection_enabled = true

  # Encrypt lock records at rest
  server_side_encryption {
    enabled = true
  }

  tags = {
    Name      = var.tf_lock_table
    Purpose   = "Terraform state locking"
    ManagedBy = "terraform"
  }
}
