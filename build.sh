#!/bin/bash -e

chmod +x *.sh *.shh

source ./board-config-info.shh

./download_rootfs.sh

./create-rootfs.sh

./create-image.sh
