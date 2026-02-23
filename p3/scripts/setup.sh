#!/usr/bin/env bash
set -euo pipefail

CLUSTER="inception-of-things"

echo "[1/6] Create k3d cluster (or reuse if exists)..."
k3d cluster create "$CLUSTER" \
  -p "8888:8888@loadbalancer" \
  || echo "Cluster already exists ✅"

echo "[2/6] Create namespaces..."
kubectl create namespace argocd >/dev/null 2>&1 || echo "ns argocd exists ✅"
kubectl create namespace dev    >/dev/null 2>&1 || echo "ns dev exists ✅"

echo "[3/6] Install Argo CD..."
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "[4/6] Wait for Argo CD server to be ready..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

echo "[5/6] apply your application (argo will deploy into dev)"
kubectl apply -n argocd -f ../confs/argocd-app.yaml

echo "✅ Bootstrap done."
