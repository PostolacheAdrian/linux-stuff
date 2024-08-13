#!/bin/sh
binfiles="sh mount kmod zstd udevadm"
libs=
for f in $binfiles; do
	#cp /bin/$file usr/bin
	libs="$libs $(ldd /bin/$f | sed 's/\t//' | cut -d " " -f1)"
done
libs=$(printf "%s\n" $libs | sort -u)
echo "$libs"
#mapfile -d '' -t libs < <(ldd /usr/bin/zstd | sed -E 's/.*=> //g' | sed -E 's/\(.*\)|\t.*//g' | sed -e "/^$/d")

#for file in "${libs[@]}"; do
#	cp ${file} usr/lib
#done
