# Day 58 – Metrics Server and Horizontal Pod Autoscaler (HPA)
---

## Challenge Tasks

### Task 1: Install the Metrics Server
1. Check if it is already running: `kubectl get pods -n kube-system | grep metrics-server`
2. If not, install it:
   - Minikube: `minikube addons enable metrics-server`
   - Kind/kubeadm: apply the official manifest from the metrics-server GitHub releases
3. On local clusters, you may need the `--kubelet-insecure-tls` flag (never in production)
4. Wait 60 seconds, then verify: `kubectl top nodes` and `kubectl top pods -A`

**Verify:** What is the current CPU and memory usage of your node?

## Verification

### Metrics Server Status

```text
metrics-server-55bf4495db-9ngfw   1/1 Running
```

Metrics Server is successfully installed and serving metrics.

### Node Metrics

```text
NAME                           CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)
devops-cluster-control-plane   205m         10%      603Mi           66%
```

### Answer

**Current node CPU usage:** `205m (10%)`

**Current node memory usage:** `603Mi (66%)`

---

## Observation

Looking at pod metrics:

```text
NAMESPACE            NAME                                                   CPU(cores)   MEMORY(bytes)
default              nginx-7f8fbb96d-q64d5                                  0m           3Mi
default              nginx-deploy-5cf8dc6bc5-f5fpb                          0m           3Mi
default              nginx-deploy-5cf8dc6bc5-snh72                          0m           3Mi
default              nginx-deploy-5cf8dc6bc5-zkh7p                          0m           3Mi
kube-system          coredns-589f44dc88-9b6xf                               3m           12Mi
kube-system          coredns-589f44dc88-hz5cf                               2m           13Mi
kube-system          etcd-devops-cluster-control-plane                      25m          38Mi
kube-system          kindnet-pqfcm                                          1m           8Mi
kube-system          kube-apiserver-devops-cluster-control-plane            45m          222Mi
kube-system          kube-controller-manager-devops-cluster-control-plane   22m          58Mi
kube-system          kube-proxy-9lpvz                                       3m           20Mi
kube-system          kube-scheduler-devops-cluster-control-plane            11m          23Mi
kube-system          metrics-server-55bf4495db-9ngfw                        7m           16Mi
local-path-storage   local-path-provisioner-855c7b7774-ltzh9                1m           9Mi
```

The API server is currently the largest memory consumer.

And:

```text
kube-system          kube-apiserver-devops-cluster-control-plane            45m          222Mi
```

is also the highest CPU consumer right now.


---


<img width="1323" height="762" alt="image" src="https://github.com/user-attachments/assets/50fd058e-94d6-46f2-8cb8-5150768d7702" />


---

### Task 2: Explore kubectl top
1. Run `kubectl top nodes`, `kubectl top pods -A`, `kubectl top pods -A --sort-by=cpu`
2. `kubectl top` shows real-time usage, not requests or limits — these are different things
3. Data comes from the Metrics Server, which polls kubelets every 15 seconds

**Verify:** Which pod is using the most CPU right now?



### Commands Executed

* `kubectl top nodes` → actual CPU and memory usage of nodes.
* `kubectl top pods -A` → actual CPU and memory usage of pods.
* `kubectl top pods -A --sort-by=cpu` → pods sorted by CPU consumption.

These metrics come from the Metrics Server, which collects data from kubelets roughly every 15 seconds.

### Verification 

From your latest sorted output:

```text id="t6g7ez"
kube-system  kube-apiserver-devops-cluster-control-plane  37m
```

**The pod using the most CPU right now is:**

```text id="e1r17h"
kube-apiserver-devops-cluster-control-plane
```

using approximately:

```text id="d3ec7y"
37m CPU
```

### Observation

Your values changed several times:

| Time    | CPU |
| ------- | --- |
| Earlier | 45m |
| Later   | 35m |
| Latest  | 37m |

This is expected because `kubectl top` shows a live snapshot of resource usage.

---


**Answer:** `kube-apiserver-devops-cluster-control-plane` is currently the highest CPU-consuming pod.

---


<img width="912" height="762" alt="image" src="https://github.com/user-attachments/assets/8948b3e9-50ff-484c-abab-f0a91765f3d0" />


---

### Task 3: Create a Deployment with CPU Requests
1. Write a Deployment manifest using the `registry.k8s.io/hpa-example` image (a CPU-intensive PHP-Apache server)
2. Set `resources.requests.cpu: 200m` — HPA needs this to calculate utilization percentages
3. Expose it as a Service: `kubectl expose deployment php-apache --port=80`

Without CPU requests, HPA cannot work — this is the most common HPA setup mistake.

**Verify:** What is the current CPU usage of the Pod?

Current CPU usage of the Pod:
`php-apache-6b99fd56b-x7plk → 1m CPU`

Current memory usage:

`9Mi`

```bash
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-58/manifests$ kubectl top pod -l app=php-apache
NAME                         CPU(cores)   MEMORY(bytes)
php-apache-6b99fd56b-x7plk   1m           9Mi
```

<img width="919" height="226" alt="image" src="https://github.com/user-attachments/assets/d8f347f7-e0fa-4703-b857-07b370a633c0" />



---

### Task 4: Create an HPA (Imperative)
1. Run: `kubectl autoscale deployment php-apache --cpu=50 --min=1 --max=10`
2. Check: `kubectl get hpa` and `kubectl describe hpa php-apache`
3. TARGETS may show `<unknown>` initially — wait 30 seconds for metrics to arrive

This scales up when average CPU exceeds 50% of requests, and down when it drops below.

**Verify:** What does the TARGETS column show?


### Verification

**TARGETS column shows:**

```text
cpu: 0%/50%
```

(or equivalently from `describe`):

```text
0% (1m) / 50%
```

### What it means

* Current CPU usage = **1m**
* CPU request = **200m**
* Utilization = `(1m ÷ 200m) × 100 = 0.5%`
* Rounded by Kubernetes to **0%**
* HPA target = **50%**

Since **0% < 50%**, the HPA will **not scale up**.




<img width="1170" height="456" alt="image" src="https://github.com/user-attachments/assets/7e5723c5-cdea-4f7f-8552-13ac032d7024" />


---

### Task 5: Generate Load and Watch Autoscaling
1. Start a load generator: `kubectl run load-generator --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://php-apache; done"`
2. Watch HPA: `kubectl get hpa php-apache --watch`
3. Over 1-3 minutes, CPU climbs above 50%, replicas increase, CPU stabilizes
4. Stop the load: `kubectl delete pod load-generator`
5. Scale-down is slow (5-minute stabilization window) — you do not need to wait

**Verify:** How many replicas did HPA scale to under load?
HPA scaled from 1 replica to 2 replicas.

Evidence:
```bash
SuccessfulRescale
New size: 2
```

<img width="1844" height="536" alt="image" src="https://github.com/user-attachments/assets/dd62a606-b160-419d-bc11-cde310725d1f" />



---

### Task 6: Create an HPA from YAML (Declarative)
1. Delete the imperative HPA: `kubectl delete hpa php-apache`
2. Write an HPA manifest using `autoscaling/v2` API with CPU target at 50% utilization
3. Add a `behavior` section to control scale-up speed (no stabilization) and scale-down speed (300 second window)
4. Apply and verify with `kubectl describe hpa`

`autoscaling/v2` supports multiple metrics and fine-grained scaling behavior that the imperative command cannot configure.

**Verify:** What does the `behavior` section control?

The behavior section controls how HPA scales up and scales down.

Scale Up:
- stabilizationWindowSeconds: 0
- allows immediate scaling when CPU exceeds the target

Scale Down:
- stabilizationWindowSeconds: 300
- waits 5 minutes before reducing replicas

It prevents aggressive scaling and gives fine-grained control over autoscaling behavior.

<img width="1822" height="711" alt="image" src="https://github.com/user-attachments/assets/b8113dae-dd5c-42da-963d-5d05bcd2f80b" />


---

### Task 7: Clean Up
Delete the HPA, Service, Deployment, and load-generator pod. Leave the Metrics Server installed.



##  1. Delete HPA (correct name)

```bash
kubectl delete hpa nginx-hpa
```

---

##  2. Delete Deployment

```bash
kubectl delete deployment nginx-hpa
```

---

##  3. Delete Service

```bash
kubectl delete svc nginx-hpa
```

---

##  4. Delete load generator pod (`load1`)

This is the one still running:

```bash
kubectl delete pod load1
```

---

##  5. Verify full cleanup

```bash
kubectl get all
kubectl get hpa
```


---



#  1. What is Metrics Server & why HPA needs it

##  Metrics Server (what it is)

Kubernetes Metrics Server is a **cluster-wide component** that collects resource usage data from nodes and pods.

It:

* Scrapes CPU & memory usage from kubelets
* Stores it in-memory (not persistent storage)
* Exposes it via the **Metrics API**

  * `metrics.k8s.io`

You can verify it with:

```bash
kubectl top nodes
kubectl top pods
```

---

##  Why HPA needs Metrics Server

Kubernetes Horizontal Pod Autoscaler cannot make scaling decisions without real-time CPU/memory data.

HPA depends on Metrics Server to answer:

* How much CPU is each pod using?
* Is usage above/below threshold?

Without it:

* `TARGETS: <unknown>`
* Errors like:

  * `Metrics API not available`
  * `no metrics returned`

👉 In short:

> Metrics Server = “sensor”
> HPA = “decision maker”

---

#  2. How HPA calculates replicas

HPA uses this formula:

```
desiredReplicas = currentReplicas × (currentMetric / targetMetric)
```

---

##  Example (CPU-based HPA)

You set:

* target CPU = 50%
* current usage = 80%
* replicas = 2

Calculation:

```
2 × (80 / 50) = 3.2 → rounds up → 4 replicas
```

---

##  If load drops

* current = 20%
* target = 50%

```
2 × (20 / 50) = 0.8 → min = 1 replica
```

---

##  Important rules HPA uses

* Always respects `minReplicas`
* Never exceeds `maxReplicas`
* Uses **rolling averages**
* Applies stabilization windows (to avoid flapping)

---

# 🔄 3. autoscaling/v1 vs autoscaling/v2

##  autoscaling/v1 (old)

* Only supports **CPU-based scaling**
* No memory scaling
* No advanced rules

Example:

```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
```

Limitations:

* No custom metrics
* No multiple metrics
* Basic scaling only

---

##  autoscaling/v2 (modern, recommended)

Supports:

* CPU
* Memory
* Custom metrics
* Multiple metrics at once
* Advanced scaling behavior

Example:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
```

Features:

```yaml
metrics:
- type: Resource
  resource:
    name: cpu
    target:
      type: Utilization
      averageUtilization: 50
```

---

##  Quick comparison

| Feature           | v1 | v2 |
| ----------------- | -- | -- |
| CPU scaling       | ✔  | ✔  |
| Memory scaling    | ❌  | ✔  |
| Custom metrics    | ❌  | ✔  |
| Multiple metrics  | ❌  | ✔  |
| Advanced behavior | ❌  | ✔  |

---

