#!/bin/bash
mkfs.ext4 /dev/nvme1n1p6
mkswap /dev/nvme1n1p8
swapon /dev/nvme1n1p8
mount /dev/nvme1n1p6 /mnt
mkdir -p /mnt/{boot/efi,home}
mount /dev/nvme1n1p7 /mnt/home
mount /dev/nvme1n1p1 /mnt/boot/efi

