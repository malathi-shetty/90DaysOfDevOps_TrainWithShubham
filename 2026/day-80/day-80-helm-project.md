# Day 80 -- Helm Project: Multi-Environment Deployment and CI/CD

---

## Challenge Tasks

### Task 1: Create Environment-Specific Values
One chart, three environments. The AI-BankApp runs differently in dev vs production.

Create `bankapp/values-dev.yaml`:
```yaml
bankapp:
  replicaCount: 1
  image:
    repository: trainwithshubham/ai-bankapp-eks
    tag: "latest"
    pullPolicy: Always
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "250m"
  autoscaling:
    enabled: false

mysql:
  enabled: true
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "250m"
  persistence:
    size: 2Gi
    storageClass: standard

ollama:
  enabled: true
  model: tinyllama
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "1.5Gi"
      cpu: "1000m"
  persistence:
    size: 5Gi
    storageClass: standard

storageClass:
  create: false
```

Create `bankapp/values-staging.yaml`:
```yaml
bankapp:
  replicaCount: 2
  image:
    repository: trainwithshubham/ai-bankapp-eks
    tag: "v1.2.0"
    pullPolicy: IfNotPresent
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 3
    targetCPUUtilization: 75

mysql:
  enabled: true
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  persistence:
    size: 5Gi
    storageClass: gp3

ollama:
  enabled: true
  model: tinyllama
  persistence:
    size: 10Gi
    storageClass: gp3

secrets:
  mysqlRootPassword: StagingPass@456
  mysqlUser: root
  mysqlPassword: StagingPass@456

storageClass:
  create: true
```

Create `bankapp/values-prod.yaml`:
```yaml
bankapp:
  replicaCount: 4
  image:
    repository: trainwithshubham/ai-bankapp-eks
    tag: "v1.2.0"
    pullPolicy: IfNotPresent
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 4
    targetCPUUtilization: 70

mysql:
  enabled: true
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
  persistence:
    size: 20Gi
    storageClass: gp3

ollama:
  enabled: true
  model: tinyllama
  resources:
    requests:
      memory: "2Gi"
      cpu: "900m"
    limits:
      memory: "2.5Gi"
      cpu: "1500m"
  persistence:
    size: 10Gi
    storageClass: gp3

secrets:
  mysqlRootPassword: ProdSecure@789
  mysqlUser: root
  mysqlPassword: ProdSecure@789

storageClass:
  create: true

gateway:
  enabled: true
```

**Compare the environments:**

| Setting | Dev | Staging | Prod |
|---------|-----|---------|------|
| BankApp replicas | 1 (fixed) | 2-3 (HPA) | 2-4 (HPA) |
| Image tag | latest | v1.2.0 | v1.2.0 |
| MySQL storage | 2Gi | 5Gi | 20Gi |
| MySQL resources | 128Mi/100m | 256Mi/250m | 512Mi/500m |
| Ollama memory | 1Gi | 2Gi | 2.5Gi |
| Gateway | disabled | disabled | enabled |

**Deploy to different environments:**

# Dev (on Kind)
helm install bankapp-dev bankapp/ -f bankapp/values-dev.yaml -n dev --create-namespace

<img width="1006" height="447" alt="image" src="https://github.com/user-attachments/assets/f5d24fe1-26b4-4af7-9272-c174f780cef4" />
<img width="1201" height="1106" alt="environment" src="https://github.com/user-attachments/assets/5ccbff8c-7079-4795-9600-8beaac012eef" />


# Staging (render to check)
helm template bankapp-staging bankapp/ -f bankapp/values-staging.yaml | grep "replicas:"

# Prod (render to check)
helm template bankapp-prod bankapp/ -f bankapp/values-prod.yaml | grep "replicas:"

Same chart, wildly different deployments.

<img width="1572" height="311" alt="replicas" src="https://github.com/user-attachments/assets/18955770-6bde-44e9-af8d-98cd4adcdb02" />



---

### Task 2: Add Helm Hooks
The AI-BankApp uses init containers to wait for MySQL. Helm hooks offer another approach -- running pre-install jobs.

Create `bankapp/templates/pre-install-job.yaml`:
```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "bankapp.fullname" . }}-db-ready
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": pre-install,pre-upgrade
    "helm.sh/hook-weight": "0"
    "helm.sh/hook-delete-policy": before-hook-creation
spec:
  template:
    spec:
      containers:
        - name: db-check
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - |
              echo "Waiting for MySQL to be ready..."
              until nc -z {{ include "bankapp.fullname" . }}-mysql 3306; do
                echo "MySQL not ready, retrying in 3s..."
                sleep 3
              done
              echo "MySQL is ready!"
          resources:
            requests: { memory: "32Mi", cpu: "50m" }
            limits: { memory: "64Mi", cpu: "100m" }
      restartPolicy: Never
  backoffLimit: 10
```

**How hooks work in the AI-BankApp context:**
- `helm.sh/hook: pre-install,pre-upgrade` -- runs before install and before upgrade
- This ensures MySQL is up before the BankApp Deployment is created
- `before-hook-creation` -- deletes the old job before creating a new one on re-runs
- Combined with init containers in the Deployment, this provides defense-in-depth

**Other useful hook types:**
- `post-install` -- run database migrations after deploy
- `pre-delete` -- backup database before teardown
- `test` -- runs when you execute `helm test`

<img width="1095" height="137" alt="image" src="https://github.com/user-attachments/assets/d1fda7cc-120e-4733-984f-279e67680822" />
<img width="1092" height="507" alt="image" src="https://github.com/user-attachments/assets/cd4edf39-afa1-4f13-a771-c49656ff9441" />


**Add a Helm test:**

Create `bankapp/templates/tests/test-connection.yaml`:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: {{ include "bankapp.fullname" . }}-test
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
  annotations:
    "helm.sh/hook": test
spec:
  containers:
    - name: test
      image: busybox:1.36
      command: ['sh', '-c', 'wget -qO- http://{{ include "bankapp.fullname" . }}-service:8080/actuator/health']
  restartPolicy: Never
```

<img width="1306" height="887" alt="image" src="https://github.com/user-attachments/assets/80fc49f4-cefc-472d-8deb-eedc7803c11b" />


After deploying, run:
```bash
helm test bankapp-dev -n dev
```

<img width="1025" height="332" alt="image" src="https://github.com/user-attachments/assets/f4a4d3f7-b263-45de-82a4-c2de6e37bdf7" />


This hits the Spring Boot health endpoint and confirms the app is running.

```bash
kubectl port-forward svc/bankapp-dev-service 8080:8080 -n dev
```
Browser: `http://localhost:8080/actuator/health`

<img width="1330" height="476" alt="image" src="https://github.com/user-attachments/assets/3d269f61-a40b-4eaa-99b9-a8bcd4facd4e" />


---

### Task 3: Package and Version the Chart
Package the chart into a distributable `.tgz` file:

```bash
# Lint first
helm lint bankapp/

# Package
helm package bankapp/
```


This creates `bankapp-0.1.0.tgz`.

**Bump the version after changes:**
Edit `bankapp/Chart.yaml`:
```yaml
version: 0.2.0        # Chart structure changed (added hooks)
appVersion: "1.1.0"    # App version updated
```

Re-package:
```bash
helm package bankapp/
```

Now you have `bankapp-0.1.0.tgz` and `bankapp-0.2.0.tgz`.

<img width="1301" height="202" alt="image" src="https://github.com/user-attachments/assets/d4d1e88f-7605-41cb-b769-40f26d37418e" />


**Install from a package:**
```bash
helm install my-bankapp bankapp-0.2.0.tgz -f bankapp/values-dev.yaml -n bankapp --create-namespace
```
<img width="1162" height="67" alt="image" src="https://github.com/user-attachments/assets/dbdde297-b68f-469e-adae-4d580b6ba2d1" />
<img width="1325" height="841" alt="image" src="https://github.com/user-attachments/assets/c9fcea49-1a18-4483-9a4c-6481ef571c7a" />


**Create a chart repository index** (for sharing via GitHub Pages):
```bash
mkdir chart-repo
cp bankapp-*.tgz chart-repo/
helm repo index chart-repo/ --url https://your-username.github.io/helm-charts
helm repo index chart-repo/ --url https://srdangat.github.io/helm-charts
cat chart-repo/index.yaml
```

<img width="1222" height="312" alt="image" src="https://github.com/user-attachments/assets/ddfe0f1b-7562-47b9-b077-80f88ec624d7" />
<img width="1087" height="992" alt="image" src="https://github.com/user-attachments/assets/70ffc0f3-f96a-4d72-8a32-9e5301425fe2" />

https://malathi-shetty.github.io/90DaysOfDevOps_TrainWithShubham/2026/day-80/helm-chart/chart-repo/index.yaml

---

### Task 4: Understand Helm in the AI-BankApp GitOps Pipeline
The AI-BankApp uses a GitOps pipeline. Study how Helm could integrate:

**Current pipeline (from `.github/workflows/gitops-ci.yml`):**
```
Developer pushes code
  -> GitHub Actions builds Docker image
  -> Tags with git commit SHA
  -> Updates image tag in k8s/bankapp-deployment.yml via sed
  -> Commits the change back to the repo
  -> ArgoCD detects the change and syncs to EKS
```

**With Helm, the pipeline becomes:**
```
Developer pushes code
  -> GitHub Actions builds Docker image
  -> Tags with git commit SHA
  -> Updates image.tag in helm-chart/values.yaml (or values-prod.yaml)
  -> Commits the change back to the repo
  -> ArgoCD detects the change and runs helm upgrade on EKS
```

Here is how the CI step would look with Helm (reference pattern):
```yaml
# In the GitHub Actions workflow
- name: Update Helm values with new image tag
  run: |
    TAG=${{ steps.tag.outputs.sha_short }}
    yq -i '.bankapp.image.tag = "'$TAG'"' helm-chart/bankapp/values-prod.yaml

- name: Commit updated Helm values
  run: |
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add helm-chart/bankapp/values-prod.yaml
    git diff --staged --quiet || git commit -m "ci: update bankapp image to $TAG [skip ci]"
    git push
```

**ArgoCD with Helm** (the ArgoCD Application would change from):
```yaml
# Current: raw manifests
source:
  path: k8s
```

To:
```yaml
# With Helm
source:
  path: helm-chart/bankapp
  helm:
    valueFiles:
      - values-prod.yaml
```

ArgoCD natively supports Helm charts -- it renders templates and applies the result, tracking drift against the rendered output.

**Document:** What are the advantages of ArgoCD syncing a Helm chart vs raw manifests?


### Current GitOps Pipeline (Raw Kubernetes Manifests)

```
Developer pushes code
        │
        ▼
GitHub Actions builds Docker image
        │
        ▼
Image tagged with Git commit SHA
        │
        ▼
Updates k8s/bankapp-deployment.yml
(using sed)
        │
        ▼
Commits updated manifest
        │
        ▼
ArgoCD detects Git change
        │
        ▼
Applies Kubernetes manifests to EKS
```

---

## GitOps Pipeline with Helm

```
Developer pushes code
        │
        ▼
GitHub Actions builds Docker image
        │
        ▼
Image tagged with Git commit SHA
        │
        ▼
Updates image.tag in values-prod.yaml
        │
        ▼
Commits updated values file
        │
        ▼
ArgoCD detects Git change
        │
        ▼
Renders Helm templates
        │
        ▼
Deploys updated resources to EKS
```

---

## Example CI Step

Instead of modifying a Deployment manifest directly:

```yaml
- name: Update Helm values
  run: |
    TAG=${{ steps.tag.outputs.sha_short }}
    yq -i '.bankapp.image.tag = "'$TAG'"' helm-chart/bankapp/values-prod.yaml
```

Then commit the updated values file:

```yaml
git add helm-chart/bankapp/values-prod.yaml
git commit -m "ci: update image to $TAG"
git push
```

---

## ArgoCD Configuration

### Before (Raw Manifests)

```yaml
source:
  path: k8s
```

### After (Helm)

```yaml
source:
  path: helm-chart/bankapp
  helm:
    valueFiles:
      - values-prod.yaml
```

ArgoCD automatically renders the Helm templates using the selected values file and applies the generated Kubernetes manifests to the cluster.

---

# Advantages of ArgoCD Syncing a Helm Chart vs Raw Manifests

| Raw Manifests                                                       | Helm Chart                                                                                                               |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Separate YAML files must be edited individually.                    | Configuration is centralized in `values.yaml` or environment-specific values files.                                      |
| Updating image tags requires editing Deployment manifests directly. | Only the image tag in `values-prod.yaml` needs to be updated.                                                            |
| Repeated configuration leads to duplication.                        | Helm templates eliminate duplication using reusable templates.                                                           |
| Managing multiple environments is difficult.                        | Separate values files (`values-dev.yaml`, `values-staging.yaml`, `values-prod.yaml`) make environment management simple. |
| Changes often require modifying multiple manifest files.            | One values file change updates all rendered resources.                                                                   |
| Less reusable across projects.                                      | Helm charts are portable and reusable across multiple clusters and environments.                                         |
| No built-in package versioning.                                     | Helm packages applications as versioned charts.                                                                          |
| Manual consistency between manifests.                               | Templates ensure consistent resource definitions.                                                                        |
| GitOps tracks individual YAML files.                                | GitOps tracks Helm values while ArgoCD renders the manifests automatically.                                              |

---

## Conclusion

Using Helm with ArgoCD simplifies GitOps by separating application configuration from Kubernetes templates. Instead of editing multiple manifest files, only the Helm values file (such as `values-prod.yaml`) needs to be updated with the new image tag. ArgoCD then renders the Helm chart and deploys the generated Kubernetes resources, making deployments more reusable, maintainable, and easier to manage across development, staging, and production environments.




---

### Task 5: Helm Best Practices for Production
Review these patterns used in production AI-BankApp deployments:

**1. Always use `helm upgrade --install`:**
```bash
helm upgrade --install bankapp bankapp/ \
  -f bankapp/values-prod.yaml \
  --set bankapp.image.tag=$GIT_SHA \
  -n bankapp --create-namespace \
  --wait --timeout 300s \
  --atomic
```

- `--install` -- creates if missing, upgrades if exists
- `--set bankapp.image.tag=$GIT_SHA` -- pins to exact git commit
- `--wait` -- waits for all pods to be ready
- `--atomic` -- rolls back automatically if the upgrade fails

**2. Use `helm diff` before upgrading:**
```bash
helm plugin install https://github.com/databus23/helm-diff
helm diff upgrade bankapp bankapp/ -f bankapp/values-prod.yaml
```

Shows exactly what would change before you commit to the upgrade.

**3. Resource quotas per namespace:**
```yaml
# Add to templates/resourcequota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: {{ include "bankapp.fullname" . }}-quota
  namespace: {{ .Release.Namespace }}
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
```

**4. Never store real secrets in values.yaml.** In production, use:
- External Secrets Operator with AWS Secrets Manager
- Sealed Secrets
- Vault by HashiCorp

The `values.yaml` defaults are fine for local dev but should be overridden in CI/CD via `--set` with pipeline secrets.

<img width="1235" height="92" alt="image" src="https://github.com/user-attachments/assets/25790372-ac6e-42f8-9a7d-e15d98b7b107" />
<img width="1037" height="92" alt="image" src="https://github.com/user-attachments/assets/d2f8e7ab-89f8-4fcb-a0d0-aa76d315c920" />



---

### Task 6: Clean Up and Review
Check what you have deployed:
```bash
helm list -A
```

<img width="1305" height="97" alt="helm" src="https://github.com/user-attachments/assets/e03e51c5-946f-4eed-ae78-2bf763793998" />

**Reflect and document the 3-day Helm journey:**

| Day | Concept | AI-BankApp Connection |
|-----|---------|----------------------|
| 78 | Helm install, repos, values, upgrade, rollback | Deployed MySQL for the BankApp via Bitnami chart |
| 79 | Custom chart from scratch, Go templates | Converted 12 raw `k8s/` manifests into a Helm chart |
| 80 | Multi-env values, hooks, packaging, CI/CD | Production-ready chart with dev/staging/prod configs |

**When would you use Helm vs raw manifests vs Kustomize?**

| Approach | Best For | AI-BankApp Example |
|----------|---------|-------------------|
| Raw manifests | Simple, single-env deployments | The current `k8s/` directory |
| Helm | Multi-env, complex apps with dependencies | The chart you built (3 services, HPA, hooks) |
| Kustomize | Overlays on existing manifests, no templating | Good if you want to patch `k8s/` without rewriting |

**Clean up:**
```bash
helm uninstall bankapp-dev -n dev
kubectl delete namespace dev
kind delete cluster --name tws-cluster
```
<img width="1202" height="155" alt="image" src="https://github.com/user-attachments/assets/f26b3aec-eea6-4fc1-80f1-6dbdf9235528" />


---

# Documentation

---

# 1. Three environment values files

## values-dev.yaml

```yaml
bankapp:
  replicaCount: 1

mysql:
  persistence:
    size: 2Gi

ollama:
  enabled: false

gateway:
  enabled: false
```

---

## values-staging.yaml

```yaml
bankapp:
  replicaCount: 2

mysql:
  persistence:
    size: 5Gi

ollama:
  enabled: true

gateway:
  enabled: false
```

---

## values-prod.yaml

```yaml
bankapp:
  replicaCount: 4

mysql:
  persistence:
    size: 20Gi

ollama:
  enabled: true

gateway:
  enabled: true
```

---

# Comparison Table

| Feature       | Dev           | Staging        | Production |
| ------------- | ------------- | -------------- | ---------- |
| Replicas      | 1             | 2              | 4          |
| Ollama        | Disabled      | Enabled        | Enabled    |
| MySQL Storage | 2Gi           | 5Gi            | 20Gi       |
| Gateway       | Disabled      | Disabled       | Enabled    |
| Purpose       | Local testing | Pre-production | Live users |

---

# 2. Helm hook template with annotations explained

Example:

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: "{{ include "bankapp.fullname" . }}-db-ready"
  annotations:
    "helm.sh/hook": post-install,post-upgrade
    "helm.sh/hook-delete-policy": hook-succeeded
spec:
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: wait
        image: busybox
        command:
          - sh
          - -c
          - echo "Database Ready"
```

### Annotation explanation

| Annotation                 | Purpose                                     |
| -------------------------- | ------------------------------------------- |
| helm.sh/hook               | Runs the Job after install and upgrade      |
| post-install               | Executes after Helm install                 |
| post-upgrade               | Executes after Helm upgrade                 |
| helm.sh/hook-delete-policy | Deletes the Job automatically after success |

---

# 3. Output of helm test

If you have no test templates, simply show:

```bash
helm test my-bankapp -n bankapp

NAME: my-bankapp
LAST DEPLOYED: ...
NAMESPACE: bankapp
STATUS: deployed

TEST SUITE: None
```

If your deployment isn't working because of Kind storage issues, mention:

> helm test could not be executed because the release was not successfully deployed in the Kind cluster due to pending PersistentVolumeClaims.

That is acceptable because the problem is environmental, not Helm syntax.

---

# 4. GitOps CI/CD Pipeline Integration

Typical production flow:

```
Developer

      │
      ▼

Git Push

      │
      ▼

GitHub Actions

      │

Build Docker Image

      │

Push Image to Docker Hub

      │

helm lint

      │

helm template

      │

helm diff upgrade

      │

helm upgrade --install

      │

Kubernetes Cluster

      │

Application Updated
```

Typical deployment command:

```bash
helm upgrade --install my-bankapp . \
-f values-prod.yaml \
--set bankapp.image.tag=$GITHUB_SHA \
-n bankapp \
--create-namespace \
--wait \
--atomic
```

---

# 5. Helm vs Raw YAML vs Kustomize

| Feature               | Raw Manifests  | Kustomize       | Helm                    |
| --------------------- | -------------- | --------------- | ----------------------- |
| Templates             | ❌              | ❌               | ✅                       |
| Variables             | ❌              | Limited         | ✅                       |
| Multiple Environments | Difficult      | Good            | Excellent               |
| Package Management    | ❌              | ❌               | ✅                       |
| Rollbacks             | Manual         | Manual          | Automatic               |
| Dependency Management | ❌              | ❌               | ✅                       |
| Charts                | ❌              | ❌               | ✅                       |
| Best for              | Small projects | Medium projects | Production applications |

---

# 6. Production Secrets Management

Never store passwords like this:

```yaml
secrets:
  mysqlRootPassword: Test@123
```

Instead use:

### Option 1 — AWS Secrets Manager + External Secrets Operator

```
AWS Secrets Manager

↓

External Secrets Operator

↓

Kubernetes Secret

↓

Application
```

Advantages:

* Secrets encrypted
* Automatic rotation
* IAM authentication
* No passwords in Git

---

### Option 2 — HashiCorp Vault

* Dynamic credentials
* Secret rotation
* Audit logs
* Enterprise-grade security

---

### Option 3 — Bitnami Sealed Secrets

Workflow:

```
Secret

↓

kubeseal

↓

Encrypted Secret in Git

↓

Controller decrypts

↓

Kubernetes Secret
```

Safe for Git repositories.

---

# Production Best Practices

* Use `helm upgrade --install`
* Use `helm diff` before upgrading
* Store secrets outside `values.yaml`
* Use separate values files for Dev, Staging, and Production
* Add ResourceQuota and LimitRange
* Use `--wait` and `--atomic` for reliable deployments
* Pin Docker images using a Git commit SHA instead of `latest`

