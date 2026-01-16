# Playbook Operations (Simplified)

This file is a quick reference for what each playbook does, which roles it runs, and the tags you can use.

## Build images (first time only)

```bash
docker build -t network-device-router:latest network-devices/router
docker build -t network-device-switch:latest network-devices/switch
```

## Start containers (required before Ansible)

```bash
docker compose up -d
```

## Which playbook to use

- Initialization (lab setup): `ansible/lab_setup.yml`
- Later automation (post-lab operations): `ansible/operations.yml`
- Device provisioning (via API): `ansible/provision_devices.yml`
- IPsec tunnels (strongSwan): `ansible/ipsec_tunnels.yml`

## Playbook: lab_setup.yml (initial lab setup)

Runs a single consolidated role across all devices.

- Role: `lab_setup`
- Tags: `lab_setup`
- What it does:
  - Hostname configuration
  - Router OSPF configuration
  - Switch VLAN configuration
  - DNS and NAT settings
  - Configuration backups

Run:
```bash
ansible-playbook -i inventories/inventory.yml lab_setup.yml -v
```

Manual verify:
```bash
# Router (FRR)
ssh -p 2201 root@localhost
vtysh -c "show running-config"
exit

# Switch (bridge/VLAN)
ssh -p 2221 root@localhost
cat /config/vlans.conf
brctl show
exit
```

## Playbook: operations.yml (post-lab automation)

Runs post-deployment tasks with tag selection. Without tags, all tasks run.

### Role and tags

- `post_lab_operations` (single role; tasks use tags below)

- `validation` (task)
  - Tags: `validation`
  - Does: validation checks and report generation

- `telemetry` (task)
  - Tags: `telemetry`
  - Does: telemetry collection and report generation

- `health` (task)
  - Tags: `health`
  - Does: health checks and stability monitoring

- `security` (task)
  - Tags: `security`
  - Does: security verification and compliance checks

Run all operations:
```bash
ansible-playbook -i inventories/inventory.yml operations.yml -v
```

Run a specific operation:
```bash
ansible-playbook -i inventories/inventory.yml operations.yml --tags validation -v
ansible-playbook -i inventories/inventory.yml operations.yml --tags health -v
ansible-playbook -i inventories/inventory.yml operations.yml --tags security -v
ansible-playbook -i inventories/inventory.yml operations.yml --tags telemetry -v
```

Run multiple operations:
```bash
ansible-playbook -i inventories/inventory.yml operations.yml --tags "health,security" -v
```

## Playbook: provision_devices.yml (lab setup with alternate inventory)

Runs the lab setup playbook using a separate inventory.

Run:
```bash
ansible-playbook -i inventories/inventory_provision.yml provision_devices.yml -v
```

Inventory reference:
- `ansible/inventories/inventory_provision.yml` defines the `new_branch` group.

## Playbook: ipsec_tunnels.yml (strongSwan tunnels)

Configures IPsec tunnels on routers using the `ipsec` vars in `ansible/group_vars_all.yml`.

Run:
```bash
ansible-playbook -i inventories/inventory.yml ipsec_tunnels.yml -v
```

Manual verify:
```bash
ssh -p 2201 root@localhost
ipsec statusall
ipsec status
exit
```
