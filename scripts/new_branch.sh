#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/new_branch.sh [options]

Options:
  --router-name <name>        Default: branch-router1
  --switch-name <name>        Default: branch-switch1
  --router-ssh-port <port>    Default: 2301
  --switch-ssh-port <port>    Default: 2321
  --router-mgmt-ip <ip>       Default: 172.199.0.30
  --switch-mgmt-ip <ip>       Default: 172.199.0.31
  --router-wan-ip <ip>        Default: 10.0.1.5
  --router-lan-ip <ip>        Default: 192.168.11.30
  --switch-lan-ip <ip>        Default: 192.168.11.31
  --project <name>            Docker Compose project name (optional)

Example:
  ./scripts/new_branch.sh --router-name router4 --switch-name switch3 \
    --router-ssh-port 2204 --switch-ssh-port 2223 \
    --router-mgmt-ip 172.199.0.13 --switch-mgmt-ip 172.199.0.22 \
    --router-wan-ip 10.0.1.5 --router-lan-ip 192.168.11.12 \
    --switch-lan-ip 192.168.11.22
EOF
}

ROUTER_NAME="branch-router1"
SWITCH_NAME="branch-switch1"
ROUTER_SSH_PORT="2301"
SWITCH_SSH_PORT="2321"
ROUTER_MGMT_IP="172.199.0.30"
SWITCH_MGMT_IP="172.199.0.31"
ROUTER_WAN_IP="10.0.1.5"
ROUTER_LAN_IP="192.168.11.30"
SWITCH_LAN_IP="192.168.11.31"
PROJECT_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --router-name) ROUTER_NAME="${2:-}"; shift 2 ;;
    --switch-name) SWITCH_NAME="${2:-}"; shift 2 ;;
    --router-ssh-port) ROUTER_SSH_PORT="${2:-}"; shift 2 ;;
    --switch-ssh-port) SWITCH_SSH_PORT="${2:-}"; shift 2 ;;
    --router-mgmt-ip) ROUTER_MGMT_IP="${2:-}"; shift 2 ;;
    --switch-mgmt-ip) SWITCH_MGMT_IP="${2:-}"; shift 2 ;;
    --router-wan-ip) ROUTER_WAN_IP="${2:-}"; shift 2 ;;
    --router-lan-ip) ROUTER_LAN_IP="${2:-}"; shift 2 ;;
    --switch-lan-ip) SWITCH_LAN_IP="${2:-}"; shift 2 ;;
    --project) PROJECT_NAME="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1"; usage; exit 1 ;;
  esac
done

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project="${PROJECT_NAME:-${COMPOSE_PROJECT_NAME:-}}"
if [[ -z "$project" ]]; then
  project="$(basename "$ROOT_DIR" | tr '[:upper:]' '[:lower:]')"
fi

mgmt_net="${project}_mgmt"
wan_net="${project}_wan"
lan_net="${project}_lan"

for net in "$mgmt_net" "$wan_net" "$lan_net"; do
  if ! docker network inspect "$net" >/dev/null 2>&1; then
    echo "Network $net not found. Start docker compose first."
    exit 1
  fi
done

if docker ps -a --format '{{.Names}}' | grep -qx "$ROUTER_NAME"; then
  echo "Container $ROUTER_NAME already exists."
  exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -qx "$SWITCH_NAME"; then
  echo "Container $SWITCH_NAME already exists."
  exit 1
fi

CONFIGS_DIR="$ROOT_DIR/configs"
PROVISIONING_DIR="$CONFIGS_DIR/provisioning"
ROUTER_CFG_DIR="$CONFIGS_DIR/$ROUTER_NAME"
SWITCH_CFG_DIR="$PROVISIONING_DIR/$SWITCH_NAME"

mkdir -p "$ROUTER_CFG_DIR" "$SWITCH_CFG_DIR"

if [[ ! -f "$ROUTER_CFG_DIR/frr.conf" ]]; then
  cat > "$ROUTER_CFG_DIR/frr.conf" <<EOF
! FRR configuration for $ROUTER_NAME
hostname $ROUTER_NAME
log file /var/log/frr/frr.log
!
service integrated-vtysh-config
!
router ospf
  network 0.0.0.0/0 area 0.0.0.0
!
line vty
!
EOF
fi

if [[ ! -f "$SWITCH_CFG_DIR/vlans.conf" ]]; then
  cat > "$SWITCH_CFG_DIR/vlans.conf" <<EOF
# VLAN configuration for $SWITCH_NAME
# Format: VLAN_ID:NAME:PORTS
10:Management:eth0
20:Data:eth1
30:Voice:eth2
EOF
fi

docker run -d \
  --name "$ROUTER_NAME" \
  --hostname "$ROUTER_NAME" \
  --privileged \
  --cap-add NET_ADMIN \
  -e "DEVICE_ID=$ROUTER_NAME" \
  -p "${ROUTER_SSH_PORT}:22" \
  --network "$mgmt_net" \
  --ip "$ROUTER_MGMT_IP" \
  -v "$CONFIGS_DIR/router-common/daemons:/etc/frr/daemons:rw" \
  -v "$CONFIGS_DIR/router-common/vtysh.conf:/etc/frr/vtysh.conf:rw" \
  -v "$ROUTER_CFG_DIR/frr.conf:/etc/frr/frr.conf:rw" \
  network-device-router:latest >/dev/null

docker network connect --ip "$ROUTER_WAN_IP" "$wan_net" "$ROUTER_NAME"
docker network connect --ip "$ROUTER_LAN_IP" "$lan_net" "$ROUTER_NAME"

docker run -d \
  --name "$SWITCH_NAME" \
  --hostname "$SWITCH_NAME" \
  --privileged \
  --cap-add NET_ADMIN \
  -e "DEVICE_ID=$SWITCH_NAME" \
  -p "${SWITCH_SSH_PORT}:22" \
  --network "$mgmt_net" \
  --ip "$SWITCH_MGMT_IP" \
  -v "$SWITCH_CFG_DIR:/config:rw" \
  network-device-switch:latest >/dev/null

docker network connect --ip "$SWITCH_LAN_IP" "$lan_net" "$SWITCH_NAME"

cat <<EOF
Added new branch devices:
  Router: $ROUTER_NAME (WAN $ROUTER_WAN_IP, LAN $ROUTER_LAN_IP)
  Switch: $SWITCH_NAME (LAN $SWITCH_LAN_IP)

Router is connected to the hub router via WAN network: $wan_net
SSH:
  ssh -p $ROUTER_SSH_PORT root@localhost
  ssh -p $SWITCH_SSH_PORT root@localhost

Inventory snippet (ansible/inventories/inventory.yml):
  $ROUTER_NAME:
    ansible_host: 127.0.0.1
    ansible_port: $ROUTER_SSH_PORT
    device_type: router
    mgmt_ip: $ROUTER_MGMT_IP
    wan_ip: $ROUTER_WAN_IP
    lan_ip: $ROUTER_LAN_IP
  $SWITCH_NAME:
    ansible_host: 127.0.0.1
    ansible_port: $SWITCH_SSH_PORT
    device_type: switch
    mgmt_ip: $SWITCH_MGMT_IP
    lan_ip: $SWITCH_LAN_IP
EOF
