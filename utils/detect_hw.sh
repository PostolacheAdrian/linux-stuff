#!/bin/sh
#modalias=$(fd 'modalias' /sys -X cat)
modalias=$(find /sys -name 'modalias' | xargs cat)
deps=$(modprobe -a -i -D ${modalias} 2>/dev/null | sort -u) #| rg -v '^builtin')
echo $deps
