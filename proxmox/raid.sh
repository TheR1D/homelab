#!/bin/bash
# Reattach RAID (for my personal setup)
apt install -y mdadm
mdadm --assemble --scan
cat /proc/mdstat
mdadm --detail --scan > /etc/mdadm/mdadm.conf
update-initramfs -u
mkdir -p /mnt/storage
mount /dev/md0 /mnt/storage

# Add storage to Proxmox
pvesm add dir storage \
  --path /mnt/storage \
  --content images,backup \
  --nodes proxmox