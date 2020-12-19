# Script to enable XRDP on openSUSE Tumbleweed

## Info

- Designed to be idempotent, you can run it repeatedly
- Installs required packages
- Configures XRDP ini files
- Will compile selinux module in case SELinux is installed on machine (it doesn't need to be enabled though)

## Disclaimer

I only tested this script on my own local installation of openSUSE Tumbleweed from 19/12/2020

- Windows 10 version 20H2 (OS Build 19042.685)
- Tumbleweed installed with KDE
- Script might need some tweek in case other DE is used and thus gdm or lighdm needs to be enabled/configured
- I can't turn off machine from xrdp session, so far did not find a fix
  - workaround is to switch to basic session and click on shutdown button
