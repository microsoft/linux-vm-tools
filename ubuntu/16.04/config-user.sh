#!/bin/bash

#
# This script configures the logged in users xsession to properly
# configure unity to launch
#
# Major thanks to: http://c-nergy.be/blog/?p=10752 for the tips.
#

if [ ! "$(id -u)" ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

bash -c "cat > ~/.xsession <<EOF

/usr/lib/gnome-session/gnome-session-binary --session=ubuntu &
/usr/lib/x86_64-linux-gnu/unity/unity-panel-service &
/usr/lib/unity-settings-daemon/unity-settings-daemon &

for indicator in /usr/lib/x86_64-linux-gnu/indicator-*;
do
    basename='basename \\\${indicator}'
    dirname='dirname \\\${indicator}'
    service=\\\${dirname}/\\\${basename}/\\\${basename}-service
    \\\${service} &
done
unity
EOF"
