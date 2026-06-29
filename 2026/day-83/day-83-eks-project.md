# Day 83 -- EKS Project: Production Deployment of AI-BankApp

---

## Challenge Tasks

### Task 1: Deploy the Complete AI-BankApp Stack
Make sure your EKS cluster is running:
```bash
kubectl get nodes
```

<img width="981" height="116" alt="image" src="https://github.com/user-attachments/assets/f6f58ec2-e56e-489e-a8d8-5ff6564604ff" />


If you destroyed the cluster, re-provision it:
```bash
cd AI-BankApp-DevOps/terraform
terraform apply
aws eks update-kubeconfig --name bankapp-eks --region us-west-2
```

Deploy the entire application stack in order:

cd AI-BankApp-DevOps

# 1. Namespace and storage
```bash
kubectl apply -f k8s/namespace.yml
kubectl apply -f k8s/pv.yml
kubectl apply -f k8s/pvc.yml
```

<img width="1130" height="270" alt="image" src="https://github.com/user-attachments/assets/8dd6e449-d586-4d20-b4ab-00fc258c9a6c" />

<img width="1625" height="420" alt="image" src="https://github.com/user-attachments/assets/5f2c31ad-6d86-4233-98b2-a9916e3127a7" />
<img width="1411" height="350" alt="image" src="https://github.com/user-attachments/assets/ff2f860c-cb1c-40f7-9e4c-477b17d9a229" />
<img width="1560" height="182" alt="image" src="https://github.com/user-attachments/assets/33725bcd-3a18-4be8-871d-8330efbec7c3" />



# 2. Configuration
```bash
kubectl apply -f k8s/configmap.yml
kubectl apply -f k8s/secrets.yml
```
# 3. Database and AI service
```bash
kubectl apply -f k8s/mysql-deployment.yml
kubectl apply -f k8s/service.yml
kubectl apply -f k8s/ollama-deployment.yml
```
<img width="1275" height="821" alt="image" src="https://github.com/user-attachments/assets/cde5012a-ca0e-4218-8d1c-17a9446bc61f" />


# 4. Wait for dependencies
```bash
echo "Waiting for MySQL..."
kubectl wait --for=condition=ready pod -l app=mysql -n bankapp --timeout=120s

echo "Waiting for Ollama (this takes 2-5 minutes for model pull)..."
kubectl wait --for=condition=ready pod -l app=ollama -n bankapp --timeout=600s
```
<img width="1435" height="245" alt="image" src="https://github.com/user-attachments/assets/fb707bf8-998c-49d2-b9ec-1c2207bdcc42" />


# 5. Application
```bash
kubectl apply -f k8s/bankapp-deployment.yml
kubectl apply -f k8s/hpa.yml
```


# 6. Wait for BankApp
```bash
echo "Waiting for BankApp..."
kubectl wait --for=condition=ready pod -l app=bankapp -n bankapp --timeout=300s
```
<img width="1220" height="246" alt="image" src="https://github.com/user-attachments/assets/257fb6d3-b4ee-4897-8d78-b6adf3db759c" />



Verify everything is running:
```bash
kubectl get all -n bankapp
kubectl get pvc -n bankapp
```
You should see:
- MySQL: 1 pod running with 5Gi PVC bound
- Ollama: 1 pod running with 10Gi PVC bound
- BankApp: 2-4 pods running (managed by HPA)
- Services: 3 ClusterIP services

<img width="1272" height="751" alt="image" src="https://github.com/user-attachments/assets/2a3143e5-3339-464e-b84b-209ecacbe80d" />
<img width="2547" height="1321" alt="image" src="https://github.com/user-attachments/assets/ced520be-aefd-45ab-ae7a-98af038d0719" />

---

### Task 2: Set Up Gateway API and Access the App

```bash
kubectl get crd | grep gateway.networking.k8s.io
```

<img width="1297" height="225" alt="image" src="https://github.com/user-attachments/assets/e9a44edd-776a-40bc-b710-9d385b585a43" />



Install Envoy Gateway (if not done on Day 82):
```bash
helm install envoy-gateway oci://docker.io/envoyproxy/gateway-helm \
  --version v1.4.0 \
  -n envoy-gateway-system --create-namespace \
  --wait 2>/dev/null || echo "Already installed"
```

<img width="1451" height="202" alt="image" src="https://github.com/user-attachments/assets/8b1c0a86-869f-475a-b21a-b1abe739b158" />


Apply the Gateway configuration:
```bash
kubectl apply -f k8s/gateway.yml
```

Wait for the NLB:
```bash
kubectl get gateway -n bankapp -w
```
<img width="1192" height="242" alt="image" src="https://github.com/user-attachments/assets/184411e2-ba8e-4018-a9d6-f22f1d5469c4" />



Get the external address:
```bash
export APP_URL=$(kubectl get gateway bankapp-gateway -n bankapp -o jsonpath='{.status.addresses[0].value}')
echo "AI-BankApp URL: http://$APP_URL"
```
<img width="1341" height="246" alt="image" src="https://github.com/user-attachments/assets/867afd1b-76c7-4e1d-812f-509cf69a64ff" />

---

<img width="1476" height="905" alt="image" src="https://github.com/user-attachments/assets/d1a71048-1173-4ef4-903c-6ed9e6cfd081" />


Allow both hostnames in your HTTPRoute:
```bash
spec:
  hostnames:
    - 52.39.28.122.nip.io
    - a50ce70b771354c12a603db0741cc557-1844316640.us-west-2.elb.amazonaws.com
```
Then apply it:
```bash
kubectl apply -f k8s/gateway.yml
```

<img width="1491" height="936" alt="image" src="https://github.com/user-attachments/assets/2dc02275-1fc4-4a52-8080-adfe2e0761be" />
<img width="1262" height="136" alt="image" src="https://github.com/user-attachments/assets/81e1d336-e509-4828-8938-a497e800f42d" />


---

Test the application:
```bash
# Health check (Spring Boot Actuator)
curl -s http://$APP_URL/actuator/health | python3 -m json.tool


<img width="1682" height="756" alt="image" src="https://github.com/user-attachments/assets/7675d0c9-cd84-4a04-936b-ddf8395d6c2e" />


# Load the home page
curl -s -o /dev/null -w "%{http_code}" http://$APP_URL

curl -L -s -o /dev/null -w "%{http_code}\n" http://$APP_URL

```

<img width="1722" height="1252" alt="image" src="https://github.com/user-attachments/assets/5942a84d-af72-4622-88be-bf5cc16fd6eb" />


Open `http://$APP_URL` in your browser:
1. Click "Register" and create an account
2. Log in with your credentials
3. Perform banking operations (deposit, withdraw, transfer)
4. Try the AI chatbot -- ask a financial question
5. Toggle dark/light mode

**The full stack is running on EKS:** Spring Boot serves the UI, MySQL stores accounts and transactions, Ollama's TinyLlama model powers the AI chatbot -- all on managed Kubernetes with persistent storage and autoscaling.

<img width="1970" height="652" alt="image" src="https://github.com/user-attachments/assets/eaf3592e-24d7-4fae-964c-483b348cee14" />
<img width="2557" height="1382" alt="image" src="https://github.com/user-attachments/assets/7dec6ee5-72ca-4b5d-b1c2-159080c29122" />


---

### Task 3: Deploy the Monitoring Stack
Deploy Prometheus and Grafana to monitor the AI-BankApp on EKS.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  --set grafana.adminPassword=admin123 \
  --set prometheus.prometheusSpec.retention=3d \
  --set prometheus.prometheusSpec.resources.requests.memory=256Mi \
  --set prometheus.prometheusSpec.resources.requests.cpu=100m \
  --wait --timeout 600s
```


<img width="1610" height="336" alt="image" src="https://github.com/user-attachments/assets/5bc7ed59-fd14-45bb-94da-a6b01a774420" />
<img width="1550" height="710" alt="image" src="https://github.com/user-attachments/assets/01432183-b291-4d42-a4db-489167796610" />
<img width="1400" height="77" alt="image" src="https://github.com/user-attachments/assets/f4d78664-52bf-4c2d-b995-b6d57f4143ca" />


Verify:
```bash
kubectl get pods -n monitoring
```
<img width="1112" height="227" alt="image" src="https://github.com/user-attachments/assets/938f6115-d72e-4b8c-9feb-ec74be6dcb88" />


**Access Grafana:**
```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

Open `http://localhost:3000`. Login: `admin` / `admin123`.

<img width="2560" height="1400" alt="image" src="https://github.com/user-attachments/assets/b1f98c76-1064-4d32-89a6-80fc541bfb20" />


**The AI-BankApp exposes Prometheus metrics natively.** The Spring Boot Actuator endpoint at `/actuator/prometheus` provides JVM metrics, HTTP request metrics, and more.

Create a ServiceMonitor to scrape the BankApp:
```yaml
# bankapp-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: bankapp-monitor
  namespace: monitoring
  labels:
    release: monitoring
spec:
  namespaceSelector:
    matchNames:
      - bankapp
  selector:
    matchLabels:
      app: bankapp
  endpoints:
    - port: "8080"
      path: /actuator/prometheus
      interval: 15s
```

```bash
kubectl apply -f bankapp-servicemonitor.yaml
```

**Access Prometheus:**
```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
```

<img width="2557" height="602" alt="image" src="https://github.com/user-attachments/assets/5852f0e0-59cd-47a7-97cc-acb54cf52e76" />


Query AI-BankApp metrics:

# JVM memory usage
jvm_memory_used_bytes{namespace="bankapp"}

<img width="2560" height="1766" alt="image" src="https://github.com/user-attachments/assets/2193642c-5cf7-45a6-935b-622e4b8c579a" />


# HTTP request rate
rate(http_server_requests_seconds_count{namespace="bankapp"}[5m])

<img width="2560" height="2111" alt="image" src="https://github.com/user-attachments/assets/d5b35ba3-fb88-4495-a0e6-820ff1dac591" />


# HTTP request latency (95th percentile)
##### histogram_quantile(0.95, rate(http_server_requests_seconds_bucket{namespace="bankapp"}[5m]))

- `95th percentile latency` could not be computed because histogram metrics (http_server_requests_seconds_bucket) were not enabled; average latency was used instead. 
`Solution:` enable histogram via `management.metrics.distribution.percentiles-histogram.http.server.requests=true` in `application.properties` and redeploy the application.

```bash
rate(http_server_requests_seconds_sum[5m]) 
/
rate(http_server_requests_seconds_count[5m])
```

<img width="2560" height="2158" alt="image" src="https://github.com/user-attachments/assets/59d5e16e-644e-43b1-bbb9-79c56443e31b" />



Explore the pre-built Grafana dashboards:
- **Kubernetes / Compute Resources / Namespace (Pods)** -- select the `bankapp` namespace
- **Kubernetes / Compute Resources / Pod** -- drill into individual pods
- **Node Exporter / Nodes** -- EKS worker node health

---

# Dashboard 1: Kubernetes / Compute Resources / Namespace (Pods)

1. Click **Dashboards** (left sidebar).
2. Click **Browse**.
3. Open the folder **Kubernetes / Compute Resources**.
4. Select **Namespace (Pods)**.

If prompted, select:

* **Datasource:** Prometheus
* **Namespace:** `bankapp`

You should see:

* CPU Usage
* Memory Usage
* Running Pods
* Network Traffic
* Filesystem Usage

<img width="1920" height="3612" alt="image" src="https://github.com/user-attachments/assets/0090ac68-f392-49e5-b442-59ac8f567658" />

---

# Dashboard 2: Kubernetes / Compute Resources / Pod

Go back to **Dashboards → Browse**.

Open:

```
Kubernetes / Compute Resources / Pod
```

Select:

* **Namespace:** `bankapp`
* **Pod:** one of the BankApp pods (for example, `bankapp-xxxxx`)

You should see:

* CPU Usage
* Memory Usage
* Network I/O
* Restarts
* Container status

<img width="1920" height="3852" alt="image" src="https://github.com/user-attachments/assets/adcc2523-7e5c-40cb-8e71-ac2c561f9123" />

---

# Dashboard 3: Node Exporter / Nodes

Go to:

```
Dashboards
↓
Browse
↓
Node Exporter
↓
Nodes
```

Select one of your EKS worker nodes.

You should see:

* CPU Utilization
* Memory Utilization
* Disk Usage
* Network Traffic
* Load Average

<img width="1920" height="1668" alt="image" src="https://github.com/user-attachments/assets/29845315-8c5c-459f-a4fc-58c1fda028c1" />

---

# If these dashboards are empty

If the dashboards show **"No data"**, first verify that Prometheus is scraping metrics.

Port-forward Prometheus:

```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
```

Open:

```
http://localhost:9090/targets
```

All targets should be **UP**.

For your BankApp, check whether the `bankapp-monitor` target is **UP**. If it's missing or down, we'll need to adjust the `ServiceMonitor` (most likely by naming the service port and matching it in the `ServiceMonitor`).


---

### Task 4: End-to-End Validation Checklist
Run through the complete validation:

**Application layer:**
```bash
# All pods running and ready
kubectl get pods -n bankapp
echo "---"

# App responds on health endpoint
curl -s http://$APP_URL/actuator/health
echo "---"

# HPA is active and monitoring CPU
kubectl get hpa -n bankapp
echo "---"

# Prometheus metrics endpoint works
curl -s http://$APP_URL/actuator/prometheus | head -10
```

<img width="1332" height="617" alt="image" src="https://github.com/user-attachments/assets/756587ae-aa0d-4489-bf58-36f15b5a0ae3" />



**Data layer:**
```bash
# MySQL is healthy with persistent storage
kubectl exec -n bankapp deploy/mysql -- mysqladmin ping -h localhost -uroot -pTest@123
echo "---"

# PVCs are bound to EBS volumes
kubectl get pvc -n bankapp
echo "---"

# Ollama has the model loaded
kubectl exec -n bankapp deploy/ollama -- ollama list
```

<img width="1622" height="317" alt="image" src="https://github.com/user-attachments/assets/4ccf131d-1fa4-44fc-855f-2f269ad8f327" />


**Infrastructure layer:**
```bash
# Nodes are healthy
kubectl get nodes
kubectl top nodes
echo "---"

# Gateway is serving traffic
kubectl get gateway -n bankapp
echo "---"

# Monitoring is running
kubectl get pods -n monitoring | head -5
```

<img width="1207" height="552" alt="image" src="https://github.com/user-attachments/assets/683c8619-3357-4f2c-a442-5f58a98e080f" />


**Security layer:**
```bash
# BankApp runs as non-root (devsecops user)
kubectl exec -n bankapp deploy/bankapp -- whoami

# Secrets are not exposed in environment
kubectl get secret bankapp-secret -n bankapp -o yaml | grep -c "MYSQL_ROOT_PASSWORD"
```

<img width="1615" height="117" alt="image" src="https://github.com/user-attachments/assets/600f10f9-354b-45fb-91b9-5c2ea0341750" />


---

### Task 5: Reflect on the Full EKS Journey
Map each concept to the day you learned it:

| Day | What You Built | AI-BankApp Connection |
|-----|---------------|----------------------|
| 81 | EKS cluster via Terraform, kubectl connection, manual deploy | Used the project's `terraform/` configs to provision infra |
| 82 | Gateway API, Envoy, TLS, EBS storage, session persistence | Used `k8s/gateway.yml`, `k8s/cert-manager.yml`, `k8s/pv.yml` |
| 83 | Full production deployment, monitoring, validation | Complete stack: app + DB + AI + networking + observability |

**What the AI-BankApp's EKS setup includes that you have now seen:**
- Terraform-provisioned VPC with 3-AZ networking
- Managed node group with auto-scaling
- 6 EKS add-ons (CoreDNS, VPC CNI, kube-proxy, Pod Identity, EBS CSI, Metrics Server)
- ArgoCD pre-installed (used on Days 84-86)
- Gateway API with Envoy for traffic management
- cert-manager for automated HTTPS
- Cookie-based session persistence for stateful app
- EBS persistent storage for MySQL and Ollama
- HPA with scale-up/down policies
- Spring Boot Actuator metrics for Prometheus
- Init containers for dependency ordering
- PostStart lifecycle hooks for Ollama model pull

**What you would add for a real production deployment:**
- DNS with Route 53 and ExternalDNS
- Network Policies for pod-to-pod isolation
- Pod Disruption Budgets for safe node draining
- External Secrets Operator for AWS Secrets Manager integration
- Database backups (automated MySQL dumps to S3)
- Log aggregation with Loki (you built this on Day 75)
- Multi-environment clusters (dev + prod)

---

## Learning Progress Across the Three-Day EKS Block

| Day        | What I Built                                                                                                               | AI-BankApp Connection                                                                                                                                    |
| ---------- | -------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Day 81** | Provisioned an Amazon EKS cluster using Terraform, configured kubectl, and manually deployed workloads                     | Used the project's `terraform/` configuration to provision the VPC, EKS cluster, managed node group, IAM roles, and AWS infrastructure                   |
| **Day 82** | Configured Gateway API with Envoy Gateway, TLS using cert-manager, persistent EBS storage, and session persistence         | Deployed `gateway.yml`, `cert-manager.yml`, `pv.yml`, `pvc.yml`, and verified external access through the AWS Network Load Balancer                      |
| **Day 83** | Deployed the complete production-grade AI-BankApp, configured autoscaling, monitoring, and performed end-to-end validation | Successfully deployed the full application stack including Spring Boot, MySQL, Redis, Ollama AI, Gateway API, HPA, Prometheus, and Grafana on Amazon EKS |

---

# Components Included in the AI-BankApp EKS Deployment

During this three-day project, I worked with the following production Kubernetes components:

* Terraform-provisioned AWS VPC spanning three Availability Zones
* Amazon EKS managed Kubernetes cluster
* Managed Node Group with Auto Scaling
* Core EKS add-ons:

  * CoreDNS
  * Amazon VPC CNI
  * kube-proxy
  * Pod Identity Agent
  * Amazon EBS CSI Driver
  * Metrics Server
* ArgoCD pre-installed for upcoming GitOps exercises
* Gateway API with Envoy Gateway for ingress traffic management
* cert-manager for automated TLS certificate management
* AWS Network Load Balancer (NLB)
* Cookie-based session persistence
* Amazon EBS Persistent Volumes for MySQL and Ollama
* Horizontal Pod Autoscaler (HPA)
* Spring Boot Actuator and Micrometer metrics
* Prometheus monitoring
* Grafana dashboards
* Init Containers to control startup dependencies
* PostStart lifecycle hook to automatically download the Ollama TinyLlama model

---

# End-to-End Production Architecture

The deployed solution consisted of:

* Internet users accessing the application through an AWS Network Load Balancer
* Envoy Gateway routing incoming HTTP/HTTPS traffic
* Spring Boot AI-BankApp running with multiple replicas
* Horizontal Pod Autoscaler automatically managing application replicas
* MySQL using persistent Amazon EBS storage
* Ollama serving the TinyLlama model with persistent storage
* Redis providing session management
* Prometheus scraping application and cluster metrics
* Grafana visualizing Kubernetes and application performance

---

# Production Enhancements for a Real Enterprise Deployment

Although the deployment is production-oriented, an enterprise environment would additionally include:

* Route 53 with ExternalDNS for automatic DNS management
* Kubernetes Network Policies to isolate workloads
* Pod Disruption Budgets for high availability during maintenance
* External Secrets Operator integrated with AWS Secrets Manager
* Automated MySQL backups stored in Amazon S3
* Centralized log aggregation using Loki and Grafana
* Multiple Kubernetes environments (Development, Staging, and Production)
* CI/CD GitOps deployment using ArgoCD
* Alerting with Alertmanager integrated with Slack or Microsoft Teams
* Security scanning for container images and Kubernetes manifests
* Resource quotas and limit ranges for namespaces

---

# Key Takeaways

This three-day EKS block provided hands-on experience with deploying a production-grade application on Kubernetes.

Major concepts learned include:

* Infrastructure provisioning with Terraform
* Kubernetes application deployment
* Persistent storage using Amazon EBS CSI
* Gateway API and Envoy Gateway
* HTTPS certificate management
* Load balancing with AWS Network Load Balancer
* Application autoscaling using HPA
* Observability with Prometheus and Grafana
* Stateful workloads on Kubernetes
* Kubernetes networking and service discovery
* Production validation and operational troubleshooting
* Safe cleanup of cloud infrastructure using Terraform Destroy

Overall, the AI-BankApp demonstrated how a real-world cloud-native application is deployed, monitored, scaled, and managed on Amazon EKS using modern DevOps practices.


---

### Task 6: Complete Teardown
**This is critical -- do not leave resources running.**

Delete workloads first:
```bash
# Delete monitoring
helm uninstall monitoring -n monitoring

# Delete Gateway resources (releases the NLB)
kubectl delete -f k8s/gateway.yml 2>/dev/null

# Delete the BankApp stack
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

# Delete Envoy Gateway
helm uninstall envoy-gateway -n envoy-gateway-system 2>/dev/null

# Delete cert-manager
helm uninstall cert-manager -n cert-manager 2>/dev/null

# Delete namespaces
kubectl delete namespace monitoring envoy-gateway-system cert-manager 2>/dev/null
```

Wait for all LoadBalancers and EBS volumes to be released:
```bash
# Check for lingering load balancers
kubectl get svc -A | grep LoadBalancer

# Check for lingering PVCs
kubectl get pvc -A
```
<img width="1796" height="1157" alt="image" src="https://github.com/user-attachments/assets/d3792883-c704-46d3-ba53-e48f3cf2233f" />



**Destroy the infrastructure with Terraform:**
```bash
cd terraform
terraform destroy
```

<img width="1215" height="671" alt="image" src="https://github.com/user-attachments/assets/a9229241-8a02-4f62-b9f0-99770922b2cd" />


This takes 10-15 minutes. It deletes:
- EKS cluster and control plane
- All node groups and EC2 instances
- ArgoCD Helm release
- VPC, subnets, NAT gateway, internet gateway
- IAM roles and policies

**Verify in the AWS Console:**
- EKS: no clusters
- EC2: no instances, no load balancers, no EBS volumes
- VPC: the `bankapp-eks` VPC is gone
- CloudFormation: no lingering stacks

<img width="2552" height="1347" alt="image" src="https://github.com/user-attachments/assets/3623b565-c23d-4ff9-8779-28586b67b60d" />


**Check your AWS bill** in the Billing Dashboard. All charges should stop within the hour.

**Cost for this 3-day lab (approximate):** $15-25 depending on how long you kept the cluster running.

---

# Documentation

## Objective

Deploy the complete AI-BankApp on Amazon EKS with production-ready Kubernetes components including:

- Spring Boot AI-BankApp
- MySQL Database
- Ollama AI (TinyLlama)
- Redis
- Gateway API (Envoy Gateway)
- Persistent EBS Storage
- Horizontal Pod Autoscaler
- Prometheus
- Grafana

Finally validate the deployment and safely destroy all AWS resources.

---

# Architecture

```
                          Internet
                              │
                              │
                     AWS Network Load Balancer
                              │
                              │
                      Envoy Gateway (Gateway API)
                              │
              ┌───────────────┴───────────────┐
              │                               │
      HTTPRoute                        HTTPS Listener
              │
        bankapp-service
              │
     Spring Boot AI-BankApp Pods
              │
    ┌─────────┴──────────┐
    │                    │
 MySQL Service      Ollama Service
    │                    │
 MySQL Pod          Ollama Pod
    │                    │
 5Gi EBS PVC        10Gi EBS PVC

──────────────────────────────────────────────

Amazon EKS Cluster
│
├── Managed Node Group
├── CoreDNS
├── kube-proxy
├── VPC CNI
├── Metrics Server
├── EBS CSI Driver
├── Pod Identity
└── ArgoCD

Monitoring

Prometheus
     │
ServiceMonitor
     │
Spring Boot Actuator (/actuator/prometheus)

Grafana
```

---

# Infrastructure

- Amazon EKS
- Terraform Provisioned VPC
- Multi-AZ Networking
- Managed Node Group
- Gateway API
- Envoy Gateway
- AWS Network Load Balancer
- Amazon EBS CSI Driver
- Prometheus Operator
- Grafana

---

# Application Stack

| Component | Status |
|-----------|--------|
| Spring Boot BankApp | Running |
| MySQL | Running |
| Redis | Running |
| Ollama TinyLlama | Running |
| Envoy Gateway | Running |
| HPA | Running |
| Prometheus | Running |
| Grafana | Running |

---

# Persistent Storage

| Workload | Storage |
|----------|---------|
| MySQL | 5Gi EBS PVC |
| Ollama | 10Gi EBS PVC |

PVCs successfully bound using AWS EBS CSI Driver.

---

# Gateway API

Gateway Controller:

- Envoy Gateway

Traffic Flow

Internet

↓

AWS NLB

↓

Gateway

↓

HTTPRoute

↓

bankapp-service

↓

Spring Boot Pods

---

# Horizontal Pod Autoscaler

Configured for:

- CPU-based scaling
- Automatic scale-up
- Automatic scale-down
- Multiple BankApp replicas

---

# Monitoring Stack

Installed

- kube-prometheus-stack
- Prometheus
- Grafana
- Node Exporter
- kube-state-metrics
- Alertmanager

BankApp metrics scraped using ServiceMonitor.

---

# PromQL Queries

## JVM Memory

```promql
jvm_memory_used_bytes{namespace="bankapp"}
```

---

## HTTP Request Rate

```promql
rate(http_server_requests_seconds_count{namespace="bankapp"}[5m])
```

---

## 95th Percentile Latency

```promql
histogram_quantile(
0.95,
rate(http_server_requests_seconds_bucket{namespace="bankapp"}[5m])
)
```

---

# Validation Checklist

## Application Layer

| Check | Result |
|--------|--------|
| All BankApp Pods Running | ✅ |
| Health Endpoint | ✅ |
| Gateway Reachable | ✅ |
| HTTP Redirect Working | ✅ (302 → Login) |
| Actuator Health | ✅ UP |
| Prometheus Endpoint | ✅ |
| HPA Active | ✅ |

---

## Data Layer

| Check | Result |
|--------|--------|
| MySQL Running | ✅ |
| Redis Running | ✅ |
| Ollama Running | ✅ |
| TinyLlama Loaded | ✅ |
| PVC Bound | ✅ |

---

## Infrastructure Layer

| Check | Result |
|--------|--------|
| Worker Nodes Healthy | ✅ |
| Gateway Programmed | ✅ |
| Envoy Running | ✅ |
| LoadBalancer Created | ✅ |
| Monitoring Pods Running | ✅ |

---

## Security Layer

| Check | Result |
|--------|--------|
| Non-root Application User | ✅ |
| Kubernetes Secrets Used | ✅ |
| TLS Listener Configured | ✅ |

---

# Teardown Procedure

## Remove Monitoring

```bash
helm uninstall monitoring -n monitoring
```

---

## Remove Gateway

```bash
kubectl delete -f k8s/gateway.yml
```

---

## Remove AI-BankApp

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

---

## Remove Envoy Gateway

```bash
helm uninstall envoy-gateway -n envoy-gateway-system
```

---

## Remove cert-manager

```bash
helm uninstall cert-manager -n cert-manager
```

---

## Delete Namespaces

```bash
kubectl delete namespace monitoring envoy-gateway-system cert-manager
```

---

## Verify Cleanup

```bash
kubectl get svc -A

kubectl get pvc -A
```

---

## Destroy Infrastructure

```bash
cd terraform

terraform destroy
```

Terraform removes:

- EKS Cluster
- Worker Nodes
- ArgoCD
- IAM Roles
- Security Groups
- VPC
- NAT Gateway
- Internet Gateway
- Subnets
- Route Tables

---

# Key Takeaways (Days 81–83)

## Day 81

- Provisioned Amazon EKS using Terraform
- Connected kubectl
- Deployed workloads manually

---

## Day 82

- Learned Gateway API
- Installed Envoy Gateway
- Configured TLS
- Used Amazon EBS Persistent Volumes
- Implemented session persistence

---

## Day 83

- Deployed complete production application
- Configured autoscaling
- Added Prometheus monitoring
- Added Grafana dashboards
- Validated complete stack
- Performed full infrastructure cleanup

---

# Production Features Implemented

- Terraform Infrastructure
- Amazon EKS
- Multi-AZ Deployment
- Managed Node Groups
- Gateway API
- Envoy Gateway
- AWS Network Load Balancer
- Horizontal Pod Autoscaler
- Persistent Storage
- Spring Boot Actuator
- Prometheus Monitoring
- Grafana Dashboards
- Kubernetes Secrets
- ConfigMaps
- ServiceMonitor
- Init Containers
- Lifecycle Hooks

---

# Production Improvements

Future enhancements include:

- Route53
- ExternalDNS
- AWS Secrets Manager
- External Secrets Operator
- Network Policies
- Pod Disruption Budgets
- Loki Log Aggregation
- Automated MySQL Backups to S3
- Multi-Environment (Dev/Staging/Prod)
- CI/CD with GitOps (ArgoCD)

---

# Cost Report

| Resource | Approximate Cost |
|-----------|------------------|
| EKS Control Plane | Included |
| 3 × t3.medium Worker Nodes | Majority of Cost |
| Network Load Balancer | Included |
| EBS Volumes | Included |
| NAT Gateway | Included |

Estimated Lab Cost:

**$15–25 USD**

All resources were destroyed using Terraform to prevent ongoing AWS charges.

---

# Outcome

Successfully deployed a production-grade AI-BankApp on Amazon EKS featuring:

- Spring Boot Banking Application
- MySQL
- Redis
- Ollama TinyLlama AI
- Gateway API
- Envoy Gateway
- AWS Network Load Balancer
- Amazon EBS Persistent Storage
- Horizontal Pod Autoscaler
- Prometheus Monitoring
- Grafana Dashboards
- Complete Validation
- Full Infrastructure Teardown






