#!/bin/bash -e

if [[ -z $RF_SYSTEM_TYPE || -z $RF_SYSTEM_VERSION || -z $RF_SOURCE_ROOTFS_PATH || -z $RF_ARCH ]]; then
    echo -e "\033[34m please config board-config-info.shh, and <source> it.\033[0m"
    exit 1
fi

# 
# You need to configure yourself according to the hardware information 
# and requirements of each development board
# 

#-------------------------------user define-------------------------------
echo -e "\033[34m Copy user files.start.\033[0m"
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
if [ -d $RF_SOURCE_ROOTFS_PATH/lib ]; then
    sudo cp -arf $RF_KERNEL_MODULE_PATH/* $RF_SOURCE_ROOTFS_PATH/lib/
else
    echo -e "\033[31m kernel module error at $RF_KERNEL_MODULE_PATH.\033[0m"
fi
echo -e "\033[34m Copy user files.end.\033[0m"
#-------------------------------user define-------------------------------
