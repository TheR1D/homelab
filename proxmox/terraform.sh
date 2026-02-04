#!/bin/bash

# Check required environment variables
# User example: terraform-prov@pve
: "${PROXMOX_TERRAFORM_USER:?Error: PROXMOX_TERRAFORM_USER environment variable is not set}"
# Password example: any-password
: "${PROXMOX_TERRAFORM_PASSWORD:?Error: PROXMOX_TERRAFORM_PASSWORD environment variable is not set}"
# Token name example: terraform-token
: "${PROXMOX_TERRAFORM_TOKEN:?Error: PROXMOX_TERRAFORM_TOKEN environment variable is not set}"

echo "Setting up Proxmox VE for Terraform provider usage"
echo "Creating Proxmox role 'TerraformProv' with necessary privileges"
pveum role add TerraformProv -privs \
    "Datastore.AllocateSpace \
    Datastore.Allocate \
    Datastore.AllocateTemplate \
    Datastore.Audit \
    Pool.Allocate \
    Sys.Audit \
    Sys.Console \
    Sys.Modify \
    VM.Allocate \
    VM.Audit \
    VM.Clone \
    VM.Config.CDROM \
    VM.Config.Cloudinit \
    VM.Config.CPU \
    VM.Config.Disk \
    VM.Config.HWType \
    VM.Config.Memory \
    VM.Config.Network \
    VM.Config.Options \
    VM.Migrate \
    VM.PowerMgmt \
    VM.GuestAgent.Audit \
    VM.GuestAgent.Unrestricted \
    SDN.Use"

echo "Creating Proxmox user '$PROXMOX_TERRAFORM_USER' and assigning 'TerraformProv' role"
pveum user add $PROXMOX_TERRAFORM_USER --password $PROXMOX_TERRAFORM_PASSWORD

echo "Creating API token '$PROXMOX_TERRAFORM_TOKEN' for user '$PROXMOX_TERRAFORM_USER'"
TOKEN_OUTPUT=$(pveum user token add $PROXMOX_TERRAFORM_USER $PROXMOX_TERRAFORM_TOKEN --privsep 1 --output-format yaml)
TOKEN_SECRET=$(echo "$TOKEN_OUTPUT" | grep '^value:' | awk '{print $2}')

echo "Assigning 'TerraformProv' role to user '$PROXMOX_TERRAFORM_USER' and token '$PROXMOX_TERRAFORM_TOKEN'"
pveum aclmod / -user $PROXMOX_TERRAFORM_USER -role TerraformProv
pveum aclmod / -token $PROXMOX_TERRAFORM_USER!$PROXMOX_TERRAFORM_TOKEN -role TerraformProv

echo "Downloading Ubuntu 24.04 LTS Cloud Init ISO"
wget -P /var/lib/vz/template/iso/ https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

PROXMOX_IP=$(hostname -I | awk '{print $1}')

cat <<EOF

Terraform bpg/proxmox Provider Configuration
Copy and paste these commands on your local machine:
export PROXMOX_VE_ENDPOINT='https://${PROXMOX_IP}:8006/'
export PROXMOX_VE_API_TOKEN='${PROXMOX_TERRAFORM_USER}!${PROXMOX_TERRAFORM_TOKEN}=${TOKEN_SECRET}'
export PROXMOX_VE_INSECURE=true

Ubuntu 24.04 LTS Live Server:
wget -P /var/lib/vz/template/iso/ https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso
EOF
