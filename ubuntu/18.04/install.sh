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

sudo bash -c 'echo "deb http://archive.ubuntu.com/ubuntu/ bionic-proposed restricted main multiverse universe" >> /etc/apt/sources.list <<EOF
EOF'

sudo apt update && sudo apt dist-upgrade -y

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

# Install the xrdp service so we have the auto start behavior
sudo apt install -y xrdp

sudo systemctl stop xrdp
sudo systemctl stop xrdp-sesman

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

# Blacklist the vmw module
sudo bash -c 'echo "blacklist vmw_vsock_vmci_transport" >> /etc/modprobe.d/blacklist.conf <<EOF
EOF'

#Ensure hv_sock gets loaded
sudo bash -c 'echo "hv_sock" >> /etc/modules <<EOF
EOF'

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

# Install Gmone Tweak
sudo apt-get install gnome-tweak-tool -y

echo
echo "Install is complete."
echo "Reboot your machine to begin using XRDP."
echo
