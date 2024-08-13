#!/bin/bash
initialpath=$PWD
download_file=archlinux-bootstrap-x86_64.tar.zst
mkdir rootfs
mount -t tmpfs $PWD/rootfs $PWD/rootfs
cd rootfs
if ! [ -e $download_file ]
then
echo "Downloading arch bootstrap ..."
wget https://mirrors.chroot.ro/archlinux/iso/latest/$download_file 1>/dev/null
fi
echo "Extracting archive ..."
tar xf $download_file --numeric-owner 2>&1>/dev/null
mount --bind $PWD/root.x86_64 $PWD/root.x86_64
echo "Copying configuration files ..."
cp $initialpath/configs/pacman.conf root.x86_64/etc
cp $initialpath/configs/mirrorlist root.x86_64/etc/pacman.d
cp $initialpath/create_initramfs.sh root.x86_64/root
echo -e "en_US.UTF-8 UTF-8\nro_RO.UTF-8 UTF-8\n" > root.x86_64/etc/locale.gen
echo -e "LANG=en_US.UTF-8\n" > root.x86_64/etc/locale.conf
echo "LiveLinux" > root.x86_64/etc/hostname
cp /etc/resolv.conf $PWD/root.x86_64/etc
mount --types proc /proc $PWD/root.x86_64/proc

mount --rbind --make-slave /sys $PWD/root.x86_64/sys
#mount --make-rslave $PWD/root.x86_64/sys

mount --rbind --make-slave /dev $PWD/root.x86_64/dev
#mount --make-rslave $PWD/root.x86_64/dev

mount --rbind --make-slave /run $PWD/root.x86_64/run
#mount --make-rslave $PWD/root.x86_64/run

chroot root.x86_64 /bin/bash -c "pacman-key --init"
chroot root.x86_64 /bin/bash -c "pacman-key --populate archlinux"
chroot root.x86_64 /bin/bash -c "ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime"
chroot root.x86_64 /bin/bash -c "locale-gen"
chroot root.x86_64 /bin/bash -c "pacman -Syu linux linux-firmware mkinitcpio cpio zstd bash-completion vim htop acpi acpid lm_sensors fastfetch squashfs-tools mtools dosfstools ntfs-3g wpa_supplicant wireless_tools iwd networkmanager dhcpcd grub efibootmgr os-prober busybox cpio intel-ucode pacman-contrib reflector mc --noconfirm"
chroot root.x86_64 /bin/bash -c "systemctl enable acpid"
chroot root.x86_64 /bin/bash -c "systemctl enable dhcpcd"
chroot root.x86_64 /bin/bash -c "systemctl enable iwd"
chroot root.x86_64 /bin/bash -c "systemctl enable NetworkManager"
chroot root.x86_64 /bin/bash -c "systemctl disable systemd-networkd"

chroot root.x86_64 /bin/bash -c "passwd root"
chroot root.x86_64 /bin/bash -c "/root/create_initramfs.sh"
chroot root.x86_64 /bin/bash -c "yes|pacman -Scc"


cp root.x86_64/initramfs.img $initialpath
cp root.x86_64/boot/vmlinuz-linux $initialpath
cp root.x86_64/boot/intel-ucode.img $initialpath

rm -rf root.x86_64/boot/init* 
rm -rf root.x86_64/boot/vmlinuz* 
rm -rf root.x86_64/boot/intel*
rm -rf root.x86_64/root/create_initramfs.sh
rm -rf root.x86_64/initramfs
rm -rf root.x86_64/initramfs.img

root.x86_64/bin/mksquashfs root.x86_64 $initialpath/rootfs.sfs -wildcards -e  dev/* proc/* sys/* run/*

