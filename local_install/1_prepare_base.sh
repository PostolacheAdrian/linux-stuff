#!/bin/bash
pacman -Syy
pacstrap /mnt base base-devel linux linux-firmware intel-ucode vim bash-completion
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
