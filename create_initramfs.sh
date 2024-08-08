#!/bin/sh
KERNEL_VERSION=$(ls -1 /lib/modules)
if [ -d initramfs ]; then
    rm -rf initramfs
fi
mkdir initramfs
cd initramfs
mkdir -p dev etc root new_root sys proc usr/bin usr/lib/modules mnt run tmp var opt
cp /usr/bin/busybox usr/bin
ln -sf usr/bin bin
ln -sf usr/bin sbin
ln -sf usr/lib lib
ln -sf usr/lib lib64
cd usr
ln -sf lib lib64
ln -sf bin sbin
cd ..
mknod dev/console c 5 1
mknod dev/null c 1 3
mknod dev/tty c 5 0
mknod dev/tty0 c 4 0
cat > init << "EOF"
#!/bin/busybox ash

#Install busybox symlinks
#/bin/busybox --install -s /usr/bin

#Export the path
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

#Mount the kernel dependecies
busybox mount -t proc      proc      /proc -o nosuid,noexec,nodev
busybox mount -t sysfs     sysfs     /sys  -o nosuid,noexec,nodev
busybox mount -t devtmpfs  dev /dev -o mode=0755,nosuid
busybox mount -t tmpfs  run /run -o nosuid,nodev,mode=0755
busybox mount -t tmpfs tmp /tmp -o nosuid,nodev
busybox mkdir dev/pts
busybox mount -t devpts  devpts /dev/pts -o mode=0620

# Create symlinks for standard file descriptors
busybox ln -s /proc/self/fd /dev/fd
busybox ln -s /proc/self/fd/0 /dev/stdin
busybox ln -s /proc/self/fd/1 /dev/stdout
busybox ln -s /proc/self/fd/2 /dev/stderr
[ -e /proc/kcore ] && ln -snf /proc/kcore /dev/core
busybox ln -s /proc/self/mounts /etc/mtab
#Scan devices and populate /dev
echo "Loading kernel modules ..."
#systemd-udevd --daemon --resolve-names=never
#udevadm trigger --action=add --type=subsystems
#udevadm trigger --action=add --type=devices
#udevadm settle
mdev -s
#/usr/bin/depmod -a
#Install modules
#find /sys -name 'modalias' | xargs sort -u | xargs -n 1 /bin/modprobe -ab
#find /sys -name 'modalias' -type f -exec cat '{}' + | sort -u | xargs modprobe
grep -h MODALIAS /sys/bus/*/devices/*/uevent | cut -d= -f2 | xargs /bin/modprobe -abq 2> /dev/null
grep -h MODALIAS /sys/bus/*/devices/*/uevent | cut -d= -f2 | xargs /bin/modprobe -abq 2> /dev/null
/usr/bin/modprobe -abq loop
/usr/bin/modprobe -abq squashfs
/usr/bin/modprobe -abq overlay

mkdir -p /mnt/cdrom
mkdir -p /run/image/ro
mkdir -p /run/image/rw/data
mkdir -p /run/image/rw/work

uuid=$(xargs -n1 -a /proc/cmdline | sed '/^mountid/!d' | sed 's/.*=//g')
device=$(blkid | sed -n "/${uuid}/p" | sed 's/:.*//g')
timeout 30
while [ -z "$device" ]
do
if [ $timeout == 0 ]
then
break
else
timeout=$((timeout - 1))
fi
sleep 0.5
device=$(blkid | sed -n "/${uuid}/p" | sed 's/:.*//g')
done
mount -t ext4 $device /mnt/cdrom
mount -t squashfs -o defaults,ro /mnt/cdrom/rootfs.sfs /run/image/ro
mount -t overlay -o lowerdir=/run/image/ro,upperdir=/run/image/rw/data,workdir=/run/image/rw/work overlay /new_root

#Execute the shell
busybox_req=$(xargs -n1 -a /proc/cmdline | sed '/^busybox/!d' | sed 's/.*=//g')
if [ "$busybox_req" == "ON" ]
then
exec /bin/busybox ash
else
#Switch to new root
mount -n -o move /run /new_root/run
mount -n -o move /tmp /new_root/tmp
mount -n -o move /dev /new_root/dev
mount -n -o move /sys /new_root/sys
mount -n -o move /proc /new_root/proc
exec /usr/bin/busybox switch_root -c /dev/console /new_root /sbin/init "$@"
fi
EOF
chmod +x init
cat > etc/passwd << 'EOF'
root:x:0:0:root:/root:/bin/ash
nobody:x:65534:65534:nobody:/proc/self:/dev/null
EOF

cat > etc/group << 'EOF'
root:x:0:
nobody:x:65534:
EOF


#mapfile -d '' -t modules < <(find \
#     /usr/lib/modules/$KERNEL_VERSION/kernel\
#     -type f -name '*.zst' -print0 ) 
#
#for module in "${modules[@]}"; do
#	zstd -qd $module --output-dir-mirror .
#done
#cp /usr/lib/modules/$KERNEL_VERSION/modules.{builtin,order,builtin.modinfo} usr/lib/modules/$KERNEL_VERSION
cp -r /usr/lib/modules/$KERNEL_VERSION usr/lib/modules
cp -r /usr/lib/firmware usr/lib
depmod -b $PWD ${KERNEL_VERSION}
shopt -s extglob
rm usr/lib/modules/${KERNEL_VERSION}/modules.!(*.bin|devname|softdep)

#copy required libs for udev
#mapfile -d '' -t libs < <(ldd /usr/lib/systemd/systemd-udevd | sed -E 's/.*=> //g' | sed -E 's/\(.*\)|\t.*//g' | sed -e "/^$/d") 
#for file in "${libs[@]}"; do
#	cp ${file} usr/lib
#done

unset $libs
mapfile -d '' -t libs < <(ldd /usr/bin/zstd | sed -E 's/.*=> //g' | sed -E 's/\(.*\)|\t.*//g' | sed -e "/^$/d") 
for file in "${libs[@]}"; do
	cp ${file} usr/lib
done
unset $libs
mapfile -d '' -t libs < <(ldd /usr/bin/kmod | sed -E 's/.*=> //g' | sed -E 's/\(.*\)|\t.*//g' | sed -e "/^$/d") 
for file in "${libs[@]}"; do
	cp ${file} usr/lib
done

cp /usr/bin/kmod usr/bin/modprobe
cp /usr/bin/kmod usr/bin/depmod
cp /usr/bin/kmod usr/bin/lsmod
cp /usr/bin/kmod usr/bin/insmod
cp /usr/bin/kmod usr/bin/rmmod

cp /usr/bin/zstd usr/bin
cp /usr/bin/zstdcat usr/bin
#cp /usr/bin/udevadm usr/bin
#cp /usr/lib/systemd/systemd-udevd usr/bin
#cp -r /etc/udev etc
#rm -rf etc/udev/rules/*.*
#cp -r /lib/udev lib

find . | cpio -oH newc | gzip --best > ../initramfs.img
cd ..

