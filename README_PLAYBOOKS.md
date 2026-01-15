# Playbook Operations (Simplified)

This file is a quick reference for what each playbook does, which roles it runs, and the tags you can use.

## Build images (first time only)

```bash
docker build -t network-device-router:latest network-devices/router
docker build -t network-device-switch:latest network-devices/switch
```

## Which playbook to use

- Initialization (lab setup): `ansible/lab_setup.yml`
- Later automation (post-lab operations): `ansible/operations.yml`

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
ansible-playbook -i inventory.yml lab_setup.yml -v
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
ansible-playbook -i inventory.yml operations.yml -v
```

Run a specific operation:
```bash
ansible-playbook -i inventory.yml operations.yml --tags validation -v
ansible-playbook -i inventory.yml operations.yml --tags health -v
ansible-playbook -i inventory.yml operations.yml --tags security -v
ansible-playbook -i inventory.yml operations.yml --tags telemetry -v
```

Run multiple operations:
```bash
ansible-playbook -i inventory.yml operations.yml --tags "health,security" -v
```
