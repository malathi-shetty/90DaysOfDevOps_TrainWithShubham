# Day 52 – Kubernetes Namespaces and Deployments

## Challenge Tasks

### Task 1: Explore Default Namespaces
Kubernetes comes with built-in namespaces. List them:

```bash
kubectl get namespaces
```

You should see at least:
- `default` — where your resources go if you do not specify a namespace
- `kube-system` — Kubernetes internal components (API server, scheduler, etc.)
- `kube-public` — publicly readable resources
- `kube-node-lease` — node heartbeat tracking

Check what is running inside `kube-system`:
```bash
kubectl get pods -n kube-system
```

These are the control plane components keeping your cluster alive. Do not touch them.

**Verify:** How many pods are running in `kube-system`? `12 Pods are running`

```bash
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-52$ kubectl get pods -n kube-system
NAME                                                   READY   STATUS    RESTARTS   AGE
coredns-589f44dc88-5gc9m                               1/1     Running   0          145m
coredns-589f44dc88-ltv6n                               1/1     Running   0          145m
etcd-devops-cluster-control-plane                      1/1     Running   0          145m
kindnet-pqfcm                                          1/1     Running   0          145m
kube-apiserver-devops-cluster-control-plane            1/1     Running   0          145m
kube-controller-manager-devops-cluster-control-plane   1/1     Running   0          145m
kube-proxy-9lpvz                                       1/1     Running   0          145m
kube-scheduler-devops-cluster-control-plane            1/1     Running   0          145m
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-52$
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-52$ kubectl get pods -n kube-system --no-headers | wc -l
8
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-52$
```

<img width="880" height="333" alt="image" src="https://github.com/user-attachments/assets/44ce376b-7a28-4a29-8e52-122f62c640c6" />


---

### Task 2: Create and Use Custom Namespaces
Create two namespaces — one for a development environment and one for staging:

```bash
kubectl create namespace dev
kubectl create namespace staging
```

Verify they exist:
```bash
kubectl get namespaces
```



You can also create a namespace from a manifest:
```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
```

```bash
kubectl apply -f namespace.yaml
```



Now run a pod in a specific namespace:
```bash
kubectl run nginx-dev --image=nginx:latest -n dev
kubectl run nginx-staging --image=nginx:latest -n staging
```



List pods across all namespaces:
```bash
kubectl get pods -A
```



Notice that `kubectl get pods` without `-n` only shows the `default` namespace. You must specify `-n <namespace>` or use `-A` to see everything.

**Verify:** Does `kubectl get pods` show these pods? What about `kubectl get pods -A`?
- When I run `kubectl get pods`, it does not show any Pods because it only displays Pods in the current namespace (default), and there are no Pods running there.
- When I run `kubectl get pods -A`, it shows Pods from all namespaces, including `kube-system` and `local-path-storage`, so I can see the Kubernetes system Pods.


<img width="1251" height="850" alt="image" src="https://github.com/user-attachments/assets/cf83abb2-5107-4971-b939-942d4bb5676e" />


---

### Task 3: Create Your First Deployment
A Deployment tells Kubernetes: "I want X replicas of this Pod running at all times." If a Pod crashes, the Deployment controller recreates it automatically.

Create a file `nginx-deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: dev
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
        image: nginx:1.24
        ports:
        - containerPort: 80
```

Key differences from a standalone Pod:
- `kind: Deployment` instead of `kind: Pod`
- `apiVersion: apps/v1` instead of `v1`
- `replicas: 3` tells Kubernetes to maintain 3 identical pods
- `selector.matchLabels` connects the Deployment to its Pods
- `template` is the Pod template — the Deployment creates Pods using this blueprint

Apply it:
```bash
kubectl apply -f nginx-deployment.yaml
```

Check the result:
```bash
kubectl get deployments -n dev
kubectl get pods -n dev
```



You should see 3 pods with names like `nginx-deployment-xxxxx-yyyyy`.

**Verify:** What do the READY, UP-TO-DATE, and AVAILABLE columns mean in the deployment output?

For a Deployment, when you run:

```bash id="mlul5q"
kubectl get deployments -n dev
```

you'll see columns like:

```text id="8s7cbg"
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   2/2     2            2           10m
```

### READY

```text id="gl4xkt"
READY = Number of ready Pods / Desired number of Pods
```

Example:

```text id="79mzyv"
2/2
```

means 2 Pods are ready and serving traffic out of the 2 Pods requested by the Deployment.

---

### UP-TO-DATE

```text id="ebln6m"
UP-TO-DATE = Number of Pods running the latest Deployment configuration.
```

Example:

```text id="4vy4n9"
2
```

means both Pods are using the newest Deployment specification (such as the latest image version).

During a rolling update, this number may temporarily be lower than the desired replica count until all Pods are updated.

---

### AVAILABLE

```text id="7wxf4q"
AVAILABLE = Number of Pods available to serve traffic.
```

A Pod is considered available after it has started successfully and passed its readiness checks.

Example:

```text id="rn6zgq"
2
```

means 2 Pods are healthy and available for use.

---

### Example 

```text id="71gj3f"
NAME               READY   UP-TO-DATE   AVAILABLE
nginx-deployment   2/2     2            2
```

This means:

* Desired replicas = 2
* Both Pods are running the latest version
* Both Pods are healthy and ready
* The Deployment is operating normally

### Quick Memory Trick

```text id="j8s42e"
READY      → Can the Pods serve traffic?
UP-TO-DATE → Are the Pods running the latest version?
AVAILABLE  → How many healthy Pods are available right now?
```


<img width="847" height="382" alt="image" src="https://github.com/user-attachments/assets/668c72a9-a21c-4a0b-a773-70d6c2ef3bed" />


---

### Task 4: Self-Healing — Delete a Pod and Watch It Come Back
This is the key difference between a Deployment and a standalone Pod.

```bash
# List pods
kubectl get pods -n dev

# Delete one of the deployment's pods (use an actual pod name from your output)
kubectl delete pod <pod-name> -n dev

# Immediately check again
kubectl get pods -n dev
```

The Deployment controller detects that only 2 of 3 desired replicas exist and immediately creates a new one. The deleted pod is replaced within seconds.

**Verify:** Is the replacement pod's name the same as the one you deleted, or different?

It is **different**.

### Verification

When you delete a Pod that is managed by a Deployment:

```bash id="p9k2xq"
kubectl delete pod nginx-deployment-68cd4c497b-77cgz -n dev
```

Kubernetes immediately creates a replacement Pod, but:

* ❌ It does NOT reuse the same Pod name
* ✅ It creates a new Pod with a new name

---

### Why the name changes

A Deployment manages Pods through a ReplicaSet, and Pods are treated as **ephemeral objects**. Each Pod gets a unique identity (name + UID), so when one is recreated, it is considered a **new instance**, not a restart of the same Pod.

---

### Example

Before deletion:

```text id="a1b2c3"
nginx-deployment-68cd4c497b-77cgz
```

After deletion:

```text id="d4e5f6"
nginx-deployment-68cd4c497b-9xk2m
```

---

### Final Answer

```text id="v8m1qz"
The replacement Pod has a different name from the one you deleted.
```


<img width="1465" height="463" alt="image" src="https://github.com/user-attachments/assets/dbd8405f-eae7-4583-9f68-84af7838037c" />


---

### Task 5: Scale the Deployment
Change the number of replicas:

```bash
# Scale up to 5
kubectl scale deployment nginx-deployment --replicas=5 -n dev
kubectl get pods -n dev

# Scale down to 2
kubectl scale deployment nginx-deployment --replicas=2 -n dev
kubectl get pods -n dev
```



Watch how Kubernetes creates or terminates pods to match the desired count.

You can also scale by editing the manifest — change `replicas: 4` in your YAML file and run `kubectl apply -f nginx-deployment.yaml` again.

<img width="966" height="779" alt="image" src="https://github.com/user-attachments/assets/6e4cab68-d882-48df-a2a3-6838caf5d4f1" />


**Verify:** When you scaled down from 5 to 2, what happened to the extra pods?

When you scale a Deployment from **5 replicas to 2 replicas**, Kubernetes reduces the number of running Pods.

### Command used

```bash id="sc1"
kubectl scale deployment nginx-deployment --replicas=2 -n dev
```

---

### What happens to the extra Pods (3 Pods)

They are:

```text id="sc2"
Terminated by the ReplicaSet controller
```

More specifically:

* Kubernetes identifies 3 extra Pods beyond the desired state
* It selects Pods to remove (not specific “special” ones)
* Those Pods enter **Terminating** state
* Containers inside them are gracefully stopped
* Pod objects are removed from the cluster

---

### Final outcome

Before scaling:

```text id="sc3"
5 Pods Running
```

After scaling:

```text id="sc4"
2 Pods Running
```

Extra Pods:

```text id="sc5"
3 Pods → Terminated (cleaned up by ReplicaSet)
```

---

### Key point

```text id="sc6"
Kubernetes does not “pause” or “hide” Pods.
It actually deletes the extra Pods to match desired state.
```

---

### Important insight

The specific Pods removed are chosen automatically by Kubernetes; you don’t control which ones get terminated.


---

### Task 6: Rolling Update
Update the Nginx image version to trigger a rolling update:

```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.25 -n dev
```

Watch the rollout in real time:
```bash
kubectl rollout status deployment/nginx-deployment -n dev
```

<img width="1066" height="625" alt="image" src="https://github.com/user-attachments/assets/b4a0c037-e99d-45af-93f0-5798e739bcd4" />


Kubernetes replaces pods one by one — old pods are terminated only after new ones are healthy. This means zero downtime.

Check the rollout history:
```bash
kubectl rollout history deployment/nginx-deployment -n dev
```



Now roll back to the previous version:
```bash
kubectl rollout undo deployment/nginx-deployment -n dev
kubectl rollout status deployment/nginx-deployment -n dev
```

### Verify the image is back to the previous version:

```bash
kubectl describe deployment nginx-deployment -n dev | grep Image
```

<img width="1071" height="671" alt="image" src="https://github.com/user-attachments/assets/298dc11e-76ee-4561-b80c-51b1ee7c47c5" />


**Verify:** What image version is running after the rollback?
After a rollback, the image version returns to the **previous working revision** that was active before the update.

From your command:

```bash id="r1"
kubectl rollout undo deployment/nginx-deployment -n dev
```

You verified it using:

```bash id="r2"
kubectl describe deployment nginx-deployment -n dev | grep Image
```

### Result:

```text id="r3"
Image: nginx:1.24
```

---

### Final Answer

```text id="r4"
After rollback, the running image version is nginx:1.24
```

---

### Key insight

```text id="r5"
Rollback restores the Deployment to the previous ReplicaSet revision,
including the exact container image used earlier.
```


---

### Task 7: Clean Up
```bash
kubectl delete deployment nginx-deployment -n dev
kubectl delete pod nginx-dev -n dev
kubectl delete pod nginx-staging -n staging
kubectl delete namespace dev staging production
```

Deleting a namespace removes everything inside it. Be very careful with this in production.

```bash
kubectl get namespaces
kubectl get pods -A
```
<img width="951" height="462" alt="image" src="https://github.com/user-attachments/assets/5d69d7b7-d272-4583-894f-f642f547dba3" />



**Verify:** Are all your resources gone?

To verify whether all resources are gone after cleanup, you check both namespaces and cluster-wide workloads.

---

### 1. Check Namespaces

```bash id="v1"
kubectl get namespaces
```

### Result (from your cluster):

```text id="v2"
default
kube-node-lease
kube-public
kube-system
local-path-storage
```

### Meaning:

* ❌ `dev`, `staging`, `production` are gone
* ✅ Only system + default namespaces remain

---

### 2. Check All Pods

```bash id="v3"
kubectl get pods -A
```

### Result shows:

* Only system Pods (`kube-system`)
* Default namespace Pod (if any like `nginx-7f8fbb96d-h8xfq`)

---

### Final Verification Answer

```text id="v4"
Not all resources are completely gone.

✔ User-created namespaces (dev, staging, production) are deleted
✔ Their Deployments and Pods are removed

❌ Cluster still contains system namespaces (kube-system, default, etc.)
❌ System Pods are still running (this is expected in Kubernetes)
```

---

### Key Insight

```text id="v5"
Deleting namespaces removes user workloads,
but Kubernetes system components always remain running.
```



---

# Documentation

# What are Namespaces and Why Use Them?

### Definition

Namespaces are **logical separation boundaries inside a Kubernetes cluster**.

They allow you to divide cluster resources into isolated groups.

---

### Why we use Namespaces

* Organize resources by environment (dev, staging, prod)
* Avoid name conflicts (same app name in different environments)
* Apply resource quotas per team/environment
* Improve access control (RBAC)
* Better cluster management in multi-team setups

---

### Example

```text id="ns1"
dev        → development workloads
staging    → testing environment
production → live applications
```

---

# Your Deployment manifest and an explanation of each section
## Deployment Manifest Explanation

Example:

```yaml id="dep1"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: dev
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
        image: nginx:1.24
        ports:
        - containerPort: 80
```

---

### Explanation of Each Section

### 1. apiVersion

```text id="d1"
Defines Kubernetes API version used for Deployment
```

---

### 2. kind

```text id="d2"
Specifies object type → Deployment
```

---

### 3. metadata

```text id="d3"
Contains name and namespace of the Deployment
```

---

### 4. spec

```text id="d4"
Defines desired state of the Deployment
```

---

### 5. replicas

```text id="d5"
Number of Pods Kubernetes should maintain
```

---

### 6. selector

```text id="d6"
Tells Deployment how to find matching Pods
```

---

### 7. template

```text id="d7"
Blueprint for creating Pods
```

---

### 8. containers

```text id="d8"
Defines container image and configuration
```

---

# What happens when you delete a Pod managed by a Deployment vs a standalone Pod
##  What happens when you delete a Pod?

## Case 1: Pod managed by Deployment

```bash id="p1"
kubectl delete pod nginx-pod -n dev
```

### Result:

* Pod is deleted
* ReplicaSet notices missing Pod
* New Pod is automatically created

```text id="p2"
Self-healing happens automatically
```

---

## Case 2: Standalone Pod

```bash id="p3"
kubectl run nginx --image=nginx
kubectl delete pod nginx
```

### Result:

* Pod is permanently deleted
* No controller recreates it

```text id="p4"
No self-healing happens
```

---

# How scaling works (both imperative and declarative)

##  Imperative Scaling

```bash id="s1"
kubectl scale deployment nginx-deployment --replicas=5 -n dev
```

### Meaning:

Direct command to change replicas instantly.

---

## Declarative Scaling

Modify YAML:

```yaml id="s2"
spec:
  replicas: 5
```

Apply:

```bash id="s3"
kubectl apply -f deployment.yaml
```

### Meaning:

Kubernetes continuously maintains desired state.

---

### Difference

```text id="s4"
Imperative → direct command change
Declarative → desired state in YAML
```

---

# How rolling updates and rollbacks work

## Rolling Update

```bash id="u1"
kubectl set image deployment/nginx-deployment nginx=nginx:1.25 -n dev
```

### What happens:

* New Pods created with new image
* Old Pods removed gradually
* Zero downtime update

```text id="u2"
Old Pods → New Pods (gradual replacement)
```

---

## Rollback

```bash id="u3"
kubectl rollout undo deployment/nginx-deployment -n dev
```

### What happens:

* Kubernetes restores previous ReplicaSet
* Old image version comes back
* Failed update is reversed

```text id="u4"
New version → Previous stable version
```


---

# Summary

* Namespaces isolate workloads
* Deployments manage Pods via ReplicaSets
* Deleting Deployment Pods triggers self-healing
* Standalone Pods do NOT recover
* Scaling can be imperative or declarative
* Rolling updates are zero-downtime
* Rollbacks restore previous stable state


