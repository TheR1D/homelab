#!/bin/bash

# Check required environment variables
# User example: terraform-prov@pve
: "${PROXMOX_USER:?Error: PROXMOX_USER environment variable is not set}"
# Password example: any-password
: "${PROXMOX_USER_PASSWORD:?Error: PROXMOX_USER_PASSWORD environment variable is not set}"
# Token name example: terraform-token
: "${PROXMOX_TOKEN:?Error: PROXMOX_TOKEN environment variable is not set}"

info "Setting up Proxmox VE for Terraform provider usage"
info "Creating Proxmox role 'TerraformProv' with necessary privileges"
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

info "Creating Proxmox user '$PROXMOX_USER' and assigning 'TerraformProv' role"
pveum user add $PROXMOX_USER --password $PROXMOX_USER_PASSWORD

info "Creating API token '$PROXMOX_TOKEN' for user '$PROXMOX_USER'"
TOKEN_OUTPUT=$(pveum user token add $PROXMOX_USER $PROXMOX_TOKEN --privsep 1 --output-format yaml)
TOKEN_SECRET=$(echo "$TOKEN_OUTPUT" | grep '^value:' | awk '{print $2}')

info "Assigning 'TerraformProv' role to user '$PROXMOX_USER' and token '$PROXMOX_TOKEN'"
pveum aclmod / -user $PROXMOX_USER -role TerraformProv
pveum aclmod / -token $PROXMOX_USER!$PROXMOX_TOKEN -role TerraformProv

info "Downloading Ubuntu 24.04 LTS Cloud Init ISO"
wget -P /var/lib/vz/template/iso/ https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img

PROXMOX_IP=$(hostname -I | awk '{print $1}')

cat <<EOF

[Terraform bpg/proxmox provider ENVs]
export PROXMOX_VE_ENDPOINT='https://${PROXMOX_IP}:8006/'
export PROXMOX_VE_API_TOKEN='${PROXMOX_USER}!${PROXMOX_TOKEN}=${TOKEN_SECRET}'
export PROXMOX_VE_INSECURE=true

[ISO images]
Ubuntu 24.04 LTS
wget -P /var/lib/vz/template/iso/ https://releases.ubuntu.com/24.04/ubuntu-24.04.3-live-server-amd64.iso
EOF
