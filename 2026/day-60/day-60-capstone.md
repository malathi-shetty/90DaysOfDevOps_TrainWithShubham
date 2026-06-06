# Day 60 – Capstone: Deploy WordPress + MySQL on Kubernetes

---

## Challenge Tasks

### Task 1: Create the Namespace (Day 52)
1. Create a `capstone` namespace
2. Set it as your default: `kubectl config set-context --current --namespace=capstone`

create the namespace
```bash
kubectl create namespace capstone
```
Set it as default:
```bash
kubectl config set-context --current --namespace=capstone
```
Verify:
```bash
kubectl config view --minify | grep namespace
```
Expected:
```bash
namespace: capstone
```

<img width="790" height="112" alt="image" src="https://github.com/user-attachments/assets/90b8b185-19fd-44ce-b917-a49a4f9e01fb" />


---

### Task 2: Deploy MySQL (Days 54-56)
1. Create a Secret with `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, and `MYSQL_PASSWORD` using `stringData`

`mysql-secret.yaml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: Opaque

stringData:
  MYSQL_ROOT_PASSWORD: rootpass123
  MYSQL_DATABASE: wordpress
  MYSQL_USER: wpuser
  MYSQL_PASSWORD: wppass123
```


2. Create a Headless Service (`clusterIP: None`) for MySQL on port 3306

`mysql-headless-service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql

spec:
  clusterIP: None

  selector:
    app: mysql

  ports:
    - port: 3306
      targetPort: 3306
```

3. Create a StatefulSet for MySQL with:
   - Image: `mysql:8.0`
   - `envFrom` referencing the Secret
   - Resource requests (cpu: 250m, memory: 512Mi) and limits (cpu: 500m, memory: 1Gi)
   - A `volumeClaimTemplates` section requesting 1Gi of storage, mounted at `/var/lib/mysql`

`mysql-statefulset.yaml`
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql

spec:
  serviceName: mysql

  replicas: 1

  selector:
    matchLabels:
      app: mysql

  template:
    metadata:
      labels:
        app: mysql

    spec:
      containers:
        - name: mysql
          image: mysql:8.0

          envFrom:
            - secretRef:
                name: mysql-secret

          ports:
            - containerPort: 3306

          resources:
            requests:
              cpu: "250m"
              memory: "512Mi"
            limits:
              cpu: "500m"
              memory: "1Gi"

          volumeMounts:
            - name: mysql-data
              mountPath: /var/lib/mysql

  volumeClaimTemplates:
    - metadata:
        name: mysql-data

      spec:
        accessModes:
          - ReadWriteOnce

        resources:
          requests:
            storage: 1Gi
```

   
4. Verify MySQL works: `kubectl exec -it mysql-0 -- mysql -u <user> -p<password> -e "SHOW DATABASES;"`

**Verify:** Can you see the `wordpress` database?

- `YES` if:
 - MySQL pod is Running
 - PVC is Bound
 - wordpress database appears in SHOW DATABASES

<img width="1159" height="594" alt="image" src="https://github.com/user-attachments/assets/87f5a2db-fdb0-4f72-b8d9-010578aa46da" />



---

### Task 3: Deploy WordPress (Days 52, 54, 57)
1. Create a ConfigMap with `WORDPRESS_DB_HOST` set to `mysql-0.mysql.capstone.svc.cluster.local:3306` and `WORDPRESS_DB_NAME`
`wordpress-configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: wordpress-config

data:
  WORDPRESS_DB_HOST: mysql-0.mysql.capstone.svc.cluster.local:3306
  WORDPRESS_DB_NAME: wordpress
```
```bash
ubuntu@ip-172-31-36-28:~/90DaysOfDevOps_TrainWithShubham/2026/day-60/manifests$ kubectl get configmap
NAME               DATA   AGE
kube-root-ca.crt   1      24m
wordpress-config   2      6s
```

2. Create a Deployment with 2 replicas using `wordpress:latest` that:
   - Uses `envFrom` for the ConfigMap
   - Uses `secretKeyRef` for `WORDPRESS_DB_USER` and `WORDPRESS_DB_PASSWORD` from the MySQL Secret
   - Has resource requests and limits
   - Has a liveness probe and readiness probe on `/wp-login.php` port 80

`wordpress-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress

spec:
  replicas: 2

  selector:
    matchLabels:
      app: wordpress

  template:
    metadata:
      labels:
        app: wordpress

    spec:
      containers:
        - name: wordpress
          image: wordpress:latest

          ports:
            - containerPort: 80

          envFrom:
            - configMapRef:
                name: wordpress-config

          env:
            - name: WORDPRESS_DB_USER
              valueFrom:
                secretKeyRef:
                  name: mysql-secret
                  key: MYSQL_USER

            - name: WORDPRESS_DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-secret
                  key: MYSQL_PASSWORD

          resources:
            requests:
              cpu: "200m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"

          livenessProbe:
            httpGet:
              path: /wp-login.php
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 10

          readinessProbe:
            httpGet:
              path: /wp-login.php
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 5
```
   
3. Wait until both pods show `1/1 Running`

```bash
ubuntu@ip-172-31-36-28:~/90DaysOfDevOps_TrainWithShubham/2026/day-60/manifests$ kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
mysql-0                     1/1     Running   0          19m
wordpress-cd98b7bb6-5b62f   1/1     Running   0          39s
wordpress-cd98b7bb6-f4ph8   1/1     Running   0          40s
```

**Verify:** Are both WordPress pods running and ready?
YES — both pods are running and READY (1/1).

<img width="901" height="579" alt="image" src="https://github.com/user-attachments/assets/57bc2380-fb24-4aae-9bcf-88f4146bb981" />


---

### Task 4: Expose WordPress (Day 53)
1. Create a NodePort Service on port 30080 targeting the WordPress pods

`wordpress-service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: wordpress

spec:
  type: NodePort

  selector:
    app: wordpress

  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

2. Access WordPress in your browser:
   - Minikube: `minikube service wordpress -n capstone`
   - Kind: `kubectl port-forward svc/wordpress 8080:80 -n capstone`
3. Complete the setup wizard and create a blog post

**Verify:** Can you see the WordPress setup page?
- Yes

<img width="1920" height="2290" alt="Task 4 - wordpress-11" src="https://github.com/user-attachments/assets/ae5aa6a9-6469-4044-8935-d3f883e7422a" />


---

### Task 5: Test Self-Healing and Persistence
1. Delete a WordPress pod — watch the Deployment recreate it within seconds. Refresh the site.
2. Delete the MySQL pod: `kubectl delete pod mysql-0 -n capstone` — watch the StatefulSet recreate it
3. After MySQL recovers, refresh WordPress — your blog post should still be there

**Verify:** After deleting both pods, is your blog post still there?
Yes, blog post is still there after deleting both pods, because MySQL data is stored in a Persistent Volume attached to the StatefulSet.

<img width="1905" height="1037" alt="image" src="https://github.com/user-attachments/assets/6aba5668-dace-44c5-afae-09353aaad33b" />


---

### Task 6: Set Up HPA (Day 58)
1. Write an HPA manifest targeting the WordPress Deployment with CPU at 50%, min 2, max 10 replicas

`wordpress-hpa.yaml`
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: wordpress-hpa
  namespace: capstone
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: wordpress
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

2. Apply and check: `kubectl get hpa -n capstone`
3. Run `kubectl get all -n capstone` for the complete picture

**Verify:** Does the HPA show correct min/max and target?
- Yes

<img width="823" height="484" alt="image" src="https://github.com/user-attachments/assets/e07dde94-d5f7-43e6-9ca1-3b7c670f569e" />

<img width="487" height="154" alt="image" src="https://github.com/user-attachments/assets/f271f7a4-70a1-462b-bcbd-216d46aaacf1" />


---

### Task 7: (Bonus) Compare with Helm (Day 59)
1. Install WordPress using `helm install wp-helm bitnami/wordpress` in a separate namespace

<img width="780" height="178" alt="image" src="https://github.com/user-attachments/assets/990cbf04-3753-4ca3-97cd-ed647b7f39a6" />


2. Compare: how many resources did each approach create? Which gives more control?
- manual YAML deployment gives more control.

<img width="673" height="180" alt="image" src="https://github.com/user-attachments/assets/fd37740f-7dca-4015-bf86-cb3ef2db91f2" />


<img width="1920" height="1088" alt="image" src="https://github.com/user-attachments/assets/60656eb6-ce38-4554-893b-b93d9ca4e79f" />


```bash
ubuntu@ip-172-31-36-28:~/90DaysOfDevOps_TrainWithShubham/2026/day-60/manifests$ kubectl get all,pvc,secret,configmap,serviceaccount -n helm-wp -o wide
NAME                                     READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
pod/wp-helm-mariadb-0                    1/1     Running   0          10m   10.244.0.13   minikube   <none>           <none>
pod/wp-helm-wordpress-859f4ff7df-fzncx   1/1     Running   0          10m   10.244.0.12   minikube   <none>           <none>

NAME                               TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE   SELECTOR
service/wp-helm-mariadb            ClusterIP      10.100.243.29   <none>        3306/TCP                     10m   app.kubernetes.io/component=primary,app.kubernetes.io/instance=wp-helm,app.kubernetes.io/name=mariadb
service/wp-helm-mariadb-headless   ClusterIP      None            <none>        3306/TCP                     10m   app.kubernetes.io/instance=wp-helm,app.kubernetes.io/name=mariadb,app.kubernetes.io/part-of=mariadb
service/wp-helm-wordpress          LoadBalancer   10.108.39.226   <pending>     80:30324/TCP,443:31087/TCP   10m   app.kubernetes.io/instance=wp-helm,app.kubernetes.io/name=wordpress

NAME                                READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                                          SELECTOR
deployment.apps/wp-helm-wordpress   1/1     1            1           10m   wordpress    registry-1.docker.io/bitnami/wordpress:latest   app.kubernetes.io/instance=wp-helm,app.kubernetes.io/name=wordpress

NAME                                           DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                                          SELECTOR
replicaset.apps/wp-helm-wordpress-859f4ff7df   1         1         1       10m   wordpress    registry-1.docker.io/bitnami/wordpress:latest   app.kubernetes.io/instance=wp-helm,app.kubernetes.io/name=wordpress,pod-template-hash=859f4ff7df

NAME                               READY   AGE   CONTAINERS   IMAGES
statefulset.apps/wp-helm-mariadb   1/1     10m   mariadb      registry-1.docker.io/bitnami/mariadb:latest

NAME                                           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE   VOLUMEMODE
persistentvolumeclaim/data-wp-helm-mariadb-0   Bound    pvc-166b929f-fad4-4afa-ab83-b5c9931ac68b   8Gi        RWO            standard       <unset>                 10m   Filesystem
persistentvolumeclaim/wp-helm-wordpress        Bound    pvc-448d2994-8d03-4514-a262-99e247285f76   10Gi       RWO            standard       <unset>                 10m   Filesystem

NAME                                   TYPE                 DATA   AGE
secret/sh.helm.release.v1.wp-helm.v1   helm.sh/release.v1   1      10m
secret/wp-helm-mariadb                 Opaque               2      10m
secret/wp-helm-wordpress               Opaque               1      10m

NAME                         DATA   AGE
configmap/kube-root-ca.crt   1      10m
configmap/wp-helm-mariadb    1      10m

NAME                               AGE
serviceaccount/default             10m
serviceaccount/wp-helm-mariadb     10m
serviceaccount/wp-helm-wordpress   10m
```
VS

```bash
ubuntu@ip-172-31-36-28:~/90DaysOfDevOps_TrainWithShubham/2026/day-60/manifests$ kubectl get all,pvc,secret,configmap,hpa -n capstone -o wide
NAME                            READY   STATUS    RESTARTS      AGE     IP            NODE       NOMINATED NODE   READINESS GATES
pod/load-generator              1/1     Running   1 (12m ago)   16m     10.244.0.11   minikube   <none>           <none>
pod/mysql-0                     1/1     Running   0             30m     10.244.0.8    minikube   <none>           <none>
pod/wordpress-cd98b7bb6-4rhtw   1/1     Running   0             31m     10.244.0.7    minikube   <none>           <none>
pod/wordpress-cd98b7bb6-f4ph8   1/1     Running   0             3h36m   10.244.0.5    minikube   <none>           <none>

NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE     SELECTOR
service/mysql       ClusterIP   None            <none>        3306/TCP       3h56m   app=mysql
service/wordpress   NodePort    10.104.118.30   <none>        80:30080/TCP   136m    app=wordpress

NAME                        READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES             SELECTOR
deployment.apps/wordpress   2/2     2            2           3h36m   wordpress    wordpress:latest   app=wordpress

NAME                                  DESIRED   CURRENT   READY   AGE     CONTAINERS   IMAGES             SELECTOR
replicaset.apps/wordpress-cd98b7bb6   2         2         2       3h36m   wordpress    wordpress:latest   app=wordpress,pod-template-hash=cd98b7bb6

NAME                     READY   AGE     CONTAINERS   IMAGES
statefulset.apps/mysql   1/1     3h55m   mysql        mysql:8.0

NAME                                                REFERENCE              TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/wordpress-hpa   Deployment/wordpress   cpu: 4%/50%   2         10        2          19m

NAME                                       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE     VOLUMEMODE
persistentvolumeclaim/mysql-data-mysql-0   Bound    pvc-58b54d94-a17d-49dc-8ffb-0466ab710ec8   1Gi        RWO            standard       <unset>                 3h55m   Filesystem

NAME                  TYPE     DATA   AGE
secret/mysql-secret   Opaque   4      3h56m

NAME                         DATA   AGE
configmap/kube-root-ca.crt   1      4h2m
configmap/wordpress-config   2      3h38m
```

<img width="841" height="512" alt="image" src="https://github.com/user-attachments/assets/96bf4d50-7373-4ee5-b4e4-975b651e4296" />


##  Kubernetes vs Helm WordPress Deployment Comparison

###  Resource Comparison Table

| Resource Type | Manual YAML (capstone)    | Helm (wp-helm namespace)                      |
| ------------- | ------------------------- | --------------------------------------------- |
| Pods          | 3 (2 WordPress + 1 MySQL) | 2 (1 WordPress + 1 MariaDB)                   |
| Deployments   | 1 (WordPress)             | 1 (WordPress)                                 |
| StatefulSets  | 1 (MySQL)                 | 1 (MariaDB)                                   |
| ReplicaSets   | 1 (WordPress)             | 1 (WordPress)                                 |
| Services      | 2 (NodePort + ClusterIP)  | 3 (LoadBalancer + ClusterIP + Headless)       |
| HPA           | 1 (WordPress CPU-based)   | 0 (Not enabled by default)                    |
| ConfigMaps    | 1 (wordpress-config)      | 2 (mariadb + app config)                      |
| Secrets       | 1 (mysql-secret)          | 3 (mariadb + wordpress + helm release secret) |
| PVCs          | 1 (MySQL storage)         | 2 (MariaDB + WordPress storage)               |

---

## Key Observations 

### 1. Manual YAML (Capstone)

* Full **control over every resource**
* You explicitly define:

  * HPA
  * NodePort
  * ConfigMaps
  * Scaling logic
* More effort, but **better understanding of Kubernetes internals**

---

### 2. Helm Deployment

* Faster deployment (single command)
* Automatically creates:

  * Secrets
  * PVCs
  * Services (including headless)
  * Default configs
* BUT:

  * Less control unless you override `values.yaml`

---

 **Manual YAML = Learning + Control + Interview-ready understanding**
 **Helm = Production speed + Automation + Standardization**

---

> Manual manifests give deep Kubernetes control, while Helm provides production-ready automation with trade-offs in customization.

---

###  Which approach created more resources?

From your outputs:

####  Manual YAML (capstone)

You created:

* Pods: 3
* Deployments: 1
* StatefulSets: 1
* Services: 2
* HPA: 1
* ConfigMaps: 1
* Secrets: 1
* PVCs: 1
* ReplicaSets: 1

 **Total: ~11–12 Kubernetes resource types (fewer auxiliary objects)**

---

####  Helm (wp-helm)

Helm created:

* Pods: 2
* Deployments: 1
* StatefulSets: 1
* Services: 3 (includes headless service)
* PVCs: 2
* Secrets: 3 (including Helm release secret)
* ConfigMaps: 2
* ServiceAccounts: 3
* ReplicaSets: 1
* Helm release secret (extra metadata object)

 **Total: ~15+ resource objects (more auto-generated components)**

---



##  Which gives more control?

 **Manual YAML (capstone) gives MORE control**

### Why:

* You explicitly define everything:

  * Scaling (HPA)
  * Service type (NodePort)
  * Storage (PVC size, access)
  * Security (Secrets)
* Nothing is hidden — you control every manifest

---

##  Helm (less control, more automation)

### Why:

* Helm auto-generates:

  * Secrets
  * Services
  * PVCs
  * ConfigMaps
* Uses default “best guess” values
* You only control what is exposed via `values.yaml`

---



> The Helm deployment creates more resources automatically due to abstraction and templating, while the manual YAML approach gives fewer but fully controlled resources. Therefore, manual manifests provide greater control and visibility, whereas Helm provides faster and more automated deployments with less granular control.

---


3. Clean up the Helm deployment

```bash
ubuntu@ip-172-31-36-28:~/90DaysOfDevOps_TrainWithShubham/2026/day-60/manifests$ helm uninstall wp-helm -n helm-wp
release "wp-helm" uninstalled
ubuntu@ip-172-31-36-28:~/90DaysOfDevOps_TrainWithShubham/2026/day-60/manifests$ kubectl delete namespace helm-wp
namespace "helm-wp" deleted
ubuntu@ip-172-31-36-28:~/90DaysOfDevOps_TrainWithShubham/2026/day-60/manifests$ kubectl get all -n helm-wp
No resources found in helm-wp namespace.
ubuntu@ip-172-31-36-28:~/90DaysOfDevOps_TrainWithShubham/2026/day-60/manifests$ kubectl get ns
NAME              STATUS   AGE
capstone          Active   4h11m
default           Active   4h20m
kube-node-lease   Active   4h20m
kube-public       Active   4h20m
kube-system       Active   4h20m
ubuntu@ip-172-31-36-28:~/90DaysOfDevOps_TrainWithShubham/2026/day-60/manifests$ kubectl get pvc -n helm-wp
No resources found in helm-wp namespace.
ubuntu@ip-172-31-36-28:~/90DaysOfDevOps_TrainWithShubham/2026/day-60/manifests$ kubectl delete pvc --all -n helm-wp
No resources found
```

<img width="647" height="218" alt="image" src="https://github.com/user-attachments/assets/12c5a857-b575-4951-992f-4aaf4141e398" />


---

### Task 8: Clean Up and Reflect
1. Take a final look: `kubectl get all -n capstone`
2. Count the concepts you used: Namespace, Secret, ConfigMap, PVC, StatefulSet, Headless Service, Deployment, NodePort Service, Resource Limits, Probes, HPA, Helm — twelve concepts in one deployment
3. Delete the namespace: `kubectl delete namespace capstone`
4. Reset default: `kubectl config set-context --current --namespace=default`

**Verify:** Did deleting the namespace remove everything?

---

## Step 1: Final check before deletion

```bash
kubectl get all -n capstone
```

This shows your full WordPress stack:

* Deployment (WordPress)
* StatefulSet (MySQL)
* Services
* Pods
* HPA (if created)
* etc.

---

##  Step 2: Concepts  used

You used **12 Kubernetes + DevOps concepts**:

1. Namespace
2. Secret
3. ConfigMap
4. PVC (Persistent Volume Claim)
5. StatefulSet (MySQL)
6. Headless Service (MySQL)
7. Deployment (WordPress)
8. NodePort Service
9. Resource Limits
10. Probes (Liveness/Readiness)
11. HPA (Horizontal Pod Autoscaler)
12. Helm (comparison deployment)

 This is a **full production-grade Kubernetes workflow**

---

##  Step 3: Delete the entire application

```bash
kubectl delete namespace capstone
```

---

##  Step 4: Wait and verify deletion

Check:

```bash
kubectl get ns
```

Also:

```bash
kubectl get all -n capstone
```

---

##  Expected result

After deletion:

```bash
Error from server (NotFound): namespaces "capstone" not found
```

or

```bash
No resources found in capstone namespace
```

---

##  Step 5: Reset context

```bash
kubectl config set-context --current --namespace=default
```

---



###  Did deleting the namespace remove everything?

**YES**

Because:

* A Kubernetes namespace is a **logical boundary**
* Deleting it removes:

  * Pods
  * Deployments
  * StatefulSets
  * Services
  * Secrets
  * ConfigMaps
  * PVCs (unless storage class retains them)

---

Sometimes:

* PVCs or PVs may remain (depends on storage policy: Retain vs Delete)

But in most lab setups:
 Everything inside the namespace is fully cleaned.

---



> Deleting the namespace successfully removed all resources including deployments, statefulsets, services, secrets, and configmaps. This demonstrates Kubernetes’ namespace-based isolation and cleanup mechanism. The project covered 12 core DevOps and Kubernetes concepts, making it a complete end-to-end container orchestration workflow.

---

<img width="495" height="262" alt="image" src="https://github.com/user-attachments/assets/86ed263a-8fe0-44c7-9e48-b1a3c30e2d8e" />


---




#  1. Architecture of Deployment

##  Resource Flow

```
Users (Browser)
      ↓
NodePort Service (WordPress: 30080)
      ↓
WordPress Deployment (Pods: ReplicaSet)
      ↓
MySQL StatefulSet (Database Pod)
      ↓
Headless Service (MySQL Service Discovery)
      ↓
Persistent Volume Claim (Database Storage)
      ↓
Persistent Volume (Cluster Storage)
```

---

##  Component Mapping

* **WordPress Deployment**

  * Runs application pods
  * Handles scaling via ReplicaSet + HPA

* **MySQL StatefulSet**

  * Ensures stable database identity (mysql-0)
  * Maintains persistent storage

* **Services**

  * NodePort → External access to WordPress
  * ClusterIP → Internal DB communication
  * Headless Service → StatefulSet networking

* **PVC + PV**

  * Stores MySQL data permanently

* **Secrets**

  * Stores DB credentials securely

* **ConfigMap**

  * Stores non-sensitive configuration

---

#  2. Self-Healing & Persistence Results

##  Self-Healing Test

### Action:

* Deleted WordPress pod

### Result:

* ReplicaSet automatically recreated the pod within seconds
* No downtime observed

✔ Kubernetes ensured **desired state = actual state**

---

### Action:

* Deleted MySQL pod (`mysql-0`)

### Result:

* StatefulSet recreated the pod with same identity
* Database remained stable

✔ StatefulSet ensured **stable network identity + recovery**

---

##  Persistence Test

### Action:

* Created blog post in WordPress
* Deleted MySQL pod
* Waited for recreation

### Result:

✔ Blog post was still present after recovery

 Reason:

* Data stored in **Persistent Volume (PVC backed storage)**

---

#  3. Concept vs Learning Day Mapping

| Concept                       | Day Learned |
| ----------------------------- | ----------- |
| Namespace                     | Day 55      |
| Pods                          | Day 55      |
| Deployment                    | Day 56      |
| ReplicaSet                    | Day 56      |
| Service (ClusterIP, NodePort) | Day 56      |
| ConfigMap                     | Day 57      |
| Secret                        | Day 57      |
| Persistent Volume Claim (PVC) | Day 57      |
| StatefulSet                   | Day 58      |
| Headless Service              | Day 58      |
| Resource Limits               | Day 58      |
| Probes (Liveness/Readiness)   | Day 58      |
| HPA (Autoscaling)             | Day 58      |
| Helm                          | Day 59      |

---

#  4. Reflection

##  What was hardest

* Understanding **StatefulSet + MySQL persistence**
* Debugging service connectivity between WordPress and database
* Handling NodePort vs LoadBalancer access differences

---

##  What clicked

* Kubernetes self-healing concept (pods automatically restarting)
* Service discovery using DNS inside cluster
* Clear separation of:

  * Stateless (WordPress)
  * Stateful (MySQL)

---

##  What I would add for production

If this were production-ready, I would add:

* Ingress Controller (NGINX / ALB) instead of NodePort
* TLS/HTTPS using cert-manager
* Central logging (EFK / Loki stack)
* Monitoring (Prometheus + Grafana)
* Backup strategy for MySQL PVC
* CI/CD pipeline (GitHub Actions / ArgoCD)
* Resource quotas per namespace
* Network policies (zero-trust communication)

---

