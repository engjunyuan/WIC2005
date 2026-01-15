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
- Legacy all-in-one flow (kept for compatibility): `ansible/playbook.yml`

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

Runs post-deployment tasks with tag selection. Without tags, all roles run.

### Roles and tags

- `post_deployment_validation`
  - Tags: `validation`, `post_lab`, `testing`, `default`
  - Does: validation checks and report generation

- `telemetry_report`
  - Tags: `telemetry`, `reporting`, `post_lab`, `default`
  - Does: telemetry collection and report generation

- `health_monitoring`
  - Tags: `health`, `monitoring`, `post_lab`, `default`
  - Does: health checks and stability monitoring

- `security_verification`
  - Tags: `security`, `compliance`, `post_lab`, `default`
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

## Playbook: playbook.yml (legacy all-in-one)

This is the original playbook that combines setup and operations. Use it only if you need the older flow.

### Initial configuration roles

- `router_config`
  - Tags: `router_config`, `topology_setup`, `deployment`
  - Does: router OSPF, ACLs, NAT, hostname

- `switch_config`
  - Tags: `switch_config`, `topology_setup`, `deployment`
  - Does: VLANs, bridging, hostname

- `batch_update`
  - Tags: `batch_update`, `topology_setup`, `deployment`
  - Does: shared settings (DNS/common updates)

- `backup_configs`
  - Tags: `backup_configs`, `topology_setup`, `deployment`
  - Does: configuration backups

### Post-deployment roles

- `post_deployment_validation`
  - Tags: `post_deployment_validation`, `post_deployment`, `testing`
  - Does: validation checks and report generation

- `telemetry_report`
  - Tags: `telemetry_report`, `topology_setup`, `post_deployment`
  - Does: telemetry collection and report generation

### Monitoring roles

- `health_monitoring`
  - Tags: `health_monitoring`, `monitoring`, `operations`
  - Does: health checks and stability monitoring

- `security_verification`
  - Tags: `security_verification`, `security`, `operations`
  - Does: security verification and compliance checks

Run:
```bash
ansible-playbook -i inventory.yml playbook.yml -v
```
