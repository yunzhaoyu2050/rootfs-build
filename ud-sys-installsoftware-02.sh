#!/bin/bash -e

ROOTFS_USER=$1

function print_terminal() {
    echo -e "\033[32m $0 $@\033[0m"
    $@
    if [ $? -ne 0 ]; then
        return 1
    fi
    return 0
}

# ----------------------------------------software_install---------------------------------------
echo -e "\033[34m install softeware\033[0m"
# update software
print_terminal apt-get update
print_terminal apt-get install -y
print_terminal apt --fix-broken install

#apt-get install -y locales --no-install-recommends
#dpkg-reconfigure locales

print_terminal apt-get install -y udev sudo ssh vim keyboard-configuration --no-install-recommends
# config user authority
#print_terminal sed -i '16a admin   ALL=(ALL:ALL) ALL' etc/sudoers
echo "admin   ALL=(ALL:ALL) ALL" >> etc/sudoers
print_terminal sed -i 's/PATH=\"\/usr\/local\/bin:\/usr\/bin:\/bin:\/usr\/local\/games:\/usr\/games\"/PATH=\"\/usr\/local\/bin:\/usr\/bin:\/bin:\/usr\/local\/games:\/usr\/games:\/usr\/sbin\"/' etc/profile

# power management
print_terminal apt-get install -y busybox pm-utils triggerhappy
cp /etc/Powermanager/triggerhappy.service /lib/systemd/system/triggerhappy.service

print_terminal apt-get install -y ifupdown net-tools ethtool --no-install-recommends

print_terminal apt-get install -y network-manager --no-install-recommends <<EOF
Y
EOF

print_terminal apt-get install -y rsyslog bash-completion htop --no-install-recommends --fix-missing

print_terminal apt-get install -y openssh-server --no-install-recommends

# wlan tools
print_terminal apt-get install -y wireless-tools wpasupplicant iputils-ping --no-install-recommends

# bluetooth tools
print_terminal apt-get install -y bluez bluez-hcidump --no-install-recommends

# minicom
print_terminal apt-get install -y minicom --no-install-recommends
print_terminal apt-get install -y microcom --no-install-recommends

# ppp
print_terminal apt-get install -y ppp --no-install-recommends

# udhcpc
print_terminal apt-get install -y udhcpc --no-install-recommends

# can-utils
print_terminal apt-get install -y can-utils --no-install-recommends

# x ---------------------------------------------------------------------------------------------
# for user define
echo -e "\033[34m install x-window-system-core\033[0m"
# x-window-system-core
print_terminal apt-get install -y x-window-system-core --no-install-recommends
if [ $? -ne 0 ]; then
    print_terminalapt-get update
    print_terminal apt-get install -y
    print_terminal apt --fix-broken install
    print_terminal apt-get install -y x-window-system-core --no-install-recommends
fi
echo -e "\033[34m install electron app.and depend\033[0m"
print_terminal apt-get install -y libnss3 atk-1.0 at-spi libgdk-pixbuf2.0-0 libgtk-3-0 libasound2 --no-install-recommends
print_terminal /bin/bash /home/electron/electron-install.sh # install electron app
# x ---------------------------------------------------------------------------------------------
# ----------------------------------------software_install---------------------------------------
