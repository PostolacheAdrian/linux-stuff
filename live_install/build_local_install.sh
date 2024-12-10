#!/bin/bash
initialpath=$PWD
download_file=archlinux-bootstrap-x86_64.tar.zst
mkdir rootfs
mkdir -p /home/live-install
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
cp $initialpath/create_initramfs.sh root.x86_64/root
echo -e "en_US.UTF-8 UTF-8\nro_RO.UTF-8 UTF-8\n" > root.x86_64/etc/locale.gen
echo -e "LANG=en_US.UTF-8\n" > root.x86_64/etc/locale.conf
echo "LiveLinux" > root.x86_64/etc/hostname
cp /etc/resolv.conf $PWD/root.x86_64/etc
arch-chroot root.x86_64 /bin/bash -c "pacman-key --init"
arch-chroot root.x86_64 /bin/bash -c "pacman-key --populate archlinux"
arch-chroot root.x86_64 /bin/bash -c "curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o root/cachyos-repo.tar.xz"
cat > root.x86_64/install-repos.sh << 'EOF'
#!/bin/bash
cd root
tar xvf cachyos-repo.tar.xz
cd cachyos-repo
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist
./cachyos-repo.sh
EOF
chmod +x root.x86_64/install-repos.sh
arch-chroot root.x86_64 /bin/bash -c "./install-repos.sh"

rm -rf root.x86_64/install-repos.sh
rm -rf root.x86_64/root/cachyos-repo
rm -rf root.x86_64/root/cachyos-repo.tar.xz

arch-chroot root.x86_64 /bin/bash -c "pacman -Sy cachyos-rate-mirrors"
arch-chroot root.x86_64 /bin/bash -c "cachyos-rate-mirrors"

arch-chroot root.x86_64 /bin/bash -c "pacman -Sy base base-devel linux-cachyos linux-firmware intel-ucode pacman-contrib archinstall arch-install-scripts squashfs-tools grub efivar efibootmgr os-prober vim mc htop acpid acpi lm_sensors fastfetch git mtools dosfstools ntfs-3g wireless_tools iwd networkmanager dhcpcd busybox cpio mkinitcpio mkinitcpio-utils cachyos-settings cachyos-hooks"
arch-chroot root.x86_64 /bin/bash -c "systemctl enable acpid"
arch-chroot root.x86_64 /bin/bash -c "systemctl enable dhcpcd"
arch-chroot root.x86_64 /bin/bash -c "systemctl enable NetworkManager"
arch-chroot root.x86_64 /bin/bash -c "systemctl enable systemd-timesyncd"
arch-chroot root.x86_64 /bin/bash -c "systemctl disable systemd-networkd"
arch-chroot root.x86_64 /bin/bash -c "passwd"
arch-chroot root.x86_64 /bin/bash -c "/root/create_initramfs.sh"
arch-chroot root.x86_64 /bin/bash -c "yes|pacman -Scc"
mv root.x86_64/initramfs.img /home/live-install
mv root.x86_64/boot/intel-ucode.img /home/live-install
mv root.x86_64/boot/vmlinuz-linux-cachyos /home/live-install
rm -rf root.x86_64/initramfs
rm -rf root.x86_64/root/create_initramfs.sh
rm -rf root.x86_64/boot/*
root.x86_64/bin/mksquashfs root.x86_64 /home/live-install/rootfs.sfs
cd ..
rm -rf rootfs
umount -R rootfs
rm -rf rootfs
./create_grub_entry.sh /dev/nvme1n1p3

