#!/bin/sh
programs=$(busybox --list | sed 's/\\n/ /g' | sed '/busybox\|mount\|modprobe\|insmod\|kmod\|rmmod\|modprobe/d')
echo ${programs}
cd test
for prg in  ${programs}; do
	ln -sf busybox "$prg"
done
