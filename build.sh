#!/bin/bash -e

chmod +x *.sh *.shh

source board-config-info.shh
echo -e "\033[32m Config :system_type:$RF_SYSTEM_TYPE, system_version:$RF_SYSTEM_VERSION.\n
         source_rootfs_path:$RF_SOURCE_ROOTFS_PATH.\n
         arch:$RF_ARCH.\033[0m"

echo -e "\033[32m Download source rootfs.\033[0m"
./download_rootfs.sh
if [ $? -ne 0 ]
then
    echo -e "\033[31m download_rootfs.sh failed.\033[0m"
    exit 1
fi

echo -e "\033[32m Create rootfs.\033[0m"
./create-rootfs.sh
if [ $? -ne 0 ]
then
    echo -e "\033[31m create-rootfs.sh failed.\033[0m"
    exit 1
fi

echo -e "\033[32m Create image.\033[0m"
./create-image.sh
if [ $? -ne 0 ]
then
    echo -e "\033[31m create-image.sh failed.\033[0m"
    exit 1
fi
