#!/bin/bash
#Apped a sequence
cat testfile | sed "/command=/s/\"$/ cmd4\"/"
cat testfile | sed "/command=.*/a/new line/"
#Modify a pattern
cat testfile | sed "/flag=/s/=.*/=false/"
#Uncomment a line
cat sudoers | sed "/wheel ALL=(ALL:ALL) ALL/s/^# //"





