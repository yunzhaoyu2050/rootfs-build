#!/bin/bash -e

# need board-config-info.shh :
#   RF_SYSTEM_TYPE: debian , ubuntu
#   RF_SYSTEM_VERSION: stretch debian9 , buster debian10
#   RF_SOURCE_ROOTFS_PATH: ./debian_rootfs/
#   image-cache/

if [[ -z $RF_SYSTEM_TYPE || -z $RF_SYSTEM_VERSION || -z $RF_SOURCE_ROOTFS_PATH ]]; then
    echo -e "\033[34m please config board-config-info.shh, and <source> it.\033[0m"
    exit 1
fi

TEMP_IMG_PATH=./image-cache/
IMG_NAME=${RF_SYSTEM_TYPE}-${RF_SYSTEM_VERSION}-rootfs.img

function err_exit() {
    sudo umount $TEMP_IMG_PATH/
    exit 1
}
trap err_exit ERR

function int_exit() {
    sudo umount $TEMP_IMG_PATH/
    exit 1
}
trap int_exit INT

echo -e "\033[32m Creat $RF_SYSTEM_TYPE $RF_SYSTEM_VERSION rootfs...\033[0m"

if [ -d $TEMP_IMG_PATH ]; then
    sudo rm -rf $TEMP_IMG_PATH
fi

mkdir $TEMP_IMG_PATH

dd if=/dev/zero of=$IMG_NAME bs=1M count=4000 # default 4g

echo format image file:$IMG_NAME
mkfs.ext4 $IMG_NAME # ext4 img

sudo mount $IMG_NAME $TEMP_IMG_PATH/

sudo cp -rfp $RF_SOURCE_ROOTFS_PATH/* $TEMP_IMG_PATH/

sudo umount $TEMP_IMG_PATH/

e2fsck -p -f $IMG_NAME

echo resize image file:$IMG_NAME
resize2fs -M $IMG_NAME

echo -e "\033[32m output img file:./$IMG_NAME\033[0m"
