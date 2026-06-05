# Day 59 – Helm — Kubernetes Package Manager
---

## Challenge Tasks

### Task 1: Install Helm
1. Install Helm (brew, curl script, or chocolatey depending on your OS)

Installed Helm on Ubuntu:

```bash
curl -LO https://get.helm.sh/helm-v4.1.3-linux-amd64.tar.gz
tar -zxvf helm-v4.1.3-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
```
2. Verify with `helm version` and `helm env`

Three core concepts:
- **Chart** — a package of Kubernetes manifest templates
- **Release** — a specific installation of a chart in your cluster
- **Repository** — a collection of charts (like a package repo)

**Verify:** What version of Helm is installed?
- Installed Helm Version: v4.1.3

<img width="1784" height="817" alt="image" src="https://github.com/user-attachments/assets/056ef831-7e84-4ebb-bd45-6a728f85444f" />



---

### Task 2: Add a Repository and Search
1. Add the Bitnami repository: `helm repo add bitnami https://charts.bitnami.com/bitnami`
2. Update: `helm repo update`
3. Search: `helm search repo nginx` and `helm search repo bitnami`

**Verify:** How many charts does Bitnami have?
```bash
helm search repo bitnami | wc -l
```
Output:
`145`

and then:

Counted available Bitnami charts:
```bash
helm search repo bitnami | tail -n +2 | wc -l
```

Output:
`144`

Result:
Bitnami currently has 144 charts available (excluding the header row).

<img width="955" height="227" alt="image" src="https://github.com/user-attachments/assets/f45eda03-6ac0-4784-ae0b-8f5ea017eea9" />


---

### Task 3: Install a Chart
1. Deploy nginx: `helm install my-nginx bitnami/nginx`

<img width="842" height="173" alt="image" src="https://github.com/user-attachments/assets/b82b9627-9dda-4576-ac77-f8d79fb73000" />


2. Check what was created: `kubectl get all`

<img width="797" height="184" alt="image" src="https://github.com/user-attachments/assets/3700cb24-d62c-45f7-91c6-6de22ab6071a" />


3. Inspect the release: `helm list`, `helm status my-nginx`, `helm get manifest my-nginx`

- `helm list` Lists all Helm releases in the current namespace

<img width="931" height="47" alt="image" src="https://github.com/user-attachments/assets/f69754db-e9cd-42eb-9c2b-0727d0a74d10" />



- `helm status my-nginx` Shows the current status (deployed, failed, etc.) of the my-nginx

<img width="1299" height="896" alt="image" src="https://github.com/user-attachments/assets/daca7a5f-bb65-4643-a470-0eb728e50002" />



- `helm get manifest my-nginx` Displays the Kubernetes YAML manifests generated for the my-nginx release

<img width="565" height="838" alt="image" src="https://github.com/user-attachments/assets/8b76ef5f-7596-46b4-a7a7-742771b00a5b" />



One command replaced writing a Deployment, Service, and ConfigMap by hand.

**Verify:** How many Pods are running? What Service type was created?

Output:

```text
pod/my-nginx-6b69d887f4-hs69f   1/1 Running
```

✅ **Pods Running:** **1**

---

From your Service output:

```text
service/my-nginx     LoadBalancer
```

✅ **Service Type:** **LoadBalancer**

---

### Why is it LoadBalancer and not ClusterIP?

The current Bitnami NGINX chart version defaults to:

```yaml
service:
  type: LoadBalancer
```

On Minikube, you'll see:

```text
EXTERNAL-IP   <pending>
```

because Minikube doesn't automatically provision cloud load balancers like AWS, Azure, or GCP.

---

### Verification

Pods Running: 1

Service Type: LoadBalancer
```

### Resources Helm Created

From `kubectl get all`:

* Deployment: `my-nginx`
* ReplicaSet: `my-nginx-6b69d887f4`
* Pod: `my-nginx-6b69d887f4-hs69f`
* Service: `my-nginx` (LoadBalancer)

This demonstrates the key Helm benefit: **one command created multiple Kubernetes resources instead of writing separate YAML files for Deployment, Service, and related objects.**


---

### Task 4: Customize with Values
1. View defaults: `helm show values bitnami/nginx`
2. Install a custom release with `--set replicaCount=3 --set service.type=NodePort`

<img width="1320" height="801" alt="image" src="https://github.com/user-attachments/assets/fe79f3e9-bb3d-439f-933c-ea4588bce183" />



3. Create a `custom-values.yaml` file with replicaCount, service type, and resource limits
<img width="743" height="185" alt="image" src="https://github.com/user-attachments/assets/273c97cc-8a4d-4122-8ec0-288575253c76" />

4. Install another release using `-f custom-values.yaml`

<img width="1002" height="178" alt="image" src="https://github.com/user-attachments/assets/14892df2-73f7-475b-90d2-b4fbba054c9f" />


5. Check overrides: `helm get values <release-name>`

<img width="770" height="171" alt="image" src="https://github.com/user-attachments/assets/99d7d131-24ee-44b5-8ed6-acd4b1dbe7f5" />


**Verify:** Does the values file release have the correct replicas and service type? 


Output:

#### User-supplied values

```yaml
replicaCount: 3

service:
  type: NodePort

resources:
  limits:
    cpu: 200m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

#### Deployment

```text
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
nginx-values   3/3     3            3           16m
```

 **Replicas = 3**

#### Service

```text
NAME           TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)
nginx-values   NodePort   10.99.241.125   <none>        80:31538/TCP,443:30711/TCP
```

 **Service Type = NodePort**

---

## Verification Answer

**Does the values file release have the correct replicas and service type?**

**Yes.** The release installed using `custom-values.yaml` was deployed with:
* **3 replicas**
* **NodePort service**
exactly as defined in the values file.

---

### Verification

The release installed using `custom-values.yaml` correctly applied all overrides:

- Replicas: 3
- Service Type: NodePort
- CPU Limit: 200m
- Memory Limit: 256Mi
- CPU Request: 100m
- Memory Request: 128Mi

Output:

Deployment:
READY 3/3

Service:
TYPE NodePort


### Learned

* `helm show values` displays default chart settings.
* `--set` is useful for quick one-off overrides.
* `custom-values.yaml` is preferred for reproducible deployments.
* `helm get values <release>` shows the values applied to a release.
* Values files make Helm charts reusable across environments (dev, staging, production).



---

### Task 5: Upgrade and Rollback
1. Upgrade: `helm upgrade my-nginx bitnami/nginx --set replicaCount=5`

<img width="985" height="218" alt="image" src="https://github.com/user-attachments/assets/e1569b5e-9720-4a2b-a5df-3c662b112ee7" />


2. Check history: `helm history my-nginx`
3. Rollback: `helm rollback my-nginx 1`
4. Check history again — rollback creates a new revision (3), not overwriting revision 2

<img width="832" height="155" alt="image" src="https://github.com/user-attachments/assets/ed9fea90-1264-4097-99b6-935229a67746" />


Same concept as Deployment rollouts from Day 52, but at the full stack level.

**Verify:** How many revisions after the rollback?



### Upgrade Verification

Before rollback, your deployment showed:

```text
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
my-nginx   5/5     5            5           34m
```

This confirms the upgrade:

```bash
helm upgrade my-nginx bitnami/nginx --set replicaCount=5
```

worked correctly and scaled the deployment to **5 replicas**.

---

### History Before Rollback

```text
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         deployed    Upgrade complete
```

* Revision 1 = Initial install
* Revision 2 = Upgrade to 5 replicas

---

### Rollback

```bash
helm rollback my-nginx 1
```

Output:

```text
Rollback was a success! Happy Helming!
```

---

### History After Rollback

```text
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         superseded  Upgrade complete
3         deployed    Rollback to 1
```

This demonstrates an important Helm concept:

> A rollback creates a **new revision** instead of overwriting an existing one.

---

## Verification Answer

**How many revisions after the rollback?**

✅ **3 revisions**

| Revision | Description            |
| -------- | ---------------------- |
| 1        | Initial installation   |
| 2        | Upgrade to 5 replicas  |
| 3        | Rollback to revision 1 |

---




---

### Task 6: Create Your Own Chart
1. Scaffold: `helm create my-app`
2. Explore the directory: `Chart.yaml`, `values.yaml`, `templates/deployment.yaml`

<img width="809" height="381" alt="image" src="https://github.com/user-attachments/assets/f4a2eebc-3688-4d21-b925-4748bcec78df" />


3. Look at the Go template syntax in templates: `{{ .Values.replicaCount }}`, `{{ .Chart.Name }}`

<img width="955" height="1006" alt="image" src="https://github.com/user-attachments/assets/051cf4f4-00ad-41cd-950b-9635f553c612" />


4. Edit `values.yaml` — set replicaCount to 3 and image to nginx:1.25

<img width="431" height="16" alt="image" src="https://github.com/user-attachments/assets/387d7fab-f26e-4cad-9e38-12c3467c7ace" />

<img width="530" height="14" alt="image" src="https://github.com/user-attachments/assets/20cdf54d-4e9e-449a-9609-60b3ee383786" />


5. Validate: `helm lint my-app`

<img width="406" height="35" alt="image" src="https://github.com/user-attachments/assets/161c33b8-dd08-4dd0-87c4-23d3d728cfd9" />


6. Preview: `helm template my-release ./my-app`
7. Install: `helm install my-release ./my-app`

<img width="607" height="92" alt="image" src="https://github.com/user-attachments/assets/fabe8211-7104-4719-a5ae-8b7706fbd290" />


8. Upgrade: `helm upgrade my-release ./my-app --set replicaCount=5`

<img width="608" height="319" alt="image" src="https://github.com/user-attachments/assets/bc6a3fb0-d3bf-4136-8921-d584c9d7616c" />


**Verify:** After installing, 3 replicas? After upgrading, 5?
- Yes

Initial installation: 3 replicas 
After upgrade: 5 replicas 

---

### Task 7: Clean Up
1. Uninstall all releases: `helm uninstall <name>` for each
2. Remove chart directory and values file
3. Use `--keep-history` if you want to retain release history for auditing

**Verify:** Does `helm list` show zero releases?
After uninstalling all releases, yes, helm list should return an empty list (no Helm releases present).

<img width="693" height="223" alt="image" src="https://github.com/user-attachments/assets/b3a0b10b-d69e-4e84-bf5f-a79773b70387" />


---


## What is Helm?

Helm is the package manager for Kubernetes. It simplifies deploying and managing applications by packaging Kubernetes manifests into reusable units called **Charts**.

Instead of creating multiple YAML files manually (Deployments, Services, ConfigMaps, Secrets, PVCs, etc.), Helm allows you to deploy and manage an entire application stack with a single command.

### Three Core Concepts

#### 1. Chart

A **Chart** is a package containing Kubernetes resource templates and configuration values.

Examples:

```bash
bitnami/nginx
bitnami/mysql
```

A chart includes:

* Deployment templates
* Service templates
* ConfigMaps
* Ingress definitions
* Default configuration values

---

#### 2. Release

A **Release** is a running instance of a chart in a Kubernetes cluster.

Example:

```bash
helm install my-nginx bitnami/nginx
```

Here:

* Chart = `bitnami/nginx`
* Release = `my-nginx`

Multiple releases can be created from the same chart.

---

#### 3. Repository

A **Repository** is a collection of Helm charts.

Example:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

Popular repositories:

* Bitnami
* Prometheus Community
* Grafana
* Elastic

---

# Installing Helm

### Install Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Upgraded to the latest version:

```bash
curl -LO https://get.helm.sh/helm-v4.1.3-linux-amd64.tar.gz
tar -zxvf helm-v4.1.3-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
```

### Verify Installation

```bash
helm version
```

Output:

```text
Version: v4.1.3
```

Check environment:

```bash
helm env
```

---

# Working with Helm Charts

## Add Repository

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

Search charts:

```bash
helm search repo nginx
helm search repo bitnami
```

---

## Install a Chart

Install NGINX:

```bash
helm install my-nginx bitnami/nginx
```

Verify:

```bash
kubectl get all
helm list
helm status my-nginx
```

Result:

* 1 Pod running
* Service Type: LoadBalancer

---

# Customizing Helm Deployments

Helm charts expose configurable values through `values.yaml`.

View defaults:

```bash
helm show values bitnami/nginx
```

---

## Override Using --set

```bash
helm install nginx-nodeport bitnami/nginx \
  --set replicaCount=3 \
  --set service.type=NodePort
```

---

## Using a Values File

### custom-values.yaml

```yaml
replicaCount: 3

service:
  type: NodePort

resources:
  requests:
    cpu: 100m
    memory: 128Mi

  limits:
    cpu: 200m
    memory: 256Mi
```

### Explanation

#### replicaCount

```yaml
replicaCount: 3
```

Creates three pod replicas.

---

#### service.type

```yaml
service:
  type: NodePort
```

Exposes the application through a NodePort service.

---

#### resources.requests

```yaml
requests:
  cpu: 100m
  memory: 128Mi
```

Minimum resources guaranteed to the container.

---

#### resources.limits

```yaml
limits:
  cpu: 200m
  memory: 256Mi
```

Maximum resources the container can consume.

---

Install using the values file:

```bash
helm install nginx-values bitnami/nginx -f custom-values.yaml
```

Verify:

```bash
helm get values nginx-values
kubectl get deployment nginx-values
kubectl get svc nginx-values
```

Result:

* Replicas: 3
* Service Type: NodePort

---

# Upgrading and Rolling Back Releases

## Upgrade

Increase replicas:

```bash
helm upgrade my-nginx bitnami/nginx --set replicaCount=5
```

Check history:

```bash
helm history my-nginx
```

---

## Rollback

Rollback to Revision 1:

```bash
helm rollback my-nginx 1
```

Check history again:

```bash
helm history my-nginx
```

Output:

```text
REVISION  STATUS
1         superseded
2         superseded
3         deployed
```

### Result

Rollback creates a new revision instead of overwriting previous revisions.

Total revisions after rollback:

```text
3
```

---

# Creating a Custom Helm Chart

Create a chart:

```bash
helm create my-app
```

Generated structure:

```text
my-app/
├── Chart.yaml
├── values.yaml
├── charts/
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    └── ...
```

---

## Helm Chart Structure

### Chart.yaml

Contains chart metadata.

Example:

```yaml
apiVersion: v2
name: my-app
version: 0.1.0
```

---

### values.yaml

Stores default configuration values.

Example:

```yaml
replicaCount: 3

image:
  repository: nginx
  tag: "1.25"
```

---

### templates/

Contains Kubernetes manifest templates.

Examples:

* deployment.yaml
* service.yaml
* ingress.yaml

---

# Go Templating in Helm

Helm uses the Go Template Engine.

### Values

```yaml
replicaCount: 3
```

Referenced as:

```yaml
replicas: {{ .Values.replicaCount }}
```

---

### Chart Metadata

```yaml
{{ .Chart.Name }}
```

Returns:

```text
my-app
```

---

### Release Name

```yaml
{{ .Release.Name }}
```

Returns:

```text
my-release
```

---

### Common Template Variables

| Template                   | Description        |
| -------------------------- | ------------------ |
| `{{ .Values.key }}`        | Access values.yaml |
| `{{ .Chart.Name }}`        | Chart name         |
| `{{ .Release.Name }}`      | Release name       |
| `{{ .Release.Namespace }}` | Namespace          |
| `{{ .Chart.Version }}`     | Chart version      |

---

# Validate and Preview

Validate chart:

```bash
helm lint my-app
```

Render manifests without installing:

```bash
helm template my-release ./my-app
```

---

# Install and Upgrade Custom Chart

Install:

```bash
helm install my-release ./my-app
```

Verification:

```bash
kubectl get deployment my-release-my-app
```

Result:

```text
3 replicas running
```

Upgrade:

```bash
helm upgrade my-release ./my-app --set replicaCount=5
```

Verification:

```bash
kubectl get deployment my-release-my-app
```

Result:

```text
5 replicas running
```

---

# Cleanup

Uninstall releases:

```bash
helm uninstall my-release
helm uninstall my-nginx
helm uninstall nginx-nodeport
helm uninstall nginx-values
```

Remove files:

```bash
rm -rf my-app
rm -f custom-values.yaml
```

Verify:

```bash
helm list
```

Result:

```text
No releases found.
```

---

# Key Learnings

* Helm is the package manager for Kubernetes.
* A Chart packages Kubernetes manifests.
* A Release is a deployed chart instance.
* A Repository stores charts.
* Values can be customized using `--set` or `values.yaml`.
* Helm supports upgrades and rollbacks through revision history.
* Custom charts can be created using `helm create`.
* Go templates make charts reusable and configurable.
* One Helm command can deploy an entire Kubernetes application stack.
