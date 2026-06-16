output "state_bucket_name" {
  description = "S3 bucket name used for backend.tf in the main infra"
  value       = aws_s3_bucket.state.id
}

/* output "state_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.state.arn
} */

/* output "lock_table_name" {
  description = "DynamoDB table name — copy this into the main infrastracture backend.tf"
  value       = aws_dynamodb_table.terraform_locks.name
} */

/* output "backend_config" {
  description = "Paste this block into infrastracture/backend.tf after running this bootstrap"
  value       = <<-EOT

    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.state.id}"
        key            = "key name"
        region         = "${var.region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
        encrypt        = true
      }
    }
  EOT
} */
