#!/bin/bash
# Run Ansible automation from local host

echo "Running network automation playbook..."
cd "$(dirname "$0")/../ansible"
ansible-playbook -i inventory.yml playbook.yml -v
