#!/bin/bash
#function generates Limine bootloader configuration
#param1: - root partition needed to get UUID required for initramfs
#param2: - location where limine.conf file will be created.
generate_limine_configuration()
if [[ $# -lt 2 ]];then
    echo -e "Error: Missing root partition path(eg. /dev/sdaX)." >&2
else
    local rootpart=$1
    local uuid=$(blkid $rootpart	| sed 's/ /\n/g' | sed '/^UUID=/!d' | sed 's/.*=\|\"//g')
    if [[ ${#uuid} -gt 0 ]]; then
    echo "Generating Limine configuration ..."
    cat > $2/limine.conf << EOF 
timeout: 5
/Linux Installer
    protocol: linux
    path: boot():/vmlinuz-linux
    cmdline: mountid=$uuid busybox=OFF usbcore.autosuspend=-1 nowatchdog loglevel=2 zswap.enabled=0 quiet
    module_path: boot():/intel-ucode.img
    module_path: boot():/initramfs.img
}
EOF
    else
        echo -e "Error: partition not found !" >&2
    fi 
fi

#function generates GRUB bootloader configuration
#param1: - root partition needed to get UUID required for initramfs
#param2: - location where grub.cfg file will be created.
generate_grub_configuration()
if [[ $# -lt 2 ]];then
    echo -e "Error: Missing root partition path(eg. /dev/sdaX)." >&2
else
    local rootpart=$1
    local uuid=$(blkid $rootpart	| sed 's/ /\n/g' | sed '/^UUID=/!d' | sed 's/.*=\|\"//g')
    if [[ ${#uuid} -gt 0 ]]; then
    echo "Generating GRUB configuration ..."
    cat > $2/grub.conf << EOF 
insmod all_video
insmod part_msdos
insmod part_gpt
insmod ext2
set default=0
set timeout=5
menuentry "Linux Installer" {
search --no-floppy --fs-uuid --set=root ${uuid}  
linux /live-install/vmlinuz-linux mountid=${uuid} busybox=OFF usbcore.autosuspend=-1 nowatchdog loglevel=2 zswap.enabled=0 quiet
initrd /live-install/intel-ucode.img /live-install/initramfs.img
}
EOF
    else
        echo -e "Error: partition not found !" >&2
    fi 
fi

#Function installs GRUB bootloader
#param1: - EFI partition
#param2: - removable flag: true/false
install_grub_bootloader(){
if [[ $# -lt 2 ]];then
    echo -e "Error: Missing boot or efi partition path(eg. /dev/sdaX)." >&2
else
    local efipart=$1
    local removable=
    if [[ "$2" == "true" ]]; then
        removable="--removable"
    fi
    echo "Mounting efi parition $efipart to /mnt"
    mount $efipart /mnt
    echo "Installing grub bootloader ..."
    grub-install --target=x86_64-efi -d /usr/lib/grub/x86_64-efi $removable --efi-directory=/mnt --boot-directory=/mnt --bootloader-id=LinuxInstaller 1>/dev/null
    umount -R /mnt
fi
}

#Function installs Limine bootloader
#param1: - EFI partition
install_limine_bootloader(){
if [[ $# -lt 1 ]];then
    echo -e "Error: Missing boot or efi partition path(eg. /dev/sdaX)." >&2
else
    local efipart=$1
    echo "Mounting efi parition $efipart to /mnt"
    mount $efipart /mnt
    echo "Installing Limine bootloader ..."
    mkdir -p /mnt/EFI/BOOT
    rsync -ah --info=progress2 /usr/share/limine/BOOTX64.EFI /mnt/EFI/BOOT/BOOTX64.EFI
    umount -R /mnt
fi
}