#!/bin/bash
#Get installed kernel version
KERNEL_VERSION=$(ls -1 /lib/modules)
if [ -d initramfs ]; then
    rm -rf initramfs
fi

#Required modules
MODULES_TO_LOAD="nvme ahci xhci_pci usb-storage ext4 sd_mod scsi_mod loop overlay squashfs"

#Create working folder
mkdir initramfs
cd initramfs

#Create folders structure
mkdir -p dev etc root new_root sys proc usr/bin /usr/sbin usr/lib/modules usr/lib/systemd mnt run tmp var opt

#Create the symlinks
ln -s usr/bin bin
ln -s usr/sbin sbin
ln -s usr/lib lib
ln -s usr/lib lib64
cd usr
ln -s lib lib64
ln -s bin sbin
cd ..

copy_module(){
	local name=$1
	local dependencies=$(modprobe --show-depends $name 2>/dev/null | sed -E '/^builtin/d' | sed -E 's/insmod//g')
    if [ ! -z "$dependencies" ]; then
        
        for file in $dependencies; do
            local source=${file#*/lib/modules/$KERNEL_VERSION/}
            local destination=usr/lib/modules/$KERNEL_VERSION/$source
            mkdir -p $(dirname $destination)
            cp $file $destination
        done 
    fi
}

for module in $MODULES_TO_LOAD; do
    copy_module $module
    done
cp /lib/modules/$KERNEL_VERSION/modules.order lib/modules/$KERNEL_VERSION
cp /lib/modules/$KERNEL_VERSION/modules.builtin lib/modules/$KERNEL_VERSION
cp /lib/modules/$KERNEL_VERSION/modules.builtin.modinfo lib/modules/$KERNEL_VERSION
depmod -b $PWD ${KERNEL_VERSION}
