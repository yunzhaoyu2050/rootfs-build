#!/bin/bash -e

if [[ -z $RF_SYSTEM_TYPE || -z $RF_SYSTEM_VERSION || -z $RF_SOURCE_ROOTFS_PATH || -z $RF_ARCH ]]; then
    echo -e "\033[34m please config board-config-info.shh, and <source> it.\033[0m"
    exit 1
fi

echo -e "\033[34m Create rootfs ...\033[0m"

# copy qemu
if [ $RF_ARCH == "arm64" ]; then
    sudo cp -a /usr/bin/qemu-aarch64-static $RF_SOURCE_ROOTFS_PATH/usr/bin/
    sudo chmod +x $RF_SOURCE_ROOTFS_PATH/usr/bin/qemu-aarch64-static
elif [ $RF_ARCH == "armhf" ]; then
    sudo cp -a /usr/bin/qemu-arm-static $RF_SOURCE_ROOTFS_PATH/usr/bin/
    sudo chmod +x $RF_SOURCE_ROOTFS_PATH/usr/bin/qemu-arm-static
else
    echo -e "\033[31m RF_ARCH is none, please config board-config-info.shh.\033[0m"
    exit 1
fi

function umount_user_fs() {
    #sudo umount $RF_SOURCE_ROOTFS_PATH/sys/
    sudo umount $RF_SOURCE_ROOTFS_PATH/dev/pts/
    sudo umount $RF_SOURCE_ROOTFS_PATH/proc/
    sudo umount $RF_SOURCE_ROOTFS_PATH/dev/
}

function err_exit() {
    #sudo umount $RF_SOURCE_ROOTFS_PATH/sys/
    sudo umount $RF_SOURCE_ROOTFS_PATH/dev/pts/
    sudo umount $RF_SOURCE_ROOTFS_PATH/proc/
    sudo umount $RF_SOURCE_ROOTFS_PATH/dev/
    exit 1
}
trap err_exit ERR

function int_exit() {
    #sudo umount $RF_SOURCE_ROOTFS_PATH/sys/
    sudo umount $RF_SOURCE_ROOTFS_PATH/dev/pts/
    sudo umount $RF_SOURCE_ROOTFS_PATH/proc/
    sudo umount $RF_SOURCE_ROOTFS_PATH/dev/
    exit 1
}
trap int_exit INT

echo -e "\033[34m Debootstrap rootfs...\033[0m"
# mount dev/ dev/pst proc/
sudo mount --bind /dev $RF_SOURCE_ROOTFS_PATH/dev/
sudo mount --bind /proc $RF_SOURCE_ROOTFS_PATH/proc/
sudo mount --bind /dev/pts $RF_SOURCE_ROOTFS_PATH/dev/pts/
#sudo mount --bind /sys $RF_SOURCE_ROOTFS_PATH/sys/

# config debian
sudo LC_ALL=C chroot $RF_SOURCE_ROOTFS_PATH /debootstrap/debootstrap --second-stage --verbose
if [ $? -ne 0 ]; then
    echo -e "\033[31m debootstrap failed,please check error.\033[0m"
    exit 1
fi
#-------------------------------user define-------------------------------
chmod +x ud-copyfiles.sh
./ud-copyfiles.sh # use own shell script
if [ $? -ne 0 ];then
    echo -e "\033[31m user define ud-copyfiles.sh failed,please check error.\033[0m"
fi
#-------------------------------user define------------------------------

sudo cp -f ./ud-sys-*.sh $RF_SOURCE_ROOTFS_PATH/etc/app/ # Copy the script starting with ud-sys-

#-------------------------------user define------------------------------
echo -e "\033[34m Chroot rootfs and config software...\033[0m"
# config rootfs
sudo LC_ALL=C chroot $RF_SOURCE_ROOTFS_PATH <<EOF
chmod +x /etc/app/ud-sys-*.sh
bash /etc/app/ud-sys-configsystem-01.sh $RF_USER $RF_USER_PASSWD $RF_ROOT_PASSWD $RF_HOST
bash /etc/app/ud-sys-installsoftware-02.sh 
apt-get clean
exit
EOF
#-------------------------------user define------------------------------

# umount dev/ dev/pst proc/
#sudo umount $RF_SOURCE_ROOTFS_PATH/sys/
sudo umount $RF_SOURCE_ROOTFS_PATH/dev/pts/
sudo umount $RF_SOURCE_ROOTFS_PATH/proc/
sudo umount $RF_SOURCE_ROOTFS_PATH/dev/

echo -e "\033[34m Create rootfs end.\033[0m"
