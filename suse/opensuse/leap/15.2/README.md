# Script to enable XRDP on openSUSE Tumbleweed

## Info

- Designed to be idempotent, you can run it repeatedly
- Installs required packages
- Configures XRDP ini files
- Will compile selinux module in case SELinux is installed on machine (it doesn't need to be enabled though)
- support changing session to KDE Plasma

## Run

- If using GNOME

```sh
sudo sh install.sh
```

- If using KDE

```sh
sudo sh install.sh --kde
```

If using different DE

Looks like xrdp on openSUSE leap 15.2 supports below DEs by default

```sh
sudo sed -i_orig -e 's/SESSION=".*"/SESSION="sle"/g' /etc/xrdp/startwm.sh     # set to 'SLE classic'
sudo sed -i_orig -e 's/SESSION=".*"/SESSION="gnome"/g' /etc/xrdp/startwm.sh   # set to 'GNOME'
sudo sed -i_orig -e 's/SESSION=".*"/SESSION="plasma"/g' /etc/xrdp/startwm.sh  # set to 'KDE'
sudo sed -i_orig -e 's/SESSION=".*"/SESSION="icewm"/g' /etc/xrdp/startwm.sh   # set to 'IceWM'
```

## Known issues

### I can't shutdown/restart machine from xrdp session, session just logoff, but muchine keeps running

- There is a simple fix to that, but it is not a part of script as it might not be an intended change
  - This solution does not work for Tumbleweed strangely
- Below will allow any user that is part of group `power` to reboot/suspend/shutdown/hibernate the machine from GUI
- Please adjust below solution in case you want this to be available for different group. e.g. `admins` or `wheel`

```sh
# group 'power' is not available on openSUSE by default, so we will create it
sudo groupadd power

# add your user to group power
sudo usermod -a -G power <your_username>

# add polkit rule
sudo bash -c 'cat > /etc/polkit-1/rules.d/48-shutdown-power-group <<EOF
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.login1.reboot" ||
         action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
         action.id == "org.freedesktop.login1.power-off" ||
         action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
         action.id == "org.freedesktop.login1.suspend" ||
         action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
         action.id == "org.freedesktop.login1.hibernate" ||
         action.id == "org.freedesktop.login1.hibernate-multiple-sessions") && subject.isInGroup("power"))
    {
    return polkit.Result.YES;
    }
});
EOF'

# restart your machine
sudo reboot
```
