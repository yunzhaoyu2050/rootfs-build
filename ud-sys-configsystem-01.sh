#!/bin/bash -e

ROOTFS_USER=$1
ROOTFS_USER_PASSWD=$2
ROOTFS_ROOT_PASSWD=$3
ROOTFS_HOST=$4

# ----------------------------------------user---------------------------------------------------
# add new user and passwd
echo -e "\033[34m add new user and passwd\033[0m"

sh /etc/app/cr_user_ps.sh $ROOTFS_USER $ROOTFS_USER_PASSWD
sh /etc/app/cr_user_ps.sh root $ROOTFS_ROOT_PASSWD
# ----------------------------------------user---------------------------------------------------

# ----------------------------------------host---------------------------------------------------
# add hostname and config network
echo -e "\033[34m add hostname and config network\033[0m"

echo $ROOTFS_HOST > /etc/hostname
echo "127.0.0.1 $ROOTFS_HOST" >> /etc/hosts
echo "127.0.0.1 localhost.localdomain localhost" >> /etc/hosts
# ----------------------------------------host---------------------------------------------------

# ----------------------------------------network------------------------------------------------
# config eth0
echo -e "\033[34m config eth0\033[0m"

echo "auto eth0" > /etc/network/interfaces.d/eth0
echo "iface eth0 inet static" >> /etc/network/interfaces.d/eth0
echo "address 169.254.24.22" >> /etc/network/interfaces.d/eth0
echo "netmask 255.255.0.0" >> /etc/network/interfaces.d/eth0
echo "gateway 169.254.24.1" >> /etc/network/interfaces.d/eth0

# config wlan0
echo -e "\033[34m config wlan0\033[0m"

echo "auto wlan0" > /etc/network/interfaces.d/wlan0
echo "iface wlan0 inet dhcp" >> /etc/network/interfaces.d/wlan0
echo "    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf" >> /etc/network/interfaces.d/wlan0

#
# 1.Change the TimeoutStartSec=5min inside to TimeoutStartSec=5sec 
#   to solve the problem that there is no network to wait for a long time to start.
# 2.Replace oneshot of network.service with simple
#
sed -i 's/5min/5sec/g' /lib/systemd/system/networking.service 
sed -i 's/oneshot/simple/g' /lib/systemd/system/networking.service
# ----------------------------------------network------------------------------------------------

# ----------------------------------------udev---------------------------------------------------
# delete udev files
# 1.udev usb net mac
mv /lib/udev/rules.d/73-usb-net-by-mac.rules /lib/udev/rules.d/73-usb-net-by-mac.rules.bk
#rm -f 73-usb-net-by-mac.rules
# ----------------------------------------udev---------------------------------------------------

#chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
chmod +x /etc/rc.local

echo -e "\033[34m enable rockchip.service\033[0m"
systemctl enable rockchip.service
