#!/bin/sh
# Try delete old, doesn't matter if exists
rm /tmp/arch-installer-bin
# Try unmount old, doesn't matter if not mounted
umount /mnt/home
umount /mnt/efi
umount /mnt
swapoff /dev/mapper/cswap
# Try closing old, doesn't matter if not mounted
cryptsetup close cswap
cryptsetup close chome
cryptsetup close croot
# Ready to run
curl -L https://github.com/MarcusGrass/linux-utils/blob/main/arch-installer-bin?raw=true -o /tmp/arch-installer-bin && chmod +x /tmp/arch-installer-bin && /tmp/arch-installer-bin --efi-device-name nvme0n1 --efi-device-root nvme0n1p1 --home-device-crypt-name chome --home-device-name nvme0n1p4 --home-device-root nvme0n1 --root-device-crypt-name croot --root-device-name nvme0n1p2 --root-device-root nvme0n1 --swap-device-name nvme0n1p3 --swap-device-root nvme0n1 --swap-device-crypt-name cswap
