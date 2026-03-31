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
# -p "8888:8888@loadbalancer" maps port 8888 on your machine
# to port 8888 inside the cluster's load balancer.
# This is how you reach the playground app from outside.
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
# Subject requires exactly these two namespaces:
#   argocd  → where ArgoCD itself runs
#   dev     → where your playground app runs
kubectl create namespace argocd >/dev/null 2>&1 \
    || echo "  ns argocd already exists ✅"
kubectl create namespace dev >/dev/null 2>&1 \
    || echo "  ns dev already exists ✅"

# ── STEP 3: Apply ArgoCD CRDs FIRST ─────────────────────────
echo "[3/6] Applying ArgoCD CRDs (server-side, before full install)..."

# Get the exact stable version so all URLs match
ARGOCD_VERSION=$(curl -fsSL \
    https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
echo "  ArgoCD version: v${ARGOCD_VERSION}"

BASE="https://raw.githubusercontent.com/argoproj/argo-cd/v${ARGOCD_VERSION}/manifests/crds"

# --server-side bypasses the annotation size limit that causes
# CRDs to be silently skipped with plain `kubectl apply`
kubectl apply --server-side --force-conflicts \
    -f "${BASE}/application-crd.yaml"

kubectl apply --server-side --force-conflicts \
    -f "${BASE}/applicationset-crd.yaml"

kubectl apply --server-side --force-conflicts \
    -f "${BASE}/appproject-crd.yaml"

# Wait until the CRDs are fully registered in the API server
# Without this wait, the applicationset-controller starts before
# its CRD exists → CrashLoopBackOff
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
# This tells ArgoCD:
#   - Watch: github.com/ivy1001/ofrikel-aouaziz-iot → p3/confs/
#   - Deploy into: dev namespace
#   - Auto-sync when GitHub changes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -n argocd -f "${SCRIPT_DIR}/../confs/argocd-app.yaml"
echo "  Application manifest applied ✅"

# ── STEP 6: Summary ─────────────────────────────────────────
echo "[6/6] Bootstrap complete. Waiting for app pod in dev..."

# Give ArgoCD ~15s to start its first sync
sleep 15

# Show current state
echo ""
echo "══════════════════════════════════════════════"
echo "  NAMESPACES:"
kubectl get ns | grep -E "NAME|argocd|dev"

echo ""
echo "  ARGOCD PODS (all should be Running, 0 restarts):"
kubectl get pods -n argocd

echo ""
echo "  DEV PODS (app deployed by ArgoCD):"
kubectl get pods -n dev 2>/dev/null \
    || echo "  (ArgoCD is still syncing, run: kubectl get pods -n dev)"

# Print the ArgoCD admin password
PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d \
    || echo "secret-not-ready-yet")

echo ""
echo "══════════════════════════════════════════════"
echo "  HOW TO ACCESS:"
echo ""
echo "  1) ArgoCD UI:"
echo "     kubectl port-forward svc/argocd-server -n argocd 8080:443 &"
echo "     URL:      https://localhost:8080"
echo "     User:     admin"
echo "     Password: ${PASS}"
echo ""
echo "  2) Test the app:"
echo "     kubectl port-forward svc/wil-playground-svc -n dev 8888:8888 &"
echo "     curl http://localhost:8888/"
echo "     # expects: {\"status\":\"ok\", \"message\": \"v1\"}"
echo ""
echo "  3) Demo v1 → v2 (for evaluation):"
echo "     # In your GitHub repo, edit p3/confs/deployment.yaml:"
echo "     # Change image: wil42/playground:v1 → wil42/playground:v2"
echo "     # git add . && git commit -m 'v2' && git push"
echo "     # Wait ~3 min (or click Sync in ArgoCD UI)"
echo "     curl http://localhost:8888/"
echo "     # expects: {\"status\":\"ok\", \"message\": \"v2\"}"
echo "══════════════════════════════════════════════"