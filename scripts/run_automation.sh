#!/bin/bash
# Run Ansible automation from local host

echo "Running lab setup..."
cd "$(dirname "$0")/../ansible"
ansible-playbook -i inventory.yml lab_setup.yml -v

echo "Running post-lab operations..."
ansible-playbook -i inventory.yml operations.yml -v
