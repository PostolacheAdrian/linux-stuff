#!/bin/bash
if [ $1 ]
then
if [ -e $1 ]
then
rootpart=$1
uuid=$(blkid $rootpart	| sed 's/ /\n/g' | sed '/^UUID=/!d' | sed 's/.*=\|\"//g')
cat > /home/live-install/grub.cfg << EOF 
insmod all_video
insmod part_msdos
insmod part_gpt
insmod ext2
insmod sfs
insmod squash4
set default=0
set timeout=15
menuentry "Linux Live Environment x64" {
search --no-floppy --fs-uuid --set=root ${uuid}  
linux /live-install/vmlinuz-linux mountid=${uuid} busybox=OFF usbcore.autosuspend=-1 nowatchdog loglevel=2 zswap.enabled=0 quiet
initrd /live-install/intel-ucode.img /live-install/initramfs.img
}
EOF
fi
fi
