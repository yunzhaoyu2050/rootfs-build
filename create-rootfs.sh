# create-rootfs.sh
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

sudo mount --bind /dev $RF_SOURCE_ROOTFS_PATH/dev/
#sudo mount --bind /sys $RF_SOURCE_ROOTFS_PATH/sys/
sudo mount --bind /proc $RF_SOURCE_ROOTFS_PATH/proc/
sudo mount --bind /dev/pts $RF_SOURCE_ROOTFS_PATH/dev/pts/

echo -e "\033[34m Debootstrap rootfs...\033[0m"
# config debian
sudo LANGUAGE="en_US" LC_ALL=C LC_PAPER="zh_CN.UTF-8" LC_NUMERIC="zh_CN.UTF-8" LC_IDENTIFICATION="zh_CN.UTF-8" \
    LC_MEASUREMENT="zh_CN.UTF-8" LC_NAME="zh_CN.UTF-8" LC_TELEPHONE="zh_CN.UTF-8" LC_ADDRESS="zh_CN.UTF-8" \
    LC_MONETARY="zh_CN.UTF-8" LC_TIME="zh_CN.UTF-8" LANG="en_US.UTF-8" chroot $RF_SOURCE_ROOTFS_PATH /debootstrap/debootstrap --second-stage --verbose

#-------------------------------user define-------------------------------
echo -e "\033[34m Copy user files...\033[0m"
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
if [ "$RF_ARCH" == "armhf" ]; then
    sudo cp -rf overlay-debug/usr/local/share/adb/adbd-32 $RF_SOURCE_ROOTFS_PATH/usr/local/bin/adbd
elif [ "$RF_ARCH" == "arm64" ]; then
    sudo cp -rf overlay-debug/usr/local/share/adb/adbd-64 $RF_SOURCE_ROOTFS_PATH/usr/local/bin/adbd
fi
sudo chmod +x $RF_SOURCE_ROOTFS_PATH/usr/local/bin/adbd

# adb
if [ "$RF_ARCH" == "armhf" ]; then
    sudo cp -rf overlay-debug/usr/local/share/adb/adbd-32 $RF_SOURCE_ROOTFS_PATH/usr/local/bin/adbd
elif [ "$RF_ARCH" == "arm64" ]; then
    sudo cp -rf overlay-debug/usr/local/share/adb/adbd-64 $RF_SOURCE_ROOTFS_PATH/usr/local/bin/adbd
fi
sudo chmod +x $RF_SOURCE_ROOTFS_PATH/usr/local/bin/adbd

# bt/wifi firmware
if [ "$RF_ARCH" == "armhf" ]; then
    sudo cp overlay-firmware/usr/bin/brcm_patchram_plus1_32 $RF_SOURCE_ROOTFS_PATH/usr/bin/brcm_patchram_plus1
    sudo cp overlay-firmware/usr/bin/rk_wifi_init_32 $RF_SOURCE_ROOTFS_PATH/usr/bin/rk_wifi_init
elif [ "$RF_ARCH" == "arm64" ]; then
    sudo cp overlay-firmware/usr/bin/brcm_patchram_plus1_64 $RF_SOURCE_ROOTFS_PATH/usr/bin/brcm_patchram_plus1
    sudo cp overlay-firmware/usr/bin/rk_wifi_init_64 $RF_SOURCE_ROOTFS_PATH/usr/bin/rk_wifi_init
fi
sudo chmod +x $RF_SOURCE_ROOTFS_PATH/usr/bin/rk_wifi_init

sudo mkdir -p $RF_SOURCE_ROOTFS_PATH/system/lib/modules/
#sudo cp -f $RF_KERNEL_MODULE_PATH/modules/4.4.167/kernel/drivers/net/wireless/rockchip_wlan/rkwifi/bcmdhd/bcmdhd.ko $RF_SOURCE_ROOTFS_PATH/system/lib/modules/
sudo find $RF_WLAN_KERNEL_MODULE_PATH/* -name "*.ko" | xargs -n1 -i sudo cp {} $RF_SOURCE_ROOTFS_PATH/system/lib/modules/

# kernel module
if [ -d $TEMP_IMG_PATH ]; then
    sudo cp -arf $RF_KERNEL_MODULE_PATH/* $RF_SOURCE_ROOTFS_PATH/lib/
else
    echo -e "\033[31m kernel module error at $RF_KERNEL_MODULE_PATH.\033[0m"
fi
#-------------------------------user define------------------------------

#-------------------------------user define------------------------------
echo -e "\033[34m Chroot rootfs and config software...\033[0m"
RF_USER=admin
RF_HOST=server
RF_USER_PASSWD=admin
RF_ROOT_PASSWD=admin

# config rootfs
sudo LANGUAGE="en_US" LC_ALL=C LC_PAPER="zh_CN.UTF-8" LC_NUMERIC="zh_CN.UTF-8" LC_IDENTIFICATION="zh_CN.UTF-8" \
    LC_MEASUREMENT="zh_CN.UTF-8" LC_NAME="zh_CN.UTF-8" LC_TELEPHONE="zh_CN.UTF-8" LC_ADDRESS="zh_CN.UTF-8" \
    LC_MONETARY="zh_CN.UTF-8" LC_TIME="zh_CN.UTF-8" LANG="en_US.UTF-8" chroot $RF_SOURCE_ROOTFS_PATH <<EOF
# ----------------------------------------user---------------------------------------------------
# add new user and passwd
sh /etc/app/cr_user_ps.sh $RF_USER $RF_USER_PASSWD # user , pass
sh /etc/app/cr_user_ps.sh root $RF_ROOT_PASSWD # user , pass
# ----------------------------------------user---------------------------------------------------

# ----------------------------------------host---------------------------------------------------
# add hostname and config network
echo $RF_HOST > /etc/hostname
echo "127.0.0.1 $RF_HOST" >> /etc/hosts
echo "127.0.0.1 localhost.localdomain localhost" >> /etc/hosts
# ----------------------------------------host---------------------------------------------------

# ----------------------------------------network------------------------------------------------
# config eth0
echo "auto eth0" > /etc/network/interfaces.d/eth0
echo "iface eth0 inet static" >> /etc/network/interfaces.d/eth0
echo "address 192.168.1.22" >> /etc/network/interfaces.d/eth0
echo "netmask 255.255.255.0" >> /etc/network/interfaces.d/eth0
echo "gateway 192.168.1.1" >> /etc/network/interfaces.d/eth0

# config wlan0
echo "auto wlan0" > /etc/network/interfaces.d/wlan0
echo "iface wlan0 inet dhcp" >> /etc/network/interfaces.d/wlan0
echo "    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf" >> /etc/network/interfaces.d/wlan0
# ----------------------------------------network------------------------------------------------

# ----------------------------------------udev---------------------------------------------------
# delete udev files
# 1.udev usb net mac
mv /lib/udev/rules.d/73-usb-net-by-mac.rules /lib/udev/rules.d/73-usb-net-by-mac.rules.bk
#rm -f 73-usb-net-by-mac.rules
# ----------------------------------------udev---------------------------------------------------

#chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
chmod +x /etc/rc.local

# ----------------------------------------software_install---------------------------------------
# update software
apt-get update

apt-get install -y

apt --fix-broken install

#apt-get install -y locales --no-install-recommends
#dpkg-reconfigure locales
apt-get install -y udev sudo ssh vim --no-install-recommends

# power management
apt-get install -y busybox pm-utils triggerhappy
cp /etc/Powermanager/triggerhappy.service /lib/systemd/system/triggerhappy.service

apt-get install -y ifupdown net-tools network-manager ethtool --no-install-recommends
apt-get install -y rsyslog bash-completion htop --no-install-recommends --fix-missing

# wlan tools
apt-get install -y wireless-tools wpasupplicant iputils-ping --no-install-recommends

# x-window-system-core 
#apt-get install x-window-system-core 
# ----------------------------------------software_install---------------------------------------

systemctl enable rockchip.service

# ----------------------------------------network------------------------------------------------
#systemctl mask systemd-networkd-wait-online.service
#systemctl mask NetworkManager-wait-online.service
# 将里面的TimeoutStartSec=5min  修改为TimeoutStartSec=5sec，解决开机无网络需长时间等待的问题。
sed -i 's/5min/5sec/g' /lib/systemd/system/networking.service
sed -i 's/oneshot/simple/g' /lib/systemd/system/networking.service # 替换networking.service的oneshot为simple
# ----------------------------------------network------------------------------------------------

apt-get clean
exit
EOF
#-------------------------------user define------------------------------

#sudo umount $RF_SOURCE_ROOTFS_PATH/sys/
sudo umount $RF_SOURCE_ROOTFS_PATH/proc/
sudo umount $RF_SOURCE_ROOTFS_PATH/dev/pts/
sudo umount $RF_SOURCE_ROOTFS_PATH/dev/

echo -e "\033[34m Create rootfs end.\033[0m"
