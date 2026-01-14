#!/bin/bash
set -e

# Start SSH daemon
/usr/sbin/sshd

# Create bridge for switch functionality
if ! brctl show | grep -q br0; then
    brctl addbr br0
    ip link set br0 up
fi

# Initialize switch config directory
mkdir -p /config/vlans

# Create default VLAN config if not exists
if [ ! -f /config/vlans.conf ]; then
    cat > /config/vlans.conf <<EOF
# VLAN configuration for ${DEVICE_ID:-switch}
# Format: VLAN_ID:NAME:PORTS
10:Management:eth0
20:Data:eth1
30:Voice:eth2
EOF
fi

exec "$@"
