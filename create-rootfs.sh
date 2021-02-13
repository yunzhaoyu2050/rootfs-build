# create-rootfs.sh
#!/bin/bash -e

if [[ -z $RF_SYSTEM_TYPE || -z $RF_SYSTEM_VERSION || -z $RF_SOURCE_ROOTFS_PATH || -z $RF_ARCH ]]; then
    echo -e "\033[34m please config board-config-info.shh, and <source> it.\033[0m"
    exit 1
fi

echo -e "\033[34m Create rootfs ...\033[0m"

# 拷贝qemu
if [ $RF_ARCH == "arm64" ]
then
    sudo cp -a /usr/bin/qemu-aarch64-static $RF_SOURCE_ROOTFS_PATH/usr/bin/
    sudo chmod +x $RF_SOURCE_ROOTFS_PATH/usr/bin/qemu-aarch64-static
elif [ $RF_ARCH == "armhf" ]
then
    sudo cp -a /usr/bin/qemu-arm-static $RF_SOURCE_ROOTFS_PATH/usr/bin/
    sudo chmod +x $RF_SOURCE_ROOTFS_PATH/usr/bin/qemu-arm-static
else
    echo -e "\033[31m RF_ARCH is none, please config board-config-info.shh.\033[0m"
    exit 1
fi

# 挂载根文件系统到主机上
sudo mount --bind /dev $RF_SOURCE_ROOTFS_PATH/dev/
#sudo mount --bind /sys $RF_SOURCE_ROOTFS_PATH/sys/
#sudo mount --bind /proc $RF_SOURCE_ROOTFS_PATH/proc/
#sudo mount --bind /dev/pts $RF_SOURCE_ROOTFS_PATH/dev/pts/

# 解压debian
sudo LC_ALL=C LANGUAGE=C LANG=C chroot $RF_SOURCE_ROOTFS_PATH /debootstrap/debootstrap --second-stage --verbose

#-------------------------------user define-------------------------------
echo Copy user files...
# overlay folder
sudo cp -rf overlay/* $RF_SOURCE_ROOTFS_PATH/

# overlay-firmware folder
sudo cp -rf overlay-firmware/* $RF_SOURCE_ROOTFS_PATH/

# overlay-debug folder
# adb, video, camera  test file
sudo cp -rf overlay-debug/* $RF_SOURCE_ROOTFS_PATH/

# hack the serial
sudo cp -f overlay/usr/lib/systemd/system/serial-getty@.service $RF_SOURCE_ROOTFS_PATH/lib/systemd/system/serial-getty@.service

# adb
if [ "$ARCH" == "armhf" ]; then
    sudo cp -rf overlay-debug/usr/local/share/adb/adbd-32 $RF_SOURCE_ROOTFS_PATH/usr/local/bin/adbd
elif [ "$ARCH" == "arm64" ]; then
    sudo cp -rf overlay-debug/usr/local/share/adb/adbd-64 $RF_SOURCE_ROOTFS_PATH/usr/local/bin/adbd
fi

# bt/wifi firmware
if [ "$ARCH" == "armhf" ]; then
    sudo cp overlay-firmware/usr/bin/brcm_patchram_plus1_32 $RF_SOURCE_ROOTFS_PATH/usr/bin/brcm_patchram_plus1
    sudo cp overlay-firmware/usr/bin/rk_wifi_init_32 $RF_SOURCE_ROOTFS_PATH/usr/bin/rk_wifi_init
elif [ "$ARCH" == "arm64" ]; then
    sudo cp overlay-firmware/usr/bin/brcm_patchram_plus1_64 $RF_SOURCE_ROOTFS_PATH/usr/bin/brcm_patchram_plus1
    sudo cp overlay-firmware/usr/bin/rk_wifi_init_64 $RF_SOURCE_ROOTFS_PATH/usr/bin/rk_wifi_init
fi
sudo mkdir -p $RF_SOURCE_ROOTFS_PATH/system/lib/modules/
sudo find $RF_WLAN_KERNEL_MODULE_PATH/*  -name "*.ko" | xargs -n1 -i sudo cp {} $RF_SOURCE_ROOTFS_PATH/system/lib/modules/

# adb
if [ "$ARCH" == "armhf" ]; then
    sudo cp -rf overlay-debug/usr/local/share/adb/adbd-32 $RF_SOURCE_ROOTFS_PATH/usr/local/bin/adbd
elif [ "$ARCH" == "arm64" ]; then
    sudo cp -rf overlay-debug/usr/local/share/adb/adbd-64 $RF_SOURCE_ROOTFS_PATH/usr/local/bin/adbd
fi

# kernel module
if [ -d $TEMP_IMG_PATH ]; then
    sudo cp -arf $RF_KERNEL_MODULE_PATH/* $RF_SOURCE_ROOTFS_PATH/lib/
else
    echo -e "\033[31m kernel module error at $RF_KERNEL_MODULE_PATH.\033[0m"
fi
#-------------------------------user define------------------------------

#-------------------------------user define------------------------------
echo Chroot rootfs...
# 进入根文件系统配置
sudo chroot $RF_SOURCE_ROOTFS_PATH << EOF
# 配置新用户
USER=admin
HOST=server
useradd -G sudo -m -s /bin/bash $USER
passwd -S $USER
passwd -S root
echo "admin" | passwd $USER
echo "admin" | passwd root

# 配置主机名和以太网
echo $HOST > /etc/hostname
#sudo hostnamectl set-hostname $HOST
echo "127.0.0.1 $HOST" >> /etc/hosts
echo "127.0.0.1 localhost.localdomain localhost" > /etc/hosts

echo "auto eth0" > /etc/network/interfaces.d/eth0
echo "iface eth0 inet dhcp" >> /etc/network/interfaces.d/eth0
echo "nameserver 8.8.8.8 " >> /etc/resolv.conf

# 安装软件包
apt-get update
apt-get install -y udev sudo ssh --no-install-recommends 

chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
chmod +x /etc/rc.local

# 配置power management
apt-get install -y busybox pm-utils triggerhappy
cp /etc/Powermanager/triggerhappy.service  /lib/systemd/system/triggerhappy.service

# 必须安装systemd，否则系统无法挂载
apt-get install -y ifupdown net-tools network-manager ethtool --no-install-recommends 
apt-get install vim 
apt-get install -y rsyslog bash-completion htop --no-install-recommends --fix-missing

# 无线网络配置工具
apt-get install -y wireless-tools wpasupplicant iputils-ping --no-install-recommends 

systemctl enable rockchip.service
systemctl mask systemd-networkd-wait-online.service
systemctl mask NetworkManager-wait-online.service

# 将里面的TimeoutStartSec=5min  修改为TimeoutStartSec=5sec，解决开机无网络需长时间等待的问题。
sed -i 's/5min/5sec/g' /etc/systemd/system/network-online.target.wants/networking.service

apt-get clean
exit
EOF
#-------------------------------user define------------------------------

#sudo umount $RF_SOURCE_ROOTFS_PATH/sys/
#sudo umount $RF_SOURCE_ROOTFS_PATH/proc/
#sudo umount $RF_SOURCE_ROOTFS_PATH/dev/pts/
sudo umount $RF_SOURCE_ROOTFS_PATH/dev/

echo -e "\033[34m Create rootfs end.\033[0m"
