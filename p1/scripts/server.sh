#!/bin/bash
set -e

# Update system
apt update -y
apt upgrade -y

# Install K3s server
curl -sfL https://get.k3s.io | sh -

# Wait for node token
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 1
done

# Copy token to shared folder for worker
cp /var/lib/rancher/k3s/server/node-token /vagrant/token

# Allow kubectl for vagrant user
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
