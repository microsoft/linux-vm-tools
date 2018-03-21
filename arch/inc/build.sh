#!/bin/bash
#
# Do not run this script directly, it gets executed by install.sh.
#

if [ $(id -u) -eq 0 ] ; then
    echo 'This script must be run as a non-root user, as building packages as root is unsupported.' >&2
    exit 1
fi

# Create a build directory in tmpfs
mkdir /tmp/build && cd "$_"

###############################################################################
# XRDP
#
(
	git clone https://aur.archlinux.org/xrdp.git
	cd xrdp
	makepkg -sri --noconfirm
)
###############################################################################
# XORGXRDP
# Devel version, because release version includes a bug crashing gnome-settings-daemon
(
	git clone https://aur.archlinux.org/xorgxrdp-devel-git.git
	cd xorgxrdp-devel-git
	makepkg -sri --noconfirm
)
###############################################################################

