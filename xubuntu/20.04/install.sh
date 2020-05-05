#!/bin/bash

#
# This script is for Xubuntu 20.04 Focal Fossa to download and install XRDP+XORGXRDP via
# source.
#
# Major thanks to: http://c-nergy.be/blog/?p=11336 for the tips.
#

###############################################################################
# Use HWE kernel packages
#
HWE=""
#HWE="-hwe-20.04"

###############################################################################
# Update our machine to the latest code if we need to.
#

if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

apt update && apt upgrade -y

if [ -f /var/run/reboot-required ]; then
    echo "A reboot is required in order to proceed with the install." >&2
    echo "Please reboot and re-run this script to finish the install." >&2
    exit 1
fi

###############################################################################
# XRDP
#

# Install hv_kvp utils
apt install -y linux-tools-virtual${HWE}
apt install -y linux-cloud-tools-virtual${HWE}

# Install the xrdp service so we have the auto start behavior
apt install -y xrdp

systemctl stop xrdp
systemctl stop xrdp-sesman

# Configure the installed XRDP ini files.
# do not use vsock transport since newer versions of xrdp do not support it.
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
# use rdp security.
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
# remove encryption validation.
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
# disable bitmap compression since its local its much faster
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini

# Add script to setup the kubuntu session properly
if [ ! -e /etc/xrdp/startxubuntu.sh ]; then
cat >> /etc/xrdp/startxubuntu.sh << EOF
#!/bin/sh
export XDG_CURRENT_DESKTOP=XFCE
export XDG_SESSION_DESKTOP=xubuntu
export XDG_DATA_DIRS=/usr/share/xubuntu:/usr/share/xfce4:/usr/local/share:/usr/share:/var/lib/snapd/desktop:/usr/share
export XDG_CONFIG_DIRS=/etc/xdg/xdg-xubuntu:/etc/xdg:/etc/xdg
exec /etc/xrdp/startwm.sh
EOF
chmod a+x /etc/xrdp/startxubuntu.sh
fi

# use the script to setup the kubuntu session
sed -i_orig -e 's/startwm/startxubuntu/g' /etc/xrdp/sesman.ini

# rename the redirected drives to 'shared-drives'
sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# Changed the allowed_users
sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Blacklist the vmw module
if [ ! -e /etc/modprobe.d/blacklist_vmw_vsock_vmci_transport.conf ]; then
cat >> /etc/modprobe.d/blacklist_vmw_vsock_vmci_transport.conf <<EOF
blacklist vmw_vsock_vmci_transport
EOF
fi

# Ensure hv_sock gets loaded
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
fi

# Retrieve all available polkit actions and separate them accordingly
pkaction > /tmp/available_actions
actions=$(sed -e ':a' -e 'N' -e '$!ba' -e 's/\n/;/g' /tmp/available_actions)
rm /tmp/available_actions

# Configure the policies for xrdp session
cat > /etc/polkit-1/localauthority/50-local.d/xrdp-allow-all.pkla <<EOF
[Allow all for all sudoers]
Identity=unix-group:sudo
Action=$actions
ResultAny=yes
ResultInactive=yes
ResultActive=yes
EOF

# reconfigure the service
systemctl daemon-reload
systemctl start xrdp

#
# End XRDP
###############################################################################

echo "Install is complete."
echo "Reboot your machine to begin using XRDP."
