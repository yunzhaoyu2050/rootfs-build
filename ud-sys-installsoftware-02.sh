#!/bin/bash -e

# ----------------------------------------software_install---------------------------------------
echo -e "\033[34m install softeware\033[0m"
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
apt-get install -y x-window-system-core --no-install-recommends
if [ $? -ne 0 ]; then
    apt-get update
    apt-get install -y
    apt --fix-broken install
    apt-get install -y x-window-system-core --no-install-recommends
fi
# ----------------------------------------software_install---------------------------------------
