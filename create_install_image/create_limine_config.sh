#!/bin/bash
if [ $1 ]
then
if [ -e $1 ]
then
rootpart=$1
uuid=$(blkid $rootpart	| sed 's/ /\n/g' | sed '/^UUID=/!d' | sed 's/.*=\|\"//g')
cat > /home/live-install/limine.conf << EOF 
timeout: 5
/Live Linux Installer
    protocol: linux
    path: boot():/vmlinuz-linux
    cmdline: mountid=$uuid busybox=OFF usbcore.autosuspend=-1 nowatchdog loglevel=2 zswap.enabled=0 quiet
    module_path: boot():/intel-ucode.img
    module_path: boot():/initramfs.img
}
EOF
fi
fi
