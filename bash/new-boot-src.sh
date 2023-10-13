#!/bin/bash
set -e

BOOT_LOCATION="/boot"
BOOT_DISK="/dev/nvme1n1p1"
USER="gramar"
INITRAMFS_LOCATION="/root/initramfs"

BOOT_DISK_MOUNTED_CORRECTLY="y"
BOOT_DISK_MOUNTED_INCORRECTLY="i"
BOOT_DISK_NOT_MOUNTED="n"

check_boot_mounted() {
	GREP_RES=$(grep "$BOOT_DISK" /proc/mounts)
	if [ -z "$GREP_RES" ] ; then
		echo "$BOOT_DISK_NOT_MOUNTED"
	else
		BOOT_GREP_RES=$(echo "$GREP_RES" | grep -qs "$BOOT_LOCATION")
		if [ $? == 0 ] ; then
			echo "$BOOT_DISK_MOUNTED_CORRECTLY"
		else
			echo "$BOOT_DISK_MOUNTED_INCORRECTLY"
		fi
	fi
}

cleanup() {
	BOOT_MOUNTED_RES=$(check_boot_mounted)
	if [ "$BOOT_MOUNTED_RES" == "$BOOT_DISK_MOUNTED_CORRECTLY" ] ; then
		echo "Unmounting boot"
		umount /boot
	fi
}

trap cleanup EXIT

# Check args correctness

if [ -z "$1" ]; then
	echo "Need kernel version to use supplied as first argument"
	exit 1
fi

# Check that first arg is at least an existing file

if stat "$1" >> /dev/null ; then
	echo "Using $1"
else
	echo "Failed to stat $1 needs to be kernel source directory"
	exit 1
fi

# Get Linux version, ex: "linux-6.5.2-gentoo"
VERSION=$(basename $1)

# Path to built boot image
IMG="/usr/src/$VERSION/arch/x86/boot/bzImage"

# Check that the image exists
if stat "$IMG" >> /dev/null ; then
	echo "Found built kernel image at $IMG"
else
	echo "Could not find built kernel image at $IMG, kernel needs to be built"
	exi t1
fi

# Check that the initramfs seems okay
if stat "$INITRAMFS_LOCATION" >> /dev/null ; then
	# Easy to forget to place the init executable file in there
	if stat "$INITRAMFS_LOCATION/init" >> /dev/null ; then
		echo "Found correctly setup initramfs at $INITRAMFS_LOCATION"
	else
		echo "Initramfs directory $INITRAMFS_LOCATION does not contain $INITRAMFS_LOCATION/init"
		exit 1
	fi
else
	echo "Didn't find the expected initramfs directory at $INITRAMFS_LOCATION"
	exit 1
fi

BOOT_MOUNTED_RES=$(check_boot_mounted)

# Check that the boot disk mount point looks correct
if [ "$BOOT_MOUNTED_RES" == "$BOOT_DISK_MOUNTED_INCORRECTLY" ] ; then
	echo "$BOOT_DISK is mounted on a bad mount point"
	exit 1
elif [ "$BOOT_MOUNTED_RES" == "$BOOT_DISK_MOUNTED_CORRECTLY" ] ; then
	echo "$BOOT_DISK is mounted correctly"
elif [ "$BOOT_MOUNTED_RES" == "$BOOT_DISK_NOT_MOUNTED" ] ; then
	echo "Mounting $BOOT_DISK to $BOOT_LOCATION"
	mount "$BOOT_DISK" "$BOOT_LOCATION"
fi

# Build boot-strap
REPO="/home/$USER/code/rust/boot-rs"
runuser -l "$USER" -c "source /home/$USER/.zshrc && cd $REPO && ./build_strap.sh --profile lto"

# Make sure it was built
if stat "$REPO/target/x86_64-unknown-linux-gnu/lto/boot-strap" >> /dev/null ; then
	echo "Successfully built boot-strap"
else
	echo "Failed to find result binary for boot-strap"
	exit1
fi

read -p "Everything checks out, continue writing kernel image to boot disk? [y]: " WRITE_IMG

# Continue to write the new kernel image to disk, if requested
if [[ "y" == "$WRITE_IMG" ]] ; then
	"$REPO/target/x86_64-unknown-linux-gnu/lto/boot-strap" boot -i "$IMG" -e "/boot/EFI/gentoo/$VERSION.enc" -c "$REPO/boot.cfg" -d "HD(1,GPT,bbd3c021-aa1f-6140-a8d5-854a096b17ca,0x800,0x100000)" -p "/EFI/gentoo/$VERSION.enc"
else
	echo "Exiting"
	exit 0
fi

# Build boot image
runuser -l "$USER" -c "source /home/$USER/.zshrc && cd $REPO && ./build_boot.sh --profile lto"

NEW_BOOT_IMG="$REPO/target/x86_64-unknown-uefi/lto/boot-rs.efi"

# Check that the new boot image was built
if stat "$NEW_BOOT_IMG" >> /dev/null ; then
	echo "Successfully built boot-image"
else
	echo "Failed to find result binary for boot-image at $NEW_BOOT_IMG"
	exit1
fi

# Check if a boot image already exists
BOOT_IMG_DEST="/boot/EFI/boot-rs.efi"
if stat "$BOOT_IMG_DEST" >> /dev/null ; then
	read -p "Make a backup of the old boot image? [y]: " MAKE_BACKUP
	# Backup if requested
	if [[ "y" == $MAKE_BACKUP ]] ; then
		cp "$BOOT_IMG_DEST" "$BOOT_IMG_DEST.bak"
		echo "Backed up old boot image to $BOOT_IMG_DEST.bak"
	fi
else
	echo "No old boot image found at $BOOT_IMG_DEST, skipping backup"
fi

read -p "Write new boot image to $BOOT_IMG_DEST? [y]: " EXEC_WRITE

# Check if user wants to do the bootloader overwrite
if [[ "y" == $EXEC_WRITE ]] ; then
	# Copy over the new bootloader
	cp "$NEW_BOOT_IMG" "$BOOT_IMG_DEST"
	echo "Wrote new boot image to $NEW_BOOT_IMG"
else 
	echo "Exiting"
	exit 0
fi

echo "Successfully built new kernel boot"

