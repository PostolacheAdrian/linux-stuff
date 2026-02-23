#!/bin/bash
#function generates Limine bootloader configuration
#param1: - rootfs image partition needed to get UUID required for initramfs
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
#param1: - rootfs image partition needed to get UUID required for initramfs
#param2: - location where grub.cfg file will be created.
generate_grub_configuration()
if [[ $# -lt 2 ]];then
    echo -e "Error: Missing root partition path(eg. /dev/sdaX)." >&2
else
    local rootpart=$1
    local uuid=$(blkid $rootpart	| sed 's/ /\n/g' | sed '/^UUID=/!d' | sed 's/.*=\|\"//g')
    if [[ ${#uuid} -gt 0 ]]; then
    echo "Generating GRUB configuration ..."
    cat > $2/grub.cfg << EOF 
insmod all_video
insmod part_msdos
insmod part_gpt
set default=0
set timeout=5
menuentry "Linux Installer" {
linux /vmlinuz-linux mountid=${uuid} busybox=OFF usbcore.autosuspend=-1 nowatchdog loglevel=2 zswap.enabled=0 quiet
initrd /intel-ucode.img /initramfs.img
}
EOF
    else
        echo -e "Error: partition not found !" >&2
    fi 
fi

#Function installs GRUB bootloader
#param1: - path
install_grub_bootloader(){
if [[ $# -lt 1 ]];then
    echo -e "Error: Missing bootloader path(eg. /boot)." >&2
else
    echo "Installing grub bootloader ..."
    cat > /tmp/grub.cfg <<'EOF_GRUB'
insmod all_video
insmod part_gpt
insmod part_msdos
insmod fat
insmod exfat
search --no-floppy --file --set=root /grub/grub.cfg 
configfile /grub/grub.cfg 
EOF_GRUB
    mkdir -p $1/EFI/BOOT
    grub-mkstandalone -d /usr/lib/grub/x86_64-efi --format=x86_64-efi --output=$1/EFI/BOOT/BOOTX64.EFI "boot/grub/grub.cfg=/tmp/grub.cfg"
fi
}

#Function installs Limine bootloader
#param1: - path
install_limine_bootloader(){
if [[ $# -lt 1 ]];then
    echo -e "Error: Missing bootloader path(eg. /boot)." >&2
else
    echo "Installing Limine bootloader ..."
    mkdir -p $1/EFI/BOOT
    cp /usr/share/limine/BOOTX64.EFI $1/EFI/BOOT/BOOTX64.EFI
fi
}