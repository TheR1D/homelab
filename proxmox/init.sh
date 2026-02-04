#!/bin/bash
set -e

if [[ -z "$GITHUB_USERNAME" ]]; then
    read -p "GitHub username: " GITHUB_USERNAME
fi

if [[ -z "$PROXMOX_TERRAFORM_USER" ]]; then
    PROXMOX_TERRAFORM_USER="terraform-prov@pve"
fi
echo "PROXMOX_TERRAFORM_USER: $PROXMOX_TERRAFORM_USER"

# Note that Proxmox requires first character to be a letter.
if [[ -z "$PROXMOX_TERRAFORM_PASSWORD" ]]; then
    PROXMOX_TERRAFORM_PASSWORD="a-$(openssl rand -hex 8)"
    echo "Generated PROXMOX_TERRAFORM_PASSWORD: $PROXMOX_TERRAFORM_PASSWORD"
fi

# Note that Proxmox requires first character to be a letter.
if [[ -z "$PROXMOX_TERRAFORM_TOKEN" ]]; then
    PROXMOX_TERRAFORM_TOKEN="a-$(openssl rand -hex 8)"
    echo "Generated PROXMOX_TERRAFORM_TOKEN: $PROXMOX_TERRAFORM_TOKEN"
fi

if [[ -z "$SSH_PUBLIC_KEY" ]]; then
    read -p "SSH public key: " SSH_PUBLIC_KEY
fi

export PROXMOX_TERRAFORM_USER PROXMOX_TERRAFORM_PASSWORD PROXMOX_TERRAFORM_TOKEN

echo "$SSH_PUBLIC_KEY" >> ~/.ssh/authorized_keys
echo "SSH public key added"

cat <<'EOF'

IMPORTANT: Make sure the same SSH public key exists at ~/.ssh/proxmox_ssh.pub on your local machine for Terraform access.

EOF

BASE_URL="https://raw.githubusercontent.com/$GITHUB_USERNAME/homelab/refs/heads/main/proxmox"
TERRAFORM_SCRIPT_URL="$BASE_URL/terraform.sh"
TWEAKS_SCRIPT_URL="$BASE_URL/tweaks.sh"

echo "Executing tweaks.sh..."
curl -fsSL "$TWEAKS_SCRIPT_URL" | bash

echo "Executing terraform.sh..."
curl -fsSL "$TERRAFORM_SCRIPT_URL" | bash

echo "Proxmox initialization completed."

