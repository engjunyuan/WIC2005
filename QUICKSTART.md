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
- Vars: `ansible/vars/common.yml`
- Tags: `lab_setup`
- Tasks:
  - Connectivity pre-checks
  - Hostnames
  - OSPF baseline on routers
  - VLAN creation/bridge membership on switches
  - DNS resolvers and NAT host entry
  - Config backups and summary output

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

- Role: `operations`
- Vars: `ansible/vars/common.yml`
- Tags: `validation`, `health`, `security`, `telemetry` (task-level)
- Tasks:
  - Validation: connectivity, OSPF status, VLAN checks, DNS checks, reports
  - Health: load/disk/service status, basic process checks, reports
  - Security: ACL/NAT inspection, port listening checks, SSH hardening checks, VLAN security checks, reports
  - Telemetry: log tail/metrics collection and report

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

## Playbook: playbooks/acls.yml (router ACLs)

Applies ACL policies to routers using dedicated vars.

- Role: `acl_config`
- Vars: `ansible/vars/acl_policies.yml`
- Tasks:
  - Render ACL config from policies
  - Apply ACLs via vtysh to routers
  - Show ACL summary

Run:
```bash
ansible-playbook -i inventories/inventory.yml playbooks/acls.yml -v
```

Manual verification:
```bash
ssh -p 2201 root@localhost
vtysh -c "show access-lists"

# Validation report
cat ../reports/validation/*_validation_report.md

# Security report
cat ../reports/security/*_security_report.md
exit
```

## Playbook: playbooks/provision_devices.yml (lab setup with alternate inventory)

Runs device provisioning via API (optional) and then the lab setup playbook using a separate inventory.

- Role: `provision_devices` + imports `playbooks/lab_setup.yml`
- Vars: `ansible/vars/provision_devices.yml` (optional `devices` list)
- Inventory: `ansible/inventories/inventory_provision.yml` (`new_branch` group)
- Tasks:
  - Wait for provisioning API
  - POST devices from `new_branch` inventory (or `devices` var) to API
  - Run full lab_setup against provisioned inventory

Run:
```bash
ansible-playbook -i inventories/inventory_provision.yml playbooks/provision_devices.yml -v
```

## Playbook: playbooks/ipsec_tunnels.yml (strongSwan tunnels)

Configures IPsec tunnels on routers using dedicated IPsec vars.

- Role: `ipsec_tunnels`
- Vars: `ansible/vars/ipsec.yml`
- Tasks:
  - Write `ipsec.conf` with hub/spoke or mesh peers
  - Write `ipsec.secrets` with PSK
  - Restart strongSwan and show status

Run:
```bash
ansible-playbook -i inventories/inventory.yml playbooks/ipsec_tunnels.yml -v
```

Manual verify:
```bash
ssh -p 2201 root@localhost
ipsec statusall
ipsec status
exit
```
