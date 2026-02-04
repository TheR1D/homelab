# Homelab

> [!WARNING]
> Alpha - under active development.

**Goal:** Self-hosted private cloud with VMs, containers, storage, TLS reverse proxy, and APIs that's fully provisioned, easy to replicate, and recoverable from scratch with almost a single command.

### One-command Proxmox setup:
- Adds your SSH key to authorized_keys
- Removes enterprise repos (PVE + Ceph), enables pve-no-subscription
- Removes subscription nag from web UI
- Disables HA services and Corosync (single-node optimization)
- Some tweaks to enable cloud-init VM/LXC deployment
- Creates Terraform user with dedicated role and API token
- Downloads Ubuntu 24.04 cloud-init image
### Terraform VM provisioning:
- Very fast VM deployment using prebuilt cloud-init image
- Prebuilt VM setup for max perfomance (q35, VirtIO SCSI, io_uring, etc.)
- QEMU guest agent enabled to report VM status to Proxmox/Terraform
- Custom cloud-init config upload via snippets
- SSH key injection from local `~/.ssh/proxmox_ssh.pub`
- **Anything you might need is easy to add**
### Pre-configure VM/LXC with cloud-init:
- User creation with sudo, docker, video groups
- SSH hardening (password auth disabled, root disabled), only SSH key allowed.
- Custom $SHELL, $EDITOR, packages, configs, etc.
- Any other configuration can be added/changed via cloud-init

## Quick Start

1. Fork this repo

2. Run on Proxmox server

```bash
curl -O "https://raw.githubusercontent.com/ther1d/homelab/main/proxmox/init.sh" && bash init.sh
```

You'll be prompted for (if not set via environment variables):
- `GITHUB_USERNAME`
- `SSH_PUBLIC_KEY`

Auto-generated/defaulted if not provided:
- `PROXMOX_TERRAFORM_USER` - defaults to `terraform-prov@pve`
- `PROXMOX_TERRAFORM_PASSWORD` - random 32-byte hex
- `PROXMOX_TERRAFORM_TOKEN` - random 32-byte hex

3. Run Terraform from your local machine

After setup completes, it displays export commands. Copy and run them in your local terminal:

```bash
export PROXMOX_VE_ENDPOINT='https://<proxmox-ip>:8006/'
export PROXMOX_VE_API_TOKEN='terraform-prov@pve!terraform-token=<secret>'
export PROXMOX_VE_INSECURE=true
```

Ensure SSH key exists at `~/.ssh/proxmox_ssh.pub`, then:

```bash
cd terraform
terraform init && terraform apply
```
