# Homelab

> [!INFO]
> This project is currently in Alpha. Core features are under active development.

This repository contains scripts and configurations for setting up and managing a homelab environment.

## Getting Started

Before using this repository, make sure to **fork it first** to your own GitHub account. This ensures you can make changes and keep your own copy of the configurations.

To initiate the Proxmox installation, set the `HOMELAB_INIT` variable to the link of the `init.sh` script and execute it as follows:

```bash
HOMELAB_INIT='https://raw.githubusercontent.com/{YOUR_USERNAME}/homelab/refs/heads/main/proxmox/init.sh' && curl -sSL "$HOMELAB_INIT" | bash
```

This command downloads and runs the `init.sh` script to set up the environment for Proxmox installation.