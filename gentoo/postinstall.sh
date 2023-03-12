#!/bin/sh
set -e
# We want this to be idem

# Start dhcpcd
rc-update add dhcpcd default
rc-service dhcpcd start

# Start sysklogd
rc-update add sysklogd default
rc-service sysklogd start

# Fix docker group for no-sudo
usermod -aG docker gramar
# Start docker
rc-update add docker default
rc-service docker start

# Start chrony
rc-update add chronyd default
rc-service chronyd start

# Start chron
rc-update add cronie default
rc-service cronie start