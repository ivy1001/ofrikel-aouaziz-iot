
## 📚 Kubernetes & K3s Fundamentals (For P2)

This section explains the **core concepts** needed to understand **Part 2** of the project.


---

### 🔹 What is Kubernetes?

**Kubernetes (K8s)**  is an open-source platform designed to automate deploying, scaling, and managing containerized applications that:

* Runs applications in containers
* Keeps them running
* Restarts them if they crash
* Manages networking between them

Instead of manually running containers, Kubernetes **automates everything**.

---

### 🔹 What is K3s?

**K3s** is a **lightweight Kubernetes distribution**:

K3s is a certified version of Kubernetes. Standard Kubernetes is "heavy" and requires a lot of RAM; K3s is optimized for low-resource environments like the virtual machines we are building in Part 1.

* Designed for low resources
* Perfect for learning and small environments
* Uses less RAM and fewer components than full Kubernetes

👉 In this project, **K3s = Kubernetes** (just lighter).
We install K3s directly onto the operating system of our virtual machines.
---

### 🔹 Cluster, Nodes, Server, Worker

A **Kubernetes cluster** is made of **nodes**.

| Component              | Description                                 |
| ---------------------- | ------------------------------------------- |
| Server (Control Plane) | Manages the cluster (API, scheduler, state) |
| Worker                 | Runs applications (pods)                    |

In P1:
we are building a "Cluster" (aka vms) consisting of two machines:

- The Controller (Server): This is the "brain." It makes decisions about where to run applications and monitors the health of the entire system.
- The Agent (Worker): This is the "muscle." It simply follows orders from the Controller and actually runs the applications.

* `ofrikelS` → **Server**
* `ofrikelSW` → **Worker**

---

### 🔹 kubectl

`kubectl` is the **command-line tool** to talk to Kubernetes.

Examples:

```bash
vagrant up
```
conect with ssh loginS for server and loginnSW for worker

```bash
vagrant ssh loginS
```
now check the ip

```bash
ip -4 a | grep -E "enp0s8|192\.168\.56\."
ip -4 a | grep inet
```
check if the k3s running 

```bash
sudo systemctl status k3s --no-pager
sudo systemctl status k3s-agent --no-pager -l
```

```bash
kubectl get nodes -o wide
kubectl get pods
kubectl apply -f file.yaml
```

In K3s, it is available as:

```bash
sudo k3s kubectl
```

Fot ifconfog the ubuntu doesnt have it so when connecting with ssh innstal

```bash
sudo apt update
sudo apt install -y net-tools
```
So a cluster is a group of computers (in our case, virtual machines) that work together as a single system to run applications. Instead of managing each machine individually, we treat the entire group as one powerful resource managed by Kubernetes.

---

## 🧩 Core Objects Used in P2

In Part 2, the objective shifts from setting up the *infrastructure* to *application deployment* and traffic routing.
While Part 1 was about the "cluster"(how to create vm), Part 2 is about how you actually use that cluster to host websites and manage how users access them.

### 🔹 Pod

A **Pod** is the **smallest unit** in Kubernetes.
In the world of Kubernetes, you don't run a "container" directly; you run a Pod.
Think of a Pod as a "wrapper" or a "shell" around your application container. in this part the pods arre app1 app2 app3
* It runs **one or more containers**
* Usually **1 container per pod**

You rarely create pods directly.

---

### 🔹 Deployment (VERY IMPORTANT)

You rarely create a Pod by itself. Instead, you create a Deployment (The Manager).
A **Deployment**:
is a set of instructions that tells Kubernetes how many copies (replicas) of a Pod you want running.
* Manages pods
* Restarts them if they crash
* Allows scaling (replicas)

Example use:

* “I want 3 instances of my app running”

👉 In P2, **each app will be deployed using a Deployment**.

---

### 🔹 Service

Pods are "mortal"—they die and get replaced with new IP addresses all the time. A Service provides a permanent way to find them.(The Internal Phone Number)
A **Service** exposes pods **inside the cluster**.
Why?

* Pods have dynamic IPs
* Services give a **stable access point**

Types:

* `ClusterIP` → internal access only (most used)
* `NodePort` → exposes port on node (not ideal)
* `LoadBalancer` → cloud-based (not used here)

👉 In P2, apps talk to each other **through Services**.

---

### 🔹 Ingress (KEY FOR P2)

**Ingress** allows **external access** to services via HTTP.
An Ingress is like a smart receptionist for your cluster that directs visitors to the right "room" (application) based on the URL they typed.
It looks at the domain name you typed (like app1.com or app2.com) and routes you to the correct Service.
Instead of:

```text
IP:PORT
```

You get:

```text
http://app1.local
http://app2.local
```

Ingress:

* Routes traffic by **host** or **path**
* Uses a controller (Traefik / Nginx)

👉 P2 requires:

* Multiple apps
* One ingress routing traffic to them

---

### 🔹 Ingress Controller

An **Ingress Controller**:

* Watches Ingress rules
* Handles incoming HTTP traffic

In K3s:

* Traefik is installed by default
* It listens on port **80**

---

## 🔁 How Everything Connects (P2 Mental Model)

Pods run the applications, Services expose them internally, and Ingress exposes them externally with routing rules.

```
Browser
   ↓
Ingress (rules)
   ↓
Service
   ↓
Pods (Deployment)
   ↓
Container (Application)
```

---

## 🎯 What P2 Will Do (High Level)

In Part 2:

1. Create **3 applications**
2. Each app:

   * Deployment
   * Service
3. Create **1 Ingress**

   * Routes traffic to apps
4. Test access via browser or curl

---

## 🧠 Why This Matters

* This mirrors **real production Kubernetes**
* Same concepts used in cloud environments
* P3 (Argo CD) will **deploy these automatically**

---

```bash
vagrant up
```
conect with ssh loginS for server and loginnSW for worker

```bash
vagrant ssh loginS
```
test the mv

```bash
kubectl get nodes -o wide
sudo kubectl get all
```

```bash
curl -H "Host:app1.com" 192.168.56.110
curl http://app1.com
```
delete the folders. rm -rf "/Users/pro/VirtualBox VMs/ofrikelS"
---

## 📌 Summary

| Concept    | Purpose                |
| ---------- | ---------------------- |
| K3s        | Lightweight Kubernetes |
| Node       | Machine in cluster     |
| Pod        | Runs containers        |
| Deployment | Manages pods           |
| Service    | Stable networking      |
| Ingress    | External HTTP access   |

---

## 🧩 Core Objects Used in P3

K3s is a Kubernetes distribution. K3d is a tool that runs K3s inside Docker containers for local development.
