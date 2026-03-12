#!/bin/bash
set -Eeuo pipefail
#check if there is root privilege
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
        exit 1
fi

if [[ $# -lt 2 ]]; then
        echo -e "Error: Parameters are missing:\n\1. Storage type: tmpfs or local\n\t Destination path: eg. /home/user/image_folder." >&2
        exit 1
else
        if [[ "$1" == "local" || "$1" == "tmpfs" ]]; then
                destination="$1"
                destinationPath=$2
        else
                echo -e "Error:\n\t\"$1\" is a bad argument\n\tUse tmpfs or local" >&2
                exit 1
        fi
fi
rootFsPath=$destinationPath/rootfs
user_pass="\\\$6\\\$tQk2hzssD/a0tbe1\\\$bEnhqTMyzyhBJdRPKEUrku0iMFLSwMbpoGqU5vE07d7Toe37JYqAgzxRsTtOc1RNEWMvHmzutR7m22OlZA/ao/"
download_file=archlinux-bootstrap-x86_64.tar.zst
cleanup(){
        
        if [[ "$destination" == "tmpfs" ]];then
                umount -R -q $destinationPath/*
                rm -rf $destinationPath
        else
                if [[ "$destination" == "local" ]];then
                        umount -R -q $rootFsPath
                        rm -rf $destinationPath
                fi
        fi
}
error_handler() {
        echo "Script failed !" >&2
        echo "Error: $1" >&2
        echo "Line $2" >&2
        echo "Command: $3" >&2
        cleanup
}

trap 'error_handler $? $LINENO "$BASH_COMMAND"' ERR

if [ -d $destinationPath ] 
then
echo "$destinationPath already exists."
echo "Removing $destinationPath"
rm -rf $destinationPath
fi
echo "Creating directory $destinationPath/image"
mkdir -p $destinationPath/image
echo "Creating directory $destinationPath/boot"
mkdir -p $destinationPath/boot
echo "Creating directory $rootFsPath"
mkdir -p $rootFsPath
echo "Mounting $rootFsPath as tmpfs"
mount -t tmpfs $rootFsPath $rootFsPath
if [[ "$destination" == "tmpfs" ]];then
mount -t tmpfs $destinationPath/image $destinationPath/image
mount -t tmpfs $destinationPath/boot $destinationPath/boot
fi
echo "Downloading arch bootstrap ..."
curl https://fastly.mirror.pkgbuild.com/iso/2026.02.01/archlinux-bootstrap-x86_64.tar.zst -o $rootFsPath/$download_file

echo "Extracting archive ..."
tar xf $rootFsPath/$download_file --numeric-owner 2>&1>/dev/null --directory $rootFsPath
mount --bind $rootFsPath/root.x86_64 $rootFsPath/root.x86_64
echo "Copying configuration files ..."
cp create_initramfs.sh $rootFsPath/root.x86_64/root
echo -e "en_US.UTF-8 UTF-8\nro_RO.UTF-8 UTF-8\n" > $rootFsPath/root.x86_64/etc/locale.gen
echo -e "LANG=en_US.UTF-8\nLC_ALL=C\n" > $rootFsPath/root.x86_64/etc/locale.conf
echo "Linux" > $rootFsPath/root.x86_64/etc/hostname
cp /etc/resolv.conf $rootFsPath/root.x86_64/etc
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "locale-gen"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "hwclock --systohc"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "timedatectl set-ntp true"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman-key --init"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman-key --populate"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "sed -i 's/^#\[multilib\]/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist\n/' /etc/pacman.conf"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "mkdir -p /etc/pacman.d/hooks"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "ln -sf /dev/null /etc/pacman.d/hooks/60-mkinicpio-remove.hook"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "ln -sf /dev/null /etc/pacman.d/hooks/90-mkinicpio-install.hook"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman -Syy"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "yes|pacman -Syu base linux linux-firmware sudo intel-ucode pacman-contrib archinstall arch-install-scripts squashfs-tools limine grub efivar efibootmgr vim mc htop acpid acpi lm_sensors fastfetch git mtools dosfstools ntfs-3g wireless_tools iwd networkmanager dhcpcd busybox cpio mkinitcpio mkinitcpio-utils curl wget whois"
systemctl --root $rootFsPath/root.x86_64 enable acpid
systemctl --root $rootFsPath/root.x86_64 enable dhcpcd
systemctl --root $rootFsPath/root.x86_64 enable NetworkManager
systemctl --root $rootFsPath/root.x86_64 enable systemd-timesyncd
systemctl --root $rootFsPath/root.x86_64 mask systemd-networkd.service
systemctl --root $rootFsPath/root.x86_64 mask systemd-homed.service
systemctl --root $rootFsPath/root.x86_64 mask systemd-userdbd.service
systemctl --root $rootFsPath/root.x86_64 mask systemd-userdbd.socket
systemctl --root $rootFsPath/root.x86_64 mask systemd-nsresourced.service
systemctl --root $rootFsPath/root.x86_64 mask systemd-nsresourced.socket
sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' $rootFsPath/root.x86_64/etc/sudoers
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "useradd -m -G wheel live"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "usermod -p \"$user_pass\" live"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "usermod -p \"$user_pass\" root"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "./root/create_initramfs.sh"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "yes|pacman -Scc"
sed -i "/ExecStart=/s/=.*/=-\/sbin\/agetty --skip-login --noclear --nonewline --noissue --autologin live %I \$TERM/" $rootFsPath/root.x86_64/usr/lib/systemd/system/getty@.service
mv $rootFsPath/root.x86_64/initramfs.img $destinationPath/boot
mv $rootFsPath/root.x86_64/boot/intel-ucode.img $destinationPath/boot
mv $rootFsPath/root.x86_64/boot/vmlinuz-linux $destinationPath/boot
rm -rf $rootFsPath/root.x86_64/initramfs
rm -rf $rootFsPath/root.x86_64/root/*
rm -rf $rootFsPath/root.x86_64/boot/*
mkdir -p $rootFsPath/root.x86_64/root/create_install_image
cp  *.sh $rootFsPath/root.x86_64/root/create_install_image
cp -r ../installer $rootFsPath/root.x86_64/root
cp -r ../utils $rootFsPath/root.x86_64/root/


if [[ $# -gt 2 ]]; then
if [[ "$3" == "limine" ]];then
arch-chroot $rootFsPath/root.x86_64 /bin/bash << EOF
set -e
source /root/utils/bootloader_setup.sh
install_limine_bootloader /boot
EOF
mv $rootFsPath/root.x86_64/boot/* $destinationPath/boot
else
if [[ "$3" == "grub" ]];then
arch-chroot $rootFsPath/root.x86_64 /bin/bash << EOF
set -e
source /root/utils/bootloader_setup.sh
install_grub_bootloader /boot true
EOF
mv $rootFsPath/root.x86_64/boot/* $destinationPath/boot
fi
fi
fi
$rootFsPath/root.x86_64/bin/mksquashfs $rootFsPath/root.x86_64 $destinationPath/image/rootfs.sfs -wildcards -e  dev/* proc/* sys/* run/*
if [[ $# -gt 3 ]]; then
        source ../utils/bootloader_setup.sh
        if [[ "$3" == "limine" ]];then
                generate_limine_configuration $5 $destinationPath/boot/EFI/BOOT
        else
        if [[ "$3" == "grub" ]];then
                mkdir -p $destinationPath/boot/grub
                generate_grub_configuration $5 $destinationPath/boot/grub
        fi
        fi
        echo "Mounting USB boot partition..."
        mount $4 /mnt
        echo "Copying boot all files..."
        rsync -ah --no-perms --no-owner --no-group --info=progress2 $destinationPath/boot/ /mnt/
        umount -R -q /mnt
        echo "Mounting USB root partition..."
        mount $5 /mnt
        echo "Copying rootfs squash image..."
        rsync -ah --no-perms --no-owner --no-group --info=progress2 $destinationPath/image/rootfs.sfs /mnt/rootfs.sfs
        umount -R -q /mnt
        umount -R -q $destinationPath/*
        rm -rf $destinationPath
        echo "Done"
else
        if [[ $# -eq 3 ]]; then
                source ../utils/bootloader_setup.sh
                if [[ "$3" == "limine" ]];then
                        part=$(df --output=source $destinationPath | tail -n 1)
                        generate_limine_configuration $part $destinationPath/boot/EFI/BOOT
                fi
                if [[ "$3" == "grub" ]];then
                        mkdir -p $destinationPath/boot/grub
                        part=$(df --output=source $destinationPath | tail -n 1)
                        generate_grub_configuration $part $destinationPath/boot/grub
                fi
                umount -R -q $rootFsPath
                rm -rf $rootFsPath
                echo "Done"
        fi
fi


