#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# install.sh — Installs Docker, kubectl, k3d, Helm
# ─────────────────────────────────────────────────────────────
set -e

echo "[1/6] Update apt..."
sudo apt-get update -y

echo "[2/6] Install base tools..."
sudo apt-get install -y ca-certificates curl gnupg git apt-transport-https

# ── Docker ─────────────────────────────────────────────────
echo "[3/6] Install Docker..."
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    # Apply docker group to current session without logout
    echo "Docker installed. Applying group..."
    newgrp docker &
else
    echo "Docker already installed: $(docker --version)"
fi
sudo systemctl enable --now docker

# ── kubectl ─────────────────────────────────────────────────
echo "[4/6] Install kubectl..."
if ! command -v kubectl >/dev/null 2>&1; then
    # Official method from kubernetes.io/docs/tasks/tools/install-kubectl-linux
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
        sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | \
        sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null

    sudo apt-get update -y
    sudo apt-get install -y kubectl
else
    echo "kubectl already installed: $(kubectl version --client --short 2>/dev/null)"
fi

# ── k3d ─────────────────────────────────────────────────────
echo "[5/6] Install k3d..."
if ! command -v k3d >/dev/null 2>&1; then
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
    echo "k3d already installed: $(k3d version | head -1)"
fi

# ── Helm ─────────────────────────────────────────────────────
echo "[6/6] Install Helm..."
if ! command -v helm >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "Helm already installed: $(helm version --short)"
fi

# ── Verify ──────────────────────────────────────────────────
echo ""
echo "════════════════════════════════"
echo " Installation complete!"
echo "════════════════════════════════"
docker  --version
kubectl version --client --short 2>/dev/null || kubectl version --client
k3d     version | head -1
helm    version --short
echo ""
echo "⚠  If docker permission denied: run 'newgrp docker' or log out/in"
