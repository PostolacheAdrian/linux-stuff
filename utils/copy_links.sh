#!/bin/sh
cp -a $1 $2
lnk=$(readlink -f $1)
[ -n "${lnk}" ] |  cp ${lnk} $2


