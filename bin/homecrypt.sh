#!/bin/sh -e
DEV=/dev/sdb
DEVALIAS=mypen
if [ "x$1" != "x" ]; then
  DEV=$1
fi
cryptsetup luksOpen $DEV $DEVALIAS
pvscan
vgchange -a y cryptvg
mount /dev/cryptvg/home /home
mount /dev/cryptvg/grab /var/grab
