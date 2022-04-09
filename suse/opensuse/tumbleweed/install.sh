#!/bin/bash

#
# This script is for openSUSE Tumbleweed Linux to configure XRDP for enhanced session mode
#
# The confioguration is adapted from the Arch script.
#

###############################################################
# Install XRDP
#
if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

# Use rpm -q to check for exact package name, install if missing
if ! rpm -q xrdp 2>&1 > /dev/null ; then
    echo 'Refreshing repo cache'
    zypper refresh
    echo 'Installing missing xrdp package using zypper'
    zypper -n install xrdp
fi

###############################################################
# Configure XRDP
#
systemctl enable xrdp
systemctl enable xrdp-sesman

XRDP_INI_FILE=/etc/xrdp/xrdp.ini
XRDP_INI_BAK_FILE=$XRDP_INI_FILE.enh_sess_orig.bak
# Create backup of original XRDP ini file
if [ ! -f "$XRDP_INI_BAK_FILE" ]; then
    cp $XRDP_INI_FILE $XRDP_INI_BAK_FILE
    echo "Original config file saved in $XRDP_INI_BAK_FILE"
fi
# Configure the installed XRDP ini files
# use vsock transport
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' $XRDP_INI_FILE
# use rdp security
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' $XRDP_INI_FILE
# remove encryption validation
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' $XRDP_INI_FILE
# disable bitmap compression since its local its much faster
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' $XRDP_INI_FILE
#
# sed -n -e 's/max_bpp=32/max_bpp=24/g' $XRDP_INI_FILE

XRDP_SESMAN_INI_FILE=/etc/xrdp/sesman.ini
# use the default lightdm x display
#sed -i_orig -e 's/X11DisplayOffset=200/X11DisplayOffset=0/g' $XRDP_SESMAN_INI_FILE
# rename the redirected drives to 'shared-drives'
sed -i_orig -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' $XRDP_SESMAN_INI_FILE

# Change the allowed_users
echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# Ensure hv_sock gets loaded
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
    echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
fi

# Configure the policy xrdp session
cat > /etc/polkit-1/rules.d/02-allow-colord.rules <<EOF
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.color-manager.create-device" ||
         action.id == "org.freedesktop.color-manager.modify-profile" ||
         action.id == "org.freedesktop.color-manager.delete-device" ||
         action.id == "org.freedesktop.color-manager.create-profile" ||
         action.id == "org.freedesktop.color-manager.modify-profile" ||
         action.id == "org.freedesktop.color-manager.delete-profile") &&
        subject.isInGroup("users"))
    {
        return polkit.Result.YES;
    }
});
EOF

# Compile selinux module IF selinux is installed
if rpm -q selinux 2>&1 > /dev/null ; then
    checkmodule -M -m -o allow-vsock.mod allow-vsock.te
    semodule_package -o allow-vsock.pp -m allow-vsock.mod
    # Install the selinux module!
    semodule -i allow-vsock.pp
fi

###############################################################################

echo "####### Configuration Done #######"
echo "Next to do"
echo "Shutdown this VM"
echo "On your host machine in an Administrator powershell prompt, execute this command: "
echo "      Set-VM -VMName <your_vm_name> -EnhancedSessionTransportType HvSocket"
echo "Start this VM, and you will see Enhanced mode available!"
