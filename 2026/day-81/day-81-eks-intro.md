# Day 81 -- Introduction to Amazon EKS with Terraform
---

## Challenge Tasks

### Task 1: Understand EKS Architecture
Research and write notes on:

1. **What does "managed Kubernetes" mean?**
   - AWS manages the **control plane** (API server, etcd, scheduler, controller manager)
   - You manage the **data plane** (worker nodes where your pods run)
   - AWS handles control plane upgrades, patching, and high availability across multiple AZs

2. **EKS components:**
   - **EKS Control Plane** -- managed by AWS, runs in AWS-owned VPC, accessible via API endpoint
   - **Node Groups** -- EC2 instances that run your pods
     - **Managed Node Groups** -- AWS handles provisioning, scaling, and updates
     - **Self-Managed Nodes** -- you manage the EC2 instances yourself
     - **Fargate Profiles** -- serverless, no nodes to manage at all
   - **VPC and Networking** -- EKS runs inside your VPC with subnets across AZs
   - **IAM Integration** -- EKS uses IAM roles for cluster access and pod-level permissions (IRSA)

3. **EKS add-ons the AI-BankApp uses** (from `terraform/eks.tf`):
   - `coredns` -- DNS resolution inside the cluster
   - `kube-proxy` -- network routing for services
   - `vpc-cni` -- AWS VPC CNI plugin, assigns VPC IPs to pods
   - `eks-pod-identity-agent` -- enables pod-level IAM roles
   - `aws-ebs-csi-driver` -- allows pods to use EBS volumes (needed for MySQL and Ollama storage)
   - `metrics-server` -- enables `kubectl top` and HPA
  


---

#  Understand EKS Architecture

## 1. What is Managed Kubernetes?

Amazon Elastic Kubernetes Service (EKS) is AWS's **managed Kubernetes service**. Instead of installing and maintaining an entire Kubernetes cluster ourselves, AWS manages the Kubernetes control plane while we focus on deploying and managing our applications.

### Responsibilities in EKS

| AWS Manages (Control Plane) | Customer Manages (Data Plane) |
| --------------------------- | ----------------------------- |
| Kubernetes API Server       | Worker Nodes (EC2/Fargate)    |
| etcd Database               | Pods and Containers           |
| Scheduler                   | Deployments and Services      |
| Controller Manager          | Namespaces                    |
| High Availability           | Storage and Applications      |
| Security Patching           | Monitoring and Scaling        |
| Version Upgrades            | Application Updates           |

### Why Managed Kubernetes?

Without EKS, we would have to:

* Install Kubernetes manually
* Configure etcd clustering
* Set up High Availability
* Handle backups
* Upgrade Kubernetes versions
* Patch security vulnerabilities

With EKS:

* AWS maintains the Kubernetes control plane.
* AWS automatically patches and upgrades the control plane.
* AWS ensures high availability by running the control plane across multiple Availability Zones (AZs).
* Developers only need to manage the worker nodes and Kubernetes workloads.

---

# 2. EKS Components

## A. EKS Control Plane

The **control plane** is the brain of the Kubernetes cluster.

AWS hosts and manages the control plane in an AWS-owned VPC. Users interact with it through the Kubernetes API endpoint using tools like `kubectl`.

### Main Components

### Kubernetes API Server

* Entry point for all Kubernetes operations.
* Receives commands from `kubectl`.
* Validates and processes API requests.

Example:

```bash
kubectl get pods
```

This command communicates with the API Server.

---

### etcd

* Distributed key-value database.
* Stores the complete cluster state.
* Keeps information about:

  * Pods
  * Nodes
  * Services
  * ConfigMaps
  * Secrets

---

### Scheduler

Responsible for deciding **which worker node** should run a newly created pod.

It considers:

* Available CPU
* Available Memory
* Resource requests
* Node affinity
* Taints and tolerations

---

### Controller Manager

Continuously watches the cluster and ensures the desired state matches the actual state.

Example:

Desired replicas = 3

If one pod crashes:

```
Desired = 3
Running = 2
```

The Controller Manager automatically creates another pod to restore the desired state.

---

## B. Node Groups

Node Groups are collections of EC2 instances that act as Kubernetes worker nodes. These nodes run application pods.

There are three types of node management in EKS.

### 1. Managed Node Groups

This is the most common option and is used by the AI-BankApp project.

AWS automatically:

* Launches EC2 instances
* Replaces unhealthy nodes
* Updates Kubernetes node software
* Performs rolling upgrades
* Integrates with Auto Scaling Groups

Advantages:

* Easier maintenance
* Automatic updates
* Better reliability

---

### 2. Self-Managed Nodes

In this approach, users manage the EC2 instances themselves.

Responsibilities include:

* Launching EC2 instances
* Installing Kubernetes components
* Performing updates
* Replacing failed nodes
* Managing Auto Scaling

Advantages:

* Full customization

Disadvantages:

* More operational work
* Higher maintenance overhead

---

### 3. AWS Fargate Profiles

AWS Fargate is a serverless compute option for Kubernetes.

Instead of managing EC2 instances:

* Users deploy pods.
* AWS automatically provides the required compute resources.

Advantages:

* No worker node management
* Pay only for running pods
* Simplified operations

Disadvantages:

* Higher cost than EC2 for many workloads
* Some limitations on workloads and customization

---

## C. VPC and Networking

Unlike Kind or Minikube, EKS clusters run inside an Amazon VPC.

The AI-BankApp Terraform configuration creates:

* One VPC
* Three Public Subnets
* Three Private Subnets
* Three Intra Subnets
* Internet Gateway
* NAT Gateway

### Public Subnets

Used for:

* Application Load Balancers (ALB)
* Internet-facing services

---

### Private Subnets

Used for:

* Worker Nodes
* Application Pods

Worker nodes remain private for better security.

---

### Intra Subnets

Reserved for:

* EKS Control Plane Elastic Network Interfaces (ENIs)

These subnets allow communication between the AWS-managed control plane and worker nodes.

---

### AWS VPC CNI

Unlike many Kubernetes distributions, EKS assigns **real VPC IP addresses** to pods using the AWS VPC CNI plugin.

Benefits:

* Native VPC networking
* Better performance
* Direct pod-to-pod communication
* Simplified networking

---

## D. IAM Integration (IRSA)

EKS integrates with AWS Identity and Access Management (IAM).

### Cluster Access

IAM users and roles determine who can:

* Create clusters
* Access the Kubernetes API
* Manage workloads

---

### IAM Roles for Service Accounts (IRSA)

IRSA allows Kubernetes Service Accounts to assume IAM roles.

Instead of storing AWS Access Keys inside pods:

```
Pod
   ↓
Service Account
   ↓
IAM Role
   ↓
AWS Services
```

Benefits:

* No long-lived AWS credentials
* Fine-grained permissions
* Improved security
* Temporary credentials issued automatically

Example:

The **EBS CSI Driver** uses IRSA to create and manage Amazon EBS volumes without embedding AWS credentials.

---

# 3. EKS Add-ons Used by AI-BankApp

The `terraform/eks.tf` file installs six essential EKS add-ons.

---

## 1. CoreDNS

Purpose:

Provides DNS resolution inside the Kubernetes cluster.

Example:

```text
mysql.bankapp.svc.cluster.local
```

CoreDNS translates service names into IP addresses so pods can communicate using DNS instead of hardcoded IPs.

---

## 2. kube-proxy

Purpose:

Handles Kubernetes Service networking by maintaining network rules on each worker node.

Responsibilities:

* Routes traffic to services
* Performs load balancing across pod replicas
* Manages iptables or IPVS rules

Without `kube-proxy`, Kubernetes Services would not function correctly.

---

## 3. AWS VPC CNI

Purpose:

Assigns AWS VPC IP addresses directly to Kubernetes pods.

Benefits:

* Pods are first-class citizens in the VPC.
* Improved network performance.
* Native AWS networking.
* Simplified routing.

---

## 4. EKS Pod Identity Agent

Purpose:

Enables Kubernetes pods to securely obtain IAM roles.

Benefits:

* Secure access to AWS services
* Eliminates hardcoded AWS credentials
* Supports least-privilege access

This add-on works with IAM Roles for Service Accounts (IRSA) or EKS Pod Identity.

---

## 5. AWS EBS CSI Driver

Purpose:

Provides persistent storage using Amazon Elastic Block Store (EBS).

In the AI-BankApp project, it is used for:

* MySQL database storage
* Ollama model storage

Without this driver, Persistent Volume Claims (PVCs) cannot dynamically provision EBS volumes.

---

## 6. Metrics Server

Purpose:

Collects CPU and memory usage metrics from cluster nodes and pods.

It enables commands such as:

```bash
kubectl top nodes
kubectl top pods
```

It also provides metrics required by the **Horizontal Pod Autoscaler (HPA)** to automatically scale applications based on CPU or memory utilization.

---

# Summary

* **Amazon EKS** is a managed Kubernetes service where AWS operates the control plane while users manage the worker nodes and applications.
* The **control plane** includes the API Server, etcd, Scheduler, and Controller Manager, all maintained by AWS.
* **Node Groups** provide compute resources and can be Managed, Self-Managed, or Serverless using AWS Fargate.
* **VPC networking** places worker nodes in private subnets while using public subnets for load balancers and intra subnets for control plane networking.
* **IAM integration (IRSA)** allows pods to securely access AWS services without storing credentials.
* The AI-BankApp cluster uses six essential EKS add-ons: **CoreDNS**, **kube-proxy**, **AWS VPC CNI**, **EKS Pod Identity Agent**, **AWS EBS CSI Driver**, and **Metrics Server** to provide networking, storage, security, DNS, and monitoring capabilities.



---

### Task 2: Study the AI-BankApp Terraform Configuration
Clone the repo and examine the `terraform/` directory:

```bash
git clone -b feat/gitops https://github.com/TrainWithShubham/AI-BankApp-DevOps.git
cd AI-BankApp-DevOps/terraform
ls
```

```
argocd.tf           # ArgoCD Helm release
eks.tf              # EKS cluster + node group + IRSA
outputs.tf          # Cluster info and helper commands
provider.tf         # AWS + Helm providers, locals
terraform.tfvars    # Default variable values
variables.tf        # Input variables
vpc.tf              # VPC with public/private/intra subnets
```

<img width="967" height="312" alt="image" src="https://github.com/user-attachments/assets/bf91b7ee-6328-490e-a88e-990fa8813ad7" />


**Study each file and understand what it provisions:**

**`variables.tf` and `terraform.tfvars`:**
```hcl
# The defaults:
aws_region         = "us-west-2"
cluster_name       = "bankapp-eks"
cluster_version    = "1.35"
node_instance_type = "t3.medium"
node_desired_count = 3
node_max_count     = 5
```

**`vpc.tf`** -- Networking foundation:
- Uses the `terraform-aws-modules/vpc/aws` module
- 3 Availability Zones with:
  - **Public subnets** (10.0.1-3.0/24) -- for load balancers, tagged with `kubernetes.io/role/elb`
  - **Private subnets** (10.0.4-6.0/24) -- for worker nodes, tagged with `kubernetes.io/role/internal-elb`
  - **Intra subnets** (10.0.7-9.0/24) -- for EKS control plane ENIs
- NAT Gateway enabled for outbound internet from private subnets

**`eks.tf`** -- The cluster itself:
- Uses the `terraform-aws-modules/eks/aws` module (version ~> 21.0)
- AL2023 AMI for nodes (Amazon Linux 2023)
- 3x `t3.medium` instances (min 3, max 5)
- All 6 EKS add-ons installed as cluster add-ons
- IRSA configured for the EBS CSI driver
- Public + private API endpoint access

**`argocd.tf`** -- ArgoCD via Helm:
- Installs ArgoCD using the `argo-cd` Helm chart
- Exposed as a LoadBalancer service
- Depends on the EKS module (created after the cluster is ready)

**`outputs.tf`** -- Helper commands:
- Outputs the `aws eks update-kubeconfig` command
- Outputs the ArgoCD initial password retrieval command

---


## Repository Structure

Clone the repository and navigate to the Terraform directory:

```bash
git clone -b feat/gitops https://github.com/TrainWithShubham/AI-BankApp-DevOps.git
cd AI-BankApp-DevOps/terraform
ls
```

Terraform directory structure:

```text
terraform/
├── argocd.tf
├── eks.tf
├── outputs.tf
├── provider.tf
├── terraform.tfvars
├── variables.tf
└── vpc.tf
```

Each file has a specific responsibility, making the infrastructure modular and easier to maintain.

---

# 1. provider.tf

## Purpose

This file configures the Terraform providers and local variables required to communicate with AWS and the Kubernetes cluster.

### What it provisions

* AWS Provider
* Kubernetes Provider
* Helm Provider
* Local variables used across Terraform files

### Why it's needed

Terraform needs providers to interact with different platforms:

* **AWS Provider** creates AWS resources such as the VPC, EKS cluster, IAM roles, and EC2 instances.
* **Kubernetes Provider** allows Terraform to interact with the Kubernetes API after the cluster is created.
* **Helm Provider** installs applications like ArgoCD using Helm charts.

This file acts as the **entry point** for Terraform.

---

# 2. variables.tf

## Purpose

Defines reusable input variables so the infrastructure can be customized without changing the Terraform code.

### Important Variables

| Variable             | Purpose              | Default       |
| -------------------- | -------------------- | ------------- |
| `aws_region`         | AWS Region           | `us-west-2`   |
| `cluster_name`       | EKS Cluster Name     | `bankapp-eks` |
| `cluster_version`    | Kubernetes Version   | `1.35`        |
| `node_instance_type` | EC2 Instance Type    | `t3.medium`   |
| `node_desired_count` | Desired Worker Nodes | `3`           |
| `node_max_count`     | Maximum Worker Nodes | `5`           |

### Why use variables?

Instead of editing Terraform code, users only modify variable values.

For example:

```hcl
cluster_name = "bankapp-eks"
```

can easily become

```hcl
cluster_name = "production-eks"
```

without modifying the infrastructure code.

---

# 3. terraform.tfvars

## Purpose

Stores the actual values assigned to the variables declared in `variables.tf`.

### Default Configuration

```hcl
aws_region         = "us-west-2"
cluster_name       = "bankapp-eks"
cluster_version    = "1.35"
node_instance_type = "t3.medium"
node_desired_count = 3
node_max_count     = 5
```

### Benefits

* Keeps configuration separate from code.
* Makes deployments reusable across environments (development, staging, production).
* Allows different configurations without changing Terraform files.

---

# 4. vpc.tf

## Purpose

Creates the networking infrastructure required by the EKS cluster.

Instead of manually creating networking resources, this file uses the community-maintained Terraform AWS VPC module.

```hcl
terraform-aws-modules/vpc/aws
```

---

## Availability Zones

The VPC spans **3 Availability Zones** for high availability.

Example:

```text
AZ-1
AZ-2
AZ-3
```

If one AZ becomes unavailable, workloads continue running in the remaining AZs.

---

## Public Subnets

CIDR Blocks:

```text
10.0.1.0/24
10.0.2.0/24
10.0.3.0/24
```

Purpose:

* Internet-facing Load Balancers
* External traffic

Tagged as:

```text
kubernetes.io/role/elb
```

This tag tells Kubernetes where to create public load balancers.

---

## Private Subnets

CIDR Blocks:

```text
10.0.4.0/24
10.0.5.0/24
10.0.6.0/24
```

Purpose:

* EKS Worker Nodes
* Application Pods

Tagged as:

```text
kubernetes.io/role/internal-elb
```

These subnets are not directly accessible from the internet, improving security.

---

## Intra Subnets

CIDR Blocks:

```text
10.0.7.0/24
10.0.8.0/24
10.0.9.0/24
```

Purpose:

* Elastic Network Interfaces (ENIs) used by the EKS Control Plane.

These subnets provide secure communication between the AWS-managed control plane and worker nodes.

---

## NAT Gateway

The NAT Gateway enables resources in private subnets to access the internet without exposing them publicly.

Examples:

* Pulling container images from registries.
* Downloading software updates.
* Accessing AWS services.

This allows worker nodes to remain private while still having outbound internet connectivity.

---

# 5. eks.tf

## Purpose

Creates the Amazon EKS cluster and its worker nodes.

It uses the official Terraform EKS module:

```hcl
terraform-aws-modules/eks/aws
```

Version:

```text
~> 21.0
```

---

## EKS Cluster

Creates a managed Kubernetes control plane.

Configuration:

* Kubernetes Version: 1.35
* Public API Endpoint
* Private API Endpoint
* IAM Integration

---

## Managed Node Group

Creates EC2 worker nodes with the following configuration:

| Property      | Value             |
| ------------- | ----------------- |
| AMI           | Amazon Linux 2023 |
| Instance Type | t3.medium         |
| Desired Nodes | 3                 |
| Minimum Nodes | 3                 |
| Maximum Nodes | 5                 |

AWS automatically manages:

* Node provisioning
* Health monitoring
* Rolling updates
* Auto Scaling

---

## EKS Add-ons

The cluster installs six managed add-ons:

| Add-on             | Purpose                  |
| ------------------ | ------------------------ |
| CoreDNS            | Internal DNS             |
| kube-proxy         | Service networking       |
| VPC CNI            | Pod networking           |
| EBS CSI Driver     | Persistent storage       |
| Pod Identity Agent | IAM access for pods      |
| Metrics Server     | Resource metrics and HPA |

These add-ons provide essential networking, storage, monitoring, and security functionality.

---

## IAM Roles for Service Accounts (IRSA)

The configuration enables IRSA for the EBS CSI Driver.

Benefits:

* Secure access to AWS APIs.
* No hardcoded AWS credentials.
* Least-privilege permissions.
* Temporary credentials issued automatically.

---

## API Endpoint Access

The EKS cluster enables both:

* Public API Endpoint
* Private API Endpoint

This allows administrators to manage the cluster from outside the VPC while also supporting secure internal communication.

---

# 6. argocd.tf

## Purpose

Installs ArgoCD into the EKS cluster using Helm.

Terraform automatically deploys ArgoCD after the cluster is successfully created.

---

## Helm Chart

Uses the official ArgoCD Helm chart:

```text
argo-cd
```

---

## Service Type

The ArgoCD server is exposed using a:

```text
LoadBalancer
```

AWS automatically provisions an external load balancer, allowing administrators to access the ArgoCD web UI through a public endpoint.

---

## Dependency

The ArgoCD installation depends on the EKS cluster.

Terraform creates resources in this order:

```text
VPC
↓

EKS Cluster
↓

Worker Nodes
↓

ArgoCD Installation
```

This ensures the Kubernetes cluster is fully operational before Helm installs ArgoCD.

---

# 7. outputs.tf

## Purpose

Displays useful information after the infrastructure is created.

Instead of manually finding cluster details, Terraform prints ready-to-use commands.

---

## kubeconfig Command

Example output:

```bash
aws eks update-kubeconfig \
--name bankapp-eks \
--region us-west-2
```

Running this command updates the local kubeconfig file so `kubectl` can connect to the new EKS cluster.

---

## ArgoCD Password Command

Terraform also outputs the command to retrieve the initial ArgoCD admin password.

Example:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d
```

This allows logging into the ArgoCD web interface immediately after deployment.

---

# Overall Terraform Workflow

The Terraform files work together in the following order:

```text
provider.tf
      │
      ▼
variables.tf
      │
      ▼
terraform.tfvars
      │
      ▼
vpc.tf
      │
      ▼
eks.tf
      │
      ▼
argocd.tf
      │
      ▼
outputs.tf
```

---

# AI-BankApp EKS Architecture

```text
                           AWS Cloud
                               │
                     ┌──────────────────┐
                     │       VPC        │
                     │   10.0.0.0/16    │
                     └──────────────────┘
                               │
      ┌────────────────────────┼────────────────────────┐
      │                        │                        │
      ▼                        ▼                        ▼
┌─────────────┐        ┌─────────────┐        ┌─────────────┐
│ Public      │        │ Private     │        │ Intra       │
│ Subnets     │        │ Subnets     │        │ Subnets     │
│ (ALB/NLB)   │        │ Worker Nodes│        │ Control ENIs│
└─────────────┘        └─────────────┘        └─────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ EKS Control Plane    │
                    │ API Server           │
                    │ etcd                │
                    │ Scheduler           │
                    │ Controller Manager  │
                    └──────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Managed Node Group   │
                    │ 3 × t3.medium EC2    │
                    └──────────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        ▼                      ▼                      ▼
   MySQL Pod             Ollama Pod            BankApp Pod
        │                      │                      │
        └───────────────Uses EBS Storage──────────────┘
```

---

## Key Takeaways

* `provider.tf` configures AWS, Kubernetes, and Helm providers.
* `variables.tf` defines reusable infrastructure variables, while `terraform.tfvars` supplies their default values.
* `vpc.tf` provisions a highly available VPC with public, private, and intra subnets plus a NAT Gateway.
* `eks.tf` creates the EKS control plane, managed node group, IAM roles, and installs six essential EKS add-ons.
* `argocd.tf` installs ArgoCD using Helm and exposes it via a LoadBalancer service after the cluster is ready.
* `outputs.tf` prints helper commands for connecting to the cluster and retrieving the initial ArgoCD admin password.

---

**Document:** Draw the architecture: VPC -> Subnets -> EKS Control Plane -> Node Group -> Pods

<img width="1536" height="1024" alt="Detailed AWS EKS architecture diagram" src="https://github.com/user-attachments/assets/461a3b7a-e9f4-418f-aa08-60c5ae6e136c" />


---

### Task 3: Provision the EKS Cluster
Make sure you have the required tools:
```bash
terraform --version    # >= 1.0
aws --version          # AWS CLI v2
kubectl version --client
helm version
```

<img width="1242" height="363" alt="image" src="https://github.com/user-attachments/assets/6cb17298-10a2-4872-b961-edfae5838076" />


Configure AWS credentials:
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-west-2), Output (json)

# Verify
aws sts get-caller-identity
```
<img width="1192" height="242" alt="image" src="https://github.com/user-attachments/assets/2feb3184-1320-4389-a78a-aa0d4ad54b0d" />


Initialize and apply:
```bash
cd terraform

terraform init
terraform plan
```

<img width="1102" height="1151" alt="image" src="https://github.com/user-attachments/assets/90bedaf4-9d77-4e98-a47a-644372c479b3" />

<img width="1307" height="816" alt="image" src="https://github.com/user-attachments/assets/72b6c421-69a0-49c8-8520-06c3e22b2ee5" />


Review the plan carefully. It will create:
- 1 VPC with 9 subnets, NAT gateway, internet gateway
- 1 EKS cluster with control plane
- 1 managed node group (3x t3.medium)
- 6 EKS add-ons
- IAM roles and policies for the cluster, nodes, and EBS CSI driver
- ArgoCD Helm release

```bash
terraform apply
```

<img width="1255" height="502" alt="image" src="https://github.com/user-attachments/assets/a998718d-2171-468a-a7aa-e210b1dcf73a" />


This takes 15-20 minutes. While waiting, review the Terraform output for CloudFormation-like progress.

After completion, note the outputs:
```bash
terraform output
```

<img width="1250" height="422" alt="image" src="https://github.com/user-attachments/assets/ee2c5132-3e15-425b-b2e4-48e47b43ea61" />
<img width="2560" height="1783" alt="image" src="https://github.com/user-attachments/assets/db310236-5c12-442a-a43b-1b2ca27448f4" />
<img width="2560" height="1228" alt="image" src="https://github.com/user-attachments/assets/ea49b8b8-dda5-4a81-9faa-f6485a9c0167" />
<img width="2560" height="1483" alt="image" src="https://github.com/user-attachments/assets/d24e2ab9-6ebd-4db7-bccb-4da78bd7784a" />
<img width="2560" height="1229" alt="image" src="https://github.com/user-attachments/assets/1720b176-2ced-4bcd-8e50-6b4d6a32343a" />
<img width="2560" height="2453" alt="Elastic-Kubernetes-Service-us-west" src="https://github.com/user-attachments/assets/a60e81a3-7df1-4c22-843a-4d7a3f563dba" />
<img width="2535" height="926" alt="AWS EKS Cluster" src="https://github.com/user-attachments/assets/3c793af6-fa59-45b6-96cc-1e8f055f8e08" />


---

### Task 4: Connect to Your Cluster
Update kubeconfig using the Terraform output:
```bash
aws eks update-kubeconfig --name bankapp-eks --region us-west-2
```
<img width="1502" height="52" alt="image" src="https://github.com/user-attachments/assets/597bc31f-e17d-4902-821a-fd7ceef910b1" />



Verify the connection:
```bash
# Check context
kubectl config current-context

# Cluster info
kubectl cluster-info

# List nodes
kubectl get nodes -o wide
```

You should see 3 nodes with status `Ready`, instance type `t3.medium`, spread across 3 AZs.

<img width="1946" height="272" alt="Verify the connection" src="https://github.com/user-attachments/assets/b53611a6-6c16-405b-856f-b6f1d736c1b0" />


Explore the cluster:
```bash
# System pods
kubectl get pods -n kube-system

# All the add-ons are running
kubectl get daemonsets -n kube-system

# EBS CSI driver
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver

# Metrics server (enables kubectl top and HPA)
kubectl top nodes
```
<img width="1730" height="862" alt="image" src="https://github.com/user-attachments/assets/07dbdefd-a7fe-4afc-81cd-bbcdfbf4c940" />


Check ArgoCD is running:
```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```
<img width="1602" height="357" alt="image" src="https://github.com/user-attachments/assets/bb8f1f06-300b-4c2a-8ca5-235cbb45a939" />


Get the ArgoCD admin password:
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Get the ArgoCD LoadBalancer URL:
```bash
kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```
<img width="1825" height="90" alt="image" src="https://github.com/user-attachments/assets/cf24ff0f-867c-4d05-97f0-703b200255cc" />




Open the URL in your browser and log in with `admin` and the password from above. You will use ArgoCD on Days 84-86.

<img width="1920" height="927" alt="image" src="https://github.com/user-attachments/assets/17aa2498-a053-4caf-bf07-43eae996d5d3" />

---

### Task 5: Deploy the AI-BankApp Manually (Before ArgoCD)
Before setting up GitOps, deploy the app manually to validate the cluster works.

Apply the raw manifests from the `k8s/` directory:
```bash
cd ../  # Back to the repo root

kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/pv.yml
kubectl apply -f k8s/pvc.yml
kubectl apply -f k8s/configmap.yml
kubectl apply -f k8s/secrets.yml
kubectl apply -f k8s/mysql-deployment.yml
kubectl apply -f k8s/service.yml
kubectl apply -f k8s/ollama-deployment.yml
kubectl apply -f k8s/bankapp-deployment.yml
kubectl apply -f k8s/hpa.yml
```
<img width="1240" height="532" alt="image" src="https://github.com/user-attachments/assets/d0590fd9-c94a-406f-b4ee-6929f487abbf" />



Watch the pods come up:
```bash
kubectl get pods -n bankapp -w
```
<img width="1127" height="335" alt="image" src="https://github.com/user-attachments/assets/ceebfb83-8fc2-4690-abb4-b430b8bcab91" />


The startup order is:
1. MySQL starts and becomes healthy (15-30 seconds)
2. Ollama starts and pulls the TinyLlama model (2-5 minutes)
3. BankApp init containers wait for both, then the app starts (30-60 seconds after dependencies)

Check PVCs are bound to EBS volumes:
```bash
kubectl get pvc -n bankapp
kubectl get pv
```

You should see 5Gi and 10Gi EBS volumes in the correct AZs.

<img width="1580" height="177" alt="image" src="https://github.com/user-attachments/assets/ae1d7f32-2f95-4107-b58e-78dd01e2b09c" />


Once all pods are running, access the app:
```bash
kubectl port-forward svc/bankapp-service -n bankapp 8080:8080
```

Open `http://localhost:8080` -- you should see the AI-BankApp login page. Register an account, log in, and try the AI chatbot.

<img width="1740" height="1180" alt="image" src="https://github.com/user-attachments/assets/ee624428-4b9b-4835-bc78-4c7484884912" />

<img width="2560" height="1272" alt="image" src="https://github.com/user-attachments/assets/efc84255-c439-471f-a313-30f30ba5923c" />



**Verify the HPA:**
```bash
kubectl get hpa -n bankapp
```

<img width="1107" height="67" alt="image" src="https://github.com/user-attachments/assets/b3e7b5e5-a09c-49f0-92d9-b9fef56b7a09" />


---

### Task 6: Understand EKS Costs and Clean Up Strategy
EKS is not free. The AI-BankApp cluster costs:

| Component | Cost (approximate) |
|-----------|-------------------|
| EKS Control Plane | $0.10/hr (~$73/month) |
| t3.medium nodes (3x) | ~$0.042/hr each (~$91/month total) |
| NAT Gateway | ~$0.045/hr + data transfer (~$33/month) |
| EBS volumes (15Gi total) | ~$1.50/month |
| LoadBalancer (ArgoCD) | ~$0.025/hr (~$18/month) |
| **Total for this lab** | **~$220/month (~$7/day)** |

**Important:** Do NOT leave the cluster running when you are not using it.

Delete the BankApp workload (keep the cluster for Days 82-83):
```bash
kubectl delete -f k8s/hpa.yml
kubectl delete -f k8s/bankapp-deployment.yml
kubectl delete -f k8s/ollama-deployment.yml
kubectl delete -f k8s/mysql-deployment.yml
kubectl delete -f k8s/service.yml
kubectl delete -f k8s/secrets.yml
kubectl delete -f k8s/configmap.yml
kubectl delete -f k8s/pvc.yml
kubectl delete -f k8s/pv.yml
kubectl delete -f k8s/namespace.yml
```

<img width="1230" height="511" alt="Delete the BankApp workload" src="https://github.com/user-attachments/assets/65d05908-f6bb-4de7-bf84-3e5cbabcf859" />


To destroy everything (do this at the end of Day 83 or if taking a break):
```bash
cd terraform
terraform destroy
```

<img width="1125" height="897" alt="terraform destroy" src="https://github.com/user-attachments/assets/2cbae3ef-9d7f-444a-980a-75253af4b1bc" />


**Document:** What are the cost components of the AI-BankApp EKS setup? Why is the NAT Gateway surprisingly expensive?

## EKS Cost Components and NAT Gateway Analysis

### Cost Components of the AI-BankApp EKS Setup

Running the AI-BankApp on Amazon EKS incurs costs from multiple AWS services because each infrastructure component is billed independently.

| Component                  | Purpose                                                                               |                       Approximate Cost |
| -------------------------- | ------------------------------------------------------------------------------------- | -------------------------------------: |
| **EKS Control Plane**      | Managed Kubernetes control plane (API Server, etcd, Scheduler, Controller Manager)    |              **$0.10/hr (~$73/month)** |
| **Managed Node Group**     | Three `t3.medium` EC2 instances that run Kubernetes worker nodes and application pods |                         **~$91/month** |
| **NAT Gateway**            | Provides outbound internet access for worker nodes in private subnets                 | **~$33/month + data transfer charges** |
| **Amazon EBS Volumes**     | Persistent storage for MySQL (5 GiB) and Ollama (10 GiB)                              |                       **~$1.50/month** |
| **Load Balancer (ArgoCD)** | AWS Load Balancer created for the ArgoCD LoadBalancer Service                         |                         **~$18/month** |
| **Total Estimated Cost**   | Complete AI-BankApp EKS lab environment                                               |              **~$220/month (~$7/day)** |

### Why is the NAT Gateway Surprisingly Expensive?

The NAT Gateway is one of the most expensive networking components in a small EKS environment because AWS charges for both **uptime** and **data processed**.

The worker nodes in this project are deployed inside **private subnets** for security, so they cannot access the internet directly. However, they still need outbound internet connectivity to:

* Pull container images from registries such as Docker Hub or Amazon ECR.
* Download operating system and package updates.
* Access AWS services and external APIs.

The NAT Gateway enables this outbound connectivity while keeping the worker nodes private.

Unlike EC2 instances, the NAT Gateway continues to incur an **hourly charge even when there is little or no traffic**, and AWS also charges for every gigabyte of data that passes through it. As a result, a NAT Gateway can become one of the highest-cost resources in a learning environment, even though it performs only a networking function.

### Cost Optimization

To avoid unnecessary AWS charges:

* Delete the AI-BankApp Kubernetes workloads when they are no longer needed.
* Run `terraform destroy` after completing the lab to remove the EKS cluster, VPC, NAT Gateway, EC2 instances, Load Balancers, IAM resources, and other associated infrastructure.
* Never leave an EKS cluster running when it is not actively being used, as AWS resources continue to generate charges even when the applications are idle.

---

# Documentation


## Objective

Today I learned how to provision a production-grade Amazon EKS cluster using Terraform. I studied the AI-BankApp Terraform configuration, understood the EKS architecture, connected to the cluster using `kubectl`, explored the AWS-managed add-ons, manually deployed the AI-BankApp, and learned about EKS cost optimization and cleanup.

---

# EKS Architecture Diagram

```text
                                   AWS ACCOUNT
                                        │
                                        ▼
                             ┌──────────────────────┐
                             │         VPC          │
                             │     10.0.0.0/16      │
                             └──────────────────────┘
                                        │
          ┌─────────────────────────────┴─────────────────────────────┐
          │                                                           │
          ▼                                                           ▼
 ┌──────────────────────┐                                   ┌──────────────────────┐
 │   Public Subnets     │                                   │   Private Subnets    │
 │ (Load Balancers)     │                                   │ (Worker Nodes)       │
 └──────────────────────┘                                   └──────────────────────┘
          │                                                           │
          ▼                                                           ▼
 ┌──────────────────────┐                                ┌────────────────────────┐
 │ Internet Gateway     │                                │ Managed Node Group     │
 └──────────────────────┘                                │ 3 × t3.medium EC2      │
          │                                              └────────────────────────┘
          ▼                                                           │
 ┌──────────────────────┐                                             ▼
 │ AWS Load Balancer    │                               ┌────────────────────────┐
 │ (ArgoCD / App)       │                               │ kubelet               │
 └──────────────────────┘                               │ kube-proxy            │
                                                        │ VPC CNI              │
                                                        │ Pod Identity Agent   │
                                                        └────────────────────────┘
                                                                  │
                                                                  ▼
                                              ┌────────────────────────────────┐
                                              │ BankApp Pods                   │
                                              │ MySQL Pod                      │
                                              │ Ollama Pod                     │
                                              │ HPA                            │
                                              └────────────────────────────────┘
                                                                  │
                                                                  ▼
                                                     Amazon EBS Volumes
                                                       (via CSI Driver)

───────────────────────────────────────────────────────────────────────────────

                 AWS Managed EKS Control Plane (Outside Customer VPC)

              • API Server
              • Scheduler
              • Controller Manager
              • etcd

───────────────────────────────────────────────────────────────────────────────

EKS Add-ons

• CoreDNS
• kube-proxy
• Amazon VPC CNI
• Metrics Server
• AWS EBS CSI Driver
• EKS Pod Identity Agent
```

<img width="1536" height="1024" alt="AWS EKS architecture diagram" src="https://github.com/user-attachments/assets/83653e17-8b6a-4ada-aa80-01921af7a47d" />


---

# Terraform Configuration Explained

## provider.tf

* Configures the AWS provider.
* Configures the Helm provider for deploying Helm charts.
* Defines local values used throughout the Terraform project.

---

## variables.tf

Defines all configurable input variables for the infrastructure, including:

* AWS Region
* Cluster Name
* Kubernetes Version
* Node Instance Type
* Desired, Minimum and Maximum Node Count

---

## terraform.tfvars

Provides default values for the variables.

Default configuration:

* AWS Region: **us-west-2**
* Cluster Name: **bankapp-eks**
* Kubernetes Version: **1.35**
* Worker Nodes: **3**
* EC2 Instance Type: **t3.medium**

---

## vpc.tf

Creates the networking infrastructure using the AWS VPC module.

Resources created:

* VPC (10.0.0.0/16)
* 3 Public Subnets
* 3 Private Subnets
* 3 Intra Subnets
* Internet Gateway
* NAT Gateway
* Route Tables

The public subnets are used for AWS Load Balancers, while the private subnets host the EKS worker nodes.

---

## eks.tf

Creates the production EKS cluster using the AWS EKS module.

It provisions:

* EKS Control Plane
* Managed Node Group
* Amazon Linux 2023 worker nodes
* IAM Roles
* IRSA (IAM Roles for Service Accounts)

It also installs the following EKS Add-ons:

* CoreDNS
* kube-proxy
* Amazon VPC CNI
* EKS Pod Identity Agent
* AWS EBS CSI Driver
* Metrics Server

The cluster API endpoint is accessible from both public and private networks.

---

## argocd.tf

Installs ArgoCD using the official Helm chart.

Terraform automatically:

* Creates the `argocd` namespace
* Installs ArgoCD
* Exposes ArgoCD using a Kubernetes LoadBalancer Service

This prepares the cluster for GitOps deployments in upcoming labs.

---

## outputs.tf

Provides useful Terraform outputs after deployment.

Examples include:

* `aws eks update-kubeconfig`
* ArgoCD admin password retrieval command
* Cluster information

---

# EKS Cost Breakdown

| Component           | Purpose                                 |           Approximate Cost |
| ------------------- | --------------------------------------- | -------------------------: |
| EKS Control Plane   | Managed Kubernetes control plane        |      $0.10/hr (~$73/month) |
| Managed Node Group  | 3 × t3.medium EC2 instances             |                 ~$91/month |
| NAT Gateway         | Outbound internet for private subnets   | ~$33/month + data transfer |
| Amazon EBS Volumes  | Persistent storage for MySQL and Ollama |               ~$1.50/month |
| AWS Load Balancer   | ArgoCD LoadBalancer Service             |                 ~$18/month |
| **Estimated Total** | Complete AI-BankApp EKS Environment     |  **~$220/month (~$7/day)** |

### Why is the NAT Gateway Expensive?

The NAT Gateway allows worker nodes in private subnets to access the internet without exposing them directly. It is billed for both the time it remains provisioned and the amount of data processed. Since it runs continuously, even during periods of low activity, it can become one of the most expensive networking components in a small EKS environment.

---

# ArgoCD Access

**ArgoCD LoadBalancer URL**

```text
https://<your-argocd-loadbalancer-url>
```

**Username**

```text
admin
```

**Status**

* ✅ ArgoCD installed successfully via Terraform
* ✅ LoadBalancer created successfully
* ✅ Login page accessible using the initial admin credentials


