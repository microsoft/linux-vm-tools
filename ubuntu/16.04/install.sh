#! /bin/bash

#
# This script is for Ubuntu 16.04+ to download and install XRDP+XORGXRDP via
# source.
#
# Major thanks to: http://c-nergy.be/blog/?p=10752 for the tips.
#

###############################################################################
# Update our machine to the latest code if we need to.
#

if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

apt update
apt upgrade -y

# Get git if we dont have it.
apt install -y git

# Get the linux-azure kernel to add hyper-v sockets to the guest
apt install -y linux-azure

if [ -f /var/run/reboot-required ]; then
    echo "A reboot is required in order to proceed with the install." >&2
    echo "Please reboot and re-run this script to finish the install." >&2
    exit 1
fi

###############################################################################
# XRDP
#
export XRDP_PATH=~/git/src/github.com/neutrinolabs/xrdp

# Install the xrdp service so we have the auto start behavior
apt install -y xrdp

# Get XRDP requirements
apt install -y autoconf libtool libssl-dev libpam0g-dev libx11-dev libxfixes-dev libxrandr-dev libjpeg-dev libfuse-dev nasm libopus-dev

# Get XRDP
if [ ! -d $XRDP_PATH ]; then
    git clone https://github.com/neutrinolabs/xrdp $XRDP_PATH
fi

# Configure XRDP
cd $XRDP_PATH || exit
./bootstrap
./configure --enable-ipv6 --enable-jpeg --enable-fuse --enable-rfxcodec --enable-opus --enable-painter --enable-vsock

# Build/Install XRDP
make
make install

# Configure the installed XRDP ini files.
# use vsock transport.
sed -i_orig -e 's/use_vsock=false/use_vsock=true/g' /etc/xrdp/xrdp.ini
# use rdp security.
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
# remove encryption validation.
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
# disable bitmap compression since its local its much faster
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini
#
# sed -n -e 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini

# use the default lightdm x display
# sed -i_orig -e 's/X11DisplayOffset=10/X11DisplayOffset=0/g' /etc/xrdp/sesman.ini

# rename the redirected drives to 'shared-drives'
sed -i_orig -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# 16.04.3 changed the allowed_users
sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# reconfigure the service
systemctl daemon-reload
systemctl enable xrdp.service
systemctl enable xrdp-sesman.service

# Configure the policy xrdp session
# polkit policy definition language changes depending on its version. See issue #61
if [[ "$(pkaction --version | sed -E 's/^[[:alnum:] ]*([[:digit:]]+.*)/\1/' - )" != '0.105' ]]; then
    echo "Error: Policy rule specification probably invalid. Expected version: 0.105 detected $(pkaction --version)." >&2
    exit 1
fi

cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<EOF
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

#
# End XRDP
###############################################################################

###############################################################################
# XORGXRDP
#
export XORGXRDP_PATH=~/git/src/github.com/neutrinolabs/xorgxrdp

# Get XORGXRDP requirements
apt install -y autoconf libtool xserver-xorg-core xserver-xorg-dev

# 16.04.3 is missing fontutil.h
if [ ! -f /usr/include/X11/fonts/fontutil.h ]; then
    apt install -y libxfont1-dev
fi

# Get XORGXRDP
if [ ! -d $XORGXRDP_PATH ]; then
    git clone https://github.com/neutrinolabs/xorgxrdp $XORGXRDP_PATH
fi

# Configure XORGXRDP
cd $XORGXRDP_PATH || exit
./bootstrap
./configure

# Build/Install XORGXRDP
make
make install

#Installing xorgxrdp knocks out ubuntu-desktop from running. We need to reinstall it
apt-get install -y --reinstall ubuntu-desktop

#
# End XORGXRDP
###############################################################################

echo
echo "Install is complete."
echo "Reboot your machine to begin using XRDP."
echo
echo "Note: If this is the user account you would like to use for remote access run ./config-user.sh."
echo
echo
