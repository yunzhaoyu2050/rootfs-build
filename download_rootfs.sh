#!/bin/bash -e

if [[ -z $RF_SYSTEM_TYPE || -z $RF_SYSTEM_VERSION || -z $RF_SOURCE_ROOTFS_PATH || -z $RF_ARCH ]]; then
    echo -e "\033[34m please config board-config-info.shh, and <source> it.\033[0m"
    exit 1
fi

if [ "$RF_SYSTEM_TYPE" == "ubuntu" ]; then
    echo -e "\033[31m unsupport create ubuntu rootfs.\033[0m"
    exit 1
fi

sudo apt-get install qemu qemu-user-static binfmt-support debootstrap

echo "Download $RF_ARCH $RF_SYSTEM_VERSION rootfs"

# stretch debian9 , buster debian10
# 清华镜像源：https://mirrors.tuna.tsinghua.edu.cn/debian/
# 阿里镜像源：http://mirrors.aliyun.com/debian
# 下载Debian根文件系统和模拟器
sudo debootstrap --arch="$RF_ARCH" --foreign "$RF_SYSTEM_VERSION" "$RF_SOURCE_ROOTFS_PATH" http://mirrors.aliyun.com/debian/
if [ $? -ne 0 ]; then
    echo -e "\033[31m Download $RF_ARCH $RF_SYSTEM_VERSION rootfs failed.\033[0m"
    exit 1
fi
echo -e "\033[34m -->>download output file path:$RF_SOURCE_ROOTFS_PATH\033[0m"
