#!/usr/bin/env bash

input=""
timezone="Europe/Amsterdam"
hostname="arch"
password=""

echoerr() { cat <<< "$@" 1>&2; }

# Set the time zone
while
    echo "[INFO] Time zone configuration. Type \"list\" to list time zones"
    read -p "Enter time zone (${timezone}): " input

    if [[ "$input" == "list" ]]; then
        awk '/^Z/ { print $2 }; /^L/ { print $3 }' /usr/share/zoneinfo/tzdata.zi | sort | less
        continue
    fi

    if [[ ! -f "/usr/share/zoneinfo/${input}" ]]; then
        echoerr "[ERROR] The selected time zone does not exist"
    else
        timezone="$input"
    fi

    [[ ! -f "/usr/share/zoneinfo/${input}" ]]
do true; done

echo "[INFO] Setting ${timezone} as the time zone"
ln -sf "/usr/share/zoneinfo/${timezone}" /etc/localtime
hwclock --systohc

# Localization
echo "[INFO] Setting locale to en_US"
sed -i -e "s|#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|" /etc/locale.gen
locale-gen &>/dev/null
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Network configuration
read -p "Enter a valid hostname (${hostname}): " input
if [[ -n "$input" ]]; then
    hostname="$input"
fi

echo "[INFO] Setting ${hostname} as the hostname"
echo "$hostname" > /etc/hostname

echo "[INFO] Enabling NetworkManager to start at boot"
systemctl enable NetworkManager &>/dev/null

# Set the root password
read -p "Enter a new password for the root user: " password
echo "root:${password}" | chpasswd

# Install the boot loader
echo "[INFO] Installing the GRUB boot loader"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable &>/dev/null
grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

# TODO: Check for errors with grub-install

# Self-delete this script as it is no longer required
rm -- "$0"

exit 0
