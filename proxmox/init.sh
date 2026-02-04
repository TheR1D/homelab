#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Ensure HOMELAB_INIT is set and is a valid URL
if [[ -z "$HOMELAB_INIT" ]]; then
  echo "Error: HOMELAB_INIT variable is not set. Please set it to a valid URL."
  exit 1
fi

# Extract the base URL from HOMELAB_INIT
BASE_URL=$(dirname "$HOMELAB_INIT")

# Define full URLs for the scripts
TERRAFORM_SCRIPT_URL="$BASE_URL/terraform.sh"
TWEAKS_SCRIPT_URL="$BASE_URL/tweaks.sh"

# Execute tweaks.sh
echo "Executing tweaks.sh from $TWEAKS_SCRIPT_URL..."
curl -fsSL "$TWEAKS_SCRIPT_URL" | bash

# Execute terraform.sh
echo "Executing terraform.sh from $TERRAFORM_SCRIPT_URL..."
curl -fsSL "$TERRAFORM_SCRIPT_URL" | bash

echo "Proxmox initialization completed successfully."

