# Day 78 -- Introduction to Helm and Chart Basics
---

## Challenge Tasks

### Task 1: Understand Helm Concepts
Research and write notes on:

# Task 1 – Understanding Helm Concepts

## What is Helm?

Helm is the package manager for Kubernetes. It simplifies deploying and managing Kubernetes applications by packaging all required Kubernetes resources into reusable packages called **Charts**.

It is similar to package managers like:

* **apt** for Ubuntu
* **yum/dnf** for RHEL/CentOS
* **npm** for Node.js
* **pip** for Python

Instead of manually applying multiple Kubernetes YAML files, Helm allows us to deploy an application using a single command.

Another major advantage of Helm is **templating**. A single Helm chart can be reused across multiple environments (development, staging, and production) by simply changing configuration values instead of maintaining separate YAML files.

---

# Core Concepts

## 1. Chart

A **Chart** is a package that contains everything needed to deploy an application on Kubernetes.

A chart can include templates for:

* Deployment
* Service
* ConfigMap
* Secret
* PersistentVolumeClaim
* Ingress
* Horizontal Pod Autoscaler
* and other Kubernetes resources

Instead of managing these files individually, Helm groups them into a single reusable package.

---

## 2. Release

A **Release** is a deployed instance of a Helm chart inside a Kubernetes cluster.

The same chart can be installed multiple times using different release names.

Example:

```bash
helm install bankapp-dev bitnami/mysql
helm install bankapp-prod bitnami/mysql
```

Here, both releases use the same MySQL chart but represent different deployments.

---

## 3. Repository

A **Repository** is a collection of Helm charts that can be shared and downloaded.

It works similarly to Docker Hub, but instead of storing container images, it stores Helm charts.

Popular repositories include:

* Bitnami
* Prometheus Community
* Grafana
* Argo

Example:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

---

## 4. Values

**Values** are configuration settings used to customize a Helm chart without modifying its templates.

Common values include:

* Number of replicas
* Container image and tag
* CPU and memory requests/limits
* Database credentials
* Persistent storage size

Values can be overridden using:

```bash
--set key=value
```

or by providing a custom `values.yaml` file:

```bash
helm install my-app chart-name -f values.yaml
```

This allows the same chart to be reused across different environments with different configurations.

---

# Why Helm Instead of Raw Kubernetes Manifests?

The AI-BankApp project currently uses around **12 separate Kubernetes YAML files** inside the `k8s/` directory. These include Deployments, Services, ConfigMaps, Secrets, PVCs, and other resources.

Managing these files manually becomes difficult because even a small change, such as updating the application image or changing resource limits, requires editing multiple YAML files.

Helm solves these problems by providing:

### 1. Templating

One Helm chart can be used for multiple environments.

Instead of maintaining separate YAML files for development, staging, and production, different configuration values are supplied through `values.yaml` files.

---

### 2. Versioning

Every Helm chart has a version number, and Helm tracks deployment revisions.

This allows applications to be upgraded safely and rolled back to a previous working version using a single command.

---

### 3. Dependency Management

A Helm chart can depend on other charts.

For example, the AI-BankApp can use the Bitnami MySQL chart as a dependency instead of maintaining a separate MySQL deployment manually.

This makes deployments easier and keeps applications modular.

---

### 4. Community Charts

Helm provides access to thousands of production-ready charts maintained by the community.

Examples include:

* MySQL
* PostgreSQL
* Redis
* Prometheus
* Grafana
* Argo CD
* NGINX Ingress Controller

Instead of writing Kubernetes manifests from scratch, these applications can be deployed with a few Helm commands.

---

# Summary

Helm simplifies Kubernetes application deployment by packaging resources into reusable charts. It supports templating, environment-specific configuration, versioning, rollback, dependency management, and access to a large ecosystem of community-maintained charts. Compared to managing multiple raw Kubernetes manifests, Helm makes deployments more consistent, scalable, and easier to maintain.


---

### Task 2: Install Helm and Explore the AI-BankApp
You need a running Kubernetes cluster. Use any of these:
- **Kind** (recommended for this block): Use the AI-BankApp's Kind config
- **Minikube**: `minikube start`
- **Docker Desktop Kubernetes**: enable in settings

**Set up a Kind cluster using the AI-BankApp's config:**
```bash
git clone -b feat/gitops https://github.com/TrainWithShubham/AI-BankApp-DevOps.git
cd AI-BankApp-DevOps

kind create cluster --config setup-k8s/kind-config.yml
```

This creates a cluster with 1 control plane and 2 worker nodes.

<img width="1332" height="597" alt="image" src="https://github.com/user-attachments/assets/dc98cefd-0e53-4e3f-85ee-a71bab08f032" />


**Install Helm:**
```bash
# macOS
brew install helm

# Linux (script)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
```
<img width="1550" height="272" alt="image" src="https://github.com/user-attachments/assets/9487b8fa-2940-4389-a8b3-220b08921b8e" />


Confirm Helm can talk to your cluster:
```bash
kubectl cluster-info
helm list
```

<img width="1037" height="112" alt="image" src="https://github.com/user-attachments/assets/6727e57a-349e-4f32-94e4-85987b827b80" />
<img width="947" height="47" alt="image" src="https://github.com/user-attachments/assets/e72acdd4-994a-40c6-b1ad-311dde2e4705" />
<img width="945" height="46" alt="image" src="https://github.com/user-attachments/assets/a096ab53-b73d-4251-8415-58413e52d483" />


**Explore the raw manifests you will eventually replace with Helm:**
```bash
ls k8s/
```

```
bankapp-deployment.yml   configmap.yml   gateway.yml   mysql-deployment.yml
namespace.yml   ollama-deployment.yml   pv.yml   pvc.yml   secrets.yml
service.yml   hpa.yml   cert-manager.yml
```

12 files -- Deployments, Services, ConfigMaps, Secrets, PVCs, HPA, and more. All hardcoded values. On Day 79, you will convert these into a Helm chart.

<img width="1006" height="66" alt="image" src="https://github.com/user-attachments/assets/7e1a2885-dee7-4cda-9285-b0cd1a2e7582" />

---

### Task 3: Deploy MySQL Using a Helm Chart
The AI-BankApp needs MySQL. Instead of applying raw YAML like `k8s/mysql-deployment.yml`, deploy it with Helm.

> **Note on Bitnami Charts:**
> Bitnami officially moved most of its versioned container images and Helm charts to a **restricted/paid tier** starting **August 28, 2025**. Free pulls are now rate-limited, and many previously open tags require a Bitnami subscription.
>
> For **learning purposes**, this guide uses `stable/mysql` from the legacy Helm stable repository (`https://charts.helm.sh/stable`) instead of `bitnami/mysql`. The `stable/mysql` chart is **deprecated and no longer maintained**, but it remains freely accessible and is sufficient for understanding Helm concepts like install, upgrade, rollback, and values files.
>
> **For production workloads**, consider:
> - A Bitnami subscription for access to maintained, up-to-date charts
> - The official [MySQL Operator for Kubernetes](https://github.com/mysql/mysql-operator)
> - Community-maintained charts on [Artifact Hub](https://artifacthub.io/)

Add the Bitnami chart repository:
```bash
# helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add stable https://charts.helm.sh/stable
helm repo update
```
<img width="1337" height="182" alt="image" src="https://github.com/user-attachments/assets/0cb00385-8a37-4db6-9cb6-1d81db5d0aa6" />

<img width="1361" height="312" alt="image" src="https://github.com/user-attachments/assets/24322aee-a13d-4d94-8b89-ed7285a95cf6" />

Search for MySQL:
```bash
# helm search repo bitnami/mysql

helm search repo stable/mysql
```
<img width="1352" height="952" alt="image" src="https://github.com/user-attachments/assets/d70cd5f5-1d01-48f0-a672-15f96cef49ec" />



**Deploy MySQL with the same config the AI-BankApp expects:**
```bash
# helm install bankapp-mysql bitnami/mysql \
#   --set auth.rootPassword=Test@123 \
#   --set auth.database=bankappdb \
#   --set primary.resources.requests.memory=256Mi \
#   --set primary.resources.requests.cpu=250m \
#   --set primary.resources.limits.memory=512Mi \
#   --set primary.resources.limits.cpu=500m \
#   --set primary.persistence.size=5Gi



helm install bankapp-mysql-v2 stable/mysql \
  --set mysqlRootPassword=Test@123 \
  --set mysqlDatabase=bankappdb \
  --set image=mysql \
  --set imageTag=8.0 \
  --set metrics.enabled=false

```

<img width="1247" height="67" alt="image" src="https://github.com/user-attachments/assets/0d49dfaf-6451-460b-8162-2d673b9dc7ab" />



Compare this single command to the raw manifest approach which needs `mysql-deployment.yml` + `secrets.yml` + `pvc.yml` + `pv.yml` + `service.yml`. Helm handles all of it.

Check what was created:
```bash
helm list
# kubectl get all -l app.kubernetes.io/instance=bankapp-mysql
# kubectl get pvc -l app.kubernetes.io/instance=bankapp-mysql
# kubectl get secret -l app.kubernetes.io/instance=bankapp-mysql

kubectl get all -l app=bankapp-mysql
kubectl get pvc -l app=bankapp-mysql
kubectl get secret -l app=bankapp-mysql

kubectl get all -l release=bankapp-mysql
kubectl get pvc -l release=bankapp-mysql
kubectl get secret -l release=bankapp-mysql
```

<img width="1315" height="882" alt="image" src="https://github.com/user-attachments/assets/70225898-b178-41a2-9f45-a0be76d47a1d" />



Verify MySQL is running:
```bash
# kubectl exec -it bankapp-mysql-0 -- mysql -uroot -pTest@123 -e "SHOW DATABASES;"

Run:

kubectl exec -it bankapp-mysql-849f6c989f-m7mbw -- \
mysql -uroot -pTest@123 -e "SHOW DATABASES;"

or

kubectl exec -it pod/bankapp-mysql-849f6c989f-m7mbw -- \
mysql -uroot -pTest@123 -e "SHOW DATABASES;"

or

POD=$(kubectl get pods -l app=bankapp-mysql -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it "$POD" -- \
mysql -uroot -pTest@123 -e "SHOW DATABASES;"

```

You should see `bankappdb` in the output.

<img width="1606" height="947" alt="image" src="https://github.com/user-attachments/assets/32659cea-1488-4f17-950a-d62d6969de51" />


---

### Task 4: Customize a Deployment with Values Files
`--set` works for quick overrides, but real projects use values files.

Create `mysql-values.yaml`:
```yaml
# auth:
#   rootPassword: Test@123
#   database: bankappdb
# primary:
#   resources:
#     limits:
#       cpu: 500m
#       memory: 512Mi
#     requests:
#       cpu: 250m
#       memory: 256Mi
#   persistence:
#     size: 5Gi
#     storageClass: ""
# metrics:
#   enabled: true
#   serviceMonitor:
#     enabled: false
```
```yaml
mysqlRootPassword: Test@123
mysqlDatabase: bankappdb
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
persistence:
  size: 5Gi
  storageClass: ""
metrics:
  enabled: true
  serviceMonitor:
    enabled: false
```

Deploy with the values file:
```bash
# /helm install bankapp-mysql-v2 bitnami/mysql -f mysql-values.yaml

helm install bankapp-mysql-v2 stable/mysql -f mysql-values.yml
```

<img width="1492" height="817" alt="image" src="https://github.com/user-attachments/assets/11c5a17d-dbc2-4745-8da6-1890f878f3fb" />
<img width="1312" height="95" alt="image" src="https://github.com/user-attachments/assets/04a9440a-338e-42a7-a310-137d5fcec646" />

<img width="1017" height="90" alt="image" src="https://github.com/user-attachments/assets/1611c44d-a5e3-4815-917f-e08c5fc30935" />


**To see all configurable values for a chart:**
```bash
# helm show values bitnami/mysql | head -80
helm show values stable/mysql | head -80
```

<img width="1261" height="1994" alt="image" src="https://github.com/user-attachments/assets/287870cb-87de-4921-a111-9b25b972ace1" />


This is your reference for every knob you can turn. Notice how the chart supports metrics, replication, custom init scripts, and dozens more options -- all through values.

**Clean up the second release:**
```bash
helm uninstall bankapp-mysql-v2
```

<img width="1127" height="50" alt="image" src="https://github.com/user-attachments/assets/a7fa81f3-e652-4bde-b8bc-561f8480d460" />


---

### Task 5: Manage Releases -- Upgrade, Rollback, Uninstall
Helm tracks every change as a **revision**. This lets you upgrade and rollback safely.

**Upgrade MySQL to enable metrics:**
```bash
# helm upgrade bankapp-mysql bitnami/mysql \
#   --set auth.rootPassword=Test@123 \
#   --set auth.database=bankappdb \
#   --set metrics.enabled=true

helm upgrade bankapp-mysql stable/mysql \
  --set mysqlRootPassword=Test@123 \
  --set mysqlDatabase=bankappdb \
  --reuse-values
```

<img width="1361" height="882" alt="image" src="https://github.com/user-attachments/assets/28233a3f-97d5-4b9a-a827-8f10fc61d0d3" />
<img width="1382" height="156" alt="image" src="https://github.com/user-attachments/assets/f409fcf2-ab91-4cbf-a188-2d22bbda71f9" />


Check the revision history:
```bash
helm history bankapp-mysql
```
<img width="2245" height="197" alt="image" src="https://github.com/user-attachments/assets/b1d8942c-fd4d-431b-b086-879aeb9225e8" />


You should see revision 1 (original) and revision 2 (metrics enabled).

**Rollback to the previous version:**
```bash
helm rollback bankapp-mysql 1
```

Check history again:
```bash
helm history bankapp-mysql
```

Revision 3 appears -- a rollback to revision 1.

<img width="2232" height="282" alt="image" src="https://github.com/user-attachments/assets/ee334f36-7b9e-42a6-91a9-30cfc40e1601" />


**Compare this to raw manifests:** With `kubectl apply`, there is no built-in rollback. You would have to `git revert` or manually re-apply old YAML. Helm gives you `helm rollback` out of the box.

---

### Task 6: Explore a Chart's Structure
Before building your own chart for the AI-BankApp tomorrow, understand what is inside a Helm chart.

Pull the MySQL chart locally:
```bash
helm pull bitnami/mysql --untar
ls mysql/
```

You will see:
```
mysql/
  Chart.yaml              # Chart metadata (name, version, description)
  values.yaml             # Default configuration values
  charts/                 # Subchart dependencies
  templates/              # Kubernetes manifest templates
    primary/
      statefulset.yaml    # StatefulSet template with Go template syntax
      svc.yaml            # Service template
    _helpers.tpl          # Reusable template helpers
    NOTES.txt             # Post-install message shown to the user
    secrets.yaml          # Secret template
```
<img width="1155" height="77" alt="image" src="https://github.com/user-attachments/assets/a70a2171-731d-42de-847e-059fa90aa7b0" />


Open `templates/primary/statefulset.yaml` and look for Go template syntax:
```yaml
replicas: {{ .Values.primary.replicaCount }}
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

<img width="1402" height="902" alt="image" src="https://github.com/user-attachments/assets/4d95f11d-53c7-499f-869b-d039241dc215" />

<img width="1195" height="222" alt="image" src="https://github.com/user-attachments/assets/fc0ac61c-95f0-47c8-9305-03f25055c5e2" />

<img width="1597" height="902" alt="image" src="https://github.com/user-attachments/assets/fb45f201-3bc9-410e-b882-544227840a5a" />


`{{ .Values.primary.replicaCount }}` pulls from `values.yaml`. When you pass `--set primary.replicaCount=3`, it overrides this value.



Open `Chart.yaml`:
```yaml
apiVersion: v2
name: mysql
description: A Helm chart for MySQL
version: 12.2.1      # Chart version (chart structure changes)
appVersion: "8.0.40"  # Version of MySQL inside the chart
```

<img width="1017" height="825" alt="image" src="https://github.com/user-attachments/assets/da45b591-dad9-42a8-9665-6895dd5ecdc5" />


**Now compare the Helm chart approach to the AI-BankApp's raw manifests:**

| Aspect            | AI-BankApp Raw YAML (`k8s/`)                         | Bitnami MySQL Helm Chart                                |
| ----------------- | ---------------------------------------------------- | ------------------------------------------------------- |
| **Secrets**       | Hardcoded in `secrets.yml` (base64 encoded manually) | Automatically generated and securely managed by Helm    |
| **Storage**       | Manually defined `PV` + `PVC` + StorageClass configs | Configured using a single value like `persistence.size` |
| **Replicas**      | Fixed in Deployment YAML                             | Controlled dynamically via `primary.replicaCount`       |
| **Metrics**       | Not included                                         | Optional via `metrics.enabled: true`                    |
| **Configuration** | Spread across 12+ YAML files                         | Centralized in `values.yaml`                            |
| **Rollback**      | Manual (kubectl apply / git revert)                  | Built-in `helm rollback`                                |
| **Reusability**   | Low (copy-paste per environment)                     | High (same chart for dev/staging/prod)                  |
| **Deployment**    | Multiple `kubectl apply -f` commands                 | Single `helm install` command                           |


**Document:** What is the difference between `version` and `appVersion` in Chart.yaml?

- **version (Chart version)**
    - Represents the version of the Helm chart itself
    - Changes when:
     - templates are modified
     - values structure changes
     - chart logic is updated
Example: 1.2.0 → 1.3.0

Think of it as:
> “Version of the packaging (Helm chart)”

- **appVersion (Application version)**
    - Represents the actual application version inside the chart
    - In this case: MySQL version
    - Example: 8.0.40, 9.4.0

Think of it as:
> “Version of the software being installed”
 
  | Field        | Meaning                          |
| ------------ | -------------------------------- |
| `version`    | Helm chart version (packaging)   |
| `appVersion` | Real application version (MySQL) |

- version controls the Helm chart lifecycle, while appVersion tracks the actual software being deployed.

Clean up:
```bash
helm uninstall bankapp-mysql
rm -rf mysql/
```
<img width="1177" height="72" alt="image" src="https://github.com/user-attachments/assets/f5d6c92b-4173-4fc6-bc94-31a35303efb8" />


---



# Documentation

---

# 1. Helm Concepts (in my own words)

## 🔹 Chart

A **Helm Chart** is a packaged collection of Kubernetes manifests.

It is like a “blueprint” that defines everything needed to run an application:

* Deployments
* Services
* ConfigMaps
* Secrets
* PVCs

 Instead of writing many YAML files, a chart bundles everything into one reusable package.

---

## 🔹 Release

A **Release** is a running instance of a Helm chart in a Kubernetes cluster.

* Same chart → can be installed multiple times
* Each installation = a separate release
* Each release has its own name and history

 Example:

* `bankapp-mysql-prod`
* `bankapp-mysql-dev`

Both come from the same chart but behave independently.

---

## 🔹 Repository

A **Helm Repository** is a storage location for charts.

It is like:

* DockerHub → for images
* GitHub → for code
* Helm repo → for charts

Examples:

* Bitnami repo
* Artifact Hub

 You pull charts from repositories using:

```bash
helm repo add
helm repo update
```

---

## 🔹 Values

**Values** are configuration inputs for a Helm chart.

They allow customization without editing YAML files.

Examples:

* database password
* replica count
* image tag
* resource limits

 Values make one chart usable across:

* dev
* staging
* production

---

# 2. MySQL Deployment: Raw YAML vs Helm

| Feature           | Raw Kubernetes YAML (AI-BankApp)     | Helm Chart (MySQL)           |
| ----------------- | ------------------------------------ | ---------------------------- |
| Deployment method | Multiple `kubectl apply -f` commands | Single `helm install`        |
| Configuration     | Hardcoded in YAML files              | Dynamic via `values.yaml`    |
| Secrets           | Manually created and base64 encoded  | Auto-generated and managed   |
| Storage           | Separate PV + PVC YAML files         | One `persistence.size` value |
| Updates           | Manual edits + reapply               | `helm upgrade`               |
| Rollback          | Git or manual restore                | Built-in `helm rollback`     |
| Reusability       | Low                                  | High                         |
| Complexity        | High (12+ YAML files)                | Low (single chart)           |

---

# 3. My `mysql-values.yaml`

```yaml
mysqlRootPassword: Test@123
mysqlDatabase: bankappdb

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

persistence:
  size: 5Gi
  storageClass: ""

metrics:
  enabled: true
  serviceMonitor:
    enabled: false
```

---

## 🔹 Explanation of each field

###  mysqlRootPassword

* Password for MySQL root user
* Required for authentication

---

###  mysqlDatabase

* Database automatically created on startup
* Used by AI-BankApp

---

###  resources

Controls CPU and memory usage:

* **requests** → minimum guaranteed resources
* **limits** → maximum allowed resources

---

### persistence

Defines storage for MySQL data:

* `size`: storage allocated (5Gi)
* `storageClass`: storage backend (default cluster storage if empty)

---

###  metrics

Enables monitoring support:

* `enabled`: turns on metrics exporter
* `serviceMonitor`: integrates with Prometheus Operator

---

# 4. Helm Chart Directory Structure

When you run:

```bash
helm pull bitnami/mysql --untar
```

You get:

---

##  Chart.yaml

* Metadata file
* Contains:

  * chart name
  * chart version
  * app version

---

##  values.yaml

* Default configuration file
* Can be overridden using:

  * `--set`
  * `-f values.yaml`

---

##  templates/

* Contains Kubernetes YAML templates
* Uses Go templating syntax

Example:

```yaml
replicas: {{ .Values.primary.replicaCount }}
```

 This makes YAML dynamic instead of static.

---

##  charts/

* Contains dependent sub-charts
* Used when one chart depends on another

---

##  _helpers.tpl

* Reusable template functions
* Avoids duplication of logic

---

##  NOTES.txt

* Printed after installation
* Gives usage instructions to user

---

##  values.schema.json

* Validates values.yaml inputs
* Prevents invalid configuration

---

# 5. Why AI-BankApp (12 YAML files) should become a Helm Chart

The current AI-BankApp structure has:

```
12 separate YAML files:
- Deployment
- Service
- ConfigMap
- Secret
- PVC
- PV
- HPA
- Gateway
- Namespace
- etc.
```

---

##  Problems with current approach

### 1. Too many files

Hard to manage and understand

---

### 2. No reuse

Cannot reuse same setup for dev/staging/prod easily

---

### 3. Manual updates

Changing image or password requires editing multiple files

---

### 4. No rollback system

You must manually revert changes

---

### 5. Hard environment management

Each environment needs separate YAML duplication

---

##  Benefits of Helm conversion

### 1. Single package

Entire app becomes one chart

---

### 2. Environment flexibility

Same chart works for:

* dev
* staging
* production

using different values files

---

### 3. Easy upgrades

```bash
helm upgrade
```

---

### 4. Built-in rollback

```bash
helm rollback
```

---

### 5. Centralized configuration

All configs controlled via `values.yaml`

---

### 6. Reusability

Chart can be shared across teams or projects

---

#  Final Summary

Helm transforms Kubernetes from:

>  “many static YAML files”

to

>  “one reusable, configurable, versioned package”

