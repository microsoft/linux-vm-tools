#!/bin/bash

#
# This script is for Arch Linux to download and install XRDP+XORGXRDP
#

if [ "$(id -u)" -eq 0 ]; then
    echo 'This script must be run as a non-root user, as building packages as root is unsupported.' >&2
    exit 1
fi

###############################################################################
# Prepare by installing build tools.
#
# Partial upgrades aren't supported in arch.
sudo pacman -Syu --needed --noconfirm base base-devel git

# Create a build directory in tmpfs
TMPDIR=$(mktemp -d)
pushd "$TMPDIR" || exit

###############################################################################
# XRDP
#
(
	git clone https://aur.archlinux.org/xrdp.git
	cd xrdp || exit
	makepkg -sri --noconfirm
)
###############################################################################
# XORGXRDP
# Devel version, because release version includes a bug crashing gnome-settings-daemon
(
	git clone https://aur.archlinux.org/xorgxrdp.git
	cd xorgxrdp || exit
	makepkg -sri --noconfirm
)
###############################################################################

#remove build directory
rm -rf $TMPDIR
