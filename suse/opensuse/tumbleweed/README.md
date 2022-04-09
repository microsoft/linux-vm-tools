# Script to enable XRDP on openSUSE Tumbleweed

## Info

- Designed to be idempotent, you can run it repeatedly
- Installs required packages
- Configures XRDP ini files
- Will compile selinux module in case SELinux is installed on machine (it doesn't need to be enabled though)
