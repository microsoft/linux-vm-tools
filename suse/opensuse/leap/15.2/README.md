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
