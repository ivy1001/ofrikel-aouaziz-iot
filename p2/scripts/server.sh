#!/bin/bash
set -e

echo "[1/4] Updating packages..."
sudo apt-get update -y

echo "[2/4] Installing K3s (server)..."
# Traefik is needed for ingress in P2, so we should NOT disable it here><.
curl -sfL https://get.k3s.io | sh -

echo "[3/4] Waiting for node to be Ready..."
until sudo k3s kubectl get nodes 2>/dev/null | grep -q " Ready "; do
  sleep 2
done

echo "[4/4] Applying Kubernetes manifests..."
sudo k3s kubectl apply -f /vagrant/confs

echo "✅ P2 provision done."
