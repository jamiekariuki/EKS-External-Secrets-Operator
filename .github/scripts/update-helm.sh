#!/bin/bash
# update-helm.sh
# Updates each Helm chart's values file with Terraform outputs, then commits and pushes.
#
# Charts updated (each independently):
#   frontend  — region, environment, image repository
#   backend   — region, environment, image repository
#   eso       — IRSA ARN for the ESO service account
#
# Usage:
#   update-helm.sh <environment> <region> <irsa_arn> \
#                  <frontend_repo_url> <backend_repo_url> \
#                  <charts_dir>
#
# Args:
#   $1  environment        — dev, stage, prod
#   $2  region             — AWS region
#   $3  irsa_arn           — IRSA role ARN for ESO service account
#   $4  frontend_repo_url  — ECR URL for frontend image
#   $5  backend_repo_url   — ECR URL for backend image
#   $6  charts_dir         — path to charts directory, e.g. ./charts

set -euo pipefail

ENVIRONMENT="$1"
REGION="$2"
IRSA_ARN="$3"
FRONTEND_REPO_URL="$4"
BACKEND_REPO_URL="$5"
CHARTS_DIR="$6"

# ── Validate args ─────────────────────────────────────────────────────────────
for var in ENVIRONMENT REGION IRSA_ARN FRONTEND_REPO_URL BACKEND_REPO_URL CHARTS_DIR; do
  if [ -z "${!var}" ]; then
    echo "ERROR: Missing required argument: ${var}"
    exit 1
  fi
done

# ── Resolve values file paths ─────────────────────────────────────────────────
# Adjust these paths to match your actual chart layout.
FRONTEND_VALUES="${CHARTS_DIR}/frontend/values.yaml"
BACKEND_VALUES="${CHARTS_DIR}/backend/values.yaml"
ESO_VALUES="${CHARTS_DIR}/eso/values.yaml"

for file in "$FRONTEND_VALUES" "$BACKEND_VALUES" "$ESO_VALUES"; do
  if [ ! -f "$file" ]; then
    echo "ERROR: Values file not found: ${file}"
    exit 1
  fi
done

# ── Ensure yq is available ────────────────────────────────────────────────────
if ! command -v yq &> /dev/null; then
  echo "Installing yq..."
  sudo wget -q https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_amd64 \
    -O /usr/bin/yq
  sudo chmod +x /usr/bin/yq
fi

# ── Frontend chart ────────────────────────────────────────────────────────────
echo "Updating frontend values: ${FRONTEND_VALUES}"
yq -i "

  .image.repository          = \"${FRONTEND_REPO_URL}\"
" "$FRONTEND_VALUES"

# ── Backend chart ─────────────────────────────────────────────────────────────
echo "Updating backend values: ${BACKEND_VALUES}"
yq -i "

  .image.repository          = \"${BACKEND_REPO_URL}\"
" "$BACKEND_VALUES"

# ── ESO chart ─────────────────────────────────────────────────────────────────
echo "Updating ESO values: ${ESO_VALUES}"
yq -i "
  .serviceAccount.annotations[\"eks.amazonaws.com/role-arn\"] = \"${IRSA_ARN}\"
" "$ESO_VALUES"

echo "All chart values updated."

# ── Commit & push ─────────────────────────────────────────────────────────────
# Stage only the charts directory — nothing else in the repo gets touched.

git config --global user.email "ci-bot@github-actions"
git config --global user.name  "CI Bot"

git add "$CHARTS_DIR"

if git diff --cached --quiet; then
  echo "No changes to commit — all values already up to date."
  exit 0
fi

git commit -m "chore(${ENVIRONMENT}): sync terraform outputs [skip ci]"

# Discard any remaining unstaged changes before rebasing.
# The runner working tree may have dirty files from earlier pipeline steps
# (ci-secrets.tfvars, plan outputs, etc.) that were never meant to be committed.
# Our helm changes are already committed above so discarding the rest is safe.
echo "Cleaning working tree before sync..."
git restore . 2>/dev/null || true

echo "Syncing with remote before push..."
git fetch origin main
git rebase origin/main

git push origin main
echo "Helm values pushed successfully."