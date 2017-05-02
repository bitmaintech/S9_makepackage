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
    cd ./xilinx
    
    if [ ! -e /dev/ubi_ctrl ];then
            echo "File system isn't UBI, Please update ubi package first!"
            cd $path
            rm -rf *.tar.gz
            exit 1
    fi
    
    if [ -e BOOT.bin ]; then
            flash_erase /dev/mtd0 0x0 0x80 >/dev/null 2>&1
            nandwrite -p -s 0x0 /dev/mtd0 ./BOOT.bin >/dev/null 2>&1
            rm -rf BOOT.bin
    fi

    if [ -e devicetree.dtb ]; then
            flash_erase /dev/mtd0 0x1020000 0x1 >/dev/null 2>&1
            nandwrite -p -s 0x1020000 /dev/mtd0 ./devicetree.dtb >/dev/null 2>&1
            rm devicetree.dtb
    fi

    if [ -e uImage ]; then 
            flash_erase /dev/mtd0 0x1100000 0x40 >/dev/null 2>&1
            nandwrite -p -s 0x1100000 /dev/mtd0 ./uImage >/dev/null 2>&1
            rm uImage
    fi

    if [ -e rootfs.jffs2 ]; then
            if [ -f /dev/mtd3 ];then
            flash_erase /dev/mtd2 0x0 0x1E0 >/dev/null 2>&1
            else
                flash_erase /dev/mtd2 0x0 0x280 >/dev/null 2>&1
            fi
            nandwrite -p -s 0x0 /dev/mtd2 ./rootfs.jffs2 >/dev/null 2>&1
            rm rootfs.jffs2
    fi

    ubiattach /dev/ubi_ctrl -m 2
    mount -t ubifs ubi1:rootfs /mnt/upgrade
    
    cd /mnt/upgrade/upgrade
    rm -rf /mnt/upgrade/upgrade/*
    cd $path

    if [ -e ./xilinx/angstrom_rootfs.jffs2 ];then
        md5=`md5sum ./xilinx/angstrom_rootfs.jffs2 | awk {'print $1'}`
        md5_r=`cat ubi_info`
        if [ $md5 == $md5_r ];then
            cp -rf ./xilinx/angstrom_rootfs.jffs2 /mnt/upgrade/upgrade
            if [ -f /dev/mtd3 ];then
                flash_erase /dev/mtd3 0 0xa0 >/dev/null 2>&1
            fi
        fi
    fi
    flash_erase /dev/mtd0 0x1040000 0x1 >/dev/null 2>&1
    nandwrite -p -s 0x1040000 /dev/mtd0 ./xilinx/upgrade-marker.bin >/dev/null 2>&1

    sync

    umount /mnt/upgrade
    ubidetach -d 1 /dev/ubi_ctrl
    
else
    echo "this is not for c5"
fi
 
rm -rf *.tar.gz


#/sbin/reboot -f &
