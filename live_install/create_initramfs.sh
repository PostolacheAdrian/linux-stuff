#!/bin/bash
#Get installed kernel version
KERNEL_VERSION=$(ls -1 /lib/modules)
if [ -d initramfs ]; then
    rm -rf initramfs
fi

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

#Create required nodes by the kernel
mknod -m 622 dev/console c 5 1
mknod -m 666 dev/null c 1 3
mknod -m 666 dev/zero c 1 5
mknod -m 666 dev/tty c 5 0
mknod -m 444 dev/random c 1 8
mknod -m 444 dev/urandom c 1 9
chown root:tty dev/{console,tty}
#Create /etc configuration
cat > etc/passwd << 'EOF'
root:x:0:0:root:/root:/bin/sh
nobody:x:65534:65534:nobody:/proc/self:/dev/null
EOF
cat > etc/group << 'EOF'
root:x:0:
tty:x:5:/bin/sh
nobody:x:65534:
EOF

#Copy kernel modules and additional firmware
cp -r /usr/lib/modules/$KERNEL_VERSION usr/lib/modules
cp -r /usr/lib/firmware usr/lib
depmod -b $PWD ${KERNEL_VERSION}
shopt -s extglob
rm usr/lib/modules/${KERNEL_VERSION}/modules.!(*.bin|devname|softdep)

#Copy binaries
binfiles="blkid mount kmod lsmod udevadm insmod rmmod modprobe depmod systemd-dissect systemd-tmpfiles"
#Copy /bin files and libraries
for f in $binfiles; do
	cp -a /bin/$f usr/bin
	lnk=$(readlink -f /bin/$f)
	[ -n "${lnk}" ] | cp ${lnk} usr/bin
	libs="$libs $(ldd usr/bin/$f | sed -E 's/.*=> //g' | sed -E 's/\(.*\)|\t.*//g' | sed -e "/^$/d")" 
done
libs=$(printf "%s\n" $libs | sort -u) 
for l in $libs; do
	cp -a $l usr/lib
	lnk=$(readlink -f $l)
	[ -n "${lnk}" ] | cp ${lnk} usr/lib
done
cp /usr/lib/libkmod* usr/lib
cp usr/lib/libsystemd* usr/lib/systemd
#Copy busybox and create symlinks
cp /bin/busybox usr/bin
symlinks=$(busybox --list | sed 's/\\n/ /g' | sed '/busybox\|mount\|modprobe\|insmod\|kmod\|rmmod\|modprobe\|blkid\|lsmod\|depmod/d')
cd usr/bin
for sl in  ${symlinks}; do
	ln -sf busybox "$sl"
done
cd ../..
#Copy udev
cp -r /usr/lib/udev usr/lib
#Create symlink to systemd-udevd
cd usr/lib/systemd
ln -s /usr/bin/udevadm systemd-udevd
cd ../../..
#Create init file
cat > init << "EOF"
#!/bin/sh
#Export the path
export PATH='/usr/bin:/usr/sbin'

#Mount the kernel dependecies
mount -t proc      proc      /proc -o nosuid,noexec,nodev
mount -t sysfs     sysfs     /sys  -o nosuid,noexec,nodev
mount -t devtmpfs  dev /dev -o mode=0755,nosuid
mount -t tmpfs  run /run -o nosuid,nodev,mode=0755
mount -t tmpfs tmp /tmp -o nosuid,nodev
mkdir dev/pts
mount -t devpts  devpts /dev/pts -o mode=0620

# Create symlinks for standard file descriptors
ln -s /proc/self/fd /dev/fd
ln -s /proc/self/fd/0 /dev/stdin
ln -s /proc/self/fd/1 /dev/stdout
ln -s /proc/self/fd/2 /dev/stderr
[ -e /proc/kcore ] && ln -snf /proc/kcore /dev/core
ln -s /proc/self/mounts /etc/mtab
chown root:tty /dev/console
chown root:tty /dev/tty
#Install all required kernel modules
echo "Loading kernel modules ..."

/usr/lib/systemd/systemd-udevd --daemon --resolve-names=never
udevadm trigger --action=add 
udevadm settle > /tmp/udev_done

if [ -f /tmp/udev_done ]; then
grep -h "MODALIAS\|DRIVER" /sys/bus/*/devices/*/uevent | cut -d= -f2 | xargs /usr/sbin/modprobe -abq 2> /dev/null
#grep -h "MODALIAS\|DRIVER" /sys/bus/*/devices/*/uevent | cut -d= -f2 | xargs /usr/sbin/modprobe -abq 2> /dev/null
/usr/sbin/modprobe -abq loop
/usr/sbin/modprobe -abq squashfs
/usr/sbin/modprobe -abq overlay
fi

#Execute the shell
busybox_req=$(xargs -n1 -a /proc/cmdline | sed '/^busybox/!d' | sed 's/.*=//g')
if [ "$busybox_req" == "ON" ]
then
exec /bin/sh
else
#Switch to new root
mkdir -p /mnt/cdrom
mkdir -p /run/image/ro
mkdir -p /run/image/rw/data
mkdir -p /run/image/rw/work
uuid=$(xargs -n1 -a /proc/cmdline | sed '/^mountid/!d' | sed 's/.*=//g')
device=$(blkid | sed -n "/${uuid}/p" | sed 's/:.*//g')
time_out=120
while [ -z "$device" ]
do
if [ $time_out == 0 ]
then
break
else
time_out=$((time_out - 1))
fi
sleep 0.5
device=$(blkid | sed -n "/${uuid}/p" | sed 's/:.*//g')
done
mount -t ext4 $device /mnt/cdrom
mount -t squashfs -o defaults,ro /mnt/cdrom/live-install/rootfs.sfs /run/image/ro
mount -t overlay -o lowerdir=/run/image/ro,upperdir=/run/image/rw/data,workdir=/run/image/rw/work overlay /new_root
udevadm control --exit
udevadm info --cleanup-db
mount -n -o move /run /new_root/run
mount -n -o move /tmp /new_root/tmp
mount -n -o move /dev /new_root/dev
mount -n -o move /sys /new_root/sys
mount -n -o move /proc /new_root/proc
exec switch_root -c /dev/console /new_root /sbin/init "$@"
fi
EOF
chmod +x init
find . | cpio -oH newc | zstd -T0 -3 > ../initramfs.img
cd ..

