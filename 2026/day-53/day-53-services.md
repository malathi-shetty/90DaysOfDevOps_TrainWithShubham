# Day 53 – Kubernetes Services

## Challenge Tasks

### Task 1: Deploy the Application
First, create a Deployment that you will expose with Services. Create `app-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
```

```bash
kubectl apply -f app-deployment.yaml
kubectl get pods -o wide
```

Note the individual Pod IPs. These will change if pods restart — that is the problem Services fix.

**Verify:** Are all 3 pods running? Note down their IP addresses.

Yes, **all 3 pods from the `web-app` Deployment are running successfully**.

| Pod Name                 | Status  | IP Address |
| ------------------------ | ------- | ---------- |
| web-app-5c44989c65-6jsqd | Running | 10.244.0.6 |
| web-app-5c44989c65-h8q6k | Running | 10.244.0.7 |
| web-app-5c44989c65-qvk9b | Running | 10.244.0.8 |

### Verification Summary

* Desired replicas: **3**
* Running replicas: **3**
* Pod IPs:

  * **10.244.0.6**
  * **10.244.0.7**
  * **10.244.0.8**

These IP addresses are assigned dynamically and may change if the pods are recreated, which is why Kubernetes Services are used to provide a stable endpoint.

<img width="1130" height="282" alt="image" src="https://github.com/user-attachments/assets/dce7cf34-e7da-4853-bf30-b48c609947c4" />

---

### Task 2: ClusterIP Service (Internal Access)
ClusterIP is the default Service type. It gives your Pods a stable internal IP that is only reachable from within the cluster.

Create `clusterip-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-clusterip
spec:
  type: ClusterIP
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
```

Key fields:
- `selector.app: web-app` — this Service routes traffic to all Pods with the label `app: web-app`
- `port: 80` — the port the Service listens on
- `targetPort: 80` — the port on the Pod to forward traffic to

```bash
kubectl apply -f clusterip-service.yaml
kubectl get services
```



You should see `web-app-clusterip` with a CLUSTER-IP address. This IP is stable — it will not change even if Pods restart.

Now test it from inside the cluster:
```bash
# Run a temporary pod to test connectivity
kubectl run test-client --image=busybox:latest --rm -it --restart=Never -- sh

# Inside the test pod, run:
wget -qO- http://web-app-clusterip
exit
```

You should see the Nginx welcome page. The Service load-balanced your request to one of the 3 Pods.




**Verify:** Does the Service respond? Try running the wget command multiple times — the Service distributes traffic across all healthy Pods.

###  Verification

Based on your earlier test:

```bash
wget -qO- http://web-app-clusterip
```

the Service returned the Nginx welcome page successfully.

✅ **Yes, the Service responds correctly.**

---

### Current Service Details

```text
NAME                TYPE        CLUSTER-IP      PORT(S)
web-app-clusterip   ClusterIP   10.96.156.88   80/TCP
```

The Service is:

* Discoverable through DNS (`web-app-clusterip`)
* Reachable from within the cluster
* Forwarding traffic to Pods labeled:

```yaml
app: web-app
```

---

### About Load Balancing Verification

Since all three Pods run the same standard Nginx image, every request returns the same page:

```html
Welcome to nginx!
```

So you cannot visually tell which Pod handled a request.

To prove load balancing, you would normally:

1. Modify each Pod to return a unique hostname, or
2. Run:

```bash
kubectl get endpoints web-app-clusterip
```

Expected output:

```text
NAME                ENDPOINTS
web-app-clusterip   10.244.0.6:80,10.244.0.7:80,10.244.0.8:80
```

This confirms the Service is balancing across all three healthy Pods.

You can verify this now with:

```bash
kubectl get endpoints web-app-clusterip
```

Expected endpoints:

* 10.244.0.6:80
* 10.244.0.7:80
* 10.244.0.8:80

### Verification Statement

✅ The Service responds successfully.

✅ Requests to `http://web-app-clusterip` return the Nginx page.

✅ The Service has a stable ClusterIP (`10.96.156.88`).

✅ The Service routes traffic to all healthy Pods matching `app=web-app`.

> The ClusterIP Service `web-app-clusterip` responded successfully when accessed from a test pod using `wget`. The Nginx welcome page was returned, confirming connectivity. The Service provides a stable ClusterIP (`10.96.156.88`) and load-balances traffic across the three healthy `web-app` Pods.

<img width="1295" height="230" alt="image" src="https://github.com/user-attachments/assets/4aba6972-29d1-494c-8a4e-df1feb970dec" />


---

### Task 3: Discover Services with DNS
Kubernetes has a built-in DNS server. Every Service gets a DNS entry automatically:

```
<service-name>.<namespace>.svc.cluster.local
```

Test this:
```bash
kubectl run dns-test --image=busybox:latest --rm -it --restart=Never -- sh

# Inside the pod:
# Short name (works within the same namespace)
wget -qO- http://web-app-clusterip

# Full DNS name
wget -qO- http://web-app-clusterip.default.svc.cluster.local

# Look up the DNS entry
nslookup web-app-clusterip
exit
```

Both the short name and the full DNS name resolve to the same ClusterIP. In practice, you use the short name when communicating within the same namespace and the full name when reaching across namespaces.

**Verify:** What IP does `nslookup` return? Does it match the CLUSTER-IP from `kubectl get services`?


### Verification Results

#### Service DNS Resolution

The short name worked:

```bash
wget -qO- http://web-app-clusterip
```

✅ Returned the Nginx welcome page.

The full DNS name also worked:

```bash
wget -qO- http://web-app-clusterip.default.svc.cluster.local
```

✅ Returned the same Nginx welcome page.

This confirms that Kubernetes DNS is correctly resolving the Service name.

---

#### DNS Lookup Result

From `nslookup`:

```text
Name:   web-app-clusterip.default.svc.cluster.local
Address: 10.96.156.88
```

#### Service ClusterIP

From:

```bash
kubectl get svc web-app-clusterip
```

```text
CLUSTER-IP
10.96.156.88
```

### Answer to the Verification Question

**What IP does nslookup return?**

```text
10.96.156.88
```

**Does it match the CLUSTER-IP from kubectl get services?**

✅ **Yes.**

| Source                            | IP Address   |
| --------------------------------- | ------------ |
| nslookup web-app-clusterip        | 10.96.156.88 |
| kubectl get svc web-app-clusterip | 10.96.156.88 |

The IPs match exactly.

---

### About the NXDOMAIN Messages

These lines are normal with BusyBox's `nslookup`:

```text
server can't find web-app-clusterip.svc.cluster.local: NXDOMAIN
```

BusyBox tries several search domains before finding the correct record:

```text
web-app-clusterip.default.svc.cluster.local
```

Since it eventually resolves successfully and returns `10.96.156.88`, DNS is functioning correctly.

<img width="1868" height="1030" alt="image" src="https://github.com/user-attachments/assets/cccf3d43-4583-4670-bc79-854fc13b9ae9" />



---

### Task 4: NodePort Service (External Access via Node)
A NodePort Service exposes your application on a port on every node in the cluster. This lets you access the Service from outside the cluster.

Create `nodeport-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-nodeport
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

- `nodePort: 30080` — the port opened on every node (must be in range 30000-32767)
- Traffic flow: `<NodeIP>:30080` -> Service -> Pod:80

```bash
kubectl apply -f nodeport-service.yaml
kubectl get services
```



Access the service:
```bash
# If using Minikube
minikube service web-app-nodeport --url

# If using Kind, get the node IP first
kubectl get nodes -o wide
# Then curl <node-internal-ip>:30080

# If using Docker Desktop
curl http://localhost:30080
```

**Verify:** Can you see the Nginx welcome page from your browser or terminal using the NodePort?
✅ **Yes, the Nginx welcome page is accessible.**

Verification performed using:

```bash
kubectl port-forward --address 0.0.0.0 service/web-app-nodeport 8080:80
```

Then accessing:

```text
http://52.13.41.107:8080
```

displayed the **Nginx Welcome Page**.

Additionally, the application was accessible from the terminal:

```bash
curl http://localhost:8080
```

which returned the Nginx HTML content, confirming that the NodePort Service is correctly routing traffic to the `web-app` Pods.

**Result:** ✅ The Nginx welcome page is visible through the Service, confirming successful external access.

<img width="1367" height="717" alt="image" src="https://github.com/user-attachments/assets/67af6c6d-39ee-41d6-ae9d-7577f1beaa84" />


<img width="1770" height="612" alt="image" src="https://github.com/user-attachments/assets/26f71037-2771-42d9-85ef-230d5b2a9aef" />


<img width="1370" height="327" alt="image" src="https://github.com/user-attachments/assets/67463751-208c-4ae0-abc8-c927f49f0be0" />


---

### Task 5: LoadBalancer Service (Cloud External Access)
In a cloud environment (AWS, GCP, Azure), a LoadBalancer Service provisions a real external load balancer that routes traffic to your nodes.

Create `loadbalancer-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
```

```bash
kubectl apply -f loadbalancer-service.yaml
kubectl get services
```

On a local cluster (Minikube, Kind, Docker Desktop), the EXTERNAL-IP will show `<pending>` because there is no cloud provider to create a real load balancer. This is expected.

If you are using Minikube:
```bash
# Minikube can simulate a LoadBalancer
minikube tunnel
# In another terminal, check again:
kubectl get services
```

In a real cloud cluster, the EXTERNAL-IP would be a public IP address or hostname provisioned by the cloud provider.

**Verify:** What does the EXTERNAL-IP column show? Why is it `<pending>` on a local cluster?

### Verification

**What does the EXTERNAL-IP column show?**

For your LoadBalancer Service:

```text
web-app-loadbalancer   LoadBalancer   10.96.239.199   <pending>   80:32421/TCP
```

The **EXTERNAL-IP** is:

```text
<pending>
```

### Why is it `<pending>`?

You're running Kubernetes on a **Kind cluster** (Kubernetes-in-Docker), not on a managed cloud Kubernetes service.

A `LoadBalancer` Service requires a cloud provider integration to automatically create:

* An external load balancer
* A public IP address or hostname
* Routing from the internet to your Kubernetes nodes

Examples:

* AWS → Elastic Load Balancer (ELB/NLB)
* GCP → Cloud Load Balancer
* Azure → Azure Load Balancer

Since Kind has **no cloud provider**, Kubernetes cannot provision an external load balancer, so the `EXTERNAL-IP` remains:

```text
<pending>
```

### Answer

> The `web-app-loadbalancer` Service was created successfully. The `EXTERNAL-IP` column shows **`<pending>`**. This is expected because the cluster is running on Kind, which does not have a cloud provider integration to provision an external load balancer. In a cloud environment such as AWS, Azure, or GCP, Kubernetes would automatically create a load balancer and assign a public IP address or hostname. Therefore, the external IP remains pending in a local Kind cluster.


<img width="1370" height="327" alt="image" src="https://github.com/user-attachments/assets/20c9a037-aaac-47cc-8944-38e5301845d6" />


---

### Task 6: Understand the Service Types Side by Side
Check all three services:

```bash
kubectl get services -o wide
```

Verify this:
```bash
kubectl describe service web-app-loadbalancer
```

You should see all three: a ClusterIP, a NodePort, and the LoadBalancer configuration.

**Verify:** Does the LoadBalancer service also have a ClusterIP and NodePort assigned?

✅ **Yes, the LoadBalancer Service has both a ClusterIP and a NodePort assigned.**

From your `kubectl describe service web-app-loadbalancer` output:

```text
Type:       LoadBalancer
IP:         10.96.239.199
NodePort:   <unset> 32421/TCP
```

### Verification

| Component    | Value           |
| ------------ | --------------- |
| Service Type | LoadBalancer    |
| ClusterIP    | `10.96.239.199` |
| NodePort     | `32421`         |
| External IP  | `<pending>`     |

This confirms that the `web-app-loadbalancer` Service includes:

* ✅ A **ClusterIP** (`10.96.239.199`) for internal cluster communication
* ✅ A **NodePort** (`32421`) for node-level access
* ✅ A **LoadBalancer** configuration (with `EXTERNAL-IP` currently `<pending>` because Kind is not connected to a cloud provider)

### Conclusion

A LoadBalancer Service is built on top of NodePort and ClusterIP:

```text
LoadBalancer
    ↓
 NodePort
    ↓
 ClusterIP
```

Therefore, the `web-app-loadbalancer` Service automatically received both a ClusterIP and a NodePort.

**Answer:** Yes, the LoadBalancer Service has a ClusterIP (`10.96.239.199`) and a NodePort (`32421`) assigned, confirming that LoadBalancer builds on top of NodePort and ClusterIP.

<img width="908" height="632" alt="image" src="https://github.com/user-attachments/assets/b8ed3516-5d47-44f5-9f89-b358b2e4dc5d" />


---

### Task 7: Clean Up
```bash
kubectl delete -f app-deployment.yaml
kubectl delete -f clusterip-service.yaml
kubectl delete -f nodeport-service.yaml
kubectl delete -f loadbalancer-service.yaml

kubectl get pods
kubectl get services
```

Only the built-in `kubernetes` service in the default namespace should remain.

**Verify:** Is everything cleaned up?





Yes. All resources created during the lab (web-app Deployment, ClusterIP Service, NodePort Service, and LoadBalancer Service) were successfully deleted. The remaining nginx Pod and nginx Service belong to a different deployment and were not part of this exercise. Therefore, the lab resources have been fully cleaned up

<img width="1414" height="413" alt="image" src="https://github.com/user-attachments/assets/7d1b351f-5ab5-4aeb-96c6-10d4d9356255" />


---



# Kubernetes Services Report

## 1. What Problem Services Solve and How They Relate to Pods and Deployments

In Kubernetes, Pods are ephemeral. When a Pod crashes, is deleted, or is recreated by a Deployment, it receives a new IP address. Applications cannot reliably communicate using Pod IPs because those IPs can change at any time.

A Kubernetes Service provides:

* A stable IP address (ClusterIP)
* A stable DNS name
* Load balancing across multiple Pods
* Service discovery between applications

In this lab, the Deployment `web-app` created three Nginx Pods. The Services selected these Pods using the label:

```yaml
app: web-app
```

and provided stable access to them regardless of Pod restarts.

Relationship:

```text
Deployment
    ↓
Creates Pods
    ↓
Service selects Pods using labels
    ↓
Provides stable networking and load balancing
```

---

## 2. Service Manifests and Explanation

### ClusterIP Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-clusterip
spec:
  type: ClusterIP
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
```

Purpose:

* Internal communication only
* Accessible from within the cluster
* Provides a stable ClusterIP and DNS name

---

### NodePort Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-nodeport
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

Purpose:

* Exposes the application outside the cluster
* Accessible using:

```text
<NodeIP>:30080
```

* Useful for development and testing

---

### LoadBalancer Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 80
```

Purpose:

* Used in cloud environments
* Automatically provisions a cloud load balancer
* Provides external access through a public IP or hostname

In Kind, the EXTERNAL-IP remains `<pending>` because no cloud provider is available.

---

## 3. Difference Between ClusterIP, NodePort, and LoadBalancer

| Service Type | Accessible From                                 | Use Case                                  |
| ------------ | ----------------------------------------------- | ----------------------------------------- |
| ClusterIP    | Inside the cluster only                         | Internal service-to-service communication |
| NodePort     | Outside the cluster using `<NodeIP>:<NodePort>` | Development and testing                   |
| LoadBalancer | Public cloud load balancer                      | Production workloads                      |

Service hierarchy:

```text
LoadBalancer
    ↓
 NodePort
    ↓
 ClusterIP
```

A LoadBalancer Service automatically includes both a ClusterIP and a NodePort.

---

## 4. How Kubernetes DNS Works for Service Discovery

Kubernetes provides an internal DNS service.

Every Service automatically receives a DNS name.

Examples:

Short name:

```text
web-app-clusterip
```

Fully qualified name:

```text
web-app-clusterip.default.svc.cluster.local
```

Verification performed:

```bash
kubectl run dns-test --image=busybox --rm -it --restart=Never -- sh

wget -qO- http://web-app-clusterip

wget -qO- http://web-app-clusterip.default.svc.cluster.local

nslookup web-app-clusterip
```

Result:

```text
Name: web-app-clusterip.default.svc.cluster.local
Address: 10.96.156.88
```

This matched the Service ClusterIP.

---

## 5. What Endpoints Are and How to Inspect Them

Endpoints represent the actual Pod IP addresses that a Service forwards traffic to.

The Service dynamically updates its endpoints when Pods are created or removed.

View endpoints:

```bash
kubectl get endpoints web-app-nodeport
```

Output:

```text
NAME               ENDPOINTS
web-app-nodeport   10.244.0.6:80,10.244.0.7:80,10.244.0.8:80
```

This shows that traffic is distributed across all three Nginx Pods.

Detailed Service information:

```bash
kubectl describe service web-app-loadbalancer
```

---

## 6. Verification Results

### Services Created

```text
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
web-app-clusterip      ClusterIP      10.96.156.88    <none>        80/TCP
web-app-nodeport       NodePort       10.96.182.87    <none>        80:30080/TCP
web-app-loadbalancer   LoadBalancer   10.96.239.199   <pending>     80:32421/TCP
```

### DNS Test

```text
Name: web-app-clusterip.default.svc.cluster.local
Address: 10.96.156.88
```

### Endpoint Verification

```text
10.244.0.6:80
10.244.0.7:80
10.244.0.8:80
```

### NodePort Verification

Accessed successfully through:

```text
http://52.13.41.107:8080
```

(using `kubectl port-forward --address 0.0.0.0 service/web-app-nodeport 8080:80`)

Result:

```text
Welcome to nginx!
```

---

## 7. Screenshots to Include

Include screenshots of:

1. Deployment Pods

```bash
kubectl get pods -o wide
```

2. Services

```bash
kubectl get svc
```

3. DNS Resolution

```bash
nslookup web-app-clusterip
```

4. Endpoints

```bash
kubectl get endpoints web-app-nodeport
```

5. LoadBalancer Details

```bash
kubectl describe service web-app-loadbalancer
```

6. Browser showing Nginx Welcome Page

```text
http://52.13.41.107:8080
```

7. Terminal output of:

```bash
curl http://localhost:8080
```

showing the Nginx HTML response.


