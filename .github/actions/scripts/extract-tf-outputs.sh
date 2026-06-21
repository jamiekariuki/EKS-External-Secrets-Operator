#!/bin/bash
# extract-tf-outputs.sh
# Fetches Terraform state from S3 and exports all outputs to GITHUB_ENV.
#
# Usage:
#   extract-tf-outputs.sh <bucket> <environment> <state-key>
#
# Args:
#   bucket       — S3 bucket name (TF_STATE_BUCKET)
#   environment  — workspace name, e.g. dev, stage, prod
#   state-key    — path within the bucket, e.g. infra/terraform.tfstate
#
# Exports to GITHUB_ENV:
#   IRSA_ARN, SECRETS_MANAGER_ARN, DB_INSTANCE_ADDRESS,
#   DB_INSTANCE_NAME, DB_INSTANCE_PORT, FRONTEND_REPO_URL, BACKEND_REPO_URL

set -euo pipefail

BUCKET="$1"
ENVIRONMENT="$2"
STATE_KEY="$3"

S3_PATH="s3://${BUCKET}/env:/${ENVIRONMENT}/${STATE_KEY}"
TMPSTATE=$(mktemp)
OUTFILE=$(mktemp)

cleanup() { rm -f "$TMPSTATE" "$OUTFILE"; }
trap cleanup EXIT

# ── Fetch state ───────────────────────────────────────────────────────────────
echo "Fetching state: ${S3_PATH}"
aws s3 cp "$S3_PATH" "$TMPSTATE"

# ── Extract outputs ───────────────────────────────────────────────────────────
echo "Extracting outputs..."
jq '{
  irsa_arn:                .outputs.irsa_arn.value,
  secrets_manager_arn:     .outputs.SecretsManager_arn.value,
  db_instance_address:     .outputs.db_instance_address.value,
  db_instance_name:        .outputs.db_instance_name.value,
  db_instance_port:        (.outputs.db_instance_port.value | tostring),
  frontend_repository_url: .outputs.frontend_repository_url.value,
  backend_repository_url:  .outputs.backend_repository_url.value
}' "$TMPSTATE" > "$OUTFILE"

echo "Extracted outputs:"
cat "$OUTFILE"

# ── Export to GITHUB_ENV ──────────────────────────────────────────────────────
echo "Exporting to GITHUB_ENV..."
{
  echo "IRSA_ARN=$(jq -r .irsa_arn "$OUTFILE")"
  echo "SECRETS_MANAGER_ARN=$(jq -r .secrets_manager_arn "$OUTFILE")"
  echo "DB_INSTANCE_ADDRESS=$(jq -r .db_instance_address "$OUTFILE")"
  echo "DB_INSTANCE_NAME=$(jq -r .db_instance_name "$OUTFILE")"
  echo "DB_INSTANCE_PORT=$(jq -r .db_instance_port "$OUTFILE")"
  echo "FRONTEND_REPO_URL=$(jq -r .frontend_repository_url "$OUTFILE")"
  echo "BACKEND_REPO_URL=$(jq -r .backend_repository_url "$OUTFILE")"
} >> "$GITHUB_ENV"

echo "Done."
