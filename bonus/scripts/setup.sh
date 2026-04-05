#!/usr/bin/env bash
set -euo pipefail

CLUSTER="iot-bonus"

echo "[1/6] Create fresh Bonus k3d cluster..."
k3d cluster delete "$CLUSTER" 2>/dev/null || true
k3d cluster create "$CLUSTER" --wait

echo "[2/6] Create namespaces..."
kubectl create namespace argocd
kubectl create namespace dev
kubectl create namespace gitlab

echo "[3/6] Install Argo CD (with CRD fix)..."
ARGOCD_VERSION=$(curl -fsSL https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
BASE="https://raw.githubusercontent.com/argoproj/argo-cd/v${ARGOCD_VERSION}/manifests/crds"

kubectl apply --server-side --force-conflicts -f "${BASE}/application-crd.yaml"
kubectl apply --server-side --force-conflicts -f "${BASE}/applicationset-crd.yaml"
kubectl apply --server-side --force-conflicts -f "${BASE}/appproject-crd.yaml"

kubectl wait --for=condition=Established --timeout=60s \
    crd/applications.argoproj.io \
    crd/applicationsets.argoproj.io \
    crd/appprojects.argoproj.io

kubectl apply -n argocd --server-side --force-conflicts \
    -f "https://raw.githubusercontent.com/argoproj/argo-cd/v${ARGOCD_VERSION}/manifests/install.yaml"

echo "[4/6] Wait for Argo CD to start..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
kubectl rollout status deployment/argocd-applicationset-controller -n argocd --timeout=300s

echo "[5/6] Install GitLab via Helm..."
helm repo add gitlab https://charts.gitlab.io/ 2>/dev/null || true
helm repo update gitlab

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "  Applying GitLab root password secret..."
kubectl apply -n gitlab -f "${SCRIPT_DIR}/../confs/gitlab-secret.yaml"

echo "  Installing GitLab via Helm (This takes 5-10 minutes!)..."
helm upgrade --install gitlab gitlab/gitlab \
  -n gitlab \
  -f "${SCRIPT_DIR}/../confs/gitlab-values.yaml" \
  --timeout 1200s

echo "[6/6] ✅ Infrastructure deployed!"
echo ""
echo "⚠️  GitLab takes a few extra minutes to fully stabilize after Helm exits."
echo "Watch progress with:"
echo "  kubectl get pods -n gitlab -w"
echo ""
echo "Once gitlab-webservice-default is 2/2 Running, access GitLab:"
echo "  kubectl port-forward svc/gitlab-webservice-default -n gitlab 8181:8181"
echo "  Then open: http://localhost:8181"
echo ""
echo "Get the root password with:"
echo "  kubectl get secret gitlab-root-password -n gitlab -o jsonpath='{.data.password}' | base64 --decode && echo"