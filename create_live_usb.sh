#!/bin/bash
if [ $1 ] && [ $2 ] 
then
if [ -e $1 ] && [ -e $2 ]
then
efipart=$1
datapart=$2
echo "Formating $efipart ..."
mkfs.vfat -F32 $efipart 1>/dev/null
echo "Formating $datapart ..."
yes | mkfs.ext4 $datapart 1>/dev/null
uuid=$(blkid $datapart	| sed 's/ /\n/g' | sed '/^UUID=/!d' | sed 's/.*=\|\"//g') 
echo "Mounting partitions ..."
mkdir mnt
mount $2 mnt
mkdir -p mnt/boot/efi
mount $1 mnt/boot/efi
echo "Installing grub bootloader ..."
grub-install --target=x86_64-efi -d /usr/lib/grub/x86_64-efi --removable --efi-directory=mnt/boot/efi --boot-directory=mnt/boot --bootloader-id=LinuxLive 1>/dev/null
cat > mnt/boot/grub/grub.cfg << EOF 
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
linux /boot/vmlinuz-linux mountid=${uuid} busybox=OFF
initrd /boot/intel-ucode.img /boot/initramfs.img
}
EOF
echo "Copying boot files ..."
cp initramfs.img mnt/boot
cp vmlinuz-linux mnt/boot
cp intel-ucode.img mnt/boot
cp rootfs.sfs mnt
echo "Sync ..."
sync
echo "Unmounting partitions ..."
umount -R mnt
rm -rf mnt
echo "Successfully done."
else
echo "Partitions not exists"
fi
else
echo "Usage: $0 efipartition datapartition"
fi
