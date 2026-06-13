# Day 66 -- Provision an EKS Cluster with Terraform Modules

## Challenge Tasks

### Task 1: Project Setup
Create a new project directory with proper file structure:

```
terraform-eks/
  providers.tf        # Provider and backend config
  vpc.tf              # VPC module call
  eks.tf              # EKS module call
  variables.tf        # All input variables
  outputs.tf          # Cluster outputs
  terraform.tfvars    # Variable values
```

In `providers.tf`:
1. Pin the AWS provider to `~> 5.0`
2. Pin the Kubernetes provider (you will need it later)
3. Set your region

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "aws" {
  region = var.region
}
```


In `variables.tf`, define:
- `region` (string)
- `cluster_name` (string, default: `"terraweek-eks"`)
- `cluster_version` (string, default: `"1.31"`)
- `node_instance_type` (string, default: `"t3.medium"`)
- `node_desired_count` (number, default: `2`)
- `vpc_cidr` (string, default: `"10.0.0.0/16"`)

```hcl
variable "region" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "terraweek-eks"
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "node_desired_count" {
  type    = number
  default = 2
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
```

---

### Task 2: Create the VPC with Registry Module
EKS requires a VPC with both public and private subnets across multiple availability zones.

In `vpc.tf`, use the `terraform-aws-modules/vpc/aws` module:
1. CIDR: `var.vpc_cidr`
2. At least 2 availability zones
3. 2 public subnets and 2 private subnets
4. Enable NAT gateway (single NAT to save cost): `enable_nat_gateway = true`, `single_nat_gateway = true`
5. Enable DNS hostnames: `enable_dns_hostnames = true`
6. Add the required EKS tags on subnets:
```hcl
public_subnet_tags = {
  "kubernetes.io/role/elb" = 1
}

private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = 1
}
```

```hcl
data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Environment = "dev"
    Project     = "TerraWeek"
  }
}
```

Run `terraform init` and `terraform plan` to verify the VPC config before moving on.

<img width="930" height="624" alt="image" src="https://github.com/user-attachments/assets/e1052007-629a-4886-bf4f-c6c302bf3b81" />

<img width="967" height="1132" alt="image" src="https://github.com/user-attachments/assets/608e31ab-0fce-45f5-85b4-3719eed73c0f" />


##  **Document:** Why does EKS need both public and private subnets? What do the subnet tags do?


###  Documentation — EKS Networking (Public + Private Subnets + Subnet Tags)

---

#  Why does EKS need both public and private subnets?

Amazon EKS is designed using a **hybrid networking model** where different components live in different subnet types for **security, scalability, and routing control**.

---

##  Public Subnets (Internet-facing layer)

Public subnets are used for components that must be reachable from the internet.

### Used for:

* Kubernetes Service type `LoadBalancer`
* AWS Application Load Balancers (ALB)
* Network Load Balancers (NLB)

### Characteristics:

* Have route to **Internet Gateway (IGW)**
* Can receive traffic from the internet
* Do NOT host worker nodes (best practice)

👉 Example:
When you deploy Nginx with:

```yaml
type: LoadBalancer
```

AWS creates an external load balancer in a **public subnet**.

---

##  Private Subnets (Compute layer)

Private subnets host the actual **EKS worker nodes**.

### Used for:

* EC2 worker nodes (managed node groups)
* Kubernetes pods (indirectly via nodes)
* Internal services

### Characteristics:

* NO direct internet access
* Outbound internet access via NAT Gateway
* More secure (not publicly exposed)

👉 This ensures:

* Nodes cannot be directly accessed from the internet
* Only controlled access via Kubernetes API

---

##  Why this separation is important

This architecture provides:

###  Security

* Worker nodes are hidden in private subnets
* Reduces attack surface

###  Scalability

* Load balancers scale independently in public subnets

###  Best Practice (AWS Well-Architected)

* Compute layer isolated from exposure layer

---

#  What do subnet tags do in EKS?

EKS uses **subnet tags to automatically discover where to place load balancers**.

---

## 🟢 Public Subnet Tag

```hcl
"kubernetes.io/role/elb" = "1"
```

### Meaning:

* This subnet is allowed for **external LoadBalancers**
* Used when service type = `LoadBalancer`

### Result:

 AWS places internet-facing load balancers here

---

##  Private Subnet Tag

```hcl
"kubernetes.io/role/internal-elb" = "1"
```

### Meaning:

* This subnet is used for **internal LoadBalancers**
* Not exposed to internet

### Result:

 AWS places internal services here (private apps, internal APIs)

---

##  How Kubernetes uses these tags

When you run:

```yaml
type: LoadBalancer
```

Kubernetes + AWS cloud controller:

1. Checks subnet tags
2. Finds eligible subnets
3. Chooses correct subnet type:

   * Public → external LB
   * Private → internal LB

---

#  What happens if tags are missing?

If subnet tags are not set:

*  LoadBalancer creation may fail
*  Service stays in `<pending>`
*  No external IP assigned

---

#  Simple mental model

```text
PUBLIC SUBNETS  → Internet-facing LoadBalancers
PRIVATE SUBNETS → Worker Nodes + Internal workloads
```

---

#  Summary

EKS uses both subnet types to:

* Separate compute and exposure layers
* Improve security posture
* Allow controlled internet access via NAT
* Enable automatic LoadBalancer provisioning via tags



---

### Task 3: Create the EKS Cluster with Registry Module
In `eks.tf`, use the `terraform-aws-modules/eks/aws` module:

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    terraweek_nodes = {
      ami_type       = "AL2_x86_64"
      instance_types = [var.node_instance_type]

      min_size     = 1
      max_size     = 3
      desired_size = var.node_desired_count
    }
  }

  tags = {
    Environment = "dev"
    Project     = "TerraWeek"
    ManagedBy   = "Terraform"
  }
}
```

Run:
```bash
terraform init      # Download EKS module and its dependencies
terraform validate
terraform plan      # Review -- this will create 30+ resources
```

<img width="987" height="996" alt="image" src="https://github.com/user-attachments/assets/adc6856b-0dce-43e6-87cf-dfd7776bcb03" />
<img width="976" height="60" alt="image" src="https://github.com/user-attachments/assets/222f9510-35e9-443d-b8fe-898af7092ef2" />
<img width="1322" height="1157" alt="image" src="https://github.com/user-attachments/assets/b7231e69-47da-4bc2-b8cc-ba536accc367" />


Review the plan carefully before applying. You should see: EKS cluster, IAM roles, node group, security groups, and more.

---

### Task 4: Apply and Connect kubectl
1. Apply the config:
```bash
terraform apply
```
This will take 10-15 minutes. EKS cluster creation is slow -- be patient.

2. Add outputs in `outputs.tf`:
```hcl
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_region" {
  value = var.region
}
```

<img width="1852" height="482" alt="image" src="https://github.com/user-attachments/assets/9f964d4a-1c5e-4a2d-a499-30c1911ac70a" />



3. Update your kubeconfig:
```bash
aws eks update-kubeconfig --name terraweek-eks --region <your-region>
```

<img width="1087" height="87" alt="image" src="https://github.com/user-attachments/assets/597a28fc-901f-4440-beff-ce6b96fd71b7" />


4. Verify:
```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```
<img width="1395" height="377" alt="image" src="https://github.com/user-attachments/assets/fc8b76a1-4372-4d3c-a4a4-3e639bd07d85" />
<img width="2431" height="1057" alt="image" src="https://github.com/user-attachments/assets/39db2a3b-bee9-409d-a017-e299eb0f6606" />
<img width="2560" height="1355" alt="image" src="https://github.com/user-attachments/assets/fb92ebb6-c2fc-483a-bc5b-085a58451606" />
<img width="2560" height="1462" alt="image" src="https://github.com/user-attachments/assets/23e0153b-dfb1-4741-a4d7-3f074c35c3fc" />


**Verify:** Do you see 2 nodes in `Ready` state? Can you see the kube-system pods running?



### ✅ Node Verification

Your output shows:

```text
NAME                                       STATUS   ROLES    AGE    VERSION
ip-10-0-3-96.us-west-2.compute.internal    Ready    <none>   121m   v1.31.13-eks-ecaa3a6
ip-10-0-4-197.us-west-2.compute.internal   Ready    <none>   121m   v1.31.13-eks-ecaa3a6
```

**Result:**

* ✔ 2 worker nodes present
* ✔ Both nodes are in `Ready` state
* ✔ Managed node group is functioning correctly

---

### ✅ kube-system Pods Verification

Your output shows:

```text
kube-system   aws-node-9knmb             2/2 Running
kube-system   aws-node-t4hp8             2/2 Running
kube-system   coredns-8646664c46-5rsr9   1/1 Running
kube-system   coredns-8646664c46-f55ll   1/1 Running
kube-system   kube-proxy-rzcxt           1/1 Running
kube-system   kube-proxy-zvxqr           1/1 Running
```

**Result:**

* ✔ AWS VPC CNI (`aws-node`) running
* ✔ CoreDNS running
* ✔ kube-proxy running
* ✔ No CrashLoopBackOff or Pending pods

---

### ✅ Cluster Connectivity Verification

```text
Kubernetes control plane is running at ...
CoreDNS is running at ...
```

**Result:**

* ✔ `kubectl` is connected successfully
* ✔ EKS API server reachable
* ✔ Cluster healthy



---

### Task 5: Deploy a Workload on the Cluster
Your Terraform-provisioned cluster is live. Deploy something on it.

1. Create a file `k8s/nginx-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-terraweek
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
```

2. Apply:
```bash
kubectl apply -f k8s/nginx-deployment.yaml
```

3. Wait for the LoadBalancer to get an external IP:
```bash
kubectl get svc nginx-service -w
```

4. Access the Nginx page via the LoadBalancer URL

5. Verify the full picture:
```bash
kubectl get nodes
kubectl get deployments
kubectl get pods
kubectl get svc
```
<img width="1321" height="386" alt="image" src="https://github.com/user-attachments/assets/4a1234ad-f3d0-401f-939f-5bf35eeeded0" />
<img width="1602" height="1092" alt="image" src="https://github.com/user-attachments/assets/79ba0e40-6926-4bce-9cf4-55d0d0907303" />


**Verify:** Can you access the Nginx welcome page through the LoadBalancer URL?
- Yes, Successfully deployed a 3-replica Nginx application on EKS. A Kubernetes Service of type LoadBalancer provisioned an AWS Classic Load Balancer. Worker nodes registered successfully and were marked InService. Application was verified internally via Kubernetes networking (kubectl port-forward) and externally through the AWS Load Balancer endpoint.

<img width="2150" height="601" alt="image" src="https://github.com/user-attachments/assets/dbcd00c7-479a-4e40-a5b8-508672cf09ff" />
<img width="1995" height="472" alt="image" src="https://github.com/user-attachments/assets/a2db1fd8-b78b-4e4a-aa8f-304b7af49279" />


---

### Task 6: Destroy Everything
This is the most important step. EKS clusters cost money. Clean up completely.

1. First, remove the Kubernetes resources (so the AWS LoadBalancer gets deleted):
```bash
kubectl delete -f k8s/nginx-deployment.yaml
```

<img width="1247" height="332" alt="Verify" src="https://github.com/user-attachments/assets/d01f080b-6033-48e5-8e9f-ba9a74e56f18" />


2. Wait for the LoadBalancer to be fully removed (check EC2 > Load Balancers in AWS console)

3. Destroy all Terraform resources:
```bash
terraform destroy
```
This will take 10-15 minutes.

4. Verify in the AWS console:
   - EKS clusters: empty
   - EC2 instances: no node group instances
   - VPC: the terraweek VPC should be gone
   - NAT Gateways: deleted
   - Elastic IPs: released

**Verify:** Is your AWS account completely clean? No leftover resources?
- Yes, my AWS account is completely clean with no leftover resources.

<img width="1540" height="862" alt="image" src="https://github.com/user-attachments/assets/24b380ba-9de6-416c-b5d4-4bdfaac3b6f8" />
<img width="1256" height="527" alt="image" src="https://github.com/user-attachments/assets/c375023d-6999-4d8a-86a1-b72f020a227e" />
<img width="2232" height="347" alt="image" src="https://github.com/user-attachments/assets/4025b22b-5aa2-49db-876f-4e7d31920a1e" />
<img width="2262" height="637" alt="image" src="https://github.com/user-attachments/assets/26224625-d1fe-4081-a470-8d271c6d4014" />
<img width="2542" height="672" alt="image" src="https://github.com/user-attachments/assets/a1cf0f60-e05d-452d-8b24-2f72415deba3" />


---


# Documentation

## Objective

Provision a production-style Amazon EKS cluster using Terraform Registry modules, deploy a workload, verify cluster functionality, and destroy all resources cleanly.

---

# Project Structure

```text
terraform-eks/
├── providers.tf
├── variables.tf
├── terraform.tfvars
├── vpc.tf
├── eks.tf
├── outputs.tf
└── k8s/
    └── nginx-deployment.yaml
```

---

# Key Configuration Files

## providers.tf

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
  }
}

provider "aws" {
  region = var.region
}
```

---

## variables.tf

```hcl
variable "region" {
  type = string
}

variable "cluster_name" {
  type    = string
  default = "terraweek-eks"
}

variable "cluster_version" {
  type    = string
  default = "1.31"
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "node_desired_count" {
  type    = number
  default = 2
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
```

---

## vpc.tf

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "terraweek-vpc"

  cidr = var.vpc_cidr

  azs = [
    "us-west-2a",
    "us-west-2b"
  ]

  private_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  public_subnets = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
```

---

## eks.tf

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  eks_managed_node_groups = {
    terraweek_nodes = {
      ami_type       = "AL2_x86_64"
      instance_types = [var.node_instance_type]

      min_size     = 1
      max_size     = 3
      desired_size = var.node_desired_count
    }
  }

  tags = {
    Environment = "dev"
    Project     = "TerraWeek"
    ManagedBy   = "Terraform"
  }
}
```

---

## outputs.tf

```hcl
output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_region" {
  value = var.region
}
```

---

# Why EKS Needs Public and Private Subnets

### Public Subnets

Public subnets host internet-facing resources such as:

- Load Balancers
- NAT Gateway
- Public access endpoints

These resources require direct internet connectivity.

### Private Subnets

Private subnets host worker nodes and application workloads.

Benefits:

- Better security
- Nodes are not directly exposed to the internet
- Outbound internet access is provided through the NAT Gateway

---

# Purpose of Subnet Tags

```hcl
public_subnet_tags = {
  "kubernetes.io/role/elb" = 1
}
```

Allows Kubernetes to place internet-facing LoadBalancers into public subnets.

```hcl
private_subnet_tags = {
  "kubernetes.io/role/internal-elb" = 1
}
```

Allows Kubernetes to place internal LoadBalancers into private subnets.

Without these tags, Kubernetes cannot automatically discover suitable subnets.

---

# Terraform Plan Summary

Terraform plan showed:

```text
Plan: 58 to add, 0 to change, 0 to destroy.
```

Resources included:

- VPC
- Internet Gateway
- NAT Gateway
- Route Tables
- EKS Cluster
- Managed Node Group
- IAM Roles
- Security Groups
- Launch Templates
- KMS Key
- CloudWatch Resources

---

# Terraform Apply

## Screenshot

> Insert screenshot here

Example:

```text
Apply complete! Resources: 58 added, 0 changed, 0 destroyed.
```

---

# Connecting kubectl

Updated kubeconfig:

```bash
aws eks update-kubeconfig \
  --name terraweek-eks \
  --region us-west-2
```

Verified cluster access:

```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

---

# Managed Node Group Verification

## Screenshot

> Insert screenshot here

Output:

```text
NAME                                       STATUS   ROLES    AGE
ip-10-0-3-96.us-west-2.compute.internal    Ready
ip-10-0-4-197.us-west-2.compute.internal   Ready
```

Verification:

- 2 worker nodes in Ready state
- Managed Node Group functioning correctly

---

# kube-system Pods Verification

```text
aws-node
coredns
kube-proxy
```

All pods were Running.

---

# Nginx Deployment

Deployment:

```yaml
replicas: 3
image: nginx:latest
service: LoadBalancer
```

Applied using:

```bash
kubectl apply -f k8s/nginx-deployment.yaml
```

Verification:

```bash
kubectl get deployments
kubectl get pods
kubectl get svc
```

Output:

```text
nginx-terraweek   3/3 Available
```

---

# Load Balancer

AWS provisioned a Classic Load Balancer:

```text
ae3b244e4a8e844dc832717e3825bdca
```

Service:

```text
TYPE: LoadBalancer
```

Pods:

```text
3/3 Running
```

Endpoints:

```text
10.0.3.23:80
10.0.3.59:80
10.0.4.179:80
```

---

# Nginx Verification

Verified via:

```bash
kubectl port-forward svc/nginx-service 8080:80
```

Accessed:

```text
http://localhost:8080
```

Successfully displayed:

```text
Welcome to nginx!
```

## Screenshot

> Insert screenshot here

---

# Destroy Process

First removed Kubernetes resources:

```bash
kubectl delete -f k8s/nginx-deployment.yaml
```

Verified:

```bash
kubectl get deployments
kubectl get pods
kubectl get svc
```

Only the default Kubernetes service remained.

Then destroyed all AWS infrastructure:

```bash
terraform destroy
```

---

# Cleanup Verification

Verified:

```bash
aws eks list-clusters
```

Expected:

```json
{
  "clusters": []
}
```

Checked:

- EKS Clusters
- EC2 Instances
- Load Balancers
- NAT Gateways
- Elastic IPs
- VPC Resources

All resources removed successfully.

---

# Reflection

## Day 50 (kind/minikube)

| Feature | kind/minikube |
|----------|---------------|
| Local only | Yes |
| Cloud provider | No |
| IAM integration | No |
| High availability | No |
| Cost | Free |
| Infrastructure as Code | Minimal |

---

## Day 66 (EKS + Terraform)

| Feature | EKS |
|----------|-----|
| Managed Control Plane | Yes |
| Multi-AZ | Yes |
| IAM Integration | Yes |
| Production Ready | Yes |
| Terraform Automation | Yes |
| Cloud Networking | Yes |

### Key Learning

With kind/minikube, I manually created local Kubernetes clusters for learning purposes.

With EKS and Terraform, I provisioned:

- VPC
- Public and Private Subnets
- NAT Gateway
- IAM Roles
- Security Groups
- Managed Node Group
- EKS Control Plane

using reusable Terraform modules and a single `terraform apply` command.

This approach is fully automated, repeatable, scalable, and reflects how production infrastructure teams manage Kubernetes environments.

---

# Conclusion

Successfully provisioned an Amazon EKS cluster using Terraform Registry modules, connected kubectl, deployed an Nginx application, verified managed worker nodes and Kubernetes components, and destroyed all AWS resources cleanly to avoid ongoing costs.

