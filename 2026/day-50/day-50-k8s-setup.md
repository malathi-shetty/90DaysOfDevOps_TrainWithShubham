# Day 50 – Kubernetes Architecture and Cluster Setup
## Challenge Tasks

## Task 1: Recall the Kubernetes Story

### What is Kubernetes?

Kubernetes (also called K8s) is an open-source container orchestration platform used to automate the deployment, scaling, networking, and management of containerized applications.

It helps manage containers across multiple servers efficiently and reliably.

### 1. Why was Kubernetes created? What problem does it solve that Docker alone cannot?

Kubernetes was created to solve the challenges of managing containers at large scale.

Docker allows developers to build and run containers, but it mainly focuses on running containers on a single machine. 
When applications grow and require hundreds or thousands of containers running across multiple servers, managing them manually becomes difficult.

Problems Docker alone does not solve well:
 - Scheduling containers across multiple machines
 - Automatic scaling based on traffic/load
 - Restarting failed containers automatically
 - Service discovery and networking
 - Load balancing
 - Rolling updates without downtime
 - Managing the desired state of applications

Kubernetes solves these problems by acting as a container orchestration platform that automates container management across a cluster of servers.

In short:
```bash
Docker runs containers.
Kubernetes manages containers at scale.
```

### 2. Who created Kubernetes and what was it inspired by?
- Kubernetes was originally created by Google and released in 2014.
- It was inspired by Google’s internal cluster management system called Borg, which Google had used for many years to run large-scale production workloads.
- Google later open-sourced Kubernetes, and today it is maintained by the Cloud Native Computing Foundation, which is part of the Linux Foundation.

### 3. What does the name "Kubernetes" mean?
The word “Kubernetes” comes from Greek and means:
 - Helmsman
 - Pilot
 - Navigator

It refers to someone who steers a ship.

The name reflects Kubernetes’ role in managing and guiding containers across a cluster, similar to how a helmsman controls a ship.

Kubernetes is commonly shortened to:
```bash
K8s
```
The `8` represents the **eight letters between** `K` and `s`.

That is also why the Kubernetes logo contains a ship wheel.

### What Problems Does Kubernetes Solve?
| Problem                                | Kubernetes Solution |
| -------------------------------------- | ------------------- |
| Running containers across many servers | Scheduling          |
| Containers crashing                    | Self-healing        |
| Traffic increases                      | Auto-scaling        |
| Communication between services         | Service discovery   |
| Distributing traffic                   | Load balancing      |
| Updating applications                  | Rolling updates     |
| Bad deployment                         | Rollback support    |

Kubernetes is an open-source container orchestration platform created by Google in 2014 and inspired by Borg. 
It was designed to manage containerized applications at scale by handling scheduling, scaling, networking, self-healing, and rolling updates across multiple servers.

---

## Task 2: Draw the Kubernetes Architecture
From memory, draw or describe the Kubernetes architecture. Your diagram should include:

**Control Plane (Master Node):**
- API Server — the front door to the cluster, every command goes through it
- etcd — the database that stores all cluster state
- Scheduler — decides which node a new pod should run on
- Controller Manager — watches the cluster and makes sure the desired state matches reality

**Worker Node:**
- kubelet — the agent on each node that talks to the API server and manages pods
- kube-proxy — handles networking rules so pods can communicate
- Container Runtime — the engine that actually runs containers (containerd, CRI-O)

<img width="1536" height="1024" alt="K8-architecture" src="https://github.com/user-attachments/assets/427bc0ff-04b3-46d1-a174-8a8f95fd0748" />


 ### Detailed:

 <img width="1536" height="1024" alt="Kubernetes cluster architecture diagram" src="https://github.com/user-attachments/assets/938d8bb9-6b2e-4fe1-9218-1a39059be068" />


## Kubernetes Architecture 

A Kubernetes cluster consists of:

* a Control Plane
* multiple Worker Nodes

The control plane manages the cluster, while worker nodes run application workloads inside Pods.

Production Kubernetes clusters usually run:

* multiple control plane components for high availability
* multiple worker nodes for scalability and fault tolerance

---

### Control Plane Components (Master Node)

The control plane is the brain of the Kubernetes cluster.

It:

* makes global decisions about the cluster
* schedules workloads
* detects and responds to cluster events
* continuously works to keep the cluster in the desired state

Control plane components may run:

* on dedicated machines
* as static Pods
* in self-hosted setups
* or as managed cloud services

---

### 1. API Server (kube-apiserver)

#### What it does

* The central communication hub of Kubernetes
* Exposes the Kubernetes API
* Validates and processes REST requests
* Acts as the front end of the control plane
* The only core control plane component that directly communicates with etcd

All Kubernetes components communicate through the API Server.

---

#### How it works

When you run:

```bash id="l02ye9"
kubectl apply -f pod.yaml
```

the request goes to the API Server.

The API Server:

1. Validates the request
2. Authenticates and authorizes it
3. Stores the desired state in etcd
4. Makes updated cluster state available to other components

Other Kubernetes components continuously watch the API Server for changes.

---

#### Horizontal Scaling

The kube-apiserver is designed to scale horizontally.

Production clusters often run:

* multiple API Server instances
* behind a load balancer

to provide:

* high availability
* fault tolerance
* improved scalability

---

#### Key Point

If the API Server goes down:

* you cannot manage the cluster
* new changes cannot be applied

However:

* existing workloads usually continue running on worker nodes

until another reconciliation event or failure occurs.

---

### 2. etcd

#### What it does

* A distributed and highly available key-value store
* Stores the entire cluster state
* Acts as the single source of truth for Kubernetes

It stores:

* pod specifications
* deployments
* services
* secrets
* node information
* configuration data
* cluster metadata

---

#### How it works

When a pod is created:

1. The API Server writes the pod specification into etcd
2. Controllers and schedulers observe the change through the API Server
3. The cluster gradually moves toward the desired state

When cluster state changes:

* the API Server updates etcd accordingly

etcd uses the Raft consensus algorithm to maintain consistency across multiple instances.

---

#### Key Point

If etcd data is lost:

* Kubernetes loses knowledge of cluster state

Production clusters should always back up etcd regularly.

---

### 3. Scheduler (kube-scheduler)

#### What it does

* Watches for newly created Pods that do not yet have a node assigned
* Selects the most suitable worker node for each Pod

Scheduling decisions are based on:

* resource availability
* taints and tolerations
* affinity and anti-affinity rules
* topology constraints
* policies and priorities
* workload interference
* data locality

---

#### How it works

The Scheduler:

1. Watches the API Server for unscheduled Pods
2. Filters nodes that cannot run the Pod
3. Scores the remaining candidate nodes
4. Selects the best node
5. Updates the Pod’s `nodeName` field through the API Server

---

#### Key Point

The Scheduler only decides:

```text id="7svv6y"
WHERE the Pod should run
```

It does NOT start containers.

The kubelet on the selected worker node is responsible for actually starting the Pod.

---

### 4. Controller Manager (kube-controller-manager)

## What it does

Runs multiple controllers that continuously monitor cluster state and move the cluster toward the desired state.

Logically:

* each controller is a separate control loop

However:

* they are compiled into a single binary and run together as one process.

Controllers compare:

```text id="rx0l76"
desired state
vs
actual state
```

and take corrective action when needed.

---

#### How it works

Each controller:

1. Watches the API Server
2. Detects state differences
3. Performs reconciliation actions

---

## Examples

### Node Controller

* Detects node failures or unreachable nodes
* Responds when nodes go down

---

### Job Controller

* Watches Job objects
* Creates Pods that run one-time tasks to completion

---

### ReplicaSet / Replication Controller

* Ensures the correct number of Pod replicas are running

---

### EndpointSlice Controller

* Connects Services to Pods by populating EndpointSlice objects

---

### ServiceAccount Controller

* Creates default ServiceAccounts for new namespaces

---

## Key Point

Controllers continuously monitor and reconcile cluster state.

They do not directly run containers themselves.

---

### 5. cloud-controller-manager

#### What it does

* Integrates Kubernetes with cloud provider APIs
* Runs cloud-specific control logic
* Separates cloud functionality from core Kubernetes components

The cloud-controller-manager is mainly used in cloud environments such as:

* AWS
* Azure
* Google Cloud Platform (GCP)

Clusters running locally or on-premises may not use it.

---

#### Responsibilities

### Node Controller

* Checks cloud node state after nodes stop responding

---

### Route Controller

* Configures networking routes in cloud infrastructure

---

### Service Controller

* Creates and manages cloud load balancers for Services

---

## Key Point

The cloud-controller-manager allows Kubernetes to interact with cloud infrastructure without tightly coupling cloud logic into the core Kubernetes codebase.

---

### Worker Node Components

Worker nodes are the machines where application workloads actually run.

Each worker node contains components responsible for:

* running Pods
* networking
* container lifecycle management

---

### 1. kubelet

#### What it does

* The primary node agent running on every worker node
* Communicates with the API Server
* Ensures containers are running as defined in PodSpecs

The kubelet only manages containers created by Kubernetes.

---

#### How it works

The kubelet:

1. Watches the API Server for Pods assigned to its node
2. Reads Pod specifications
3. Instructs the container runtime to start containers
4. Monitors container health
5. Reports Pod and node status back to the API Server

It also:

* restarts failed containers
* performs health checks
* manages Pod lifecycle on the node

---

#### Key Point

The kubelet is the node-level manager responsible for enforcing the desired state on its worker node.

The kubelet does NOT run containers itself.

It delegates container operations to the container runtime.

---

### 2. Container Runtime

#### What it does

The container runtime is responsible for actually running containers.

It handles:

* pulling container images
* starting containers
* stopping containers
* managing container lifecycle

Kubernetes communicates with runtimes through the:

```text id="vyy29l"
CRI (Container Runtime Interface)
```

---

## Common Container Runtimes

### containerd

* The most common runtime in modern Kubernetes clusters

---

### CRI-O

* A lightweight runtime specifically designed for Kubernetes

---

### Docker (historically)

Kubernetes previously interacted with Docker Engine using dockershim.

Modern Kubernetes versions interact directly with CRI-compatible runtimes such as containerd or CRI-O.

containerd itself is also used internally by Docker.

---

## Key Point

The workflow is:

```text id="wl79g0"
kubelet
   ↓
Container Runtime
   ↓
Containers / Pods
```

The kubelet tells the runtime what to run.

The runtime performs the actual container operations.

---

### 3. kube-proxy (Optional)

#### What it does

* A network proxy that runs on each node
* Maintains networking rules on nodes
* Enables communication between Services and Pods
* Provides service-level traffic routing and connection distribution

---

#### How it works

The kube-proxy:

1. Watches the API Server for Service and Endpoint changes
2. Updates networking rules using:

   * iptables
   * IPVS
   * nftables
3. Routes traffic to backend Pods

kube-proxy may also forward traffic itself when packet filtering features are unavailable.

---

## Key Point

kube-proxy implements part of the Kubernetes Service networking model.

It performs packet-level traffic routing rather than advanced Layer 7 load balancing.

Some modern networking solutions can replace kube-proxy functionality entirely.

---

### 4. CNI Plugin (Container Network Interface)

#### What it does

* Provides Pod networking across the cluster
* Assigns IP addresses to Pods
* Enables Pod-to-Pod communication across worker nodes

Kubernetes relies on CNI plugins to implement networking behavior.

---

## Common CNI Plugins

### Calico

* Popular for networking and network policies

---

### Flannel

* Lightweight overlay networking solution

---

### Cilium

* Advanced eBPF-based networking and security platform

---

### Weave Net

* Easy-to-configure networking solution

---

## How it works

When a Pod is created:

1. The kubelet asks the container runtime to create the Pod
2. The runtime calls the CNI plugin
3. The CNI plugin:

   * assigns an IP address
   * configures networking
   * connects the Pod to the cluster network

---

## Key Point

Kubernetes itself does not directly implement Pod networking.

CNI plugins provide the networking layer that allows Pods across nodes to communicate with each other.

---

# Cluster DNS (CoreDNS)

## What it does

* Provides DNS-based service discovery inside the cluster
* Allows Pods and Services to communicate using DNS names instead of IP addresses

Most Kubernetes clusters use CoreDNS as the default DNS service.

---

## How it works

When a Service is created:

* DNS records are automatically generated

Pods can communicate using names such as:

```text id="u2b3mg"
my-service.default.svc.cluster.local
```

Containers automatically use cluster DNS for internal name resolution.

---

## Key Point

Most Kubernetes workloads rely heavily on Cluster DNS for internal service-to-service communication.

---

# Cluster Addons

Kubernetes clusters commonly include addons that extend cluster functionality.

These addons are usually deployed in the:

```text id="ccnhcv"
kube-system
```

namespace.

---

# Common Addons

## Dashboard

* Web-based Kubernetes UI
* Used for cluster management and troubleshooting

---

## Monitoring

* Collects metrics and performance data
* Often implemented using Prometheus and Grafana

---

## Cluster-Level Logging

* Centralizes logs from containers and nodes
* Enables searching and monitoring cluster logs

---

## Network Plugins

* Implement the Kubernetes CNI specification
* Provide cluster networking functionality

---

# Architecture Variations

Kubernetes architecture can be deployed in different ways depending on operational requirements.

---

## Traditional Deployment

* Control plane components run directly on dedicated machines or VMs

---

## Static Pods

* Control plane components run as static Pods managed by kubelet
* Common in kubeadm-based clusters

---

## Self-Hosted Control Plane

* Control plane components run as Pods inside the cluster itself

---

## Managed Kubernetes Services

Cloud providers may fully manage the control plane.

Examples include:

* Amazon EKS
* Google Kubernetes Engine (GKE)
* Azure Kubernetes Service (AKS)

---

# Final Architecture Flow

```text id="pd9k5d"
kubectl
   ↓
API Server
   ↓
etcd

Scheduler ───────┐
Controller Mgr ──┤
Cloud Controller ┘
        ↓
Worker Nodes
   ├── kubelet
   ├── Container Runtime
   ├── kube-proxy
   ├── CNI Plugin
   └── Pods

CoreDNS
Monitoring
Logging
Dashboard
```

<img width="1024" height="1536" alt="Kubernetes architecture overview diagram" src="https://github.com/user-attachments/assets/e05c1d8d-42c1-4944-9583-8106102c4d88" />


---

## After drawing, verify your understanding:
### What happens when you run `kubectl apply -f pod.yaml`? Trace the request through each component.
### OR
### What Happens When You Deploy a Pod?

Deploying a pod using:
```bash
kubectl apply -f pod.yaml
```
is exactly the action that starts the Kubernetes workflow.

Let's trace the request through each component:
1. kubectl reads the pod.yaml file
2. kubectl sends the request to the Kubernetes API Server
3. API Server authenticates and validates the request
4. The desired Pod state is stored in etcd
5. Scheduler detects the unscheduled Pod
6. Scheduler selects the best worker node
7. The selected node information is updated through the API Server
8. kubelet on the worker node notices the assigned Pod
9. kubelet asks the container runtime (containerd/CRI-O) to pull the image and start the container
10. Container runtime starts the container
11. kubelet reports the Pod status back to the API Server
12. API Server updates etcd with the current state
13. kube-proxy configures networking rules
14. Pod reaches the Running state

**Important Understanding:**
- Kubernetes works using a **desired state model**.

You say:
```yaml
I want 1 pod running
```
Kubernetes continuously works to make reality match that desired state.

That is why:
- API Server stores state
- etcd keeps truth
- Controllers watch changes
- Scheduler assigns nodes
- kubelet enforces state

Everything revolves around maintaining desired state.

Easy Trick:

```bash
kubectl
   ↓
API Server
   ↓
etcd
   ↓
Scheduler
   ↓
kubelet
   ↓
Container Runtime
   ↓
Running Pod
```


---

## What Happens When Things Go Wrong in Kubernetes?

### What happens if the API server goes down?
  - kubectl commands stop working because kubectl communicates through the API Server.
  - No new deployments, scaling operations, or configuration changes can happen.
  - Scheduler and controllers cannot update cluster state.
  - Existing pods and applications usually continue running because kubelet on worker nodes keeps managing containers locally.
  - Services may continue working for already-running applications.
  - Cluster state cannot be updated until the API Server is restored.

Recovery:
- Restart the API Server
- In production clusters, another API Server instance may take over (high availability setup)

**Important Clarification**

A common misunderstanding:

```bash
API Server down ≠ Entire cluster immediately stops
```
Already-running containers usually keep running.
Why?
Because:
- kubelet already knows desired state
- container runtime keeps containers alive
- networking rules already exist
But Kubernetes loses its “brain” temporarily.

### What happens if a worker node goes down?
   - kubelet on that node stops sending heartbeats to the API Server.
   - Controller Manager detects the missing heartbeats.
   - The node status changes to "NotReady".
   - Pods running on that node become unavailable.
   - Kubernetes automatically reschedules affected pods onto healthy worker nodes.
   - kubelet on the new node starts the replacement pods.
This behavior is called self-healing.

**Important Clarification**

Rescheduling only works properly when:
 - Pods are managed by:
 - Deployment
 - ReplicaSet
 - StatefulSet
 - DaemonSet

If you created a single standalone Pod manually:
 - Kubernetes may NOT recreate it automatically.


### What Happens If etcd Goes Down?
- etcd stores the entire cluster state and configuration.
- API Server depends on etcd to read and write cluster information.
- If etcd becomes unavailable, the API Server cannot function properly.
- New cluster changes cannot be stored.
- Existing workloads may continue running temporarily on worker nodes.
- Cluster recovery becomes difficult if etcd data is lost completely.

Recovery:
- Restore etcd from backup
- Restart or recover the etcd cluster
  
**Important Understanding:**
```bash
etcd is the source of truth for Kubernetes.
```

Without etcd:
- Kubernetes forgets cluster state
- Desired state cannot be tracked
That’s why etcd backups are critical in production.

### What Happens If a Pod Crashes?
- kubelet detects that the container inside the Pod has stopped.
- kubelet follows the Pod restart policy.
- Usually, Kubernetes automatically restarts the container.
- If the container repeatedly crashes, the Pod enters CrashLoopBackOff state.
- Kubernetes keeps retrying with increasing delay intervals.

Recovery:
- Fix the application bug
- Fix configuration or environment variables
- Check logs using:
  kubectl logs <pod-name>

### What is CrashLoopBackOff?
CrashLoopBackOff means:
- Container starts
- Container crashes
- Kubernetes retries
- Crash repeats continuously

Kubernetes adds waiting time between retries to avoid infinite rapid restarts.

## Full Failure Flow Summary
```bash
API Server failure:
Cluster control stops, workloads usually continue

etcd failure:
Cluster loses state management capability

Worker node failure:
Pods are moved to healthy nodes automatically

Pod/container failure:
kubelet restarts containers automatically
```

### Remember:

```bash
- If the API Server goes down, cluster management operations stop, but existing workloads usually continue running.
- If etcd goes down, Kubernetes loses access to cluster state and cannot manage the cluster properly.
- If a worker node goes down, Kubernetes marks it NotReady and reschedules pods to healthy nodes.
- If a pod crashes, kubelet restarts it automatically according to the restart policy.
```

### Mental Model
```bash
API Server = Brain / Front Door
etcd = Memory / Database
Scheduler = Decision Maker
Controller Manager = Desired State Enforcer
kubelet = Node Agent
Container Runtime = Actually runs containers
```



---

### Task 3: Install kubectl
`kubectl` is the CLI tool you will use to talk to your Kubernetes cluster.

## Step-by-Step: Setting Up Your Local Cluster

**macOS:**
```bash
brew install kubectl
```

**Linux (amd64):**
```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**Windows (with chocolatey):**
```bash
choco install kubernetes-cli
```

**Verify installation:**
```bash
kubectl version --client
```

**Expected output:**

Verify:
```bash
$ kubectl version --client
Client Version: v1.34.1
Kustomize Version: v5.7.1
```

<img width="700" height="158" alt="1- Install kubectl" src="https://github.com/user-attachments/assets/7f9a4ce9-ef28-46fb-8df0-ba18897903a7" />

<img width="103" height="23" alt="image" src="https://github.com/user-attachments/assets/9c9fbe05-8435-4e8a-8b24-5398e25090d3" />

---

### Task 4: Set Up Your Local Cluster

# kind (Kubernetes in Docker)

# Create a cluster
kind create cluster --name devops-cluster


<img width="368" height="163" alt="2" src="https://github.com/user-attachments/assets/360ca3a5-0122-407f-9b10-54a2c5644dc1" />


# Verify
```bash
kubectl cluster-info
kubectl get nodes
```

<img width="405" height="36" alt="3" src="https://github.com/user-attachments/assets/48d86f30-81f7-4ebc-94a6-0bca98c2a19c" />
<img width="383" height="31" alt="4" src="https://github.com/user-attachments/assets/ba9a8727-439c-4922-ac3b-187fb58176df" />



**The cluster initialized successfully, and the control plane node became Ready.**
```bash
Cluster endpoint: https://127.0.0.1:36955
Node name: devops-cluster-control-plane
Role: control-plane
Kubernetes version: v1.35.1
```

### Which one did you choose and why?
I chose **kind (Kubernetes IN Docker)** because it is lightweight, fast, and easy to set up for local Kubernetes testing and development.

kind runs Kubernetes clusters inside Docker containers, which allows clusters to be created and deleted quickly without requiring virtual machines or cloud infrastructure.

It is ideal for:
 - Local development
 - Learning Kubernetes
 - CI/CD testing
 - Experimenting with Kubernetes features in a lightweight environment

Another advantage is that kind uses fewer system resources compared to solutions like minikube, making it efficient for local machines.
