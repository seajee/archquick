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
