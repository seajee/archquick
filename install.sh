#!/usr/bin/env bash

# For reference: https://wiki.archlinux.org/title/Installation_guide

# TODO:
# - Add support for BIOS platform
# - Add more filesystem options (defaults to ext4)
# - Make script recoverable from errors (save script stage)
# - Add support for custom localization configuration (defaults to en_US.UTF-8)

platform="bios"
input=""
disk="/dev/sda"

echoerr() { cat <<< "$@" 1>&2; }

# Check if script is being run as root
if [[ $(id -u) -ne 0 ]]; then
    echoerr "[ERROR] This script needs root permissions to be executed"
    exit 1
fi

# Verify the boot mode
if [[ ! -f "/sys/firmware/efi/fw_platform_size" ]]; then
    echoerr "[ERROR] Non UEFI platforms are not supported by this script"
    exit 2
else
    platform=$(cat /sys/firmware/efi/fw_platform_size)
    echo "[INFO] Platform: ${platform}-bit UEFI"
fi

# Test internet connectivity
if ! ping -q -c1 archlinux.org &>/dev/null; then
    echoerr "[ERROR] Not connected to the internet"
    exit 3
else
    echo "[INFO] Connected to the internet"
fi

# Select disk to be partitioned
echo -e "[INFO] Printing available disks\n"
fdisk -l

read -p "Enter installation disk (${disk}): " input
if [[ -n "$input" ]]; then
    disk="$input"
fi

if [[ ! -b "$disk" ]]; then
    echoerr "[ERROR] The selected disk does not exist"
    exit 4
fi

# Partition the disk
echo "[INFO] Partitioning the disk with the following layout:"
echo "    | Mount point | Partition Type        | Size                    |"
echo "    |-------------|-----------------------|-------------------------|"
echo "    | /boot       | EFI system partition  | 1 GiB                   |"
echo "    | /swapfile   | Linux swap            | 4 GiB                   |"
echo "    | /           | Linux x86-64 root (/) | Remainder of the device |"
(
echo g # Create a new empty GPT partition table

# EFI system partition
echo n       # Add a new partition
echo 1       # Partition number
echo         # First sector (accept default)
echo "+1GiB" # Last sector
echo t       # Change partition type
echo "uefi"  # "EFI system" partition type

# Root partition
echo n       # Add a new partition
echo 2       # Partition number
echo         # First sector (accept default)
echo         # Last sector (accept default)
echo t       # Change partition type
echo 2       # Select partition
echo 23      # "Linux root (x86-64)" partition type

echo w # Write changes
) | fdisk "$disk" &>/dev/null

# TODO: Check if fdisk terminated succesfully

# Format the partitions
echo "[INFO] Formatting the partitions"
mkfs.fat -F 32 "${disk}1" &>/dev/null
mkfs.ext4 "${disk}2" &>/dev/null

# TODO: Check if formatting the partitions went correctly

# Mount the file systems
echo "[INFO] Mounting the file systems"
mount "${disk}2" /mnt
mount --mkdir "${disk}1" /mnt/boot

# Swap file
echo "[INFO] Creating the swap file"
mkswap -U clear --size 4G --file /mnt/swapfile &>/dev/null
swapon /mnt/swapfile

# TODO: Select the mirrors for faster download speeds

# Install essential packages
echo "[INFO] Installing essential packages"
pacstrap -K /mnt base linux linux-firmware \
    intel-ucode amd-ucode \
    networkmanager \
    grub efibootmgr \
    less

# Generate the fstab file
echo "[INFO] Generating fstab file"
genfstab -U /mnt >> /mnt/etc/fstab

# Change root into the new system
cp ./chroot.sh /mnt/chroot.sh

echo "[INFO] Changing root into the new system"
arch-chroot /mnt bash /chroot.sh

# Unmount partitions
swapoff -a
umount -R /mnt

# Tell the user that it's ok to reboot now
echo "[INFO] Now you also can say \"I use Arch, BTW\". Reboot when you're ready"

exit 0
