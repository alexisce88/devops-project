#!/bin/bash
set -e

REPO="alexisce88/devops-project"
KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/devops-capstone.pem}"
TFVARS="$(dirname "$0")/terraform.tfvars"

echo "Reading Terraform outputs..."
STAGING_IP=$(terraform output -raw staging_public_ip)
PRODUCTION_IP=$(terraform output -raw production_public_ip)

echo "Updating GitHub secrets for $REPO..."
gh secret set STAGING_IP --body "$STAGING_IP" -R "$REPO"
gh secret set PRODUCTION_IP --body "$PRODUCTION_IP" -R "$REPO"

if [ -f "$KEY_PATH" ]; then
  gh secret set SSH_PRIVATE_KEY < "$KEY_PATH" -R "$REPO"
  echo "  SSH_PRIVATE_KEY -> $KEY_PATH"
else
  echo "WARNING: SSH key not found at $KEY_PATH — SSH_PRIVATE_KEY not updated."
  echo "  Set SSH_KEY_PATH=/path/to/your.pem and re-run to update it."
fi

if [ -f "$TFVARS" ]; then
  DB_PASSWORD=$(grep 'db_password' "$TFVARS" | sed 's/.*=\s*"\(.*\)"/\1/')
  if [ -n "$DB_PASSWORD" ]; then
    gh secret set DB_PASSWORD --body "$DB_PASSWORD" -R "$REPO"
    echo "  DB_PASSWORD     -> (from terraform.tfvars)"
  else
    echo "WARNING: db_password not found in terraform.tfvars — DB_PASSWORD not updated."
  fi
else
  echo "WARNING: terraform.tfvars not found — DB_PASSWORD not updated."
fi

echo "Done."
echo "  STAGING_IP    -> $STAGING_IP"
echo "  PRODUCTION_IP -> $PRODUCTION_IP"
