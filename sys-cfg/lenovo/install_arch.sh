#!/bin/sh
# Ignores errors
# Try delete old, doesn't matter if exists
rm /tmp/arch-installer-bin
# Try unmount old, doesn't matter if not mounted
umount /mnt/home
umount /mnt/efi
umount /mnt
CRYPT_SWAP_NAME=cswap
CRYPT_HOME_NAME=chome
CRYPT_ROOT_NAME=croot
swapoff /dev/mapper/$CRYPT_SWAP_NAME
# Try closing old, doesn't matter if not mounted
cryptsetup close $CRYPT_SWAP_NAME
cryptsetup close $CRYPT_HOME_NAME
cryptsetup close $CRYPT_ROOT_NAME
ROOT_NAME=nvme0n1
# Ready to run
curl -L https://github.com/MarcusGrass/linux-utils/blob/main/arch-installer-bin?raw=true -o /tmp/arch-installer-bin && chmod +x /tmp/arch-installer-bin && /tmp/arch-installer-bin stage1 --efi-device-name nvme0n1p1 --efi-device-root $ROOT_NAME --home-device-crypt-name $CRYPT_HOME_NAME --home-device-name nvme0n1p4 --home-device-root $ROOT_NAME --root-device-crypt-name $CRYPT_ROOT_NAME --root-device-name nvme0n1p2 --root-device-root $ROOT_NAME --swap-device-name nvme0n1p3 --swap-device-root $ROOT_NAME --swap-device-crypt-name $CRYPT_SWAP_NAME
