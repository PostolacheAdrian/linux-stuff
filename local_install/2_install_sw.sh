#! /bin/bash
vim /etc/fstab
read -p "User: " usr_name
read -p "Hostname: " hst_name
echo $hst_name > /etc/hostname
echo "127.0.0.1		localhost" >> /etc/hosts
echo "::1		localhost" >> /etc/hosts
echo "127.0.0.1		"$hst_name".localdomain" $hst_name >> /etc/hosts
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
echo "en_US ISO-8859-1" >> /etc/locale.gen
echo "ro_RO ISO-8859-2" >> /etc/locale.gen
echo "ro_RO.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
ln -sf /usr/share/zoneinfo/Europe/Bucharest /etc/localtime
hwclock --systohc
useradd -m -G wheel,audio,video,storage,input,games $usr_name
echo "Enter password for " $usr_name "!" 
passwd $usr_name
echo "Enter password for root !"
passwd root
visudo
pacman -Syu grub efibootmgr os-prober mtools dosfstools ntfs-3g wireless_tools networkmanager bluez alsa-firmware pipewire mc git terminator htop sof-firmware mesa mesa-utils mesa-vdpau xorg-server gnome gnome-tweaks gdm acpi vulkan-intel  
systemctl enable NetworkManager
systemctl enable fstrim.timer
systemctl enable gdm
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Archlinux
vim /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg



