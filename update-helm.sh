#!/bin/bash
# update-helm.sh
# Updates Helm chart values with Terraform outputs, then commits and pushes.
# Helm charts live in ./charts inside this same repo — no second checkout needed.
#
# Usage:
#   update-helm.sh <environment> <region> <irsa_arn> <secrets_manager_arn> \
#                  <db_address> <db_name> <db_port> \
#                  <frontend_repo_url> <backend_repo_url> \
#                  <service_account_name> <charts_dir>
#
# Args:
#   environment          — dev, stage, prod
#   region               — AWS region
#   irsa_arn             — IRSA role ARN for ESO service account
#   secrets_manager_arn  — Secrets Manager secret ARN
#   db_address           — RDS instance endpoint
#   db_name              — RDS database name
#   db_port              — RDS port
#   frontend_repo_url    — ECR URL for frontend image
#   backend_repo_url     — ECR URL for backend image
#   service_account_name — Kubernetes service account name
#   charts_dir           — path to charts directory, e.g. ./charts

set -euo pipefail

ENVIRONMENT="$1"
REGION="$2"
IRSA_ARN="$3"
SECRETS_MANAGER_ARN="$4"
DB_ADDRESS="$5"
DB_NAME="$6"
DB_PORT="$7"
FRONTEND_REPO_URL="$8"
BACKEND_REPO_URL="$9"
SERVICE_ACCOUNT_NAME="${10}"
CHARTS_DIR="${11}"

# ── Validate ──────────────────────────────────────────────────────────────────
for var in ENVIRONMENT REGION IRSA_ARN SECRETS_MANAGER_ARN \
           DB_ADDRESS DB_NAME DB_PORT \
           FRONTEND_REPO_URL BACKEND_REPO_URL \
           SERVICE_ACCOUNT_NAME CHARTS_DIR; do
  if [ -z "${!var}" ]; then
    echo "ERROR: Missing required argument: ${var}"
    exit 1
  fi
done

# Values file — adjust the path to match your charts layout if needed
# Current assumption: ./charts/environments/<env>/values.yaml
VALUES_FILE="${CHARTS_DIR}/environments/${ENVIRONMENT}/values.yaml"

if [ ! -f "$VALUES_FILE" ]; then
  echo "ERROR: Values file not found: ${VALUES_FILE}"
  exit 1
fi

# ── Ensure yq is available ────────────────────────────────────────────────────
if ! command -v yq &> /dev/null; then
  echo "Installing yq..."
  sudo wget -q https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_amd64 \
    -O /usr/bin/yq
  sudo chmod +x /usr/bin/yq
fi

# ── Apply all updates atomically ──────────────────────────────────────────────
echo "Updating values: ${VALUES_FILE}"

yq -i "
  .global.region                        = \"${REGION}\" |
  .global.environment                   = \"${ENVIRONMENT}\" |
  .esoCrd.serviceAccount.name           = \"${SERVICE_ACCOUNT_NAME}\" |
  .esoCrd.serviceAccount.irsaArn        = \"${IRSA_ARN}\" |
  .esoCrd.secretsManagerArn             = \"${SECRETS_MANAGER_ARN}\" |
  .database.host                        = \"${DB_ADDRESS}\" |
  .database.name                        = \"${DB_NAME}\" |
  .database.port                        = ${DB_PORT} |
  .frontend.image.repository            = \"${FRONTEND_REPO_URL}\" |
  .backend.image.repository             = \"${BACKEND_REPO_URL}\"
" "$VALUES_FILE"

echo "Values updated."

# ── Commit & push ─────────────────────────────────────────────────────────────
# Git operations run from the repo root (wherever the script was invoked from).
# We stage only the charts dir to avoid accidentally committing anything else.

git config --global user.email "ci-bot@github-actions"
git config --global user.name  "CI Bot"

git add "$CHARTS_DIR"

if git diff --cached --quiet; then
  echo "No changes to commit — values already up to date."
  exit 0
fi

git commit -m "chore(${ENVIRONMENT}): sync terraform outputs [skip ci]"

echo "Pulling latest before push..."
git pull --rebase origin main

git push origin main
echo "Helm values pushed successfully."
