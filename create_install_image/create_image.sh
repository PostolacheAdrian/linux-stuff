#!/bin/bash
set -Eeuo pipefail
destination=$1
destinationPath=/home/live-install
rootFsPath=/home/rootfs
user_pass="\\\$6\\\$tQk2hzssD/a0tbe1\\\$bEnhqTMyzyhBJdRPKEUrku0iMFLSwMbpoGqU5vE07d7Toe37JYqAgzxRsTtOc1RNEWMvHmzutR7m22OlZA/ao/"
download_file=archlinux-bootstrap-x86_64.tar.zst
cleanup(){
        
        umount -R -q $rootFsPath/root.x86_64
        umount -R -q $rootFsPath
        rm -rf $rootFsPath
}
error_handler() {
        echo "Script failed !" >&2
        echo "Error: $1" >&2
        echo "Line $2" >&2
        echo "Command: $3" >&2
        cleanup
}

trap 'error_handler $? $LINENO "$BASH_COMMAND"' ERR


if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
        exit 1
fi

mkdir -p $rootFsPath
if [ -d $destinationPath ] 
then
echo "$destinationPath already exists."
echo "Removing $destinationPath"
rm -rf $destinationPath
fi
echo "Creating directory $rootFsPath"
mkdir -p $destinationPath
echo "Mounting $rootFsPath as tmpfs"
mount -t tmpfs $rootFsPath $rootFsPath
if [["$destination" == "tmpfs"]];then
mount -t tmpfs $destinationPath $destinationPath
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
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman-key --populate archlinux"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman-key --lsign-key F3B607488DB35A47"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "sed -i 's/^#\[multilib\]/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist\n/' /etc/pacman.conf"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "mkdir -p /etc/pacman.d/hooks"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "ln -sf /dev/null /etc/pacman.d/hooks/60-mkinicpio-remove.hook"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "ln -sf /dev/null /etc/pacman.d/hooks/90-mkinicpio-install.hook"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman -Syy"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "yes|pacman -Syu base linux linux-firmware sudo intel-ucode pacman-contrib archinstall arch-install-scripts squashfs-tools limine efivar efibootmgr vim mc htop acpid acpi lm_sensors fastfetch git mtools dosfstools ntfs-3g wireless_tools iwd networkmanager dhcpcd busybox cpio mkinitcpio mkinitcpio-utils curl wget whois"
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
mv $rootFsPath/root.x86_64/initramfs.img $destinationPath
mv $rootFsPath/root.x86_64/boot/intel-ucode.img $destinationPath
mv $rootFsPath/root.x86_64/boot/vmlinuz-linux $destinationPath
rm -rf $rootFsPath/root.x86_64/initramfs
rm -rf $rootFsPath/root.x86_64/root/*
rm -rf $rootFsPath/root.x86_64/boot/*
cp -r ../create_install_image $rootFsPath/root.x86_64/root
cp -r ../installer $rootFsPath/root.x86_64/root
#cp -r ../dotfiles $rootFsPath/root.x86_64/root/
$rootFsPath/root.x86_64/bin/mksquashfs $rootFsPath/root.x86_64 $destinationPath/rootfs.sfs -wildcards -e  dev/* proc/* sys/* run/*
umount -R $rootFsPath/root.x86_64
umount -R $rootFsPath
rm -rf $rootFsPath

