#!/bin/bash
set -e

# Apply sysctl settings
sysctl -w net.ipv4.ip_forward=1 2>/dev/null || true
sysctl -w net.ipv6.conf.all.forwarding=1 2>/dev/null || true

# Start SSH daemon
/usr/sbin/sshd

# Device type determines behavior
if [ "$DEVICE_TYPE" = "router" ]; then
    echo "Initializing as ROUTER: ${DEVICE_ID}"
    
    # Initialize FRR if config doesn't exist
    if [ ! -f /etc/frr/frr.conf ]; then
        cat > /etc/frr/frr.conf <<EOF
! FRR configuration for ${DEVICE_ID:-router}
hostname ${DEVICE_ID:-router}
log file /var/log/frr/frr.log
!
interface eth0
 description Management
!
interface eth1
 description WAN
!
interface eth2
 description LAN
!
line vty
!
EOF
        chown frr:frr /etc/frr/frr.conf
        chmod 640 /etc/frr/frr.conf
    fi
    
    # Start FRR
    /usr/lib/frr/frrinit.sh start

elif [ "$DEVICE_TYPE" = "switch" ]; then
    echo "Initializing as SWITCH: ${DEVICE_ID}"
    
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
else
    echo "Unknown DEVICE_TYPE: ${DEVICE_TYPE}. Defaulting to basic network device."
fi

exec "$@"
