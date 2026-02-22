#!/bin/bash
set -e

# Update system
apt update -y
apt upgrade -y

# Wait for token from server
while [ ! -f /vagrant/token ]; do
  sleep 2
done

TOKEN=$(cat /vagrant/token)

# Install K3s agent
# curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$TOKEN sh -
curl -sfL https://get.k3s.io | \
  K3S_URL="https://192.168.56.110:6443" \
  K3S_TOKEN="$TOKEN" \
  sh -s - --node-ip 192.168.56.111
