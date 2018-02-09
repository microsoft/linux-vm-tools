#! /bin/bash

#
# This script is for Ubuntu 18.04 Bionic Beaver to download and install XRDP+XORGXRDP via
# source.
#
# Major thanks to: http://c-nergy.be/blog/?p=11336 for the tips.
#

###############################################################################
# Update our machine to the latest code if we need to.
#

sudo apt update
sudo apt upgrade -y

# Get git if we dont have it.
sudo apt install -y git

# TODO: Remove the custom kernel logic when 18.04 supports hv_sock by default.
sudo add-apt-repository ppa:billy-olsen/test-kernels-bionic
sudo apt-get update
sudo apt install linux-image-4.14.0-17-generic

if [ -f /var/run/reboot-required ]; then
    reboot
fi

###############################################################################
# XRDP
#
export XRDP_PATH=~/git/src/github.com/neutrinolabs/xrdp

# Install the xrdp service so we have the auto start behavior
sudo apt install -y xrdp

# Get XRDP requirements
# ./bootstrap requirements 'autoconf libtool pkg-config'
# ./configure requirements 'libssl-dev libpam0g-dev libjpeg-dev libfuse-dev libx11-dev libxfixes-dev libxrandr-dev nasm'
sudo apt install -y autoconf libtool pkg-config libssl-dev libpam0g-dev libjpeg-dev libfuse-dev libx11-dev libxfixes-dev libxrandr-dev nasm

# Get XRDP
if [ ! -d $XRDP_PATH ]; then
    git clone https://github.com/neutrinolabs/xrdp $XRDP_PATH
fi

# Configure XRDP
cd $XRDP_PATH
./bootstrap
./configure --enable-vsock --enable-jpeg --enable-fuse

sudo systemctl stop xrdp
sudo systemctl stop xrdp-sesman

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

# use the default lightdm x display
# sudo sed -i_orig -e 's/X11DisplayOffset=10/X11DisplayOffset=0/g' /etc/xrdp/sesman.ini

# Changed the allowed_users
sudo sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Enable the hv_sock module
sudo rmmod vmw_vsock_vmci_transport
sudo rmmod vsock
sudo modprobe hv_sock

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

# reconfigure the service
sudo systemctl daemon-reload
sudo systemctl start xrdp

#
# End XRDP
###############################################################################

#reboot
echo
echo "Reboot your machine to begin using XRDP"
echo