 #!/bin/bash
set -e

# INPUTS
SERVICE_ACCOUNT_NAME="$1"
IRSA_ARN="$2"
HELM_CHART_PATH="$3"

echo "Service account name: $SERVICE_ACCOUNT_NAME"
echo "irsa arn: $IRSA_ARN"
echo "Helm Chart Path: $HELM_CHART_PATH"

if [ -z "$SERVICE_ACCOUNT_NAME" ] || [ -z "$IRSA_ARN" ]  || [ -z "$HELM_CHART_PATH" ] ; then
  echo "ERROR: Missing required arguments."
  exit 1
fi

#1. Ensure yq is available 
if ! command -v yq &> /dev/null
then
    echo "Installing yq..."
    sudo wget -q https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_amd64 -O /usr/bin/yq
    sudo chmod +x /usr/bin/yq
fi

echo "Updating $HELM_CHART_PATH..."

#2. Update values dynamically 

#updating service account name
yq -i ".esoCrd.serviceAccount.name = \"$SERVICE_ACCOUNT_NAME\"" "$HELM_CHART_PATH"
#service account role-arn
yq -i ".esoCrd.serviceAccount.irsaArn = \"$IRSA_ARN\"" "$HELM_CHART_PATH"

#yq -i  '.serviceAccount.annotations["eks.amazonaws.com/role-arn"] = "'"$IRSA_ARN"'"'  "$HELM_CHART_PATH"


#3. Commit & Push
git config --global user.email "jamiekariuki18@gmail.com"
git config --global user.name "bot2" #diffent name from  update helm 

git add .

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "update service account"

  echo "Syncing with remote main before pushing..."
  git pull --rebase origin main

  git push
fi

