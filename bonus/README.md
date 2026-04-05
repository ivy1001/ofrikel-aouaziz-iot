# Bonus — GitLab + Argo CD (Local GitOps)

## 📌 Overview

The bonus extends **Part 3** by replacing the public GitHub repository with a **self-hosted GitLab instance** running inside the Kubernetes cluster. Everything from Part 3 now works entirely locally:

- **GitLab CE** hosts the application manifests (replaces GitHub)
- **Argo CD** watches the local GitLab repository and auto-deploys changes
- The **wil42/playground** application is deployed in the `dev` namespace

> **Subject requirement**: *"Add Gitlab to the lab you completed in Part 3. Your Gitlab instance must run locally. Configure Gitlab to make it work with your cluster. Create a dedicated namespace named gitlab. Everything you did in Part 3 must work with your local Gitlab."*

---

## 🏗️ Architecture

```
┌────────────────────── k3d cluster (iot-bonus) ──────────────────────┐
│                                                                      │
│   ┌──────────────┐      watches repo      ┌─────────────────────┐   │
│   │   Argo CD    │ ◄───────────────────── │   GitLab CE         │   │
│   │  (argocd ns) │   (local git repo)     │   (gitlab ns)       │   │
│   └──────┬───────┘                        │   localhost:8181     │   │
│          │                                └─────────────────────┘   │
│          │ auto-deploys                                              │
│          ▼                                                           │
│   ┌──────────────┐                                                   │
│   │  wil42/play  │                                                   │
│   │  ground:v1   │                                                   │
│   │   (dev ns)   │                                                   │
│   └──────────────┘                                                   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**3 namespaces** as required:

| Namespace  | Content                                          |
| ---------- | ------------------------------------------------ |
| `argocd`   | Argo CD (server, repo-server, app controller)    |
| `gitlab`   | GitLab CE (webservice, sidekiq, gitaly, DB, etc) |
| `dev`      | wil-playground deployment + service              |

---

## 📁 File Structure

```
bonus/
├── Vagrantfile                    # VM setup (Ubuntu 22.04, 8GB RAM, 4 CPUs)
├── confs/
│   ├── app/
│   │   ├── deployment.yaml        # wil42/playground deployment (pushed to GitLab)
│   │   └── service.yaml           # ClusterIP service for the app
│   ├── argocd-app.yaml            # Argo CD Application pointing to local GitLab
│   ├── gitlab-secret.yaml         # K8s Secret for GitLab root password
│   └── gitlab-values.yaml         # Helm values for GitLab CE
├── scripts/
│   ├── install.sh                 # Install dependencies (Docker, kubectl, k3d, Helm)
│   └── setup.sh                   # Deploy the full infrastructure
└── README.md
```

---

## ⚙️ Requirements

- **OS**: Linux (Ubuntu/Debian)
- **RAM**: At least **8 GB free** (GitLab is resource-intensive)
- **Disk**: At least **10 GB free**

---

## 🚀 How to Run

### Step 1 — Start the virtual machine

From the `bonus/` directory:

```bash
vagrant up
vagrant ssh
```

This creates an Ubuntu 22.04 VM with **8 GB RAM** and **4 CPUs** (required for GitLab).

### Step 2 — Install dependencies (inside the VM)

```bash
cd /home/vagrant/iot
sudo bash scripts/install.sh
```

Installs: **Docker**, **kubectl**, **k3d**, **Helm**.

> After install, log out (`exit`) and SSH back in (`vagrant ssh`) for Docker group to take effect.

### Step 3 — Deploy the infrastructure

```bash
cd /home/vagrant/iot
bash scripts/setup.sh
```

The script automatically:
1. Creates a **k3d cluster** (`iot-bonus`)
2. Creates namespaces: `argocd`, `dev`, `gitlab`
3. Installs **Argo CD**
4. Installs **GitLab CE** via Helm (takes ~5-10 minutes)
5. Waits for all pods to be ready
6. Creates the **root** user with the correct password

### Step 4 — Access GitLab

Inside the VM, run:

```bash
kubectl port-forward svc/gitlab-webservice-default -n gitlab 8181:8181 --address 0.0.0.0
```

Open **http://localhost:8181** and log in:

| Field    | Value            |
| -------- | ---------------- |
| Username | `root`           |
| Password | `B0nusR00t#2026!` |

### Step 5 — Create the GitLab repository and push the app

1. In GitLab, click **"New project"** → **"Create blank project"**
2. Name it **`iot-bonus`**, set visibility to **Public**, uncheck "Initialize with README"
3. Click **"Create project"**

Now push the application manifests to this repository:

```bash
# Create a temporary directory to set up the git repo
cd /tmp && rm -rf iot-bonus && mkdir iot-bonus && cd iot-bonus
git init --initial-branch=main

# Copy the application manifests (deployment + service)
cp /home/vagrant/iot/confs/app/deployment.yaml .
cp /home/vagrant/iot/confs/app/service.yaml .

# Commit and push to the local GitLab
git add .
git commit -m "Initial deployment v1"
git remote add origin http://localhost:8181/root/iot-bonus.git
git push -u origin main
```

> When Git asks for credentials, use: `root` / `gitlabadmin123`

### Step 6 — Connect Argo CD to GitLab

Apply the Argo CD Application manifest:

```bash
kubectl apply -f /home/vagrant/iot/confs/argocd-app.yaml
```

Argo CD will now watch the local GitLab repository and auto-deploy the app.

---

## 🧪 How to Test & Verify

### 1. Verify the namespaces

```bash
kubectl get ns
```

Expected output:

```
NAME     STATUS   AGE
argocd   Active   ...
dev      Active   ...
gitlab   Active   ...
```

### 2. Verify all pods are running

```bash
kubectl get pods -n gitlab
kubectl get pods -n argocd
kubectl get pods -n dev
```

All pods should be `Running` or `Completed`.

### 3. Verify the app is deployed in dev

```bash
kubectl get pods -n dev
```

Expected:

```
NAME                              READY   STATUS    RESTARTS   AGE
wil-playground-xxxxxxxxx-xxxxx    1/1     Running   0          ...
```

### 4. Test the application (v1)

```bash
kubectl port-forward svc/wil-playground-svc -n dev 8888:8888 --address 0.0.0.0
```

In another terminal:

```bash
curl http://localhost:8888/
```

Expected output:

```json
{"status":"ok", "message": "v1"}
```

### 5. Test version change (v1 → v2) — GitOps auto-sync

This is the key demonstration: changing the version in the local GitLab repo and watching Argo CD auto-deploy it.

```bash
cd /tmp/iot-bonus

# Change the image from v1 to v2
sed -i 's/wil42\/playground:v1/wil42\/playground:v2/g' deployment.yaml

# Verify the change
cat deployment.yaml | grep v2

# Push to local GitLab
git add .
git commit -m "Update to v2"
git push
```

Wait ~30 seconds for Argo CD to sync, then verify:

```bash
curl http://localhost:8888/
```

Expected output:

```json
{"status":"ok", "message": "v2"}
```

### 6. Verify via Argo CD dashboard (optional)

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0
```

Open **https://localhost:8080** (accept the self-signed certificate).

| Field    | Value |
| -------- | ----- |
| Username | `admin` |
| Password | Run: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' \| base64 -d` |

You should see the **playground** application with status **Synced** and **Healthy**.

---

## 🔑 Key Difference from Part 3

| | Part 3 | Bonus |
| --- | --- | --- |
| **Git source** | Public GitHub repo | Local GitLab (in-cluster) |
| **Argo CD repo URL** | `https://github.com/...` | `http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/iot-bonus.git` |
| **GitLab** | Not used | Deployed via Helm in `gitlab` namespace |
| **Everything else** | Same | Same (Argo CD, dev namespace, wil42/playground) |

---


## 🧹 Cleanup

```bash
k3d cluster delete iot-bonus
```
