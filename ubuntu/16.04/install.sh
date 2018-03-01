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

sudo apt update
sudo apt upgrade -y

# Get git if we dont have it.
sudo apt install -y git

# Get the linux-azure kernel to add hyper-v sockets to the guest
sudo apt install -y linux-azure

if [ -f /var/run/reboot-required ]; then
    echo
    echo "A reboot is required in order to proceed with the install."
    echo "Please reboot and re-run this script to finish the install."
    echo

    exit
fi

###############################################################################
# XRDP
#
export XRDP_PATH=~/git/src/github.com/neutrinolabs/xrdp

# Install the xrdp service so we have the auto start behavior
sudo apt install -y xrdp

# Get XRDP requirements
sudo apt install -y autoconf libtool libssl-dev libpam0g-dev libx11-dev libxfixes-dev libxrandr-dev libjpeg-dev libfuse-dev nasm

# Get XRDP
if [ ! -d $XRDP_PATH ]; then
    git clone https://github.com/neutrinolabs/xrdp $XRDP_PATH
fi

# Configure XRDP
cd $XRDP_PATH
./bootstrap
./configure --enable-ipv6 --enable-jpeg --enable-fuse --enable-rfxcodec --enable-opus --enable-painter --enable-vsock

# Build/Install XRDP
make
sudo make install

# Configure the installed XRDP ini files.
# use vsock transport.
sudo sed -i_orig -e 's/use_vsock=false/use_vsock=true/g' /etc/xrdp/xrdp.ini
# use rdp security.
sudo sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
# remove encryption validation.
sudo sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
# disable bitmap compression since its local its much faster
sudo sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini
#
# sudo sed -n -e 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini

# use the default lightdm x display
# sudo sed -i_orig -e 's/X11DisplayOffset=10/X11DisplayOffset=0/g' /etc/xrdp/sesman.ini

# 16.04.3 changed the allowed_users
sudo sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# reconfigure the service
sudo systemctl daemon-reload
sudo systemctl enable xrdp.service
sudo systemctl enable xrdp-sesman.service

# Configure the policy xrdp session
sudo bash -c 'cat >/etc/polkit-1/localauthority.conf.d/02-allow-colord.conf <<EOF

polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.color-manager.create-device" ||
         action.id == "org.freedesktop.color-manager.modify-profile" ||
         action.id == "org.freedesktop.color-manager.delete-device" ||
         action.id == "org.freedesktop.color-manager.create-profile" ||
         action.id == "org.freedesktop.color-manager.modify-profile" ||
         action.id == "org.freedesktop.color-manager.delete-profile") &&
        subject.isInGroup("{group}"))
    {
        return polkit.Result.YES;
    }
});
EOF'

#
# End XRDP
###############################################################################

###############################################################################
# XORGXRDP
#
export XORGXRDP_PATH=~/git/src/github.com/neutrinolabs/xorgxrdp

# Get XORGXRDP requirements
sudo apt install -y autoconf libtool xserver-xorg-core xserver-xorg-dev

# 16.04.3 is missing fontutil.h
if [ ! -f /usr/include/X11/fonts/fontutil.h ]; then
    sudo apt install -y libxfont1-dev
fi

# Get XORGXRDP
if [ ! -d $XORGXRDP_PATH ]; then
    git clone https://github.com/neutrinolabs/xorgxrdp $XORGXRDP_PATH
fi

# Configure XORGXRDP
cd $XORGXRDP_PATH
./bootstrap
./configure

# Build/Install XORGXRDP
make
sudo make install

#Installing xorgxrdp knocks out ubuntu-desktop from running. We need to reinstall it
sudo apt-get install --reinstall ubuntu-desktop

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
