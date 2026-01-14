#!/bin/bash
set -e

# Apply sysctl settings
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

# Start SSH daemon
/usr/sbin/sshd

# Create daemons file if it doesn't exist
if [ ! -f /etc/frr/daemons ]; then
    cat > /etc/frr/daemons <<EOF
zebra=yes
bgpd=yes
ospfd=yes
ripd=yes
staticrouted=yes
EOF
    chown frr:frr /etc/frr/daemons
    chmod 640 /etc/frr/daemons
fi

# Create vtysh.conf if missing (required by vtysh)
if [ ! -f /etc/frr/vtysh.conf ]; then
    cat > /etc/frr/vtysh.conf <<EOF
service integrated-vtysh-config
username frr nopassword
EOF
    chown frr:frr /etc/frr/vtysh.conf
    chmod 640 /etc/frr/vtysh.conf
fi

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

exec "$@"
