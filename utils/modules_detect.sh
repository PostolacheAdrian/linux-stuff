#!/bin/bash
#shopt -s extglob
uevents=
while [ -z "$uevents" ]
do
	uevents=$(LC_ALL=C.UTF-8 find /sys/devices -name uevent | xargs cat |  sort -u )
	if [ -n "$uevents" ]
	then
		break
	fi
	sleep 1
done	
mapfile -t modules < <(sed -n 's/\(DRIVER\|MODALIAS\)=\(.\+\)/\2/p' <<<"$uevents")
mapfile -t modules < <(modprobe -qaR "${modules[@]}" | LC_ALL=C.UTF-8 sort -u)
for module in ${modules[@]}
do
	echo $module
done

