# Day 57 – Resource Requests, Limits, and Probes

## Challenge Tasks

### Task 1: Resource Requests and Limits
1. Write a Pod manifest with `resources.requests` (cpu: 100m, memory: 128Mi) and `resources.limits` (cpu: 250m, memory: 256Mi)

`resource-demo.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-demo
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "250m"
        memory: "256Mi"
```

2. Apply and inspect with `kubectl describe pod` — look for the Requests, Limits, and QoS Class sections
3. Since requests and limits differ, the QoS class is `Burstable`. If equal, it would be `Guaranteed`. If missing, `BestEffort`.

CPU is in millicores: `100m` = 0.1 CPU. Memory is in mebibytes: `128Mi`.

**Requests** = guaranteed minimum (scheduler uses this for placement). **Limits** = maximum allowed (kubelet enforces at runtime).

**Verify:** What QoS class does your Pod have?

```bash
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-57/manifests$ nano resource-demo.yaml
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-57/manifests$ kubectl apply -f resource-demo.yaml
pod/resource-demo created
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-57/manifests$ kubectl get pods -w
NAME                            READY   STATUS              RESTARTS      AGE
nginx-7f8fbb96d-q64d5           1/1     Running             3 (17h ago)   2d14h
nginx-deploy-5cf8dc6bc5-f5fpb   1/1     Running             1 (17h ago)   20h
nginx-deploy-5cf8dc6bc5-snh72   1/1     Running             1 (17h ago)   20h
nginx-deploy-5cf8dc6bc5-zkh7p   1/1     Running             1 (17h ago)   20h
resource-demo                   0/1     ContainerCreating   0             15s
resource-demo                   1/1     Running             0             19s
^C
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-57/manifests$ kubectl get pods
NAME                            READY   STATUS    RESTARTS      AGE
nginx-7f8fbb96d-q64d5           1/1     Running   3 (17h ago)   2d14h
nginx-deploy-5cf8dc6bc5-f5fpb   1/1     Running   1 (17h ago)   20h
nginx-deploy-5cf8dc6bc5-snh72   1/1     Running   1 (17h ago)   20h
nginx-deploy-5cf8dc6bc5-zkh7p   1/1     Running   1 (17h ago)   20h
resource-demo                   1/1     Running   0             84s
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-57/manifests$ kubectl describe pod resource-demo
Name:             resource-demo
Namespace:        default
Priority:         0
Service Account:  default
Node:             devops-cluster-control-plane/172.18.0.2
Start Time:       Thu, 04 Jun 2026 04:36:22 +0000
Labels:           <none>
Annotations:      <none>
Status:           Running
IP:               10.244.0.9
IPs:
  IP:  10.244.0.9
Containers:
  nginx:
    Container ID:   containerd://b0bb52f31310dbd86017365ee07e14f3a0c2b0d10a371a101070c9744d86c48a
    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:5aca99593157f4ae539a5dec1092a0ad8762f8e2eb1789085a13a0f5622369f6
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Thu, 04 Jun 2026 04:36:35 +0000
    Ready:          True
    Restart Count:  0
    Limits:
      cpu:     250m
      memory:  256Mi
    Requests:
      cpu:        100m
      memory:     128Mi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-xddjx (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       True
  ContainersReady             True
  PodScheduled                True
Volumes:
  kube-api-access-xddjx:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  93s   default-scheduler  Successfully assigned default/resource-demo to devops-cluster-control-plane
  Normal  Pulling    87s   kubelet            spec.containers{nginx}: Pulling image "nginx"
  Normal  Pulled     84s   kubelet            spec.containers{nginx}: Successfully pulled image "nginx" in 2.534s (2.534s including waiting). Image size: 63120520 bytes.
  Normal  Created    83s   kubelet            spec.containers{nginx}: Container created
  Normal  Started    78s   kubelet            spec.containers{nginx}: Container started
```

```text
    Limits:
      cpu:     250m
      memory:  256Mi
    Requests:
      cpu:        100m
      memory:     128Mi
```

Also find:

```text
QoS Class: Burstable
```

---

## Why Burstable?

Because:

```text
Requests < Limits
```

Specifically:

| Resource | Request | Limit |
| -------- | ------- | ----- |
| CPU      | 100m    | 250m  |
| Memory   | 128Mi   | 256Mi |

QoS rules:

* Guaranteed → requests = limits
* Burstable → requests < limits
* BestEffort → no requests/limits

Your pod falls into the **Burstable** category.

---

## Verification Question

**What QoS class does your Pod have?**

Answer:

```text
Burstable
```
Reason:
The Pod has requests and limits configured, but requests are lower than limits. Therefore Kubernetes assigns the Burstable QoS class.

<img width="989" height="857" alt="image" src="https://github.com/user-attachments/assets/48852ed8-6a10-4b1a-8ec8-151e849f4e36" />




---

### Task 2: OOMKilled — Exceeding Memory Limits
1. Write a Pod manifest using the `polinux/stress` image with a memory limit of `100Mi`
2. Set the stress command to allocate 200M of memory: `command: ["stress"] args: ["--vm", "1", "--vm-bytes", "200M", "--vm-hang", "1"]`
3. Apply and watch — the container gets killed immediately

CPU is throttled when over limit. Memory is killed — no mercy.

Check `kubectl describe pod` for `Reason: OOMKilled` and `Exit Code: 137` (128 + SIGKILL).

**Verify:** What exit code does an OOMKilled container have?

## Verification

Created a Pod using polinux/stress with a memory limit of 100Mi.

The container attempted to allocate 200M of memory:

--vm 1 --vm-bytes 200M --vm-hang 1

Observed:
- Pod entered Error state
- Restart count increased
- Pod entered CrashLoopBackOff
- Exit Code: 137

Conclusion:
The container exceeded its memory limit and was terminated by the OOM killer.

Verification Answer:
**Exit Code 137**

Explanation:
```bash
137 = 128 + 9
```
where:
```bash
128 = terminated by signal
9 = SIGKILL
```
So:
```bash
OOMKilled -> Exit Code 137
```

<img width="881" height="955" alt="image" src="https://github.com/user-attachments/assets/d62a0935-a2ff-493d-9ec4-ab7929983ae8" />


---

### Task 3: Pending Pod — Requesting Too Much
1. Write a Pod manifest requesting `cpu: 100` and `memory: 128Gi`
`huge-request.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: huge-request
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "100"
        memory: "128Gi"
```

3. Apply and check — STATUS stays `Pending` forever
4. Run `kubectl describe pod` and read the Events — the scheduler says exactly why: insufficient resources

**Verify:** What event message does the scheduler produce?

## Verification

Created a Pod requesting:
- CPU: 100
- Memory: 128Gi

Observed:
- STATUS: Pending
- PodScheduled: False
- Node: <none>

Scheduler Event:
FailedScheduling:
0/1 nodes are available:
1 Insufficient cpu,
1 Insufficient memory.

Conclusion:
The scheduler could not find a node with enough resources to satisfy the Pod's requests.

<img width="838" height="295" alt="image" src="https://github.com/user-attachments/assets/8baadc67-b723-4a54-bf95-3618b7f9a4db" />



---

### Task 4: Liveness Probe
A liveness probe detects stuck containers. If it fails, Kubernetes restarts the container.

1. Write a Pod manifest with a busybox container that creates `/tmp/healthy` on startup, then deletes it after 30 seconds
`liveness-demo.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-demo
spec:
  containers:
  - name: busybox
    image: busybox
    args:
      - /bin/sh
      - -c
      - |
        touch /tmp/healthy
        sleep 30
        rm -f /tmp/healthy
        sleep 600

    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      periodSeconds: 5
      failureThreshold: 3
```
2. Add a liveness probe using `exec` that runs `cat /tmp/healthy`, with `periodSeconds: 5` and `failureThreshold: 3`
3. After the file is deleted, 3 consecutive failures trigger a restart. Watch with `kubectl get pod -w`

**Verify:** How many times has the container restarted?


## Verification

Created a BusyBox Pod that:

1. Created /tmp/healthy on startup
2. Deleted the file after 30 seconds

Configured a liveness probe:

- exec: cat /tmp/healthy
- periodSeconds: 5
- failureThreshold: 3

Observed:

- Liveness probe failures after file deletion
- Kubernetes restarted the container automatically
- Event: "Container busybox failed liveness probe, will be restarted"
- Restart Count: 13

Verification Answer:
The container restarted repeatedly after liveness probe failures.
Observed restart count: 13.




---

### Task 5: Readiness Probe
A readiness probe controls traffic. Failure removes the Pod from Service endpoints but does NOT restart it.

1. Write a Pod manifest with nginx and a `readinessProbe` using `httpGet` on path `/` port `80`
2. Expose it as a Service: `kubectl expose pod <name> --port=80 --name=readiness-svc`
3. Check `kubectl get endpoints readiness-svc` — the Pod IP is listed
4. Break the probe: `kubectl exec <pod> -- rm /usr/share/nginx/html/index.html`
5. Wait 15 seconds — Pod shows `0/1` READY, endpoints are empty, but the container is NOT restarted

**Verify:** When readiness failed, was the container restarted?


`readiness-demo.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-demo
  labels:
    app: readiness-demo
spec:
  containers:
  - name: nginx
    image: nginx
    readinessProbe:
      httpGet:
        path: /index.html
        port: 80
      periodSeconds: 5
      failureThreshold: 3
```

Created an nginx Pod with a readiness probe:

- HTTP GET /index.html
- periodSeconds: 5
- failureThreshold: 3

Created a Service:
```bash
kubectl expose pod readiness-demo --port=80 --name=readiness-svc
```
Initial state:
- READY: 1/1
- Endpoints: 10.244.0.15:80

Deleted the file used by the readiness check:
```bash
kubectl exec readiness-demo -- rm /usr/share/nginx/html/index.html
```
Observed:
- READY changed to 0/1
- Service endpoints became empty
- Readiness probe failed with HTTP 404
- Restart Count remained 0

Answer:
- No, the container was not restarted.
- Readiness probe failures only remove Pods from Service endpoints.

<img width="1657" height="812" alt="image" src="https://github.com/user-attachments/assets/2e47cad4-fb2a-458e-8395-d4895b397a52" />


---

### Task 6: Startup Probe
A startup probe gives slow-starting containers extra time. While it runs, liveness and readiness probes are disabled.

1. Write a Pod manifest where the container takes 20 seconds to start (e.g., `sleep 20 && touch /tmp/started`)
2. Add a `startupProbe` checking for `/tmp/started` with `periodSeconds: 5` and `failureThreshold: 12` (60 second budget)
3. Add a `livenessProbe` that checks the same file — it only kicks in after startup succeeds

**Verify:** What would happen if `failureThreshold` were 2 instead of 12?

If failureThreshold were 2, Kubernetes would allow only 10 seconds (2 × 5s) for startup. 
Since the application needs 20 seconds to start, the startup probe would fail and Kubernetes would restart the container before startup completed, causing repeated restarts/CrashLoopBackOff.

<img width="1471" height="913" alt="image" src="https://github.com/user-attachments/assets/02d71f9b-d6fe-4554-9fa9-304089f05e7c" />


---

### Task 7: Clean Up
Delete all pods and services you created.

```bash
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-57/manifests$ kubectl delete pod resource-demo oom-demo huge-request liveness-demo readiness-demo startup-demo
pod "resource-demo" deleted from default namespace
pod "oom-demo" deleted from default namespace
pod "huge-request" deleted from default namespace
pod "liveness-demo" deleted from default namespace
pod "readiness-demo" deleted from default namespace
pod "startup-demo" deleted from default namespace
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-57/manifests$ kubectl delete svc readiness-svc
service "readiness-svc" deleted from default namespace
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-57/manifests$ kubectl get pods
NAME                            READY   STATUS    RESTARTS      AGE
nginx-7f8fbb96d-q64d5           1/1     Running   3 (21h ago)   2d18h
nginx-deploy-5cf8dc6bc5-f5fpb   1/1     Running   1 (21h ago)   24h
nginx-deploy-5cf8dc6bc5-snh72   1/1     Running   1 (21h ago)   24h
nginx-deploy-5cf8dc6bc5-zkh7p   1/1     Running   1 (21h ago)   24h
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-57/manifests$ kubectl get svc
NAME         TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
kubernetes   ClusterIP   10.96.0.1     <none>        443/TCP        5d2h
nginx        NodePort    10.96.31.26   <none>        80:30739/TCP   5d2h
```

<img width="646" height="167" alt="image" src="https://github.com/user-attachments/assets/c8546321-d75b-45c9-99b9-a0715fedd9cb" />



---


## Requests vs Limits (Scheduling vs Enforcement)

### Requests

* Define the **minimum CPU and memory** a container needs.
* Used by the **Kubernetes scheduler** to decide which node can run the Pod.
* Kubernetes guarantees the requested resources are available when scheduling.

Example:

```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
```

### Limits

* Define the **maximum CPU and memory** a container is allowed to use.
* Enforced by the **kubelet** at runtime.

Example:

```yaml
resources:
  limits:
    cpu: "250m"
    memory: "256Mi"
```

### Key Difference

| Requests                      | Limits                        |
| ----------------------------- | ----------------------------- |
| Used for scheduling           | Used for runtime enforcement  |
| Minimum guaranteed resources  | Maximum allowed resources     |
| Scheduler checks these values | Kubelet enforces these values |

### QoS Classes

| QoS Class  | Condition                     |
| ---------- | ----------------------------- |
| Guaranteed | requests = limits             |
| Burstable  | requests < limits             |
| BestEffort | no requests or limits defined |

In Task 1:

```yaml
requests:
  cpu: 100m
  memory: 128Mi

limits:
  cpu: 250m
  memory: 256Mi
```

**QoS Class = Burstable**

---

## What Happens When CPU or Memory Limits Are Exceeded?

### CPU Limit Exceeded

CPU is **compressible**.

When a container uses more CPU than its limit:

* Kubernetes does **not kill** the container.
* The Linux kernel **throttles** CPU usage.
* Application continues running but becomes slower.

Example:

```yaml
limits:
  cpu: 250m
```

Container tries to use:

```text
500m CPU
```

Result:

```text
CPU usage throttled to 250m
Container continues running
```

---

### Memory Limit Exceeded

Memory is **incompressible**.

When a container uses more memory than its limit:

* Kubernetes immediately terminates the container.
* Container receives a SIGKILL.
* Pod restarts if restart policy allows it.

Example:

```yaml
limits:
  memory: 100Mi
```

Container allocates:

```text
200Mi
```

Result:

```text
Reason: OOMKilled
Exit Code: 137
```

From Task 2:

```text
Exit Code: 137
Reason: OOMKilled
```

Where:

```text
137 = 128 + 9
```

* 128 = signal offset
* 9 = SIGKILL

---

## Liveness vs Readiness vs Startup Probes

Kubernetes probes help determine container health and availability.

### 1. Liveness Probe

Purpose:

* Detects a stuck or unhealthy container.
* If probe fails repeatedly, Kubernetes restarts the container.

Example:

```yaml
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  periodSeconds: 5
  failureThreshold: 3
```

Task 4 behavior:

```text
Container creates /tmp/healthy
After 30s file is deleted
Probe fails 3 times
Container restarted
```

Observed event:

```text
Container busybox failed liveness probe, will be restarted
```

Result:

```text
Liveness failure = Restart container
```

---

### 2. Readiness Probe

Purpose:

* Determines whether a Pod can receive traffic.
* Does NOT restart the container.

Example:

```yaml
readinessProbe:
  httpGet:
    path: /index.html
    port: 80
```

Task 5 behavior:

Before deleting file:

```text
Pod READY = 1/1
Endpoint present
```

After:

```bash
kubectl exec readiness-demo -- rm /usr/share/nginx/html/index.html
```

Result:

```text
Pod READY = 0/1
Service endpoints become empty
Restart count = 0
```

Observed:

```text
HTTP probe failed with statuscode: 404
```

Result:

```text
Readiness failure = Remove from Service endpoints
No restart
```

---

### 3. Startup Probe

Purpose:

* Gives slow-starting applications extra startup time.
* While startup probe is running:

  * Liveness probe is disabled
  * Readiness probe is disabled

Example:

```yaml
startupProbe:
  exec:
    command:
    - cat
    - /tmp/started
  periodSeconds: 5
  failureThreshold: 12
```

Task 6 behavior:

Container startup:

```bash
sleep 20
touch /tmp/started
```

Startup budget:

```text
5s × 12 = 60 seconds
```

Container becomes healthy after:

```text
20 seconds
```

So startup probe succeeds and Pod continues running.

---

### What If failureThreshold Were 2?

```yaml
periodSeconds: 5
failureThreshold: 2
```

Startup budget:

```text
5 × 2 = 10 seconds
```

Container needs:

```text
20 seconds
```

Result:

```text
Startup probe fails twice
Kubernetes kills container
Container restarts
Loop continues forever
```

So:

```text
failureThreshold: 2
→ Startup probe fails before application starts
→ Container repeatedly restarts
→ CrashLoopBackOff
```

---

### Probe Summary

| Probe Type | Purpose                     | Failure Action                                       |
| ---------- | --------------------------- | ---------------------------------------------------- |
| Liveness   | Detect dead/stuck container | Restart container                                    |
| Readiness  | Control traffic routing     | Remove from endpoints                                |
| Startup    | Allow slow startup          | Kill and restart container if startup never succeeds |

### Key Takeaways

* **Requests** help scheduling.
* **Limits** enforce runtime resource usage.
* **CPU over limit → throttled.**
* **Memory over limit → OOMKilled (Exit Code 137).**
* **Liveness failure → restart container.**
* **Readiness failure → remove Pod from Service endpoints.**
* **Startup failure → kill container before liveness/readiness begin.**
