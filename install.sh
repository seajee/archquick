#!/usr/bin/env bash

# For reference: https://wiki.archlinux.org/title/Installation_guide

# TODO:
# - Add support for BIOS platform
# - Add more filesystem options (defaults to ext4)
# - Make script recoverable from errors (save script stage)
# - Add support for custom localization configuration

platform="bios"
input=""
disk="/dev/sda"
timezone="Europe/Amsterdam"
hostname="arch"
password=""

echoerr() { cat <<< "$@" 1>&2; }

# Check is script is being run as root
if [[ $(id -u) -ne 0 ]]; then
    echoerr "[ERROR] Please run this script as root or using sudo"
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
echo "[INFO] Printing available disks"
fdisk -l

read -p "Enter installation disk (${disk}): " input
if [[ -n "$input" ]]; then
    disk="$input"
fi

if [[ ! -b "$disk" ]]; then
    echoerr "[ERROR] The selected disk does not exist"
    exit 4
fi

# Partition the disk with the following layout:
# | Mount point | Partition Type        | Size                    |
# |-------------|-----------------------|-------------------------|
# | /boot       | EFI system partition  | 1 GiB                   |
# | [SWAP]      | Linux swap            | 4 GiB                   |
# | /           | Linux x86-64 root (/) | Remainder of the device |
echo "[INFO] Partitioning the disk"
(
echo g # Create a new empty GPT partition table

# EFI system partition
echo n       # Add a new partition
echo 1       # Partition number
echo         # First sector (accept default: 2048)
echo "+1GiB" # Last sector
echo t       # Change partition type
echo "uefi"  # "EFI system partition" type

# Swap partition
echo n       # Add a new partition
echo 2       # Partition number
echo         # First sector (accept default)
echo "+4GiB" # Last sector
echo t       # Change partition type
echo 2       # Select partition
echo "swap"  # "Linux swap partition" type

# Root partition
echo n       # Add a new partition
echo 3       # Partition number
echo         # First sector (accept default)
echo         # Last sector (accept default)
echo t       # Change partition type
echo 3       # Select partition
echo 23      # "Linux x86-64 root (/) Linux" partition type

echo w # Write changes
) | fdisk "$disk" &>/dev/null

# TODO: Check if fdisk terminated succesfully

# Format the partitions
echo "[INFO] Formatting the partitions"
mkfs.ext4 "${disk}3" &>/dev/null
mkswap "${disk}2" &>/dev/null
mkfs.fat -F 32 "${disk}1" &>/dev/null

# TODO: Check if formatting the partitions went correctly

# Mount the file systems
echo "[INFO] Mounting the file systems"
mount "${disk}3" /mnt
mount --mkdir "${disk}1" /mnt/boot
swapon "${disk}2"

# TODO: Select the mirrors for faster download speeds

# Install essential packages
echo "[INFO] Installing essential packages"
pacstrap -K /mnt base linux linux-firmware \
    intel-ucode amd-ucode \
    networkmanager \
    grub efibootmgr

# Generate an fstab file
echo "[INFO] Generating fstab file"
genfstab -U /mnt >> /mnt/etc/fstab

# Change root into the new system
cp ./chroot.sh /mnt/chroot.sh

echo "[INFO] Changing root into the new system"
arch-chroot /mnt bash /chroot.sh

# Unmount partitions
umount -R /mnt

# Tell the user that it's ok to reboot now
echo "[INFO] Now you also can say \"I use Arch, BTW\". Reboot when you're ready"

exit 0
