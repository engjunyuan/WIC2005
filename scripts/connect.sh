#!/bin/bash
# Quick access script for network devices

DEVICE=$1

case $DEVICE in
  router1)
    echo "Connecting to Router 1..."
    ssh -p 2201 root@localhost
    ;;
  router2)
    echo "Connecting to Router 2..."
    ssh -p 2202 root@localhost
    ;;
  router3)
    echo "Connecting to Router 3..."
    ssh -p 2203 root@localhost
    ;;
  switch1)
    echo "Connecting to Switch 1..."
    ssh -p 2221 root@localhost
    ;;
  switch2)
    echo "Connecting to Switch 2..."
    ssh -p 2222 root@localhost
    ;;
  ansible)
    echo "Entering Ansible control container..."
    docker-compose exec ansible bash
    ;;
  *)
    echo "Usage: $0 {router1|router2|switch1|switch2|ansible}"
    echo ""
    echo "Available devices:"
    echo "  router1  - Edge router (port 2201)"
    echo "  router2  - Core router (port 2202)"
    echo "  switch1  - Access switch (port 2221)"
    echo "  switch2  - Distribution switch (port 2222)"
    echo "  ansible  - Ansible control node"
    exit 1
    ;;
esac
