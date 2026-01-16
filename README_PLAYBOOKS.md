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

Note: The `configs/` directory is mounted into the containers for shared daemon/vtysh settings and switch configs. Router OSPF config is applied by Ansible during `playbooks/lab_setup.yml`.

## Which playbook to use

- Initialization (lab setup): `ansible/playbooks/lab_setup.yml`
- Later automation (post-lab operations): `ansible/playbooks/operations.yml`
- Device provisioning (via API): `ansible/playbooks/provision_devices.yml`
- IPsec tunnels (strongSwan): `ansible/playbooks/ipsec_tunnels.yml`

## Playbook: playbooks/lab_setup.yml (initial lab setup)

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
ansible-playbook -i inventories/inventory.yml playbooks/lab_setup.yml -v
```

Manual verify:
```bash
# Router (FRR)
ssh -p 2201 root@localhost
hostname
vtysh -c "show running-config"
vtysh -c "show ip ospf neighbor"
vtysh -c "show ip route"
cat /etc/resolv.conf
vtysh -c "show ip nat translations"
exit

# Switch (bridge/VLAN)
ssh -p 2221 root@localhost
cat /config/vlans.conf
brctl show
ip link show
exit

# Backup files on controller
ls -la backups/
```

## Playbook: playbooks/operations.yml (post-lab automation)

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
ansible-playbook -i inventories/inventory.yml playbooks/operations.yml -v
```

Run a specific operation:
```bash
ansible-playbook -i inventories/inventory.yml playbooks/operations.yml --tags validation -v
ansible-playbook -i inventories/inventory.yml playbooks/operations.yml --tags health -v
ansible-playbook -i inventories/inventory.yml playbooks/operations.yml --tags security -v
ansible-playbook -i inventories/inventory.yml playbooks/operations.yml --tags telemetry -v
```

Run multiple operations:
```bash
ansible-playbook -i inventories/inventory.yml playbooks/operations.yml --tags "health,security" -v
```


## Playbook: acls.yml (router ACLs)

Applies ACL policies to routers using dedicated vars.

- Role: `acl_config`
- Vars file: `ansible/vars/acl_policies.yml`

Run:
```bash
ansible-playbook -i inventories/inventory.yml acls.yml -v
```

Manual verification:
```bash
# ACL summary on router
 vtysh -c "show access-lists"

# Validation report
cat ../reports/validation/*_validation_report.md

# Security report
cat ../reports/security/*_security_report.md
```

## Playbook: playbooks/provision_devices.yml (lab setup with alternate inventory)

Runs device provisioning via API (optional) and then the lab setup playbook using a separate inventory.

Run:
```bash
ansible-playbook -i inventories/inventory_provision.yml playbooks/provision_devices.yml -v
```

Vars:
- `ansible/vars/provision_devices.yml` (optional `devices` list for API-based onboarding)

Inventory reference:
- `ansible/inventories/inventory_provision.yml` defines the `new_branch` group.

## Playbook: playbooks/ipsec_tunnels.yml (strongSwan tunnels)

Configures IPsec tunnels on routers using dedicated IPsec vars.

Run:
```bash
ansible-playbook -i inventories/inventory.yml playbooks/ipsec_tunnels.yml -v
```

Vars:
- `ansible/vars/ipsec.yml`

Manual verify:
```bash
ssh -p 2201 root@localhost
ipsec statusall
ipsec status
exit
```
