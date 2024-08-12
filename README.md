# archquick

archquick is a set of scripts to facilitate the process of quickly installing
Arch Linux.

## Quick start

To use the scripts run the following on a live Arch Linux environment:

```bash
$ pacman -Sy git
$ git clone --depth 1 https://github.com/seajee/archquick
$ cd archquick
$ ./install.sh
```

## Post-install

The suggested post-install configuration steps are:
- Configure the keymap for ttys via /etc/vconsole.conf

## End result

The installation scripts follow every step of the
[Arch Linux installation guide](https://wiki.archlinux.org/title/Installation_guide)
with no extra steps or modifications.

After the setup finishes you'll have a very basic Arch Linux installation with
just a root user and the only the necessary base packages installed.

Note:
- The installed bootloader is GRUB.
- The network configuration is done with NetworkManager.
