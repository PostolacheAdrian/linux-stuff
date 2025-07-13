#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
        echo 'This script must be run by root' >&2
        exit 1
fi
destinationPath=/home/live-install
rootFsPath=/home/rootfs
user_pass="\\\$6\\\$tQk2hzssD/a0tbe1\\\$bEnhqTMyzyhBJdRPKEUrku0iMFLSwMbpoGqU5vE07d7Toe37JYqAgzxRsTtOc1RNEWMvHmzutR7m22OlZA/ao/"
download_file=archlinux-bootstrap-x86_64.tar.zst
cachyos_repo=https://mirror.cachyos.org/repo/x86_64/cachyos/
cachyos_mirrorlist=$(curl $cachyos_repo -s | sed -n "/cachyos-mirrorlist.*\.zst</p" | sed -n 's/.*\(title="[^"]*"\).*/\1/p' | sed "s/\"\|title=//g")
cachyos_keyring=$(curl $cachyos_repo -s | sed -n "/cachyos-keyring.*\.zst</p" | sed -n 's/.*\(title="[^"]*"\).*/\1/p' | sed "s/\"\|title=//g")
cachyos_pacman=$(curl $cachyos_repo -s | sed -n "/pacman-.*\.zst</p" | sed -n 's/.*\(title="[^"]*"\).*/\1/p' | sed "s/\"\|title=//g")
cachyos_rate_mirrors=$(curl $cachyos_repo -s | sed -n "/\"cachyos-rate-mirrors.*\.zst</p" | sed -n 's/.*\(title="[^"]*"\).*/\1/p' | sed "s/\"\|title=//g")
rate_mirrors=$(curl $cachyos_repo -s | sed -n "/\"rate-mirrors.*\.zst</p" | sed -n 's/.*\(title="[^"]*"\).*/\1/p' | sed "s/\"\|title=//g")
mkdir -p $rootFsPath
if [ -d $destinationPath ] 
then
rm -rf $destinationPath
fi
mkdir -p $destinationPath
mount -t tmpfs $rootFsPath $rootFsPath
if ! [ -e $download_file ]
then
echo "Downloading arch bootstrap ..."
curl https://mirror.ro.cdn-perfprod.com/archlinux/iso/latest/$download_file -o $rootFsPath/$download_file
fi
echo "Extracting archive ..."
tar xf $rootFsPath/$download_file --numeric-owner 2>&1>/dev/null --directory $rootFsPath
mount --bind $rootFsPath/root.x86_64 $rootFsPath/root.x86_64
echo "Copying configuration files ..."
cp create_initramfs.sh $rootFsPath/root.x86_64/root
echo -e "en_US.UTF-8 UTF-8\nro_RO.UTF-8 UTF-8\n" > $rootFsPath/root.x86_64/etc/locale.gen
echo -e "LANG=en_US.UTF-8\n" > $rootFsPath/root.x86_64/etc/locale.conf
echo "LiveLinux" > $rootFsPath/root.x86_64/etc/hostname
cp /etc/resolv.conf $rootFsPath/root.x86_64/etc

arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "locale-gen"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman-key --init"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman-key --populate archlinux"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman-key --lsign-key F3B607488DB35A47"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "curl $cachyos_repo$cachyos_mirrorlist -o root/$cachyos_mirrorlist"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "curl $cachyos_repo$cachyos_keyring -o root/$cachyos_keyring"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "curl $cachyos_repo$rate_mirrors -o root/$rate_mirrors"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "curl $cachyos_repo$cachyos_rate_mirrors -o root/$cachyos_rate_mirrors"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "curl $cachyos_repo$cachyos_pacman -o root/$cachyos_pacman"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "sed -i 's/^#\[multilib\]/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist\n/' /etc/pacman.conf"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman -Syy"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "yes|pacman -U /root/${cachyos_mirrorlist} /root/${cachyos_keyring} /root/${rate_mirrors} /root/${cachyos_rate_mirrors} /root/${cachyos_pacman}"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "sed -i '/^#\[core-testing\]/i[cachyos]\nInclude = \/etc/pacman.d\/cachyos-mirrorlist\n' /etc/pacman.conf"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "cachyos-rate-mirrors"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "pacman -Syy"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "yes|pacman -Syu base base-devel linux-cachyos linux-firmware intel-ucode pacman-contrib archinstall arch-install-scripts squashfs-tools grub efivar efibootmgr os-prober vim mc htop acpid acpi lm_sensors fastfetch git mtools dosfstools ntfs-3g wireless_tools iwd networkmanager dhcpcd busybox cpio mkinitcpio mkinitcpio-utils cachyos-settings cachyos-hooks whois chwd"
systemctl --root $rootFsPath/root.x86_64 enable acpid
systemctl --root $rootFsPath/root.x86_64 enable dhcpcd
systemctl --root $rootFsPath/root.x86_64 enable NetworkManager
systemctl --root $rootFsPath/root.x86_64 enable systemd-timesyncd
systemctl --root $rootFsPath/root.x86_64 disable systemd-nsresourced.service
systemctl --root $rootFsPath/root.x86_64 disable systemd-networkd.service
systemctl --root $rootFsPath/root.x86_64 disable systemd-homed.service
systemctl --root $rootFsPath/root.x86_64 disable systemd-userdbd.service
systemctl --root $rootFsPath/root.x86_64 disable ananicy-cpp.service
sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' $rootFsPath/root.x86_64/etc/sudoers
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "useradd -m -G wheel live"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "usermod -p \"$user_pass\" live"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "usermod -p \"$user_pass\" root"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "./root/create_initramfs.sh"
arch-chroot $rootFsPath/root.x86_64 /bin/bash -c "yes|pacman -Scc"

sed -i "/ExecStart=/s/=.*/=-\/sbin\/agetty --skip-login --noclear --nonewline --noissue --autologin live %I \$TERM/" $rootFsPath/root.x86_64/usr/lib/systemd/system/getty@.service
mv $rootFsPath/root.x86_64/initramfs.img $destinationPath
mv $rootFsPath/root.x86_64/boot/intel-ucode.img $destinationPath
mv $rootFsPath/root.x86_64/boot/vmlinuz-linux-cachyos $destinationPath
rm -rf $rootFsPath/root.x86_64/initramfs
rm -rf $rootFsPath/root.x86_64/root/*
rm -rf $rootFsPath/root.x86_64/boot/*
cp -r ../live_install $rootFsPath/root.x86_64/root
cp -r ../local_install $rootFsPath/root.x86_64/root
cp -r ../dotfiles $rootFsPath/root.x86_64/root/
$rootFsPath/root.x86_64/bin/mksquashfs $rootFsPath/root.x86_64 $destinationPath/rootfs.sfs -wildcards -e  dev/* proc/* sys/* run/*
umount -R $rootFsPath/root.x86_64
umount -R $rootFsPath
rm -rf $rootFsPath
./create_grub_entry.sh /dev/nvme1n1p3
