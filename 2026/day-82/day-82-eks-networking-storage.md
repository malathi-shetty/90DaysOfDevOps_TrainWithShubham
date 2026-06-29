# Day 82 -- EKS Networking with Gateway API and Persistent Storage
---

## Challenge Tasks

### Task 1: Understand Gateway API vs Ingress
The AI-BankApp uses the Gateway API instead of the traditional Ingress resource. Research the differences:

| Feature | Ingress | Gateway API |
|---------|---------|-------------|
| API maturity | Stable but limited | GA since Kubernetes 1.26 |
| Traffic splitting | Not supported | Built-in (weighted backends) |
| Header matching | Annotation-dependent | Native HTTPRoute rules |
| Role separation | Single resource | GatewayClass (infra) -> Gateway (ops) -> HTTPRoute (dev) |
| TLS management | Annotation-based | Native TLS config in Gateway listeners |
| Session affinity | Not standardized | BackendTrafficPolicy (with Envoy) |

**The AI-BankApp's Gateway architecture:**
```
Internet
   ↓
AWS NLB
   ↓
Gateway (bankapp-gateway)
   ├── HTTP (80 → redirect to HTTPS)
   └── HTTPS (443, TLS terminated)
   ↓
HTTPRoute (bankapp-route)
   ↓
Service (bankapp-service:8080)
   ↓
Pods (2–4 replicas)
   ↓
(Session affinity handled by Gateway via cookie OR Service via ClientIP)
```

---

## Why Kubernetes introduced Gateway API

The traditional **Ingress** resource was designed to expose HTTP/HTTPS services from Kubernetes. It works well for simple routing, but as applications became more complex (microservices, canary deployments, traffic splitting, multiple teams managing networking), Ingress started showing limitations.

Examples of Ingress limitations:

* Heavy dependence on controller-specific annotations
* No standard way to split traffic
* Poor role separation
* Difficult TLS management
* No standardized session affinity

To solve these problems, Kubernetes introduced the **Gateway API**, which became **Generally Available (GA)** in Kubernetes **1.26**.

---

# Gateway API vs Ingress

| Feature           | Ingress                 | Gateway API                          |
| ----------------- | ----------------------- | ------------------------------------ |
| API maturity      | Stable but limited      | GA since Kubernetes 1.26             |
| Traffic splitting | Not supported natively  | Native weighted backend routing      |
| Header matching   | Mostly annotations      | Native HTTPRoute matching            |
| Role separation   | Single Ingress resource | GatewayClass → Gateway → HTTPRoute   |
| TLS management    | Mostly annotations      | Native listener TLS configuration    |
| Session affinity  | Controller-specific     | BackendTrafficPolicy (Envoy Gateway) |

Let's understand each feature.

---

# 1. API Maturity

### Ingress

Ingress has been around for many years and is stable.

However, its specification is intentionally minimal.

Most advanced features are implemented differently by different controllers.

Example:

NGINX uses annotations like

```yaml
nginx.ingress.kubernetes.io/rewrite-target: /
```

AWS Load Balancer Controller has different annotations.

Traefik has different annotations.

So manifests are **not portable**.

---

### Gateway API

Gateway API standardizes many networking features inside Kubernetes resources instead of annotations.

This makes manifests much more portable between Gateway implementations.

---

# 2. Traffic Splitting

Suppose your application has

```
Version 1
```

and

```
Version 2
```

You want

```
90% users → v1

10% users → v2
```

---

### Ingress

Not supported natively.

Usually requires

* NGINX annotations
* Istio
* Service Mesh
* Custom controller logic

---

### Gateway API

Native support.

Example

```
HTTPRoute

↓

Backend A
weight:90

Backend B
weight:10
```

Perfect for

* Canary deployments
* Blue/Green deployments
* A/B testing

---

# 3. Header Matching

Suppose requests contain

```
User-Agent

Authorization

X-Version

Cookie
```

---

### Ingress

Usually requires controller-specific annotations.

---

### Gateway API

HTTPRoute supports matching based on

* Path
* Hostname
* Headers
* Query Parameters
* HTTP Method

Example

```
If

Header

X-Version=beta

↓

Send to beta service
```

No annotations required.

---

# 4. Role Separation

This is one of the biggest improvements.

## Ingress

Everything is managed in one resource.

```
Developer

↓

Ingress

↓

Controller

↓

Load Balancer
```

Infrastructure and application teams often modify the same YAML.

---

## Gateway API

Responsibilities are divided.

### Infrastructure Team

Creates

```
GatewayClass
```

Defines

* Which Gateway controller
* Infrastructure policies

---

### Operations Team

Creates

```
Gateway
```

Defines

* Listeners
* Ports
* TLS
* External Load Balancer

---

### Developers

Create

```
HTTPRoute
```

Defines

* URL paths
* Backend services
* Routing rules

Diagram

```
Infrastructure

↓

GatewayClass

↓

Operations

↓

Gateway

↓

Developers

↓

HTTPRoute
```

This separation is much cleaner in large organizations.

---

# 5. TLS Management

### Ingress

TLS is configured through the Ingress resource and often depends on annotations.

Example

```yaml
annotations:
  cert-manager.io/cluster-issuer: letsencrypt
```

Different controllers use different annotations.

---

### Gateway API

TLS is part of the Gateway Listener.

Example

```yaml
listeners:
- name: https
  protocol: HTTPS
  port: 443
  tls:
    mode: Terminate
    certificateRefs:
      - name: bankapp-tls
```

This is cleaner and standardized.

---

# 6. Session Affinity

The AI-BankApp uses **Spring Security** with session-based authentication.

Imagine there are two BankApp Pods.

```
Pod A

Pod B
```

A user logs in.

The session is stored in Pod A.

If the next request goes to Pod B,

```
Session not found

↓

User logged out
```

---

### Solution

Gateway API with **Envoy Gateway** supports **BackendTrafficPolicy**.

It creates a cookie

```
BANKAPP_AFFINITY
```

Example

```
Login

↓

Pod A

↓

Cookie created

↓

Future requests

↓

Pod A
```

This is called **cookie-based session persistence**.

Without it,

Users may experience random logouts.

---

# AI-BankApp Gateway Architecture

```
                    Internet
                        │
                        ▼
               AWS Network Load Balancer
                (created automatically
                 by Envoy Gateway)
                        │
                        ▼
            Gateway (bankapp-gateway)
        ┌─────────────────────────────┐
        │ Listener : HTTP  (80)       │
        │ Listener : HTTPS (443)      │
        │ TLS terminated here         │
        └─────────────────────────────┘
                        │
                        ▼
             HTTPRoute (bankapp-route)
                        │
                        ▼
         Service (bankapp-service:8080)
                        │
          ┌─────────────┴─────────────┐
          ▼                           ▼
     BankApp Pod 1               BankApp Pod 2
        ▲                              ▲
        └────────── Cookie ────────────┘
          BANKAPP_AFFINITY
```

---

# Why the AI-BankApp Uses Gateway API

The project uses Gateway API because it provides:

* Standardized Kubernetes networking
* Native HTTP routing
* Built-in traffic splitting
* Cleaner TLS configuration
* Better separation between infrastructure and application teams
* Cookie-based session persistence using `BackendTrafficPolicy`, which is essential for Spring Security's session-based authentication in a multi-pod deployment.

---

### Task 2: Install Envoy Gateway
Envoy Gateway is the Gateway API implementation the AI-BankApp uses.

Install via Helm:
```bash
helm install envoy-gateway oci://docker.io/envoyproxy/gateway-helm \
  --version v1.4.0 \
  -n envoy-gateway-system --create-namespace \
  --wait
```

<img width="1472" height="732" alt="image" src="https://github.com/user-attachments/assets/145e2195-f2bf-404b-8e90-ba88b5fe55e3" />


Verify:
```bash
kubectl get pods -n envoy-gateway-system
kubectl get gatewayclass
```

<img width="1192" height="115" alt="image" src="https://github.com/user-attachments/assets/b8a27e53-1191-4d02-b476-8789664542fc" />


- `kubectl get gatewayclass` shows no resources because Envoy Gateway does not automatically create a `GatewayClass` during installation. A `GatewayClass` must either be enabled via Helm configuration or created manually


You should see the `envoy-gateway` GatewayClass registered.

Now install the Gateway API CRDs if not already present:
```bash
kubectl get crd gateways.gateway.networking.k8s.io 2>/dev/null || \
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml
```

<img width="1437" height="90" alt="image" src="https://github.com/user-attachments/assets/659205fb-88bd-43c7-884b-86878474c7db" />


---

### Task 3: Deploy the AI-BankApp with Gateway API
Make sure the app is deployed (from Day 81):
```bash
kubectl get pods -n bankapp
```
<img width="1077" height="182" alt="image" src="https://github.com/user-attachments/assets/903bc3d5-64fd-4b76-8994-dc2b52260ac1" />


If not running, redeploy the core manifests:
```bash
cd AI-BankApp-DevOps
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

**Now study and apply the Gateway configuration.**

Open `k8s/gateway.yml` and understand each resource:

**1. GatewayClass** -- defines which controller handles Gateways:
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy-gateway
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

**2. Gateway** -- creates the actual load balancer with listeners:
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: bankapp-gateway
  namespace: bankapp
spec:
  gatewayClassName: envoy-gateway
  listeners:
    - name: http
      protocol: HTTP
      port: 80
    - name: https
      protocol: HTTPS
      port: 443
      hostname: <your-ip>.nip.io
      tls:
        mode: Terminate
        certificateRefs:
          - name: bankapp-tls
```

When this is applied, Envoy Gateway creates an AWS NLB (Network Load Balancer) automatically.

**3. HTTPRoute** -- routes traffic to the BankApp service:
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bankapp-route
  namespace: bankapp
spec:
  parentRefs:
    - name: bankapp-gateway
      sectionName: https
    - name: bankapp-gateway
      sectionName: http
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /
      backendRefs:
        - name: bankapp-service
          port: 8080
```

**4. BackendTrafficPolicy** -- session persistence via cookies:
```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: BackendTrafficPolicy
metadata:
  name: bankapp-session
  namespace: bankapp
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: bankapp-route
  loadBalancer:
    type: ConsistentHash
    consistentHash:
      type: Cookie
      cookie:
        name: BANKAPP_AFFINITY
        ttl: 3600s
```

Apply the Gateway configuration:
```bash
kubectl apply -f k8s/gateway.yml
```

<img width="1157" height="116" alt="image" src="https://github.com/user-attachments/assets/2c623b37-0aca-4228-b92a-655906745f43" />


Wait for the NLB to be provisioned:
```bash
kubectl get gateway -n bankapp -w
```

<img width="1162" height="71" alt="image" src="https://github.com/user-attachments/assets/69f78657-4d94-4d12-8c81-2c0ba11d9f14" />
<img width="1212" height="886" alt="image" src="https://github.com/user-attachments/assets/9dc4b42a-774a-455f-91ec-64a37551df52" />


Get the external IP:
```bash
export GATEWAY_IP=$(kubectl get gateway bankapp-gateway -n bankapp -o jsonpath='{.status.addresses[0].value}')
echo "App URL: http://$GATEWAY_IP"
```
App URL: http://a8ffaec28029743cea7c62581ba7df12-1681271526.us-west-2.elb.amazonaws.com 
<img width="1835" height="71" alt="image" src="https://github.com/user-attachments/assets/6b197249-6ef0-4e60-a666-7e97313dfcf6" />


<img width="2535" height="1372" alt="image" src="https://github.com/user-attachments/assets/cea6f49b-01ef-400d-bd39-0067a26f5741" />


Test access:
```bash
curl -v http://$GATEWAY_IP
```

<img width="1091" height="552" alt="image" src="https://github.com/user-attachments/assets/2272b2cf-5edd-49ff-8303-47b52f45c341" />


---

### Task 4: Set Up TLS with cert-manager
The AI-BankApp uses cert-manager with Let's Encrypt for automatic HTTPS certificates.

Install cert-manager:
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace \
  --set crds.enabled=true \
  --wait
```

<img width="1281" height="887" alt="image" src="https://github.com/user-attachments/assets/8b0a3238-0f69-4cf6-8b12-07104a6c0895" />


Verify:
```bash
kubectl get pods -n cert-manager
```

<img width="1131" height="117" alt="image" src="https://github.com/user-attachments/assets/e500f8eb-cab9-48c6-99f5-bb1e9a987a0d" />


Study and apply the ClusterIssuer from `k8s/cert-manager.yml`:
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-account-key
    solvers:
      - http01:
          gatewayHTTPRoute:
            parentRefs:
              - group: gateway.networking.k8s.io
                kind: Gateway
                name: bankapp-gateway
                namespace: bankapp
```

<img width="786" height="597" alt="image" src="https://github.com/user-attachments/assets/acca40ca-4b7d-4021-bbde-1def6273be49" />
<img width="1295" height="1022" alt="image" src="https://github.com/user-attachments/assets/95d11030-cd23-4c0f-95b2-cac29502178f" />


To use this, you need a hostname that points to your NLB IP. The AI-BankApp uses `nip.io` for quick DNS:
```bash
export HOSTNAME="${GATEWAY_IP}.nip.io"
echo "HTTPS URL: https://$HOSTNAME"
```

<img width="1207" height="72" alt="image" src="https://github.com/user-attachments/assets/d758f0b0-8af5-4849-8caa-fbc56a1c5ff9" />



Update the Gateway hostname and apply:
```bash
# For learning: you can skip TLS and just use HTTP
# For production: update gateway.yml with your hostname and apply cert-manager.yml
```

```bash
kubectl logs -n cert-manager deploy/cert-manager | grep Gateway


helm upgrade cert-manager jetstack/cert-manager \
  -n cert-manager \
  --set crds.enabled=true \
  --set config.enableGatewayAPI=true

```


```bash
# cert-manager ClusterIssuer for Let's Encrypt TLS certificates.
# Uses HTTP-01 validation via Gateway API — cert-manager creates a temporary
# HTTPRoute to serve the ACME challenge on port 80.
# Prerequisites: cert-manager installed with --set config.enableGatewayAPI=true
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: shettymalathi113@gmail.com
    privateKeySecretRef:
      name: letsencrypt-account-key
    solvers:
      - http01:
          gatewayHTTPRoute:
            parentRefs:
              - group: gateway.networking.k8s.io
                kind: Gateway
                name: bankapp-gateway
                namespace: bankapp
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: bankapp-tls
  namespace: bankapp
spec:
  secretName: bankapp-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
    - bankapp.52.39.28.122.nip.io
```

```bash
# Requires: Gateway API CRDs + Envoy Gateway installed on the cluster
# On EKS, Envoy Gateway creates an AWS NLB for external access automatically.
# Install steps documented in terraform/README.md
# GatewayClass: defines which controller manages Gateway resources
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy-gateway
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
---
# Gateway: entry point (creates load balancer + listeners)
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: bankapp-gateway
  namespace: bankapp
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  gatewayClassName: envoy-gateway # Uses Envoy Gateway controller
  listeners:
    # HTTP — needed for cert-manager ACME HTTP-01 challenge validation.
    # cert-manager creates a temporary HTTPRoute in its own namespace to serve
    # the challenge, so allowedRoutes must permit all namespaces.
    - name: http
      protocol: HTTP
      port: 80  # HTTP traffic entry
      allowedRoutes:
        namespaces:
          from: All
    # HTTPS — TLS terminated at Envoy Gateway using cert-manager certificate
    - name: https
      protocol: HTTPS
      port: 443 # HTTPS traffic entry
      hostname: 52.39.28.122.nip.io # Use your public IP or DNS name here <your-ip>.nip.io
      tls:
        mode: Terminate # TLS handled at gateway
        certificateRefs:
          - group: ""
            kind: Secret
            name: bankapp-tls
      allowedRoutes:
        namespaces:
          from: Same
---
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: bankapp-route
  namespace: bankapp
spec:
  hostnames:
    - 52.39.28.122.nip.io
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: bankapp-gateway
      sectionName: https
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: bankapp-gateway
      sectionName: http
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /    # match all paths
      backendRefs:
        - group: ""
          kind: Service
          name: bankapp-service
          port: 8080
          weight: 1
---
# Session persistence: Envoy Gateway bypasses K8s Service sessionAffinity and
# load-balances directly to pod endpoints. Without this policy, requests from
# the same browser can hit different pods, breaking in-memory sessions (CSRF
# tokens, login state). Cookie-based consistent hashing pins a browser to one pod.
# BackendTrafficPolicy: enables sticky sessions using cookies
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: BackendTrafficPolicy
metadata:
  name: bankapp-session
  namespace: bankapp
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: bankapp-route
  loadBalancer:
    type: ConsistentHash  # ensures same user hits same backend
    consistentHash:
      type: Cookie
      cookie:
        name: BANKAPP_AFFINITY  # session cookie
        ttl: 3600s # 1 hour stickiness

```

```bash
kubectl apply -f k8s/cert-manager.yml
kubectl apply -f k8s/gateway.yml


kubectl get certificate -n bankapp
kubectl describe certificate bankapp-tls -n bankapp
kubectl get secret bankapp-tls -n bankapp
kubectl describe gateway bankapp-gateway -n bankapp

```

login with `https://52.39.28.122.nip.io/login`

<img width="1187" height="222" alt="image" src="https://github.com/user-attachments/assets/c3605f8d-a293-40e2-80fb-d25e6991c7b3" />
<img width="1430" height="755" alt="image" src="https://github.com/user-attachments/assets/c16e73fb-b737-42d7-9600-584dfdf2aaf3" />

<img width="1557" height="157" alt="image" src="https://github.com/user-attachments/assets/e570327a-ca55-459e-a5c9-7960aba94380" />

<img width="1410" height="1177" alt="image" src="https://github.com/user-attachments/assets/782073fd-d0b2-4f8a-a0f9-72898a892217" />
<img width="1367" height="1267" alt="image" src="https://github.com/user-attachments/assets/a37b15f1-3c74-4994-9879-a271a9807d60" />
<img width="1326" height="1247" alt="image" src="https://github.com/user-attachments/assets/a5c26e80-3938-446c-86b2-4731124d61a1" />

<img width="1917" height="1017" alt="image" src="https://github.com/user-attachments/assets/10dba860-c0f4-4c60-811f-7713a67e62ba" />


---

### Task 5: Understand EBS Persistent Storage in Action
The AI-BankApp uses EBS volumes for MySQL (5Gi) and Ollama (10Gi). Study how they work on EKS.

Check the storage setup:
```bash
# StorageClass
kubectl get storageclass gp3

# PVCs
kubectl get pvc -n bankapp

# PVs (dynamically provisioned)
kubectl get pv
```

Output should look like:
```
NAME                      STATUS   VOLUME         CAPACITY   STORAGECLASS
mysql-pvc                 Bound    pvc-abc123...  5Gi        gp3
ollama-pvc                Bound    pvc-def456...  10Gi       gp3
```

<img width="1107" height="72" alt="Verify the StorageClass" src="https://github.com/user-attachments/assets/8ece1e09-5df9-496b-b887-60370b707bf2" />

<img width="1570" height="181" alt="image" src="https://github.com/user-attachments/assets/1f3f3dea-5e46-4143-b1cf-cf57ed4cb7b2" />


**Find the actual EBS volumes in AWS:**
```bash
aws ec2 describe-volumes \
  --region us-west-2 \
  --filters "Name=tag:kubernetes.io/cluster/bankapp-eks,Values=owned" \
  --query "Volumes[*].{ID:VolumeId,Size:Size,AZ:AvailabilityZone,State:State,Tags:Tags}" \
  --output table
```

<img width="1035" height="912" alt="image" src="https://github.com/user-attachments/assets/ce266142-2bef-4de9-b8a1-487a7aff23be" />


**Key EBS concepts on EKS:**
- `WaitForFirstConsumer` -- the volume is created in the same AZ as the pod that claims it
- `ReadWriteOnce` -- EBS can only attach to one node at a time (MySQL and Ollama use Recreate strategy because of this)
- `gp3` -- latest generation SSD, 3000 IOPS baseline, cheaper than gp2
- `allowVolumeExpansion: true` -- you can grow volumes without recreating them

**Test persistence** -- delete the MySQL pod and watch it come back with data intact:
```bash
# Check current MySQL data
kubectl exec -n bankapp deploy/mysql -- mysql -uroot -pTest@123 -e "SHOW DATABASES;"

# Delete the pod
kubectl delete pod -n bankapp -l app=mysql

# Watch it recreate
kubectl get pods -n bankapp -l app=mysql -w

# Verify data survived
kubectl exec -n bankapp deploy/mysql -- mysql -uroot -pTest@123 -e "SHOW DATABASES;"
```

The database is intact because the EBS volume persists independently of the pod.

<img width="1276" height="602" alt="image" src="https://github.com/user-attachments/assets/6744f69c-91d2-4642-81f4-417505c2d724" />


---

### Task 6: Explore HPA and Node Capacity
The AI-BankApp's HPA scales pods between 2 and 4 based on CPU.

```bash
kubectl get hpa -n bankapp
```

Check resource usage across nodes:
```bash
kubectl top nodes
kubectl top pods -n bankapp
```
<img width="1082" height="317" alt="image" src="https://github.com/user-attachments/assets/1aab5bb3-eacc-4ccf-99ea-d2274b273ed1" />



Ollama is the heaviest consumer. If you scale BankApp to 4 pods, total CPU requests reach ~2.9 cores + system overhead.

**Clean up the workload (keep the cluster for Day 83):**
```bash
kubectl delete -f k8s/gateway.yml 2>/dev/null
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

<img width="1167" height="752" alt="image" src="https://github.com/user-attachments/assets/fc6af651-7d0d-4209-90b5-52978540263f" />

<img width="1276" height="927" alt="image" src="https://github.com/user-attachments/assets/c9ca5c4a-410e-4ced-a30f-c034883013d5" />


---

# Documentation

# Gateway API Architecture

```
                    Internet
                        │
                        ▼
              AWS Network Load Balancer
            (Created by Envoy Gateway)
                        │
                        ▼
            Gateway: bankapp-gateway
        ┌───────────────┴───────────────┐
        │                               │
 HTTP Listener (80)             HTTPS Listener (443)
                               TLS Termination
                        │
                        ▼
             HTTPRoute: bankapp-route
                        │
                        ▼
            Service: bankapp-service
                        │
                        ▼
          BankApp Pods (2–4 replicas)
        Cookie-based Session Affinity
```

---

# Gateway API vs Ingress

| Feature           | Ingress                | Gateway API                                 |
| ----------------- | ---------------------- | ------------------------------------------- |
| API Maturity      | Stable but limited     | GA since Kubernetes 1.26                    |
| Traffic Splitting | Not supported natively | Built-in weighted backends                  |
| Header Matching   | Controller annotations | Native HTTPRoute rules                      |
| Role Separation   | Single resource        | GatewayClass → Gateway → HTTPRoute          |
| TLS Management    | Annotation-based       | Native listener configuration               |
| Session Affinity  | Controller-specific    | BackendTrafficPolicy (Envoy Gateway)        |
| Extensibility     | Limited                | Highly extensible                           |
| Multi-tenancy     | Limited                | Designed for platform and application teams |

---

# Gateway API Resources

## 1. GatewayClass

Defines which Gateway controller manages Gateway resources.

```yaml
kind: GatewayClass
```

Purpose

* Infrastructure-level resource
* Managed by cluster administrators
* Points to the Envoy Gateway controller

Example

```
controllerName: gateway.envoyproxy.io/gatewayclass-controller
```

---

## 2. Gateway

Creates the application's external entry point.

Responsibilities

* Creates the AWS Network Load Balancer
* Defines HTTP and HTTPS listeners
* Terminates TLS
* Accepts incoming client traffic

Example

```
Gateway
 ├── HTTP :80
 └── HTTPS :443
```

---

## 3. HTTPRoute

Defines how requests are routed to backend services.

Responsibilities

* Matches URL paths
* Matches hostnames
* Sends traffic to Kubernetes Services

Example

```
/
   ↓
bankapp-service:8080
```

---

## 4. BackendTrafficPolicy

Provides session persistence using Envoy Gateway.

Configuration used

* Consistent Hashing
* Cookie-based stickiness
* Cookie name:

```
BANKAPP_AFFINITY
```

TTL

```
3600 seconds
```

This ensures a browser consistently reaches the same backend pod.

---

# Why Cookie-Based Session Affinity?

The AI-BankApp uses Spring Security with form-based authentication.

Without sticky sessions:

```
Login
   │
Request 1 → Pod A

Next Request
   │
Request 2 → Pod B
```

Pod B does not contain the user's in-memory session, causing authentication failures or unexpected logouts.

With BackendTrafficPolicy:

```
Login
   │
BANKAPP_AFFINITY Cookie
   │
Every request
        │
        ▼
      Pod A
```

Benefits

* Stable login sessions
* Consistent CSRF token validation
* Improved user experience
* Predictable request routing

---

# TLS Automation using cert-manager

cert-manager automates HTTPS certificate management using Let's Encrypt.

Workflow

```
Certificate Resource
        │
        ▼
ClusterIssuer
        │
        ▼
Let's Encrypt
        │
HTTP-01 Challenge
        │
Temporary HTTPRoute
        │
Validation Successful
        │
Certificate Issued
        │
Stored as Secret
(bankapp-tls)
        │
Gateway Listener
        │
HTTPS Enabled
```

Advantages

* Automatic certificate provisioning
* Automatic renewal before expiration
* No manual certificate management
* Secure HTTPS communication

---

# Amazon EBS Persistent Storage Flow

```
StorageClass (gp3)
          │
          ▼
PersistentVolumeClaim
          │
          ▼
PersistentVolume
          │
          ▼
AWS EBS Volume
          │
          ▼
Mounted into Pod
(MySQL / Ollama)
```

The application uses:

| Component | Storage        |
| --------- | -------------- |
| MySQL     | 5 GiB gp3 EBS  |
| Ollama    | 10 GiB gp3 EBS |

Key concepts

* WaitForFirstConsumer ensures the EBS volume is created in the same Availability Zone as the scheduled pod.
* ReadWriteOnce allows a volume to be attached to only one node at a time.
* gp3 provides better performance and lower cost than gp2.
* allowVolumeExpansion enables online storage expansion without recreating volumes.

Persistence was verified by deleting the MySQL pod. Kubernetes recreated the pod while the database remained intact because the EBS volume persisted independently of the pod lifecycle.

---

# AI-BankApp Resource Budget on EKS

Cluster

* 3 × t3.medium Worker Nodes

Total Capacity

| Resource | Total          |
| -------- | -------------- |
| CPU      | 6000m (6 vCPU) |
| Memory   | 12 GiB         |

Application Resource Requests

| Component              | CPU Request | Memory Request | Instances |
| ---------------------- | ----------- | -------------- | --------- |
| BankApp                | 250m        | 256Mi          | 2–4 Pods  |
| MySQL                  | 250m        | 256Mi          | 1 Pod     |
| Ollama                 | 900m        | 2Gi            | 1 Pod     |
| Init Containers        | 50m         | 32Mi           | Temporary |
| Kubernetes System Pods | ~500m       | ~500Mi         | Per Node  |

Observations

* Ollama is the largest consumer of CPU and memory.
* BankApp is horizontally scalable using the Horizontal Pod Autoscaler.
* HPA scales BankApp between 2 and 4 replicas based on 70% CPU utilization.
* The workload comfortably fits within the available resources of the three-node EKS cluster.

---

# Screenshots

Add the following screenshots:

* `kubectl get gateway -n bankapp`
* `kubectl get pvc -n bankapp`
* `kubectl get hpa -n bankapp`
* `kubectl top nodes`
* `kubectl top pods -n bankapp`

---

# Conclusion

In this exercise, I learned how modern Kubernetes networking is implemented using the Gateway API and Envoy Gateway. 
I configured GatewayClass, Gateway, HTTPRoute, and BackendTrafficPolicy to expose the AI-BankApp with cookie-based session persistence. 
I also explored automated TLS management with cert-manager and Let's Encrypt, and verified persistent storage using Amazon EBS volumes. 
Finally, I examined resource utilization and Horizontal Pod Autoscaling to understand production-ready deployment practices on Amazon EKS.







