#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Running terraform apply..."
terraform -chdir="$SCRIPT_DIR" apply -auto-approve

echo "==> Updating GitHub secrets..."
cd "$SCRIPT_DIR"
bash update-secrets.sh

echo "==> Infrastructure ready and secrets updated."
