#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install K3s server
curl -sfL https://get.k3s.io | sh -s - \
  --node-ip 192.168.56.110 \
  --advertise-address 192.168.56.110 \
  --write-kubeconfig-mode 644 \
  --disable traefik \
  --disable servicelb

# Wait for node token till it is created and ready
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do
  sleep 1
done

# Copy token to shared folder for worker
cp /var/lib/rancher/k3s/server/node-token /vagrant/token

# Allow kubectl for vagrant user
mkdir -p /home/vagrant/.kube
cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
chown -R vagrant:vagrant /home/vagrant/.kube
