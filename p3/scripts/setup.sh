#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# setup.sh — Creates k3d cluster, installs ArgoCD, deploys app
#
# THE FIX:
#   Old: kubectl apply (client-side) → CRDs silently skipped
#        → applicationset-controller crashes (CrashLoopBackOff)
#
#   New: Apply 3 CRDs with --server-side FIRST
#        Wait until they are "Established"
#        THEN apply the full ArgoCD manifest
# ─────────────────────────────────────────────────────────────
set -euo pipefail

CLUSTER="inception-of-things"

# ── STEP 1: Create k3d cluster ──────────────────────────────
echo "[1/6] Create k3d cluster..."
if k3d cluster list 2>/dev/null | grep -q "^${CLUSTER}"; then
    echo "  Cluster '${CLUSTER}' already exists ✅"
else
    k3d cluster create "$CLUSTER" \
        -p "8888:8888@loadbalancer" \
        --wait
    echo "  Cluster created ✅"
fi

# ── STEP 2: Create namespaces ────────────────────────────────
echo "[2/6] Create namespaces..."
kubectl create namespace argocd >/dev/null 2>&1 \
    || echo "  ns argocd already exists ✅"
kubectl create namespace dev >/dev/null 2>&1 \
    || echo "  ns dev already exists ✅"

# ── STEP 3: Apply ArgoCD CRDs FIRST ─────────────────────────
echo "[3/6] Applying ArgoCD CRDs (server-side, before full install)..."

ARGOCD_VERSION=$(curl -fsSL \
    https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
echo "  ArgoCD version: v${ARGOCD_VERSION}"

BASE="https://raw.githubusercontent.com/argoproj/argo-cd/v${ARGOCD_VERSION}/manifests/crds"


kubectl apply --server-side --force-conflicts \
    -f "${BASE}/application-crd.yaml"

kubectl apply --server-side --force-conflicts \
    -f "${BASE}/applicationset-crd.yaml"

kubectl apply --server-side --force-conflicts \
    -f "${BASE}/appproject-crd.yaml"

echo "  Waiting for CRDs to be Established..."
kubectl wait \
    --for=condition=Established \
    --timeout=60s \
    crd/applications.argoproj.io \
    crd/applicationsets.argoproj.io \
    crd/appprojects.argoproj.io

echo "  CRDs ready ✅"
echo "  Registered ArgoCD CRDs:"
kubectl get crd | grep argoproj.io

# ── STEP 4: Install full ArgoCD manifest ────────────────────
echo "[4/6] Install ArgoCD (full manifest, server-side)..."
kubectl apply \
    -n argocd \
    --server-side \
    --force-conflicts \
    -f "https://raw.githubusercontent.com/argoproj/argo-cd/v${ARGOCD_VERSION}/manifests/install.yaml"

echo "  Waiting for argocd-server deployment..."
kubectl rollout status deployment/argocd-server \
    -n argocd --timeout=300s

echo "  Waiting for applicationset-controller (the one that was crashing)..."

kubectl rollout status deployment/argocd-applicationset-controller \
    -n argocd --timeout=300s

echo "  ArgoCD ready ✅"

# ── STEP 5: Apply the ArgoCD Application ────────────────────
echo "[5/6] Apply ArgoCD Application manifest..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -n argocd -f "${SCRIPT_DIR}/../confs/argocd-app.yaml"
echo "  Application manifest applied ✅"

