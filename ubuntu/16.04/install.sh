#! /bin/bash

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
    reboot
fi

###############################################################################
# XRDP
#

# Get XRDP requirements
sudo apt install -y autoconf libtool libssl-dev libpam0g-dev libx11-dev libxfixes-dev libxrandr-dev libjpeg-dev libfuse-dev nasm
# sudo apt install -y xrdp

# Get XRDP
git clone https://github.com/neutrinolabs/xrdp ~/git/xrdp

# Configure XRDP
cd ~/git/xrdp
./bootstrap
./configure --enable-vsock --enable-jpeg --enable-fuse

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
# sudo sed -n -e 's/max_bpp=32/max_bpp=24/g' /etc/xrdp/xrdp.ini

# use the default lightdm x display
sudo sed -i_orig -e 's/X11DisplayOffset=10/X11DisplayOffset=0/g' /etc/xrdp/sesman.ini

#
# End XRDP
###############################################################################

###############################################################################
# XORGXRDP
#

# Get XORGXRDP requirements
sudo apt install -y autoconf libtool xserver-xorg-dev libxfont1-dev
# sudo apt install -y xorgxrdp

# Get XORGXRDP
git clone https://github.com/neutrinolabs/xorgxrdp ~/git/xorgxrdp

# Configure XORGXRDP
cd ~/git/xorgxrdp
./bootstrap
./configure

# Build/Install XORGXRDP
make
sudo make install

#
# End XORGXRDP
###############################################################################

# configure lightdm to use xrdp's xorg.conf on startup.

if [ -f /etc/lightdm/lightdm.conf ]; then
    sudo grep -f /etc/lightdm/lightdm.conf "xserver-config=/etc/X11/xrdp/xorg.conf"
    if [ "$?" != "0" ]; then
        echo "xserver-config=/etc/X11/xrdp/xorg.conf" | sudo tee --append /etc/lightdm/lightdm.conf > /dev/null
    fi
else
    # No lightdm config file.
    echo "[Seat:*]" > sudo tee /etc/lightdm/lightdm.conf > /dev/null
    echo "xserver-config=/etc/X11/xrdp/xorg.conf" | sudo tee --append /etc/lightdm/lightdm.conf > /dev/null
fi

#reboot
