#!/bin/bash
PACKAGES="fastfetch os-prober vim bash-completion efivar ntfs-3g wireless_tools networkmanager bluez alsa-firmware sof-firmware pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber alsa-ucm-conf dhcpcd git mc acpid acpi mtools dosfstools grub efibootmgr grub htop bash-completion wget archinstall arch-install-scripts wireless-regdb squashfs-tools paru-bin busybox cpio powertop"
pacstrap -K -i /mnt base base-devel linux-cachyos linux-cachyos-headers linux-firmware mkinitcpio zstd intel-ucode cachyos-keyring cachyos-rate-mirrors curl cachyos-settings cachyos-hooks
genfstab -U /mnt > /mnt/etc/fstab
read -p "User: " usr_name
read -p "Hostname: " hst_name
echo $hst_name > /mnt/etc/hostname
echo "127.0.0.1		localhost" >> /mnt/etc/hosts
echo "::1		localhost" >> /mnt/etc/hosts
echo "127.0.0.1		"$hst_name".localdomain" $hst_name >> /mnt/etc/hosts
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "ro_RO.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
arch-chroot /mnt /bin/bash -c "locale-gen"
arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime"
arch-chroot /mnt /bin/bash -c "hwclock --systohc"
arch-chroot /mnt /bin/bash -c "timedatectl set-ntp true"
arch-chroot /mnt /bin/bash -c "curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz"
cat > /mnt/install-repos.sh << 'EOF'
#!/bin/bash
tar xvf cachyos-repo.tar.xz
cd cachyos-repo
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
./cachyos-repo.sh
sed -i 's/^#\[multilib\]/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist\n/' /etc/pacman.conf
EOF
chmod +x /mnt/install-repos.sh
arch-chroot /mnt /bin/bash -c "./install-repos.sh"

rm -rf /nnt/install-repos.sh
rm -rf /mnt/cachyos-repo
rm -rf /mnt/cachyos-repo.tar.xz
arch-chroot /mnt /bin/bash -c "useradd -m -c "$usr_name" -G wheel,video,audio,storage,disk,input,games,adm,uucp,kvm $usr_name"
echo "Enter password for $usr_name:"
arch-chroot /mnt /bin/bash -c "passwd $usr_name"
echo "Enter passwd for root :"
arch-chroot /mnt /bin/bash -c "passwd root"
arch-chroot /mnt /bin/bash -c "pacman-key --init"
arch-chroot /mnt /bin/bash -c "pacman-key --populate archlinux cachyos"
arch-chroot /mnt /bin/bash -c "cachyos-rate-mirrors"
arch-chroot /mnt /bin/bash -c "pacman -Syu"

arch-chroot /mnt /bin/bash -c "pacman -Sy $PACKAGES"
arch-chroot /mnt /bin/bash -c "grub-install -d /usr/lib/grub/x86_64-efi --target=x86_64-efi --efi-directory=/boot/efi --boot-directory=/boot --bootloader-id=LinuxOS"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
arch-chroot /mnt /bin/bash -c "systemctl enable acpid"
arch-chroot /mnt /bin/bash -c "systemctl enable bluetooth"
arch-chroot /mnt /bin/bash -c "systemctl enable NetworkManager"
arch-chroot /mnt /bin/bash -c "systemctl enable systemd-timesyncd"
arch-chroot /mnt /bin/bash -c "systemctl enable fstrim.timer"
arch-chroot /mnt /bin/bash -c "systemctl disable systemd-networkd"


#cat > /mnt/etc/systemd/zram-generator.conf << 'EOF'
#!/bin/bash
#[zram0]
#zram-size = min(ram / 2, ram)
#compression-algorithm = zstd
#EOF

#cat > /mnt/etc/sysctl.d/99-zram-generator.conf << 'EOF'
#!/bin/bash
#vm.swappiness = 180
#vm.watermark_boost_factor = 0
#vm.watermark_scale_factor = 125
#vm.page-cluster = 0
#EOF
