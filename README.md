
# Inception of Things – Part 1

**K3s & Vagrant**

## 📌 Project Overview

This project is an introduction to Kubernetes using **K3s**, **K3d**, and **Vagrant**.
Part 1 focuses on setting up a **minimal Kubernetes cluster** using **K3s** on **two virtual machines** managed by Vagrant.

---

## 🧱 Architecture (P1)

| Machine | Hostname    | Role              | IP Address       |
| ------- | ----------- | ----------------- | ---------------- |
| Server  | `ajeftaniS`  | K3s Control Plane | `192.168.56.110` |
| Worker  | `ajeftaniSW` | K3s Agent         | `192.168.56.111` |

* OS: **Ubuntu 22.04 LTS**
* Provider: **VirtualBox**
* Provisioning: **Vagrant shell scripts**
* Resources:

  * 1 CPU
  * 1024 MB RAM

---

## 📁 Repository Structure

```
.
├── p1/
│   ├── Vagrantfile
│   └── scripts/
│       ├── server.sh
│       └── worker.sh
└── README.md
```

---

## ⚙️ Requirements

* VirtualBox
* Vagrant
* Hardware virtualization enabled (VT-x / SVM)

---

## 🚀 How to Run Part 1

### 1️⃣ Start the virtual machines

From the `p1/` directory:

```bash
vagrant up
```

This will:

* Create two VMs
* Assign static private IPs
* Install K3s server on `ajeftaniS`
* Install K3s agent on `ajeftaniSW`
* Automatically join the worker to the cluster

---

### 2️⃣ Access the server node

```bash
vagrant ssh ajeftaniS
```

---

### 3️⃣ Verify the Kubernetes cluster

```bash
sudo k3s kubectl get nodes -o wide
```

Expected output:

* Two nodes
* Both in `Ready` state
* One control-plane, one worker

Example:

```text
NAME        STATUS   ROLES           INTERNAL-IP
ajeftanis    Ready    control-plane   192.168.56.110
ajeftanisw   Ready    <none>          192.168.56.111
```

---

## 🔐 SSH Access

* Passwordless SSH is enabled via Vagrant
* Access machines using:

```bash
vagrant ssh ajeftaniS
vagrant ssh ajeftaniSW
```

---

## ✅ Part 1 Validation Checklist

✔ Two machines created using Vagrant
✔ Static private IPs assigned
✔ K3s installed in server & agent modes
✔ kubectl available on server
✔ Worker successfully joined cluster

---

## 🧠 Notes

* Traefik was disabled on the server to reduce memory usage (allowed in P1).
* The project strictly follows the subject requirements.
* All configuration files are located in the `p1/` folder as required.

---

## ➡️ Next Step

➡️ **Part 2: K3s with 3 applications and Ingress**

