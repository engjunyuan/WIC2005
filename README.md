# Network Automation for TechMart Retail Chain Expansion

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Quick Start Guide](#quick-start-guide)
3. [Architecture & Design](#architecture--design)
4. [Network Topology](#network-topology)
5. [Automation Features](#automation-features)
6. [Complete Deployment Workflow](#complete-deployment-workflow)
7. [Post-Deployment Validation & Testing](#post-deployment-validation--testing)
8. [Monitoring & Health Checks](#monitoring--health-checks)
9. [Security Verification](#security-verification)
10. [Device Access & Management](#device-access--management)
11. [Project Structure](#project-structure)
12. [Troubleshooting](#troubleshooting)
13. [Extensions & Future Work](#extensions--future-work)
14. [Team Information](#team-information)

---

## Project Overview

**Client:** TechMart Retail Chain (Technology Retail Expansion)  
**Challenge:** Manual network configuration for new branch openings causing inconsistencies, security vulnerabilities, and delays.  
**Solution:** Automated network provisioning using Ansible, Python, Docker, and FRRouting for rapid, reliable deployment.

### Business Requirements Met

✅ **5 Network Devices** (3 Routers + 2 Switches) with automated provisioning  
✅ **VLAN Configuration** with access/trunk port management  
✅ **OSPFv2 Multi-Area Routing** for dynamic network connectivity  
✅ **ACL Configuration** for security policy enforcement  
✅ **NAT Configuration** for IP address space optimization  
✅ **Ansible Automation** with Infrastructure-as-Code approach  
✅ **Post-Deployment Validation** for quality assurance  
✅ **Health Monitoring** for operational visibility  
✅ **Security Verification** for compliance assurance  

---

## Quick Start Guide

### Prerequisites
- Docker and Docker Compose
- Ansible 2.9+
- SSH client
- Basic networking knowledge

### 1. Clone and Initialize the Project

```bash
cd /home/engjunyuan/Documents/WIC2005
```

### 2. Start the Network Topology

### 2a. Build the Device Images (once per fresh checkout)

```bash
# Router image (FRRouting + SSH)
docker build -t network-device-router:latest network-devices/router

# Switch image (bridge-utils + VLAN + SSH)
docker build -t network-device-switch:latest network-devices/switch
```

These images are referenced by `docker-compose.yml`. Rebuild them if you change any Dockerfiles or `entrypoint.sh`.

**Why three Dockerfiles?**
- `network-devices/router/Dockerfile`: Router-only image with FRRouting and routing daemons.
- `network-devices/switch/Dockerfile`: Switch-only image with bridge-utils and VLAN tooling.
- `network-devices/Dockerfile`: A combined, all-in-one base image useful for debugging or experimenting outside the router/switch split (not used by `docker-compose.yml`).

### 2b. Start the Network Topology

```bash
docker compose down  # Clean previous state (optional)
docker compose up -d
sleep 20  # Wait for SSH daemons to start
```

**Verify containers are running:**
```bash
docker compose ps
```

Expected output:
```
NAME          STATUS         PORTS
router1       Up 20 seconds  0.0.0.0:2201->22/tcp
router2       Up 20 seconds  0.0.0.0:2202->22/tcp
router3       Up 20 seconds  0.0.0.0:2203->22/tcp
switch1       Up 20 seconds  0.0.0.0:2221->22/tcp
switch2       Up 20 seconds  0.0.0.0:2222->22/tcp
```

### 3. Run Lab Setup Playbook

```bash
cd ansible
# Run lab setup (configures all devices)
ansible-playbook -i inventories/inventory.yml lab_setup.yml -v
```

This playbook configures:
- ✓ Device hostnames
- ✓ Router OSPF configuration
- ✓ Switch VLAN configuration
- ✓ DNS and NAT gateway settings
- ✓ Configuration backups
- ✓ Optional Batfish snapshot export of rendered FRR configs (enable with `-e batfish_enabled=true`)
- ✓ Router ACLs rendered from `ansible/group_vars_all.yml:acl_policies` via `roles/lab_setup/templates/frr.conf.j2`

**Expected runtime:** ~1-2 minutes

### 4. (Optional) Run Operations Playbook for Post-Lab Automation

After setup is complete, run operations playbook for post-deployment validation, monitoring, and security verification:

```bash
cd ansible

# Option A: Run all post-lab operations
ansible-playbook -i inventories/inventory.yml operations.yml -v

# Option B: Run specific operations using tags
ansible-playbook -i inventories/inventory.yml operations.yml --tags validation -v       # Validation only
ansible-playbook -i inventories/inventory.yml operations.yml --tags health -v           # Health monitoring only
ansible-playbook -i inventories/inventory.yml operations.yml --tags security -v         # Security verification only
ansible-playbook -i inventories/inventory.yml operations.yml --tags telemetry -v        # Telemetry only

# Option C: Combine multiple tags
ansible-playbook -i inventories/inventory.yml operations.yml --tags "health,security" -v
```

### Batfish integration (optional)

If you pass `-e batfish_enabled=true` to `lab_setup.yml`, the router role will copy each rendered `/etc/frr/frr.conf` to `ansible/batfish/snapshots/<router>/configs/frr.conf` on the controller. Plug your `bf_init_snapshot` / `bf_answer` steps into the placeholder shell block inside `roles/lab_setup/tasks/router.yml` to validate OSPF and ACL intent before/after deployment.

**Available tags:**

| Tag | Playbook | What it does | Output files |
| --- | --- | --- | --- |
| `validation` | `operations.yml` | Post-deployment validation tests | `reports/validation/*_validation_report.md` |
| `health` | `operations.yml` | Health monitoring and resource checks | `reports/health/*_health_report.md` |
| `security` | `operations.yml` | Security verification and compliance checks | `reports/security/*_security_report.md` |
| `telemetry` | `operations.yml` | Telemetry collection and reporting | `reports/*_*.md` |

### 5. Review Reports (after running operations playbook)

```bash
# Validation report
cat ../reports/validation/*_validation_report.md

# Health monitoring report
cat ../reports/health/*_health_report.md

# Security verification report
cat ../reports/security/*_security_report.md

# Telemetry/metrics report
cat ../reports/*_*.md
```

### 5. Verify Network Connectivity

```bash
# Test OSPF neighbors
docker compose exec router1 vtysh -c "show ip ospf neighbor"

# Check routing table
docker compose exec router1 vtysh -c "show ip route"

# Verify VLANs on switches
docker compose exec switch1 cat /config/vlans.conf

# Test inter-device ping
docker compose exec router1 ping -c 2 172.199.0.11
```

---

## Architecture & Design

### System Components

**Container Infrastructure (Docker Compose):**
- **Routers**: FRRouting-based containers for routing, ACLs, NAT
- **Switches**: Bridge-utils-based containers for VLAN switching
- **Networks**: Management (172.199.0.0/24), WAN (10.0.1.0/24), LAN (192.168.11.0/24)

**Automation Framework (Ansible):**
- **Inventory**: Device definitions with SSH credentials
- **Roles**: Modular, reusable automation tasks
- **Playbooks**: Orchestrated workflow combining multiple roles
- **Variables**: Centralized configuration management

**Device Software:**
- **FRRouting**: Open-source routing protocol suite (OSPF, BGP, RIP)
- **vtysh**: Interactive CLI for FRRouting
- **bridge-utils**: Linux bridging for VLAN support
- **OpenSSH**: Remote access for Ansible automation

### Design Philosophy

**Infrastructure as Code (IaC):**
- All configurations stored in YAML files
- Version-controlled, repeatable deployments
- Infrastructure changes traceable and auditable

**Idempotent Automation:**
- Safe to run multiple times
- Detects and skips unnecessary changes
- Rollback capability via config backups

**Modular Roles:**
- Single responsibility per role
- Reusable across different playbooks
- Easy to test and maintain

**Comprehensive Validation:**
- Post-deployment verification
- Health monitoring
- Security compliance checking

---

## Network Topology

### Diagram

```
                       WAN (10.0.1.0/24)
           
          router1 (HQ)---wan1--+--wan2---router2 (Regional DC)
          172.199.0.10        |         172.199.0.11
          10.0.1.2            |         10.0.1.3
                       |
                       +--wan3---router3 (Remote DC)
                              172.199.0.12
                              10.0.1.4

            LAN (192.168.11.0/24)
  
          router2 -- trunk -- switch1 -- access -- Branch1 devices
          192.168.11.10       172.199.0.20        192.168.11.20/100/200
                      
          router3 -- trunk -- switch2 -- access -- Branch2 devices
          192.168.11.11       172.199.0.21        192.168.11.21/100/200

          Mgmt Network (172.199.0.0/24) - SSH/Ansible access

          Note: Gateway addresses (.1) are reserved by Docker networks
```

### Device Roles

| Device | Type | Responsibility | IP (Mgmt) | IP (WAN/LAN) |
|--------|------|-----------------|-----------|--------------|
| router1 | Router | HQ Distribution Center, Edge routing | 172.199.0.10 | 10.0.1.2 |
| router2 | Router | Regional DC, OSPF core | 172.199.0.11 | 10.0.1.3, 192.168.11.10 |
| router3 | Router | Remote DC, OSPF core | 172.199.0.12 | 10.0.1.4, 192.168.11.11 |
| switch1 | Switch | Branch 1 Access, VLAN switching | 172.199.0.20 | 192.168.11.20 |
| switch2 | Switch | Branch 2 Access, VLAN switching | 172.199.0.21 | 192.168.11.21 |

### Network Addressing

**Management Network (SSH/Ansible):** `172.199.0.0/24`
- Router1: 172.199.0.10
- Router2: 172.199.0.11
- Router3: 172.199.0.12
- Switch1: 172.199.0.20
- Switch2: 172.199.0.21

**WAN (Distribution Centers):** `10.0.1.0/24`
- Router1: 10.0.1.2
- Router2: 10.0.1.3
- Router3: 10.0.1.4

**LAN (Branch Offices):** `192.168.11.0/24`
- Router2: 192.168.11.10
- Router3: 192.168.11.11
- Switch1: 192.168.11.20
- Switch2: 192.168.11.21

---

## Automation Features

### VLAN Configuration

**On switch1 & switch2:**
- **VLAN 10:** Management (172.199.0.x)
- **VLAN 20:** Data (192.168.100.x)
- **VLAN 30:** Voice (192.168.200.x)
- **VLAN 40:** Servers (192.168.50.x)

**Access Ports:** Connected to branch devices (end-hosts)  
**Trunk Ports:** Inter-switch and switch-to-router links with 802.1Q tagging

**Automation Role:** `ansible/roles/lab_setup/tasks/main.yml`

**Benefit:** VLAN segregation provides security boundaries and QoS capabilities for multi-tenant branch networks.

### OSPFv2 Multi-Area Routing

**On router1, router2, router3:**
- **OSPF Process ID:** 1
- **Area 0.0.0.0:** Backbone area containing all distribution center routers
- **Dynamic Neighbor Discovery:** Automatic recognition of adjacent routers
- **All Interfaces Advertised:** Enables end-to-end routing
- **Automatic Failover:** Reroutes traffic on link failures

**Enables:** Branch switches to reach all distribution centers dynamically without manual route configuration.

**Automation Role:** `ansible/roles/lab_setup/tasks/main.yml`

**Benefit:** Dynamic routing eliminates manual route maintenance and provides automatic failover for high availability.

### ACL Configuration

**On router1 (Edge Router):**
- **Inbound ACL** on WAN interface
- **Deny** unauthorized traffic from external networks
- **Permit** branch office subnets (192.168.x.x)
- **Log** dropped packets for security auditing

**Protects:** Prevents unauthorized access to distribution centers from external WAN connections.

**Automation Role:** `ansible/roles/lab_setup/tasks/main.yml`

**Benefit:** Centralized security policy prevents network intrusions and data exfiltration.

### NAT Configuration

**On router1 & router2:**
- **Inside Local:** Branch IP addresses (192.168.x.x)
- **Inside Global:** Distribution Center IPs (10.0.1.x)
- **Dynamic NAT Pool:** Translates source IPs as packets leave branch networks
- **Multiple Branches:** Enables overlapping IP spaces to coexist

**Enables:** Allows multiple branch offices with identical IP schemes to connect to DCs transparently.

**Automation Role:** `ansible/roles/lab_setup/tasks/main.yml`

**Benefit:** Simplifies branch network design, reduces IP planning complexity, and maintains centralized IP registry.

### Full Automation (Setup + Operations)

**Commands:**
```bash
ansible-playbook -i inventories/inventory.yml lab_setup.yml -v
ansible-playbook -i inventories/inventory.yml operations.yml -v
```

**What Happens:**
1. Waits for SSH availability on all 5 devices (60s timeout)
2. Configures hostnames on all devices
3. Configures OSPF routing on all routers (parallel execution)
4. Configures VLAN switching on all switches (parallel execution)
5. Applies ACLs to edge routers
6. Configures NAT on core routers
7. Backs up all configurations to `/backups/`
8. Validates post-deployment configurations
9. Performs health monitoring checks
10. Verifies security configurations
11. Collects telemetry and generates reports

**Efficiency:** All 5 devices configured in ~2-3 minutes vs. 30+ minutes manual CLI work.

---

## Complete Deployment Workflow

### Available Playbooks

**Playbooks:**
1. **lab_setup.yml** - Lab environment setup (hostnames, OSPF, VLANs, DNS, backups)
2. **operations.yml** - Post-deployment operations with flexible tag selection (validation, health, security, telemetry)
3. **provision_devices.yml** - Provision new devices via API (uses separate inventory)
4. **ipsec_tunnels.yml** - IPsec tunnel setup (strongSwan)

### Phase 1: Infrastructure Provisioning

```bash
# Step 1.1: Start Docker containers
docker compose up -d
echo "Waiting for SSH daemons..."
sleep 20

# Verify: All 5 containers running
docker compose ps
```

### Phase 2: Lab Setup

```bash
# Step 2.1: Navigate to Ansible directory
cd ansible

# Step 2.2: Run lab setup
ansible-playbook -i inventories/inventory.yml lab_setup.yml -v
```

**What Happens:**
1. Waits for SSH availability on all 5 devices (60s timeout)
2. Configures hostnames on all devices
3. Configures OSPF routing on all routers (parallel execution)
4. Configures VLAN switching on all switches (parallel execution)
5. Configures DNS and NAT gateway on all devices
6. Backs up all configurations to `/backups/`

**Time:** ~1-2 minutes for all 5 devices

### Phase 3: (Optional) Run Post-Deployment Operations

After lab setup is complete, you can run post-deployment operations with flexible tag selection:

```bash
# Option A: Run all post-deployment operations at once
ansible-playbook -i inventories/inventory.yml operations.yml -v

# Option B: Run specific operations using tags
ansible-playbook -i inventories/inventory.yml operations.yml --tags validation -v       # Validation only
ansible-playbook -i inventories/inventory.yml operations.yml --tags health -v           # Health monitoring only
ansible-playbook -i inventories/inventory.yml operations.yml --tags security -v         # Security verification only
ansible-playbook -i inventories/inventory.yml operations.yml --tags telemetry -v        # Telemetry collection only

# Option C: Combine multiple tags
ansible-playbook -i inventories/inventory.yml operations.yml --tags "health,security" -v
```

**What Happens (for each tag):**
- `validation` - Post-deployment connectivity, OSPF, routing, VLAN, DNS, system health validation
- `health` - Interface, routing, switch, resource, process, connectivity, uptime monitoring
- `security` - ACL, NAT, firewall, VLAN, authentication, logging, baseline security checks
- `telemetry` - Metrics and statistics collection with report generation

### Phase 4: Review Reports (if running operations playbook)

```bash
# Review validation reports
cat ../reports/validation/*_validation_report.md

# Review health monitoring reports
cat ../reports/health/*_health_report.md

# Review security verification reports
cat ../reports/security/*_security_report.md

# Review telemetry reports
cat ../reports/*_*.md
```

### Phase 5: Manual Verification (Optional)

```bash
# Step 5.0: Verify configs inside containers
# Router (FRR)
ssh -p 2201 root@localhost
vtysh -c "show running-config"
exit

# Switch (bridge/VLAN)
ssh -p 2221 root@localhost
cat /config/vlans.conf
brctl show
exit

# IPsec (strongSwan) status
ssh -p 2201 root@localhost
ipsec statusall
ipsec status
exit

# Step 5.1: Test OSPF routing
docker compose exec router1 vtysh -c "show ip ospf neighbor"
docker compose exec router1 vtysh -c "show ip route"

# Step 5.2: Verify VLAN configuration
docker compose exec switch1 cat /config/vlans.conf
docker compose exec switch1 brctl show

# Step 5.3: Test end-to-end connectivity
docker compose exec router1 ping -c 2 172.199.0.11
docker compose exec router1 ping -c 2 172.199.0.12

# Step 5.4: Check interface status
docker compose exec router2 ip -br addr
docker compose exec switch1 ip link show
```

### Phase 5: Operational Handoff

```bash
# Step 5.1: Review all reports
ls -la ../reports/

# Step 5.2: Archive configuration backups
cp -r ../backups ~/backups_$(date +%Y%m%d)

# Step 5.3: Document any manual changes (if needed)
# Edit ansible/group_vars_all.yml with any custom settings
# Commit changes to version control
```

---

## Post-Deployment Validation & Testing

### Overview

After initial deployment, comprehensive validation ensures the network meets all functional requirements.

### Post-Deployment Validation Role

**Purpose:** Automated verification that deployment succeeded.

**Location:** `ansible/roles/post_lab_operations/tasks/validation.yml`

**Automated Checks:**

1. **Connectivity Tests**
   - SSH accessibility from Ansible controller
   - Device response to basic connectivity commands
   - Management network reachability

2. **Router Validation**
   - OSPF process status
   - OSPF neighbor adjacencies
   - Routing table population
   - Interface IP configuration
   - ACL configuration presence
   - Router self-ping verification

3. **Switch Validation**
   - VLAN configuration completeness
   - Bridge status and member ports
   - Interface link status
   - Interface statistics (no errors)

4. **Network Connectivity**
   - Inter-router connectivity (ping tests)
   - DNS configuration and resolution
   - Multi-device reachability

5. **System Health**
   - System load levels
   - Disk space availability
   - FRR service status (routers)

**Generated Report:** `reports/validation/*_validation_report.md`

**Example Output:**
```
POST-DEPLOYMENT VALIDATION SUMMARY
========================================
Devices Checked: 5
Routers: 3
Switches: 2

Key Checks:
  ✓ Connectivity verified
  ✓ OSPF status checked on routers
  ✓ VLAN configuration verified on switches
  ✓ Routing table validated
  ✓ Interface status confirmed
========================================
```

### Running Post-Deployment Validation Alone

```bash
# Run only post-deployment validation (skip other stages)
ansible-playbook -i inventories/inventory.yml operations.yml --tags validation -v
```

### Testing Checklist

✓ **Functional Tests**
- [ ] All 5 devices SSH accessible
- [ ] OSPF neighbors established on all routers
- [ ] Routing table populated with all network prefixes
- [ ] VLAN configuration applied to switches
- [ ] Inter-device ping connectivity verified

✓ **Configuration Tests**
- [ ] Hostnames set correctly
- [ ] Interface IPs correctly assigned
- [ ] ACL rules present on edge routers
- [ ] NAT configuration active
- [ ] DNS resolvers configured

✓ **Performance Tests**
- [ ] No interface errors or dropped packets
- [ ] System load within acceptable range
- [ ] Disk space adequate for logs
- [ ] Memory utilization normal
- [ ] FRR processes running (routers)

---

## Monitoring & Health Checks

### Health Monitoring Role

**Purpose:** Continuous collection of device health metrics and operational status.

**Location:** `ansible/roles/post_lab_operations/tasks/health.yml`

**Metrics Collected:**

1. **Interface Health**
   - Interface statistics (RX/TX counters)
   - Error and dropped packet detection
   - Interface UP/DOWN status verification

2. **Routing Health (Routers)**
   - Route summary (count of prefixes)
   - OSPF Link State Database (LSDB) size
   - OSPF neighbor state details
   - Routing flap detection (log analysis)

3. **Switch Health**
   - VLAN integrity verification
   - Bridge forwarding database
   - VLAN member port status

4. **System Resources**
   - CPU usage monitoring
   - Memory usage tracking
   - Disk I/O statistics
   - Kernel error monitoring

5. **Process Health**
   - FRR daemon process count (routers)
   - Zombie process detection
   - Service availability

6. **Connectivity Health**
   - Device-to-device ping tests
   - DNS resolution health
   - Multi-hop reachability

7. **Device Uptime**
   - System uptime collection
   - Boot time tracking

**Generated Report:** `reports/health/*_health_report.md`

### Running Health Monitoring

```bash
# Run health monitoring role
ansible-playbook -i inventories/inventory.yml operations.yml --tags health -v

# Or run all operations
ansible-playbook -i inventories/inventory.yml operations.yml -v
```

### Health Monitoring Interpretation

**Good Health Indicators:**
- All interfaces UP with no errors
- Stable routing table (no route flaps)
- OSPF neighbors stable (no rapid changes)
- CPU usage < 80%
- Memory available > 20%
- Disk usage < 80%
- FRR processes running

**Warning Signs:**
- Interface errors increasing
- Route flaps in logs
- OSPF neighbor state changes
- High CPU sustained > 90%
- Low available memory < 10%
- Disk usage > 85%
- Zombie processes present

---

## Security Verification

### Security Verification Role

**Purpose:** Automated compliance validation of security configurations.

**Location:** `ansible/roles/post_lab_operations/tasks/security.yml`

**Security Checks:**

1. **ACL Verification**
   - ACL configuration presence
   - Inbound filtering rules
   - ACL hit count statistics
   - Outbound ACL rules

2. **NAT Verification**
   - NAT configuration status
   - Inside/outside network definitions
   - NAT pool settings
   - Translation activity (if available)

3. **Firewall & Interface Security**
   - Interface IP address assignment
   - Listening service enumeration
   - SSH security configuration
   - Unnecessary service detection

4. **VLAN & Switch Security**
   - Native VLAN configuration
   - VLAN isolation verification
   - Trunk port security
   - Port-based access control

5. **Authentication & Access Control**
   - SSH key configuration
   - Account lockdown status
   - Sudoers configuration
   - Password policy enforcement

6. **Logging & Monitoring**
   - FRR logging status
   - Debug log analysis
   - Syslog facility verification
   - Log retention policy

7. **Security Baselines**
   - Hostname configuration
   - Time synchronization (NTP)
   - Kernel security parameters (IP forwarding, TCP SYN cookies)
   - System hardening

**Generated Report:** `reports/security/*_security_report.md`

### Compliance Checklist

✓ **Access Control**
- [ ] ACLs configured on edge routers
- [ ] Inbound/outbound filtering rules active
- [ ] SSH keys configured (optional)

✓ **Network Segregation**
- [ ] VLANs implemented for traffic isolation
- [ ] Access and trunk ports properly configured
- [ ] Management network isolated

✓ **Protocol Security**
- [ ] NAT preventing IP spoofing
- [ ] Dynamic NAT pools active
- [ ] Inside/outside translation working

✓ **Authentication**
- [ ] SSH hardened
- [ ] Root account password set (for automation)
- [ ] Unnecessary accounts disabled

✓ **Logging & Monitoring**
- [ ] FRR logging enabled
- [ ] Syslog facility active
- [ ] ACL logging for audit trails
- [ ] Error/warning capture

✓ **Compliance**
- [ ] Security baselines met
- [ ] Kernel parameters optimized
- [ ] No critical vulnerabilities
- [ ] Audit trail maintained

### Running Security Verification

```bash
# Run security verification role
ansible-playbook -i inventories/inventory.yml operations.yml --tags security -v

# Or run all operations
ansible-playbook -i inventories/inventory.yml operations.yml -v
```

---

## Device Access & Management

### SSH Access from Host

**Quick Access Script:**
```bash
./scripts/connect.sh router1
./scripts/connect.sh router2
./scripts/connect.sh router3
./scripts/connect.sh switch1
./scripts/connect.sh switch2
```

**Direct SSH:**
```bash
ssh -p 2201 root@localhost    # router1
ssh -p 2202 root@localhost    # router2
ssh -p 2203 root@localhost    # router3
ssh -p 2221 root@localhost    # switch1
ssh -p 2222 root@localhost    # switch2
```

### Add a New Device Container

```bash
./scripts/add_device.sh --type router --name router4 --ssh-port 2204 --mgmt-ip 172.199.0.13 --wan-ip 10.0.1.5 --lan-ip 192.168.11.12
./scripts/add_device.sh --type switch --name switch3 --ssh-port 2223 --mgmt-ip 172.199.0.22 --lan-ip 192.168.11.22
```

The script prints an inventory snippet you can paste into `ansible/inventories/inventory.yml`.

### Add a New Branch Pair (Router + Switch)

```bash
./scripts/new_branch.sh
```

This adds a branch router and switch connected to the hub router via the WAN network and prints an inventory snippet.

**Password:** `netdev123` or `root` (container-specific)

### Docker Exec Access

```bash
# Access via docker compose exec
docker compose exec router1 /bin/sh
docker compose exec router2 /bin/sh
docker compose exec switch1 /bin/sh
```

### FRRouting CLI Commands (Routers)

```bash
# View OSPF status
vtysh -c 'show ip ospf'
vtysh -c 'show ip ospf neighbor'
vtysh -c 'show ip route'

# View interface status
vtysh -c 'show interface'
vtysh -c 'show interface brief'

# View ACL configuration
vtysh -c 'show access-lists'

# View running configuration
vtysh -c 'show running-config'
```

### Bridge Commands (Switches)

```bash
# View bridge status
brctl show

# View VLAN configuration
cat /config/vlans.conf

# View interface status
ip -br link
ip -br addr

# View bridge MAC address table
brctl showmacs br0
```

---

## Project Structure

```
.
├── docker-compose.yml                 # 5-device network topology
├── README.md                          # This file
├── ansible/
│   ├── ansible.cfg                    # Ansible settings
│   ├── inventories/                   # Inventory files
│   │   ├── inventory.yml              # 5 devices, groups, SSH config
│   │   └── inventory_provision.yml    # Provisioning inventory (new_branch)
│   ├── group_vars_all.yml             # Global vars (OSPF, VLAN, NAT, etc)
│   │
│   ├── lab_setup.yml                  # Lab setup playbook (RECOMMENDED)
│   ├── operations.yml                 # Operations & monitoring with tag selection
│   ├── provision_devices.yml          # Provision new devices via API
│   │
│   └── roles/                         # Modular automation tasks
│       ├── lab_setup/                 # Consolidated setup role
│       │   └── tasks/                 # Split by setup stage
│       ├── post_lab_operations/        # Post-lab reports (validation, health, security, telemetry)
│       │   ├── tasks/                  # Split by task type
│       │   └── templates/              # Report templates
│       └── provision_devices/
│           └── tasks/main.yml         # Device provisioning (optional)
├── network-devices/
│   ├── Dockerfile                     # Base all-in-one image (router + switch tools)
│   ├── entrypoint.sh                  # Container initialization
│   ├── router/
│   │   ├── Dockerfile                 # Router container (FRRouting)
│   │   └── entrypoint.sh              # Router startup script
│   └── switch/
│       ├── Dockerfile                 # Switch container (bridge-utils)
│       └── entrypoint.sh              # Switch startup script
├── scripts/
│   ├── connect.sh                     # Quick device SSH access
│   ├── run_automation.sh              # Run Ansible from host
│   ├── add_device.sh                  # Add a new device container
│   └── new_branch.sh                  # Add a router+switch branch pair
├── configs/
│   ├── router-common/                 # Shared FRR daemon config
│   │   ├── daemons
│   │   └── vtysh.conf
│   ├── router1/                       # Optional per-router overrides
│   ├── router2/
│   ├── router3/
│   ├── provisioned-router/            # Created by new_branch.sh
│   ├── provisioned-switches/          # Created by new_branch.sh
│   ├── switch1/
│   │   ├── vlans.conf                 # Switch VLAN config
│   │   └── vlans/
│   └── switch2/
├── backups/                           # Configuration backups
│   ├── router1_2026-01-14.conf
│   ├── router2_2026-01-14.conf
│   ├── router3_2026-01-14.conf
│   ├── switch1_2026-01-14.conf
│   └── switch2_2026-01-14.conf
└── reports/                           # Automation and validation reports
    ├── validation/
    │   └── *_validation_report.md     # Post-deployment validation
    ├── health/
    │   └── *_health_report.md         # Health monitoring metrics
    ├── security/
    │   └── *_security_report.md       # Security compliance audit
    └── router[1-3]_*.md               # Individual telemetry reports
```

---

## Playbook Execution Options

### Playbooks Available

#### 1. Lab Setup Playbook (FASTEST - Recommended)
```bash
# Initialize lab environment (setup, config, backups)
ansible-playbook -i inventories/inventory.yml lab_setup.yml -v
```
**Runs:** Consolidated lab_setup role
**Tasks:** Hostnames, OSPF, VLANs, DNS, NAT, backups
**Time:** 1-2 minutes
**Perfect for:** Initial lab environment configuration

#### 2. Operations Playbook (Flexible - With Tag Selection)
```bash
# Run post-deployment operations (with flexible tag selection)
ansible-playbook -i inventories/inventory.yml operations.yml -v
```
**Runs:** `post_lab_operations` role (validation, health, security, telemetry tasks)
**Tasks:** Post-deployment checks, monitoring, compliance, reporting
**Time:** 2-3 minutes for all tags, ~1 minute per individual tag
**Perfect for:** Post-setup validation and ongoing operations

#### 3. Provision Devices Playbook (Alternate Inventory)
```bash
# Provision new devices from a separate inventory
ansible-playbook -i inventories/inventory_provision.yml provision_devices.yml -v
```
**Runs:** `lab_setup.yml` using a separate inventory
**Inventory:** `ansible/inventories/inventory_provision.yml` with `new_branch` group
**Perfect for:** Running lab setup against a different set of devices

#### 4. IPsec Tunnels Playbook (strongSwan)
```bash
# Configure IPsec tunnels on routers
ansible-playbook -i inventories/inventory.yml ipsec_tunnels.yml -v
```
**Runs:** `ipsec_tunnels` role
**Perfect for:** Hub-and-spoke or mesh VPN tunnels between routers

### Run Only Specific Operations (Using Tags)

```bash
# Post-deployment validation only
ansible-playbook -i inventories/inventory.yml operations.yml --tags validation -v

# Health monitoring only
ansible-playbook -i inventories/inventory.yml operations.yml --tags health -v

# Security verification only
ansible-playbook -i inventories/inventory.yml operations.yml --tags security -v

# Telemetry collection and reporting only
ansible-playbook -i inventories/inventory.yml operations.yml --tags telemetry -v

# Combine multiple tags
ansible-playbook -i inventories/inventory.yml operations.yml --tags "health,security" -v
```

### Limit to Specific Devices

```bash
# Lab setup on routers only
ansible-playbook -i inventories/inventory.yml lab_setup.yml --limit routers -v

# Lab setup on switches only
ansible-playbook -i inventories/inventory.yml lab_setup.yml --limit switches -v

# Validation on router1 only
ansible-playbook -i inventories/inventory.yml operations.yml --tags validation --limit router1 -v
```

---

## Troubleshooting

### Docker Issues

**Containers won't start:**
```bash
docker compose logs
docker compose logs router1
docker compose down
docker compose up -d
```

**Port conflicts:**
```bash
# Check if ports are in use
netstat -tlnp | grep 220
# Change ports in docker-compose.yml if needed
```

### SSH Connectivity Issues

**SSH access fails:**
```bash
# Wait 20-30 seconds for SSH daemons
sleep 30

# Test SSH connection
ssh -p 2201 root@localhost

# Check container status
docker compose exec router1 ps aux | grep sshd

# Check SSH logs
docker compose exec router1 tail -20 /var/log/auth.log
```

**Ansible can't reach devices:**
```bash
# Verify DNS resolution
ping 172.199.0.10

# Test manual SSH access
ssh -p 2201 -o ConnectTimeout=5 root@localhost

# Check inventories/inventory.yml ansible_host values
cat ansible/inventories/inventory.yml | grep ansible_host

# Increase Ansible timeout
# Edit ansible/ansible.cfg: timeout = 60
```

### Ansible Playbook Issues

**Playbook syntax errors:**
```bash
ansible-playbook -i inventories/inventory.yml lab_setup.yml --syntax-check
ansible-playbook -i inventories/inventory.yml operations.yml --syntax-check
```

**Specific task failures:**
```bash
# Run with increased verbosity
ansible-playbook -i inventories/inventory.yml lab_setup.yml -vvv
ansible-playbook -i inventories/inventory.yml operations.yml -vvv

# Start at specific task
ansible-playbook -i inventories/inventory.yml lab_setup.yml --start-at-task "Set hostname"

# Run in check mode (dry-run)
ansible-playbook -i inventories/inventory.yml lab_setup.yml --check
```

**SSH key issues:**
```bash
# Check SSH configuration
cat ansible/ansible.cfg | grep ssh

# Test SSH with password
ssh -p 2201 -o PubkeyAuthentication=no root@localhost
```

### FRRouting Issues (Routers)

**OSPF not starting:**
```bash
docker compose exec router1 /usr/lib/frr/frrinit.sh status
docker compose exec router1 /usr/lib/frr/frrinit.sh start

# Check FRR logs
docker compose exec router1 tail -50 /var/log/frr/frr.log
```

**OSPF neighbors not forming:**
```bash
# Check neighbor status
docker compose exec router1 vtysh -c "show ip ospf neighbor"

# Check interface status in OSPF
docker compose exec router1 vtysh -c "show ip ospf interface"

# Check running config
docker compose exec router1 vtysh -c "show running-config | section ospf"
```

**Routing table empty:**
```bash
# Check if OSPF is advertising networks
docker compose exec router1 vtysh -c "show ip ospf database"

# Verify OSPF process ID matches (should be 1)
docker compose exec router1 vtysh -c "show ip ospf"

# Check interface configuration
docker compose exec router1 ip addr
```

### Health Monitoring Issues

**Reports not generated:**
```bash
# Check report directory
ls -la reports/

# Manual report generation
ansible-playbook -i inventories/inventory.yml operations.yml --tags health -v

# Check for errors in playbook
ansible-playbook -i inventories/inventory.yml operations.yml --tags health -vvv
```

**Metrics not collected:**
```bash
# Test manual metric collection
docker compose exec router1 ip -s link

# Check if commands exist
docker compose exec router1 which iostat
docker compose exec router1 which top
```

### Security Verification Issues

**ACL verification fails:**
```bash
# Manually check ACLs
docker compose exec router1 vtysh -c "show access-lists"

# Check FRR configuration
docker compose exec router1 cat /etc/frr/frr.conf | grep acl
```

**NAT not found:**
```bash
# Check NAT configuration in FRR
docker compose exec router1 vtysh -c "show running-config | section nat"

# Note: Some FRR builds may not have NAT support
# This is expected and documented
```

---

## Extensions & Future Work

### Planned Enhancements

1. **VPN/IPSec Tunneling**
   - Encrypted inter-DC connections
   - Site-to-site VPN automation
   - Pre-shared key management

2. **Quality of Service (QoS)**
   - Bandwidth allocation policies
   - Traffic prioritization rules
   - DiffServ marking

3. **SNMP Monitoring**
   - Remote monitoring protocol
   - Centralized metric collection
   - Integration with monitoring platforms

4. **Configuration Drift Detection**
   - Config diff generation
   - Audit trail maintenance
   - Automated remediation

5. **CI/CD Integration**
   - Configuration syntax validation
   - Automated testing pipeline
   - Pre-deployment verification

6. **HSRPv2 Redundancy**
   - Virtual IP failover
   - Active-passive router pairs
   - Sub-second convergence

7. **BGP Routing**
   - External routing for ISP connections
   - Route summarization
   - Traffic engineering

8. **Enhanced Logging**
   - Centralized syslog aggregation
   - Elasticsearch integration
   - Log-based alerting

---

## Team Information

**Project:** Network Automation for TechMart Retail Chain Expansion  
**Course:** WIC2005 - Network Automation  
**Submission Date:** January 2026

### Deliverables

- ✅ Complete Docker simulation (5 nodes)
- ✅ Ansible automation (7 roles)
- ✅ Network configurations (OSPF, VLAN, ACLs, NAT)
- ✅ Post-deployment validation automation
- ✅ Health monitoring system
- ✅ Security verification system
- ✅ Comprehensive documentation (README.md)
- ✅ Configuration backups and reports
- 📋 Group assignment details (in PDF)

### Key Metrics

| Metric | Value |
|--------|-------|
| Network Devices | 5 (3 routers + 2 switches) |
| Automation Roles | 7 (config, validation, monitoring, security, telemetry, backup, batch) |
| Configuration Lines | 500+ |
| Playbook Execution Time | 2-3 minutes |
| Manual Configuration Time | 30+ minutes |
| Time Savings | 90%+ |

---

## Additional Resources

### Ansible Documentation
- [Ansible Playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks.html)
- [Ansible Roles](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html)
- [Ansible Variables](https://docs.ansible.com/ansible/latest/user_guide/playbooks_variables.html)

### FRRouting Documentation
- [FRR Official Site](https://frrouting.org/)
- [OSPF Configuration](https://frrouting.org/user-guide/ospf.html)
- [Access Lists](https://frrouting.org/user-guide/filter.html)

### Docker & Networking
- [Docker Compose](https://docs.docker.com/compose/)
- [Linux Bridge VLAN](https://wiki.debian.org/BridgeNetworkConnections)
- [Network Namespaces](https://linux-kernel-labs.github.io/master/labs/networking.html)

---

**Last Updated:** January 14, 2026  
**Documentation Version:** 2.0  
**Status:** Production-Ready
