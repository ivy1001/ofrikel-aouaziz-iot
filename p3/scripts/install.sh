#!/usr/bin/env bash
set -e

echo "[1/6] Update apt"
sudo apt-get update -y

echo "[2/6] Install base tools"
sudo apt-get install -y ca-certificates curl gnupg git

echo "[3/6] Install Docker"
if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker vagrant
fi

echo "[4/6] Install kubectl"
if ! command -v kubectl >/dev/null 2>&1; then
  curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
    https://packages.cloud.google.com/apt/doc/apt-key.gpg
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
    https://apt.kubernetes.io/ kubernetes-xenial main" | \
    sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y kubectl
fi

echo "[5/6] Install k3d"
if ! command -v k3d >/dev/null 2>&1; then
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

echo "[6/6] Done"
echo "You may need to log out/in for docker group to apply."
