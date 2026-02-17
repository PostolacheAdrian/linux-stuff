#!/bin/sh
cmds=('echo salut' 'echo welcome')
for cm in "${cmds[@]}";
do
	$cm
done
