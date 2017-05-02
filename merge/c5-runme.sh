#!/bin/sh -e

path=$(pwd)

if [ ! -d /mnt/upgrade ];
then
	mkdir /mnt/upgrade
fi

if [ -e /usr/bin/ctrl_bd ]; then
ret=`cat /usr/bin/ctrl_bd | grep "XILINX" | wc -l`
else
ret=0
fi

if [ $ret -eq 1 ];then
    echo "this is not for xilinx"
else
    mount -t jffs2 /dev/mtdblock4 /mnt/upgrade/
    cd /mnt/upgrade/upgrade
    rm -rf ./c5/*
    cd $path

    cp -rf ./c5/* /mnt/upgrade/upgrade

    flash_erase /dev/mtd2 0x0 0x1 >/dev/null 2>&1
    nandwrite -p -s 0x0 /dev/mtd2 /mnt/upgrade/upgrade/upgrade-marker.bin >/dev/null 2>&1

    sync
    umount /dev/mtdblock4
fi
 
rm -rf *.tar.gz


#/sbin/reboot -f &
