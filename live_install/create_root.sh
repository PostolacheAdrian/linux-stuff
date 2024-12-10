#!/bin/bash
mkdir rootfs
mkdir /home/live-install
mount -t tmpfs rootfs/ rootfs/
pacstrap -K -i rootfs base base-devel linux-cachyos linux-firmware linux-firmware-whence intel-ucode pacman cpio zstd cachyos-keyring cachyos-mirrorlist cachyos-v3-mirrorlist cachyos-rate-mirrors cachyos-hooks cachyos-settings pacman-contrib
cp create_initramfs.sh rootfs/root
echo -e "en_US.UTF-8 UTF-8\nro_RO.UTF-8 UTF-8\n" > rootfs/etc/locale.gen
echo -e "LANG=en_US.UTF-8\n" > rootfs/etc/locale.conf
echo "LiveLinux" > rootfs/etc/hostname
cp /etc/resolv.conf rootfs/etc
arch-chroot rootfs /bin/bash -c "cachyos-rate-mirrors"
arch-chroot rootfs /bin/bash -c "pacman -Syu"
#arch-chroot rootfs /bin/bash -c "pacman -Syu cachyos-cli-installer-new bash-completion vim mc htop acpi acpid lm_sensors fastfetch squashfs-tools mtools dosfstools ntfs-3g wireless_tools iwd networkmanager dhcpcd grub efibootmgr os-prober busybox"
#arch-chroot rootfs /bin/bash -c "systemctl enable acpid"
#arch-chroot rootfs /bin/bash -c "systemctl enable dhcpcd"
#arch-chroot rootfs /bin/bash -c "systemctl enable NetworkManager"
#arch-chroot rootfs /bin/bash -c "systemctl disable systemd-networkd"
#arch-chroot rootfs /bin/bash -c "systemctl enable systemd-timesyncd"
#arch-chroot rootfs /bin/bash -c "passwd"
#arch-chroot rootfs /bin/bash -c "/root/create_initramfs.sh"
#arch-chroot rootfs /bin/bash -c "yes | pacman -Scc"
#mv rootfs/initramfs.img /home/live-install
#mv rootfs/boot/intel-ucode.img /home/live-install
#mv rootfs/boot/vmlinuz-linux-cachyos /home/live-install/

#rm -rf rootfs/initramfs
#rm -rf rootfs/root/create_initramfs.sh

#rootfs/bin/mksquashfs rootfs /home/live-install/rootfs.sfs


