#!/bin/bash

#
# This script is for Arch Linux to download and install XRDP+XORGXRDP
#

if [ $(id -u) -eq 0 ] ; then
    echo 'This script must be run as a non-root user, as building packages as root is unsupported.' >&2
    exit 1
fi

###############################################################################
# Prepare by installing build tools.
#
# Partial upgrades aren't supported in arch.
sudo pacman -Syu --needed --noconfirm base base-devel git

###############################################################################
# Build & Install
bash inc/build.sh
echo "Installation is complete. Beginning configuration..."

###############################################################################
# Configure
sudo bash inc/config-xrdp.sh
echo "Configuration is complete."

###############################################################################
# .xinitrc has to be modified manually.
#
echo "You will have to configure .xinitrc to start your windows manager, see https://wiki.archlinux.org/index.php/Xinit"
echo "Reboot your machine to begin using XRDP."
