# Day 84 -- Introduction to GitOps and ArgoCD

---

## Challenge Tasks

### Task 1: Understand GitOps
Research and write notes on:



## What is GitOps?

GitOps is a modern deployment methodology where **Git acts as the single source of truth** for both infrastructure and application configurations. Instead of manually deploying resources to a Kubernetes cluster using commands like `kubectl apply`, all changes are first committed to a Git repository.

A GitOps operator, such as **ArgoCD**, continuously monitors the Git repository and compares the desired state stored in Git with the actual state running inside the Kubernetes cluster. If there is any difference (called **configuration drift**), ArgoCD automatically synchronizes the cluster to match Git.

This approach ensures that every infrastructure or application change follows the standard software development workflow:

* Developers make changes locally.
* Changes are reviewed through Pull Requests.
* Approved changes are merged into Git.
* ArgoCD automatically deploys the updated configuration.

Since Git stores every change, GitOps provides:

* Complete version history
* Easy rollback using Git
* Audit trail of who changed what and when
* Consistent and repeatable deployments
* Automatic self-healing of the cluster

---

## GitOps vs Traditional CI/CD

| Aspect                 | Traditional CI/CD                                   | GitOps                                     |
| ---------------------- | --------------------------------------------------- | ------------------------------------------ |
| **Deployment Trigger** | CI pipeline executes `kubectl apply`                | Git commit triggers ArgoCD synchronization |
| **Source of Truth**    | Pipeline scripts and deployment jobs                | Git repository                             |
| **Deployment Model**   | Push-based deployment                               | Pull-based deployment                      |
| **Drift Detection**    | No automatic detection                              | Continuous reconciliation                  |
| **Rollback**           | Re-run pipeline or manually deploy previous version | `git revert` followed by automatic sync    |
| **Audit Trail**        | Pipeline execution logs                             | Complete Git history                       |
| **Access Control**     | CI/CD pipeline requires Kubernetes credentials      | Only ArgoCD has cluster access             |
| **Security**           | CI server has broad permissions on the cluster      | Developers only push code to Git           |

### Traditional CI/CD Workflow

```text
Developer
    │
    ▼
Git Push
    │
    ▼
CI Pipeline
    │
    ▼
kubectl apply
    │
    ▼
Kubernetes Cluster
```

The CI pipeline directly pushes changes into the cluster.

---

### GitOps Workflow

```text
Developer
    │
    ▼
Git Push
    │
    ▼
Git Repository
    │
    ▼
ArgoCD
    │
    ▼
Kubernetes Cluster
```

ArgoCD continuously pulls the desired state from Git and applies it to the cluster.

---

# AI-BankApp GitOps Flow

The AI-BankApp project follows a complete GitOps workflow where CI is responsible for building and publishing the application, while ArgoCD is responsible for deployment.

```text
Developer pushes code to feat/gitops
         │
         ▼
GitHub Actions CI
 ├── Build Maven project
 ├── Run unit tests
 ├── Build Docker image
 ├── Push image to DockerHub (Git SHA tag)
 ├── Update image tag in k8s/bankapp-deployment.yml
 └── Commit updated manifest back to Git
         │
         ▼
Git Repository
         │
         ▼
ArgoCD watches the repository
 ├── Detects new commit
 ├── Compares Git manifests with live cluster
 ├── Finds differences (drift)
 ├── Synchronizes resources
 └── Performs rolling update
         │
         ▼
Amazon EKS Cluster
         │
         ▼
AI-BankApp Pods restart with the new Docker image

Zero manual deployment after the Git push.
```

### Workflow Explanation

1. A developer pushes code to the `feat/gitops` branch.
2. GitHub Actions builds and tests the application.
3. A Docker image is created and pushed to DockerHub using the Git commit SHA as the tag.
4. The Kubernetes deployment manifest is automatically updated with the new image tag.
5. The updated manifest is committed back to Git.
6. ArgoCD detects the new commit.
7. ArgoCD compares the manifests in Git with the running Kubernetes resources.
8. If differences exist, ArgoCD performs a rolling update.
9. The cluster reaches the desired state automatically without anyone running `kubectl apply`.

---

# Four GitOps Principles (OpenGitOps)

## 1. Declarative

The desired system state is described using declarative configuration files instead of imperative commands.

For Kubernetes, this means writing YAML manifests that define resources such as Deployments, Services, ConfigMaps, and Ingresses.

Example:

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 4
```

Instead of telling Kubernetes **how** to create resources, we describe **what** the final state should be.

---

## 2. Versioned and Immutable

All infrastructure and application configuration is stored in a Git repository.

Every modification is:

* Version controlled
* Auditable
* Reviewable through Pull Requests
* Easy to roll back

Git becomes the complete history of the infrastructure.

---

## 3. Pulled Automatically

GitOps uses a **pull-based deployment model**.

Instead of a CI pipeline pushing manifests into Kubernetes, ArgoCD continuously pulls the latest desired state from Git and applies it.

Benefits include:

* Better security
* Reduced cluster credential exposure
* Consistent deployments
* Simpler CI pipelines

---

## 4. Continuously Reconciled

ArgoCD continuously compares:

* **Desired State** (Git repository)
* **Actual State** (Kubernetes cluster)

If someone manually modifies or deletes a resource, ArgoCD detects the drift and automatically restores the cluster to match Git.

This process is called **continuous reconciliation** and enables **self-healing**.

---

# Key Takeaways

* Git is the single source of truth.
* ArgoCD continuously watches Git for changes.
* Deployments are pull-based rather than push-based.
* Manual changes in the cluster are automatically reverted.
* Every change is tracked through Git history.
* Rollbacks are performed by reverting commits instead of manually redeploying.
* GitOps improves security, consistency, traceability, and reliability.



---

### Task 2: Access ArgoCD on Your EKS Cluster
ArgoCD was installed by Terraform on Day 81 (via `terraform/argocd.tf`). Verify it is running:

```bash
kubectl get pods -n argocd
```

You should see pods for: `argocd-server`, `argocd-repo-server`, `argocd-application-controller`, `argocd-applicationset-controller`, `argocd-redis`, and `argocd-dex-server`.

<img width="1086" height="202" alt="image" src="https://github.com/user-attachments/assets/ce0234a7-003b-46bb-9d46-bb1101f5ca0e" />


**Get the ArgoCD admin password:**
```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

**Access the ArgoCD UI:**

Option A -- via LoadBalancer (if Terraform exposed it):
```bash
export ARGOCD_URL=$(kubectl get svc argocd-server -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ArgoCD URL: http://$ARGOCD_URL"
```

http://aebeb1f0205ed479baac3383135e0858-795951744.us-west-2.elb.amazonaws.com

Option B -- via port-forward:
```bash
kubectl port-forward svc/argocd-server -n argocd 8443:443
```

Open `https://localhost:8443` (accept the self-signed certificate). Log in with:
- Username: `admin`
- Password: the value from the command above

<img width="1617" height="227" alt="image" src="https://github.com/user-attachments/assets/764cd12f-7947-4990-a2c8-34d2cae9c2d2" />
<img width="2557" height="1071" alt="image" src="https://github.com/user-attachments/assets/08c58ab3-9c43-465f-bc9e-3743708f431d" />


**Install the ArgoCD CLI:**
```bash
# macOS
brew install argocd

# Linux
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x argocd
sudo mv argocd /usr/local/bin/

# Verify
argocd version --client
```

<img width="1737" height="662" alt="image" src="https://github.com/user-attachments/assets/37acbf38-6218-4802-81e4-b6946ed11a1c" />


Log in via CLI:
```bash
argocd login $ARGOCD_URL --username admin --password <your-password> --insecure
# or for port-forward:
argocd login localhost:8443 --username admin --password <your-password> --insecure
```

<img width="1550" height="97" alt="image" src="https://github.com/user-attachments/assets/44821661-0264-47cf-9148-47c8444886c4" />


**Explore the ArgoCD UI:**
- **Applications** -- shows all managed applications (empty for now)
- **Settings > Repositories** -- Git repos ArgoCD can access
- **Settings > Clusters** -- Kubernetes clusters ArgoCD manages (your EKS cluster is the default `in-cluster`)

<img width="1917" height="542" alt="image" src="https://github.com/user-attachments/assets/65d957b7-1d64-4e7b-b09b-547e5adfe9d1" />


---

### Task 3: Study the AI-BankApp's ArgoCD Application Manifest
Open `argocd/application.yml` from the AI-BankApp repo:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bankapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/TrainWithShubham/AI-BankApp-DevOps.git
    targetRevision: feat/gitops
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: bankapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
```

<img width="1002" height="52" alt="image" src="https://github.com/user-attachments/assets/91eb636d-c506-462c-8d33-c61ac051d710" />
<img width="1215" height="52" alt="image" src="https://github.com/user-attachments/assets/60880955-bc54-45d1-9f43-08e161d1a138" />
<img width="1357" height="180" alt="image" src="https://github.com/user-attachments/assets/1353e3c6-e2fc-440f-bf2a-0b29b26f9784" />


---

### Task 4: Deploy the AI-BankApp via ArgoCD
First, make sure the BankApp is NOT already deployed (clean slate):
```bash
kubectl delete namespace bankapp 2>/dev/null
```

**Fork the AI-BankApp repo** -- you need your own copy to push changes later:
1. Go to https://github.com/TrainWithShubham/AI-BankApp-DevOps
2. Click "Fork" and create your fork
3. Note your fork URL: `https://github.com/<your-username>/AI-BankApp-DevOps.git`

**Create the ArgoCD Application** (update the repoURL to your fork):
```bash
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bankapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/srdangat/AI-BankApp-DevOps.git
    targetRevision: feat/gitops
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: bankapp
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
EOF
```

**Watch ArgoCD deploy the app:**
- In the ArgoCD UI, click on the `bankapp` application
- You will see a visual tree of all Kubernetes resources being created
- Each resource shows its sync and health status (green = healthy, yellow = progressing, red = degraded)

Or watch via CLI:
```bash
argocd app get bankapp
argocd app wait bankapp
```

<img width="1762" height="1152" alt="image" src="https://github.com/user-attachments/assets/56c60e39-24c7-4f93-b095-12d1af174d24" />
<img width="1782" height="557" alt="image" src="https://github.com/user-attachments/assets/5bee4bd6-65a9-46ec-afab-d4f66150c4cd" />




Monitor pods coming up:
```bash
kubectl get pods -n bankapp -w
```

<img width="1090" height="207" alt="image" src="https://github.com/user-attachments/assets/890cf20a-1f84-4443-aaf8-2b5eb6d5f984" />



The deployment order is automatic -- ArgoCD applies all manifests from the `k8s/` directory. MySQL and Ollama start first, then the BankApp's init containers wait for dependencies.

After everything is healthy (5-10 minutes):
```bash
argocd app get bankapp
```
<img width="1687" height="952" alt="image" src="https://github.com/user-attachments/assets/4596a9b4-8750-4167-8a89-f90558be72c8" />

<img width="1707" height="1146" alt="image" src="https://github.com/user-attachments/assets/5d9ae1b8-9897-4110-b8a7-29a7afd111a2" />


Status should show: `Health: Healthy`, `Sync: Synced`.

---

### Task 5: Explore ArgoCD's Live View
Click on the `bankapp` application in the ArgoCD UI. You will see:

**The resource tree:**
```
bankapp (Application)
  |-- Namespace: bankapp
  |-- StorageClass: gp3
  |-- PVC: mysql-pvc (Bound)
  |-- PVC: ollama-pvc (Bound)
  |-- ConfigMap: bankapp-config
  |-- Secret: bankapp-secret
  |-- Deployment: mysql -> ReplicaSet -> Pod
  |-- Deployment: ollama -> ReplicaSet -> Pod
  |-- Deployment: bankapp -> ReplicaSet -> Pod (x4)
  |-- Service: mysql-service
  |-- Service: ollama-service
  |-- Service: bankapp-service
  |-- HPA: bankapp-hpa
```

<img width="1912" height="1020" alt="image" src="https://github.com/user-attachments/assets/26620cb3-cdd7-41b5-909d-7cdaa80b282b" />


**Click on any resource** to see its details:
- Pod logs (live streaming)
- Events
- YAML manifest (as applied to the cluster)
- Diff (what changed since last sync)

**App Details tab shows:**
- Source repo and path
- Last sync time and revision (git commit SHA)
- Sync status and health status
- History of all syncs

**Check the sync history:**
```bash
argocd app history bankapp
```

<img width="1106" height="295" alt="image" src="https://github.com/user-attachments/assets/8c90b2b6-9093-43c5-92f7-6ee8467e33eb" />
<img width="2730" height="3104" alt="bankapp-Application-Details-Tree-Argo-CD" src="https://github.com/user-attachments/assets/031c3aba-10a6-4ecb-b4ec-6de7fe90911d" />


This shows every revision that was synced, when, and the commit SHA.

<img width="2550" height="1191" alt="image" src="https://github.com/user-attachments/assets/af291694-2b85-4058-a71b-b74d477e88a2" />


---

### Task 6: Test Self-Healing
ArgoCD's `selfHeal: true` means it reverts any manual changes made directly to the cluster.

**Test 1 -- Manually scale the BankApp:**
```bash
kubectl scale deployment bankapp -n bankapp --replicas=1
```

Watch what happens:
```bash
kubectl get pods -n bankapp -w
```
Within 3-5 minutes, ArgoCD detects the drift and scales it back to the value defined in Git (4 replicas, or whatever the HPA decides). Check the ArgoCD UI -- you will see a sync event.


<img width="1332" height="532" alt="image" src="https://github.com/user-attachments/assets/735789c7-2611-4d83-aa5f-7ccd5da7bf31" />
<img width="1440" height="846" alt="image" src="https://github.com/user-attachments/assets/1dcc7384-3507-4ec9-8059-293e68195365" />



**Test 2 -- Manually delete a ConfigMap:**
```bash
kubectl delete configmap bankapp-config -n bankapp
```
<img width="1317" height="202" alt="image" src="https://github.com/user-attachments/assets/277dc2e7-dd87-4b9a-b336-8ab41bb3bd3c" />

<img width="1392" height="308" alt="image" src="https://github.com/user-attachments/assets/6b0834ba-88f6-46bb-a915-c592c962aed9" />


<img width="1312" height="287" alt="image" src="https://github.com/user-attachments/assets/71be46a4-4d30-4283-aed5-8158dde19535" />


ArgoCD will recreate it from Git within minutes.

**Test 3 -- Manually change an environment variable:**
```bash
kubectl edit configmap bankapp-config -n bankapp
# Change MYSQL_DATABASE to something wrong
```
<img width="1360" height="422" alt="image" src="https://github.com/user-attachments/assets/5db3ca08-a3c8-4469-a24f-3992f29465d4" />
<img width="1022" height="687" alt="image" src="https://github.com/user-attachments/assets/7b8d1ea5-ea34-496c-af3a-8ee7091845fd" />

<img width="962" height="546" alt="image" src="https://github.com/user-attachments/assets/71d34cba-a1e7-4d3d-8987-8c7ccd5aa890" />


ArgoCD will overwrite your change with the value from Git.

**This is the core GitOps promise:** The cluster always matches Git. Manual changes do not survive. All changes must go through Git (pull requests, review, merge).

**Document:** What happened during each self-healing test? How quickly did ArgoCD revert the changes?


#### Test 1: Manual Scaling of the BankApp Deployment

**Command:**

```bash
kubectl scale deployment bankapp -n bankapp --replicas=1
```

**Observation:**

* The Deployment was manually scaled down.
* The Horizontal Pod Autoscaler (HPA) detected that the replica count was below the configured minimum (`minReplicas: 3`).
* The Deployment was automatically scaled back to **3 replicas**.
* ArgoCD remained in the **Synced** state because the HPA manages the Deployment's replica count.

**Recovery Time:** Approximately **1–2 minutes**.

---

#### Test 2: Delete the ConfigMap

**Command:**

```bash
kubectl delete configmap bankapp-config -n bankapp
```

**Observation:**

* The `bankapp-config` ConfigMap was deleted successfully.
* ArgoCD detected that the resource was missing.
* ArgoCD automatically recreated the ConfigMap from the Git repository.
* The recreated ConfigMap had a new `creationTimestamp`, confirming that it was restored by ArgoCD.

**Recovery Time:** Approximately **2–3 minutes**.

---

#### Test 3: Modify the ConfigMap

**Command:**

```bash
kubectl edit configmap bankapp-config -n bankapp
```

**Change Made:**

```yaml
MYSQL_DATABASE: wrongdb
```

**Observation:**

* The ConfigMap was successfully modified.
* After ArgoCD's reconciliation interval (configured as `120s` with up to `60s` jitter), the modified value was automatically replaced with the original value stored in Git (`bankappdb`).
* The cluster returned to the desired state without manual intervention.
* Because self-healing was enabled, the application returned to **Synced** quickly, so the **OutOfSync** state was not visible for long in the ArgoCD UI.

**Recovery Time:** Approximately **2–3 minutes**.

---

# Documentation

## 1. GitOps Principles (In My Own Words)

GitOps is a way of managing Kubernetes infrastructure and applications where **Git is the single source of truth**. Instead of making changes directly in the cluster, all changes are committed to a Git repository. A GitOps controller such as ArgoCD continuously compares the desired state stored in Git with the actual state of the Kubernetes cluster. If any differences are found, ArgoCD automatically synchronizes the cluster to match the Git repository.

The main principles of GitOps are:

* **Git is the source of truth** – All Kubernetes manifests are stored in Git.
* **Declarative configuration** – Resources are described in YAML files rather than created manually.
* **Automatic synchronization** – ArgoCD continuously applies changes from Git to the cluster.
* **Self-healing** – Manual modifications in the cluster are automatically reverted.
* **Version control and auditing** – Every infrastructure change is tracked through Git commits, making rollbacks and auditing simple.

---

# 2. GitOps vs Traditional CI/CD

| Feature                   | Traditional CI/CD                  | GitOps                              |
| ------------------------- | ---------------------------------- | ----------------------------------- |
| Source of truth           | CI/CD pipeline                     | Git repository                      |
| Deployment trigger        | CI/CD tool pushes changes          | ArgoCD pulls changes from Git       |
| Manual cluster changes    | Allowed and often persist          | Automatically reverted              |
| Rollback                  | Redeploy previous build            | Git revert + sync                   |
| Audit trail               | Pipeline logs                      | Complete Git commit history         |
| Drift detection           | Usually unavailable                | Automatic continuous reconciliation |
| Infrastructure management | Scripts or manual commands         | Declarative Kubernetes manifests    |
| Security                  | CI/CD requires cluster credentials | ArgoCD runs inside the cluster      |

---

# 3. AI-BankApp GitOps Flow

```text
                Developer
                     │
                     │
          Edit Kubernetes YAML
                     │
                     ▼
              Git Commit & Push
                     │
                     ▼
             GitHub Repository
                     │
        ArgoCD continuously watches
                     │
                     ▼
             Detects Git changes
                     │
                     ▼
          Sync Kubernetes manifests
                     │
                     ▼
            Amazon EKS Cluster
                     │
     ┌───────────────┼────────────────┐
     │               │                │
     ▼               ▼                ▼
 Deployment      Services         ConfigMaps
     │
     ▼
 ReplicaSet
     │
     ▼
    Pods
     │
     ▼
  AI-BankApp Running

If someone manually changes the cluster
              │
              ▼
      ArgoCD detects drift
              │
              ▼
    Self-Heal restores Git state
```

---

# 4. ArgoCD Application Manifest Explained

```yaml
apiVersion: argoproj.io/v1alpha1
```

Specifies the API version for the ArgoCD Application Custom Resource.

---

```yaml
kind: Application
```

Defines this resource as an ArgoCD Application.

---

```yaml
metadata:
  name: bankapp
```

The name of the ArgoCD application.

---

```yaml
namespace: argocd
```

The namespace where ArgoCD is installed and manages applications.

---

```yaml
spec:
```

Contains the desired configuration of the application.

---

```yaml
project: default
```

Specifies the ArgoCD Project that the application belongs to. Projects are used to organize applications and control permissions.

---

```yaml
source:
```

Defines where ArgoCD retrieves the Kubernetes manifests.

---

```yaml
repoURL: https://github.com/srdangat/AI-BankApp-DevOps.git
```

Git repository containing all Kubernetes YAML files.

---

```yaml
targetRevision: feat/gitops
```

The Git branch, tag, or commit that ArgoCD continuously monitors.

---

```yaml
path: k8s
```

The directory inside the repository containing the Kubernetes manifests.

---

```yaml
destination:
```

Specifies where ArgoCD deploys the application.

---

```yaml
server: https://kubernetes.default.svc
```

The Kubernetes API server. This URL represents the current cluster where ArgoCD is running.

---

```yaml
namespace: bankapp
```

The target namespace where all application resources are deployed.

---

```yaml
syncPolicy:
```

Defines how ArgoCD synchronizes Git with the Kubernetes cluster.

---

```yaml
automated:
```

Enables automatic synchronization without requiring manual approval.

---

```yaml
prune: true
```

Automatically deletes Kubernetes resources that have been removed from the Git repository.

Example:

* Delete `redis.yaml` from Git.
* Commit and push.
* ArgoCD automatically removes the Redis Deployment and Service from the cluster.

---

```yaml
selfHeal: true
```

Continuously compares the cluster with Git and automatically restores resources if someone changes them manually.

Example:

* Change a ConfigMap using `kubectl edit`.
* ArgoCD detects the drift.
* The ConfigMap is restored to the version stored in Git.

---

```yaml
syncOptions:
```

Additional synchronization options.

---

```yaml
CreateNamespace=true
```

Automatically creates the target namespace (`bankapp`) if it does not already exist.

---

```yaml
ServerSideApply=true
```

Uses Kubernetes Server-Side Apply instead of Client-Side Apply during synchronization. This reduces merge conflicts, handles large manifests more reliably, and lets Kubernetes track field ownership, making updates safer when multiple controllers manage the same resources.

---

# 5. What `prune`, `selfHeal`, and `ServerSideApply` Do

### `prune: true`

**Purpose:** Remove resources that exist in the cluster but have been deleted from Git.

**Without prune**

* Deleted resources continue running in the cluster.

**With prune**

* ArgoCD automatically deletes those resources during synchronization.

---

### `selfHeal: true`

**Purpose:** Continuously detect and correct configuration drift.

**Without selfHeal**

* Manual `kubectl edit` or `kubectl scale` changes remain until the next manual sync.

**With selfHeal**

* ArgoCD automatically restores the resource to match the Git repository, ensuring the cluster always reflects the desired state.

---

### `ServerSideApply=true`

**Purpose:** Use Kubernetes' server-side apply mechanism for updates.

**Benefits:**

* Better conflict resolution when multiple controllers manage the same resource.
* Kubernetes tracks ownership of individual fields.
* Supports larger and more complex manifests.
* Reduces issues caused by client-side merge annotations.
* Provides more reliable synchronization in GitOps workflows.

