#!/bin/sh
cmds=('echo salut' 'echo adi')
for cm in "${cmds[@]}";
do
	/calnau/$cm
done
