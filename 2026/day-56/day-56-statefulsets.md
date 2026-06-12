# Day 56 – Kubernetes StatefulSets

---

## Challenge Tasks

### Task 1: Understand the Problem
1. Create a Deployment with 3 replicas using nginx
2. Check the pod names — they are random (`app-xyz-abc`)
3. Delete a pod and notice the replacement gets a different random name

This is fine for web servers but not for databases where you need stable identity.

Delete the Deployment before moving on.

**Verify:** Why would random pod names be a problem for a database cluster?

`deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
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
          image: nginx
          ports:
            - containerPort: 80
```

**Problem Observed**

Pod names are random:
```bash
nginx-deploy-5cf8dc6bc5-f5fpb
nginx-deploy-5cf8dc6bc5-snh72
nginx-deploy-5cf8dc6bc5-zkh7p
```
If a pod is deleted, a new one gets a new random name.

#### Why this is a problem for databases

If pod names keep changing:
- No stable identity between replicas
- Leader/follower confusion
- Replication breaks
- Clients cannot target specific nodes
- Cluster state becomes inconsistent

In short:
Databases need fixed identity + stable network name, not disposable pods.

<img width="1512" height="550" alt="image" src="https://github.com/user-attachments/assets/1ae71610-7000-4d1a-81c3-d413c25ffa49" />



---

### Task 2: Create a Headless Service
1. Write a Service manifest with `clusterIP: None` — this is a Headless Service
2. Set the selector to match the labels you will use on your StatefulSet pods
3. Apply it and confirm CLUSTER-IP shows `None`

A Headless Service creates individual DNS entries for each pod instead of load-balancing to one IP. StatefulSets require this.

**Verify:** What does the CLUSTER-IP column show?

- CLUSTER_IP Column Show : `None`

`headless-service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  clusterIP: None
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
```

```bash
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-56/manifests$ kubectl get svc
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
web          ClusterIP   None          <none>        80/TCP         22s
```
```bash
CLUSTER-IP: None
```

**Why Headless Service?**
- No load balancing
- Each pod gets its own DNS record
- Required for StatefulSets

<img width="1426" height="241" alt="image" src="https://github.com/user-attachments/assets/dc7b20d2-83f1-4ada-9fb2-52d009a7feaa" />


---

### Task 3: Create a StatefulSet
1. Write a StatefulSet manifest with `serviceName` pointing to your Headless Service
2. Set replicas to 3, use the nginx image
3. Add a `volumeClaimTemplates` section requesting 100Mi of ReadWriteOnce storage
4. Apply and watch: `kubectl get pods -l <your-label> -w`

Observe ordered creation — `web-0` first, then `web-1` after `web-0` is Ready, then `web-2`.

Check the PVCs: `kubectl get pvc` — you should see `web-data-web-0`, `web-data-web-1`, `web-data-web-2` (names follow the pattern `<template-name>-<pod-name>`).

**Verify:** What are the exact pod names and PVC names?

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: web
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
        volumeMounts:
        - name: web-data
          mountPath: /usr/share/nginx/html

  volumeClaimTemplates:
  - metadata:
      name: web-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 100Mi
```

### What are the exact pod names and PVC names?
Pod names:
- web-0
- web-1
- web-2

PVC names:
- web-data-web-0
- web-data-web-1
- web-data-web-2

### Why this is important

This is the core StatefulSet behavior:
- Each pod gets a **fixed identity**
- Each pod gets a **dedicated volume**
- Identity and storage are **bound together**

So even if:
- a pod dies
- restarts
- gets rescheduled
It comes back as the **same identity with the same storage**

---



<img width="1571" height="659" alt="image" src="https://github.com/user-attachments/assets/07c54979-09df-49a7-bd3d-12a2da082d95" />


---

### Task 4: Stable Network Identity
Each StatefulSet pod gets a DNS name: `<pod-name>.<service-name>.<namespace>.svc.cluster.local`

1. Run a temporary busybox pod and use `nslookup` to resolve `web-0.<your-headless-service>.default.svc.cluster.local`
2. Do the same for `web-1` and `web-2`
3. Confirm the IPs match `kubectl get pods -o wide`

**Verify:** Does the nslookup IP match the pod IP?

```bash
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-56/manifests$ kubectl get pods -o wide
NAME                            READY   STATUS    RESTARTS      AGE   IP            NODE                           NOMINATED NODE   READINESS GATES
nginx-7f8fbb96d-q64d5           1/1     Running   2 (16h ago)   42h   10.244.0.3    devops-cluster-control-plane   <none>           <none>
nginx-deploy-5cf8dc6bc5-f5fpb   1/1     Running   0             43m   10.244.0.8    devops-cluster-control-plane   <none>           <none>
nginx-deploy-5cf8dc6bc5-snh72   1/1     Running   0             43m   10.244.0.7    devops-cluster-control-plane   <none>           <none>
nginx-deploy-5cf8dc6bc5-zkh7p   1/1     Running   0             42m   10.244.0.9    devops-cluster-control-plane   <none>           <none>
web-0                           1/1     Running   0             12m   10.244.0.11   devops-cluster-control-plane   <none>           <none>
web-1                           1/1     Running   0             12m   10.244.0.13   devops-cluster-control-plane   <none>           <none>
web-2                           1/1     Running   0             11m   10.244.0.15   devops-cluster-control-plane   <none>           <none>
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-56/manifests$ kubectl run -it --rm dns-test --image=busybox -- sh
warning: couldn't fetch pre-attach logs: Get "https://127.0.0.1:41981/api/v1/namespaces/default/pods/dns-test/log?container=dns-test": context deadline exceeded
All commands and output from this session will be recorded in container logs, including credentials and sensitive information passed through the command prompt.
If you don't see a command prompt, try pressing enter.
/ #
/ # nslookup web-0.web.default.svc.cluster.local
Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   web-0.web.default.svc.cluster.local
Address: 10.244.0.11


/ # nslookup web-1.web.default.svc.cluster.local
Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   web-1.web.default.svc.cluster.local
Address: 10.244.0.13


/ # nslookup web-2.web.default.svc.cluster.local
Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   web-2.web.default.svc.cluster.local
Address: 10.244.0.15

```




## 🔹 Your nslookup results

### web-0

```text id="dnsok1"
Address: 10.244.0.11
```

### web-1

```text id="dnsok2"
Address: 10.244.0.13
```

### web-2

```text id="dnsok3"
Address: 10.244.0.15
```

---

## 🔹 actual pod IPs 

```text id="podip1"
web-0 → 10.244.0.11
web-1 → 10.244.0.13
web-2 → 10.244.0.15
```

---

# Verification

##  Does nslookup IP match pod IP?

 **YES — 100% match**
NSLOOKUP IP matches Pod IP


---

#  What this proves (important concept)

Successfully validated:

### 1. Stable DNS per pod

Each pod has its own permanent DNS record:

```
web-0.web.default.svc.cluster.local
web-1.web.default.svc.cluster.local
web-2.web.default.svc.cluster.local
```

---

### 2. No load balancing (important difference vs Deployment Service)

Unlike normal Services:

*  No random pod selection
*  No round-robin routing
*  Direct mapping to specific pod

---

### 3. StatefulSet identity guarantee

Even if a pod restarts:

* `web-0` will ALWAYS map to the same logical identity
* DNS stays stable
* IP mapping stays consistent (until rescheduled)

---

Just proved one of the most important Kubernetes concepts:

> StatefulSets give **identity + DNS stability**, not just replicas.

---

<img width="1812" height="891" alt="image" src="https://github.com/user-attachments/assets/3ea7c421-91fa-4429-928d-14f372f736d5" />




---

### Task 5: Stable Storage — Data Survives Pod Deletion
1. Write unique data to each pod: `kubectl exec web-0 -- sh -c "echo 'Data from web-0' > /usr/share/nginx/html/index.html"`

```bash
kubectl exec web-0 -- sh -c "echo 'Data from web-0' > /usr/share/nginx/html/index.html"
```

2. Delete `web-0`: `kubectl delete pod web-0`
```bash
kubectl delete pod web-0
```
3. Wait for it to come back, then check the data — it should still be "Data from web-0"

The new pod reconnected to the same PVC.

**Verify:** Is the data identical after pod recreation?

```bash
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-56/manifests$ kubectl exec web-0 -- sh -c "echo 'Data from web-0' > /usr/share/nginx/html/index.html"
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-56/manifests$ kubectl exec web-0 -- cat /usr/share/nginx/html/index.html
Data from web-0
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-56/manifests$ kubectl delete pod web-0
pod "web-0" deleted from default namespace
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-56/manifests$ kubectl get pods
NAME                            READY   STATUS    RESTARTS      AGE
nginx-7f8fbb96d-q64d5           1/1     Running   2 (17h ago)   43h
nginx-deploy-5cf8dc6bc5-f5fpb   1/1     Running   0             73m
nginx-deploy-5cf8dc6bc5-snh72   1/1     Running   0             73m
nginx-deploy-5cf8dc6bc5-zkh7p   1/1     Running   0             72m
web-0                           1/1     Running   0             2m41s
web-1                           1/1     Running   0             42m
web-2                           1/1     Running   0             41m
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-56/manifests$ kubectl exec web-0 -- cat /usr/share/nginx/html/index.html
Data from web-0
```

#  Verification 

##  Is the data identical after pod recreation?

 **YES — the data remains exactly the same**
Data is preserved due to PVC binding.

---

#  Why this works (core StatefulSet concept)

When you deleted `web-0`:

### What Kubernetes did:

*  Deleted the pod
*  Did NOT delete the PVC
*  Recreated pod with same identity: `web-0`
*  Reattached same volume: `web-data-web-0`

---

#  Key insight

| Component | Behavior                 |
| --------- | ------------------------ |
| Pod       | Recreated                |
| PVC       | Persistent (NOT deleted) |
| Data      | Survives                 |
| Identity  | Same (`web-0`)           |

---

###  Stateful storage binding

Pod ↔ PVC relationship is permanent

###  Crash recovery behavior

Pod can die and come back safely

###  Real database-like behavior

This is exactly how MySQL/Postgres should behave in Kubernetes




<img width="1286" height="458" alt="image" src="https://github.com/user-attachments/assets/31b5b937-e7e2-4d34-a5a0-8ed43d93bf89" />


---

### Task 6: Ordered Scaling
1. Scale up to 5: `kubectl scale statefulset web --replicas=5` — pods create in order (web-3, then web-4)
```bash
kubectl scale statefulset web --replicas=5
```

2. Scale down to 3 — pods terminate in reverse order (web-4, then web-3)
```bash
kubectl scale statefulset web --replicas=3
```
3. Check `kubectl get pvc` — all five PVCs still exist. Kubernetes keeps them on scale-down so data is preserved if you scale back up.

**Verify:** After scaling down, how many PVCs exist?

#  Verification Answer

##  After scaling down, how many PVCs exist?

 **5 PVCs still exist**

---

#  Why this happens

StatefulSets NEVER delete PVCs automatically because:

###  Data safety rule

Each pod may contain critical state (like databases)

###  Re-scaling reuse

If you scale back up:

* `web-3` gets back its old PVC
* `web-4` gets back its old PVC

---

# Summary

| Action             | Pods                       | PVCs                |
| ------------------ | -------------------------- | ------------------- |
| Scale up           | Created in order (0 → N)   | Existing + new PVCs |
| Scale down         | Deleted in reverse (N → 0) |  NOT deleted       |
| Delete StatefulSet | Pods removed               | PVCs still remain   |

---


> Scaling a StatefulSet does NOT destroy data — it only changes pod count, not storage.

---



<img width="1053" height="843" alt="image" src="https://github.com/user-attachments/assets/c6dea1bf-363b-45ae-807c-6268ea217c0c" />


---

### Task 7: Clean Up
1. Delete the StatefulSet and the Headless Service
2. Check `kubectl get pvc` — PVCs are still there (safety feature)
3. Delete PVCs manually

**Verify:** Were PVCs auto-deleted with the StatefulSet?

---

# 1. Delete StatefulSet

```bash id="c7del1"
kubectl delete statefulset web
```

---

# 2. Delete Headless Service

```bash id="c7del2"
kubectl delete service web
```

---

# 3. Check PVCs

```bash id="c7del3"
kubectl get pvc
```

### Expected output (important):

```text id="c7del4"
web-data-web-0
web-data-web-1
web-data-web-2
web-data-web-3
web-data-web-4
```

They are STILL present

---

# 4. Delete PVCs manually

```bash id="c7del5"
kubectl delete pvc -l app=web
```

OR individually:

```bash id="c7del6"
kubectl delete pvc web-data-web-0 web-data-web-1 web-data-web-2 web-data-web-3 web-data-web-4
```

---

#  Verification Answer

##  Were PVCs auto-deleted with the StatefulSet?

 PVCs are NOT auto-deleted when StatefulSet is removed

---

#  Why this happens

Kubernetes intentionally keeps PVCs because:

###  Safety first design

* Data might be critical (databases, logs, etc.)
* Accidental deletion of StatefulSet should NOT destroy data

---

#  Key behavior summary

| Action              | Pods      | PVCs           |
| ------------------- | --------- | -------------- |
| Delete StatefulSet  |  Deleted |  Still exists |
| Delete Service      |  Deleted |  Still exists |
| Delete PVC manually |  Removed |  Removed      |

<img width="1660" height="461" alt="image" src="https://github.com/user-attachments/assets/ceea77a1-f4ff-44dc-8162-d061a25b449a" />

---

#  Final takeaway

> StatefulSet deletion removes workloads, but **storage is preserved by default to prevent data loss**

| Feature  | Deployment     | StatefulSet   |
| -------- | -------------- | ------------- |
| Pod Name | Random         | Fixed (web-0) |
| Identity | None           | Stable        |
| Storage  | Shared         | Dedicated PVC |
| DNS      | Dynamic        | Stable        |
| Use Case | Stateless apps | Databases     |





---



# Documentation



##  What StatefulSets are and when to use them vs Deployments?

A StatefulSet is a Kubernetes workload used for **stateful applications** that require:

- Stable pod identity
- Ordered deployment and scaling
- Persistent storage per pod
- Stable network identity (DNS)

Used for:
- Databases (MySQL, PostgreSQL)
- Kafka clusters
- Zookeeper
- Any distributed system needing identity

---

##  StatefulSet vs Deployment - The comparison table

| Feature | Deployment | StatefulSet |
|--------|-----------|------------|
| Pod names | Random | Stable (web-0, web-1, web-2) |
| Startup order | Parallel | Sequential (0 → 1 → 2) |
| Shutdown order | Random | Reverse order (2 → 1 → 0) |
| Storage | Shared/ephemeral | Dedicated PVC per pod |
| Network identity | No stable hostname | Stable DNS per pod |
| Use case | Stateless apps | Databases / Stateful apps |

---

##  How Headless Services, stable DNS, and volumeClaimTemplates work

A Headless Service is created using:

```yaml
clusterIP: None
````

### Key behavior:

* No single Cluster IP is assigned
* DNS resolves directly to individual pods
* Required for StatefulSets

Example DNS:

```
web-0.web.default.svc.cluster.local
web-1.web.default.svc.cluster.local
web-2.web.default.svc.cluster.local
```

---

##  Stable DNS (How it works)

Each StatefulSet pod gets a permanent DNS name:

```
<pod-name>.<service-name>.<namespace>.svc.cluster.local
```

This ensures:

* Predictable communication between pods
* No dependency on dynamic IPs

---

##  volumeClaimTemplates (Persistent Storage)

Each pod gets its own dedicated PVC:

Example:

```
web-data-web-0
web-data-web-1
web-data-web-2
```

### Behavior:

* PVC is created per pod
* Data persists even if pod is deleted
* PVC is NOT deleted during scaling down

---

##  Ordered Deployment & Scaling

### Pod creation order:

```
web-0 → web-1 → web-2
```

### Pod termination order:

```
web-2 → web-1 → web-0
```

### Scaling behavior:

* Scale up: sequential creation
* Scale down: reverse termination
* PVCs are always preserved




---

##  Key Learnings

* StatefulSets provide identity + storage + ordering
* Headless Services enable per-pod DNS
* volumeClaimTemplates bind storage to identity
* Pods are not interchangeable like Deployments
* Data survives pod deletion and recreation

---

## Conclusion

StatefulSets are essential for running **real production-grade stateful systems** in Kubernetes.

They ensure:

* Stable identity
* Predictable networking
* Reliable persistent storage
* Safe scaling behavior

