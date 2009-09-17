#!/bin/bash -e
# To mount home directory from a pendrive configured with a crypto LVM home partition
DEVICE=/dev/sdb
if [ "x$1" != "x" ]; then
  DEVICE=$1
fi
cryptsetup luksOpen $DEVICE mypen
pvscan
vgchange -a y
mount /dev/cryptvg/home /home
