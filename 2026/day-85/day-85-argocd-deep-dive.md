# Day 85 -- ArgoCD Deep Dive: Sync Strategies, Rollbacks, and Multi-App Management

---

## Challenge Tasks

### Task 1: Understand Sync Strategies
ArgoCD offers multiple ways to sync:

**Automated sync** (what the AI-BankApp uses):
```yaml
syncPolicy:
  automated:
    prune: true      # Delete resources removed from Git
    selfHeal: true   # Revert manual cluster changes
```
- Every Git change syncs automatically within 3 minutes
- No human approval needed
- Good for dev/staging environments

**Manual sync** (for production):
```yaml
syncPolicy: {}   # No automated section
```
- ArgoCD detects drift but does NOT auto-correct
- A human must click "Sync" or run `argocd app sync`
- Good for production where you want a review gate

**Try switching to manual sync:**
```bash
argocd app set bankapp --sync-policy none
```
<img width="1240" height="347" alt="Manual sync" src="https://github.com/user-attachments/assets/ed504446-98c3-4575-b50f-7bc3d5f14c7e" />


Now make a change in Git (edit `k8s/configmap.yml` in your fork -- change `APP_NAME` or add a new key). Push the commit.

<img width="507" height="397" alt="image" src="https://github.com/user-attachments/assets/f9695ef9-dd2f-4c9d-b9da-14480bbf17fe" />
<img width="1340" height="377" alt="image" src="https://github.com/user-attachments/assets/04182edd-eb96-4553-bfca-f60b579ac1f6" />



<img width="1302" height="291" alt="image" src="https://github.com/user-attachments/assets/137a5b5b-13ff-4e5c-91e2-bcf8ff5b7b54" />




Wait 3 minutes and check:
```bash
argocd app get bankapp
```

<img width="1752" height="952" alt="image" src="https://github.com/user-attachments/assets/fc19d629-b9e7-47db-a0ca-b8a8d0c22647" />


The status will show `OutOfSync` but ArgoCD will NOT apply the change. You can see exactly what differs:
```bash
argocd app diff bankapp
```

<img width="1067" height="177" alt="image" src="https://github.com/user-attachments/assets/537e2b8c-193f-48bd-966c-fd7eeb719335" />


**Preview before syncing:**
```bash
# Dry run -- show what would change
argocd app sync bankapp --dry-run

# Sync for real
argocd app sync bankapp
```

UI sync<img width="1717" height="1146" alt="image" src="https://github.com/user-attachments/assets/22bb69cd-04c3-4bb5-a830-1c87a0e6290b" />


In the UI, clicking "Sync" shows a preview dialog listing all resources that will change.

<img width="1277" height="287" alt="image" src="https://github.com/user-attachments/assets/5064f1be-6b35-4851-9c27-c863642e25f1" />


**Switch back to automated:**
```bash
argocd app set bankapp --sync-policy automated --self-heal --auto-prune
```
or
```
argocd app set bankapp \
  --sync-policy automated \
  --self-heal \
  --auto-prune
```

<img width="1705" height="1052" alt="image" src="https://github.com/user-attachments/assets/72dccbd6-3c43-419a-a780-13a5e2abe6c7" />
<img width="1245" height="290" alt="image" src="https://github.com/user-attachments/assets/8cecbfc2-6eb0-427d-92cd-c9bc93fb2219" />


---

### Task 2: Sync Waves and Resource Ordering
The AI-BankApp has dependencies: MySQL must be running before the BankApp starts. ArgoCD handles this with **sync waves** -- annotations that control the order of resource creation.

**Add sync wave annotations to the AI-BankApp manifests in your fork:**

Edit `k8s/namespace.yml`:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: bankapp
  annotations:
    argocd.argoproj.io/sync-wave: "-2"
```

Edit `k8s/pv.yml` (StorageClass):
```yaml
metadata:
  name: gp3
  annotations:
    argocd.argoproj.io/sync-wave: "-2"
```

Edit `k8s/pvc.yml` (both PVCs):
```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
```

Edit `k8s/configmap.yml` and `k8s/secrets.yml`:
```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "-1"
```

Edit `k8s/mysql-deployment.yml`:
```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"
```

Edit `k8s/ollama-deployment.yml`:
```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"
```

Edit `k8s/service.yml` (all three services):
```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "0"
```

Edit `k8s/bankapp-deployment.yml`:
```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "1"
```

Edit `k8s/hpa.yml`:
```yaml
metadata:
  annotations:
    argocd.argoproj.io/sync-wave: "2"
```

**The sync order becomes:**
```
Wave -2: Namespace, StorageClass          (infrastructure)
Wave -1: PVCs, ConfigMap, Secret          (configuration)
Wave  0: MySQL, Ollama, Services          (databases and networking)
Wave  1: BankApp Deployment               (application)
Wave  2: HPA                              (scaling)
```

ArgoCD processes each wave in order. Resources in the same wave sync in parallel. ArgoCD waits for each wave to be healthy before moving to the next.

Commit and push these changes. ArgoCD will re-sync and you will see the ordered deployment in the UI.

<img width="1201" height="817" alt="image" src="https://github.com/user-attachments/assets/c382cb29-318c-48ac-80ca-bb4375538612" />

<img width="2730" height="2961" alt="image" src="https://github.com/user-attachments/assets/fed41eea-ad82-440a-bfbc-206a80c8652f" />


---

### Task 3: ArgoCD Rollbacks
ArgoCD tracks every sync as a revision. You can rollback to any previous state.

**Check the sync history:**
```bash
argocd app history bankapp
```

Output:
```
ID  DATE                 REVISION
1   2026-04-10 10:00:00  abc1234
2   2026-04-10 10:15:00  def5678   (sync wave annotations)
```

<img width="1137" height="296" alt="image" src="https://github.com/user-attachments/assets/6da442fc-63a8-4da0-bfac-9cde736611c4" />

**Rollback to a previous revision:**

Via CLI:
```bash
argocd app rollback bankapp 1
```

```bash
argocd app rollback bankapp 25
```

Via UI: Click the application > History > select a revision > "Rollback".

After rollback:
```bash
argocd app get bankapp
```

The status will show `OutOfSync` because the cluster now matches an older Git commit, not the latest.

<img width="2342" height="1255" alt="rollback-1" src="https://github.com/user-attachments/assets/9f2f4fba-681d-441e-856d-77d97e6dde17" />
<img width="1717" height="1147" alt="rollback-2" src="https://github.com/user-attachments/assets/1e0adc3a-9b6f-4076-ac84-6c26d3b4633f" />
<img width="1512" height="297" alt="rollback-UI" src="https://github.com/user-attachments/assets/f04d11bc-6d00-4eaf-8def-8d62c959ea0a" />



**Important:** Rollback is a temporary fix. It does not change Git. The proper GitOps rollback is:
```bash
# In your fork
git revert HEAD
git push
```

This creates a new commit that undoes the last change. ArgoCD syncs the revert and the cluster is updated. The Git history shows the full audit trail: deploy, then revert.

<img width="1077" height="297" alt="image" src="https://github.com/user-attachments/assets/4d5db0ab-5285-472b-8474-3c4c66fb76b1" />


**Document:** What is the difference between ArgoCD rollback and `git revert`? Which is the GitOps-correct approach?

| ArgoCD Rollback                                         | Git Revert                                                               |
| ------------------------------------------------------- | ------------------------------------------------------------------------ |
| Changes only the cluster to an older deployed revision. | Creates a new Git commit that undoes previous changes.                   |
| Temporary fix.                                          | Permanent GitOps solution.                                               |
| Git history is unchanged.                               | Git history records the rollback.                                        |
| Application becomes **OutOfSync** with Git.             | Application becomes **Synced** after ArgoCD syncs the new revert commit. |

```text
A ---- B ---- C (sync waves)
                 \
                  D (git revert)
```
Which is the GitOps-correct approach?

Git revert is the GitOps-correct approach because Git remains the single source of truth. 
ArgoCD rollback is useful for quickly recovering the application, but it should normally be followed by a git revert so that the cluster and Git are brought back into sync.



---

### Task 4: App of Apps Pattern
In production, you do not manage one application -- you manage dozens. The **App of Apps** pattern uses one parent ArgoCD Application that creates child Applications.

Create a directory for the pattern:
```bash
mkdir -p argocd-apps/
```

Create `argocd-apps/bankapp.yaml` (the BankApp application):
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bankapp
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
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
```

Create `argocd-apps/monitoring.yaml` (Prometheus + Grafana):
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://prometheus-community.github.io/helm-charts
    chart: kube-prometheus-stack
    targetRevision: "65.*"
    helm:
      values: |
        grafana:
          adminPassword: admin123
        prometheus:
          prometheusSpec:
            retention: 3d
            resources:
              requests:
                memory: 256Mi
                cpu: 100m
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - ServerSideApply=true
```

Create `argocd-apps/envoy-gateway.yaml`:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: envoy-gateway
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: docker.io/envoyproxy
    chart: gateway-helm
    targetRevision: "v1.4.*"
  destination:
    server: https://kubernetes.default.svc
    namespace: envoy-gateway-system
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

**Create the parent Application** that manages all child apps:
```yaml
# argocd-apps/root-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/srdangat/AI-BankApp-DevOps.git
    targetRevision: feat/gitops
    path: argocd-apps
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Push the `argocd-apps/` directory to your fork and apply the root app:
```bash
kubectl apply -f argocd-apps/root-app.yaml
```

<img width="1222" height="672" alt="image" src="https://github.com/user-attachments/assets/975612eb-5d0f-49a4-8807-f194c14160ac" />



ArgoCD will:
1. Read the `argocd-apps/` directory from Git
2. Find `bankapp.yaml`, `monitoring.yaml`, and `envoy-gateway.yaml`
3. Create three child Applications
4. Each child Application syncs independently

**In the ArgoCD UI,** you now see 4 applications: `root-app`, `bankapp`, `monitoring`, `envoy-gateway`. Adding a new app to the cluster is as simple as adding a new YAML file to the `argocd-apps/` directory.

```bash
argocd app list
```

<img width="2271" height="920" alt="image" src="https://github.com/user-attachments/assets/904096db-6b18-4519-b039-29d404e0b315" />



---

### Task 5: ArgoCD Notifications
Get notified when deployments succeed, fail, or drift.

Install ArgoCD Notifications (included in modern ArgoCD versions):
```bash
# Check if notifications controller is running
kubectl get pods -n argocd -l app.kubernetes.io/component=notifications-controller
```

**Configure a Slack or webhook notification** (using a generic webhook example):

Create a notification config:
```bash
kubectl apply -n argocd -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  trigger.on-sync-succeeded: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-sync-succeeded]
  trigger.on-sync-failed: |
    - when: app.status.operationState.phase in ['Error', 'Failed']
      send: [app-sync-failed]
  trigger.on-health-degraded: |
    - when: app.status.health.status == 'Degraded'
      send: [app-health-degraded]
  template.app-sync-succeeded: |
    message: "Application {{.app.metadata.name}} sync succeeded. Revision: {{.app.status.sync.revision}}"
  template.app-sync-failed: |
    message: "Application {{.app.metadata.name}} sync FAILED! Check ArgoCD for details."
  template.app-health-degraded: |
    message: "Application {{.app.metadata.name}} health is DEGRADED. Investigate immediately."
EOF
```

**Subscribe an application to notifications:**
```bash
kubectl annotate application bankapp -n argocd \
  notifications.argoproj.io/subscribe.on-sync-succeeded.webhook="" \
  notifications.argoproj.io/subscribe.on-sync-failed.webhook="" \
  notifications.argoproj.io/subscribe.on-health-degraded.webhook=""
```

For Slack integration, you would add a Slack service to the ConfigMap with your webhook URL. The pattern is the same -- triggers fire on events, templates format the message, services deliver it.

**View notification history:**
```bash
kubectl get applications bankapp -n argocd -o jsonpath='{.status.operationState.message}'
```

<img width="2321" height="946" alt="image" src="https://github.com/user-attachments/assets/140ab20d-5b3a-42d7-bf1d-ab2f0446b981" />


---

### Task 6: ArgoCD Projects and RBAC
In production, you do not give every team access to every application. ArgoCD **Projects** provide multi-tenancy.

Create a project for the BankApp team:
```bash
argocd proj create bankapp-team \
  --description "AI-BankApp team project" \
  --src "https://github.com/srdangat/AI-BankApp-DevOps.git" \
  --dest "https://kubernetes.default.svc,bankapp" \
  --dest "https://kubernetes.default.svc,monitoring"
```

```bash
argocd proj create bankapp-team \
  --description "AI-BankApp team project" \
  --src "https://github.com/malathi-shetty/90DaysOfDevOps_TrainWithShubham.git" \
  --dest "https://kubernetes.default.svc,bankapp" \
  --dest "https://kubernetes.default.svc,monitoring"
```

If you're unsure, verify the repo URL first:
```bash
kubectl get application bankapp -n argocd -o yaml | grep repoURL
```

<img width="1466" height="445" alt="image" src="https://github.com/user-attachments/assets/7ed9cd1b-94ef-4faf-a82e-d283ee6338b4" />


This project:
- Can only source from the AI-BankApp repo
- Can only deploy to the `bankapp` and `monitoring` namespaces
- Cannot deploy to `kube-system`, `argocd`, or other namespaces

Move the bankapp Application to this project:
```bash
argocd app set bankapp --project bankapp-team
```

**Verify restrictions work:**
```bash
# This should fail -- cert-manager namespace is not allowed
argocd proj add-destination bankapp-team https://kubernetes.default.svc kube-system 2>&1 || echo "Restricted!"
```

**RBAC policies** (in `argocd-rbac-cm` ConfigMap):
```yaml
policy.csv: |
  p, role:bankapp-dev, applications, get, bankapp-team/*, allow
  p, role:bankapp-dev, applications, sync, bankapp-team/*, allow
  p, role:bankapp-dev, applications, rollback, bankapp-team/*, deny
  g, bankapp-developers, role:bankapp-dev
```

This gives the `bankapp-developers` group permission to view and sync but NOT rollback. Rollback requires a senior team member.


<img width="2247" height="502" alt="image" src="https://github.com/user-attachments/assets/73b3e36a-4df5-445b-96db-7d7c62d37589" />
<img width="2297" height="1092" alt="image" src="https://github.com/user-attachments/assets/fbc6d5bc-3166-41f0-b615-39ef105b3b5e" />



**Document:** 

### How do ArgoCD Projects and RBAC prevent one team from accidentally affecting another team's applications?

ArgoCD Projects and Role-Based Access Control (RBAC) provide secure multi-tenancy by isolating applications and controlling user permissions. Projects restrict which Git repositories, Kubernetes clusters, and namespaces an application can use. This ensures that a team can deploy only to its authorized namespaces and cannot accidentally modify applications belonging to other teams or system namespaces such as `kube-system` or `argocd`.

RBAC complements Projects by defining what actions users or groups are allowed to perform. For example, developers may be granted permission to view and synchronize applications but denied rollback or deletion privileges. Sensitive operations can be reserved for senior engineers or administrators.

Together, Projects and RBAC improve security, prevent accidental cross-team changes, enforce the principle of least privilege, and provide clear separation of responsibilities in a shared Kubernetes cluster.


---

# Documentation




# Day 85 - ArgoCD Deep Dive

## 1. Automated vs Manual Sync

| Feature        | Automated Sync                  | Manual Sync            |
| -------------- | ------------------------------- | ---------------------- |
| Trigger        | Automatically after Git changes | Triggered by user      |
| Human approval | Not required                    | Required               |
| Best for       | Development, GitOps pipelines   | Production deployments |
| Rollback       | Automatic re-sync to Git state  | Manual rollback/sync   |
| Risk           | Faster but less controlled      | More control and safer |

### When to use Automated Sync

* Development environments
* Continuous deployment
* Frequently changing applications
* GitOps workflows

### When to use Manual Sync

* Production environments
* Critical applications
* Regulated environments
* Deployments requiring approval

---

# 2. Sync Waves (AI-BankApp Deployment Order)

| Sync Wave | Resources                                            |
| --------- | ---------------------------------------------------- |
| Wave 0    | Namespace, StorageClass, ClusterIssuer, GatewayClass |
| Wave 1    | ConfigMaps, Secrets, PersistentVolumeClaims          |
| Wave 2    | MySQL, Redis, Ollama Deployments                     |
| Wave 3    | Services                                             |
| Wave 4    | BankApp Deployment                                   |
| Wave 5    | Gateway, HTTPRoute, BackendTrafficPolicy             |
| Wave 6    | Certificate                                          |
| Wave 7    | HorizontalPodAutoscaler                              |

This ordering ensures infrastructure components are created before the application starts.

---

# 3. ArgoCD Rollback vs Git Revert

## ArgoCD Rollback

* Rolls back to a previously deployed revision.
* Uses deployment history stored by ArgoCD.
* Very fast.
* Does not modify Git history.
* Useful for emergency recovery.

Example:

```bash
argocd app rollback bankapp <history-id>
```

---

## Git Revert

* Creates a new commit that reverses previous changes.
* Updates Git history.
* ArgoCD detects the new commit and deploys it.
* Maintains a complete audit trail.

Example:

```bash
git revert <commit-id>
git push origin master
```

---

### Comparison

| ArgoCD Rollback               | Git Revert            |
| ----------------------------- | --------------------- |
| Temporary deployment rollback | Permanent code change |
| Does not change Git           | Changes Git history   |
| Fast recovery                 | Proper long-term fix  |
| Good for incidents            | Good for bug fixes    |

---

# 4. App of Apps Architecture

```

                 Developer
                     │
             Push / Pull Request
                     │
                     ▼
        GitHub Repository (Source of Truth)
                     │
                     ▼
        ArgoCD Watches Git Repository
                     │
                     ▼
      Root Application (App of Apps)
      (root-app in argocd namespace)
      ┌──────────┼──────────┐
      │          │          │
      ▼          ▼          ▼
   BankApp   Monitoring   Envoy Gateway
 Application  Application   Application
      │          │          │
      └──────────┼──────────┘
                 ▼
         Kubernetes Cluster
       (Namespaces & Resources)


```

Benefits:

* Centralized management
* One Git repository
* Easy onboarding
* Easier scaling
* GitOps best practices



2. Sync Waves Diagram

```text
Git Commit
    │
    ▼
ArgoCD Starts Sync
    │
    ▼
Wave 0
  │
  ▼
Envoy Gateway
    │
    ▼
Wave 1
  │
  ▼
Monitoring
    │
    ▼
Wave 2
  │
  ▼
BankApp
    │
    ▼
Application Healthy
```

This explains deployment order.


| Sync Wave | Application   | Reason                    |
| --------- | ------------- | ------------------------- |
| Wave 0    | envoy-gateway | Gateway must exist first  |
| Wave 1    | monitoring    | Monitoring stack          |
| Wave 2    | bankapp       | Application deployed last |

> Implemented the App of Apps pattern with ArgoCD to manage multiple applications. Also explored Sync Waves for ordered deployments (Envoy Gateway → Monitoring → BankApp), automated sync, self-healing, rollbacks, notifications, and RBAC.

---

# 5. ArgoCD Notifications

Notification configuration consists of three parts:

## Triggers

Triggers define **when** notifications are sent.

Examples:

* Sync Succeeded
* Sync Failed
* Health Degraded

---

## Templates

Templates define the notification message.

Example:

```
Application {{.app.metadata.name}} sync succeeded.
Revision: {{.app.status.sync.revision}}
```

---

## Services

Services define **where** notifications are delivered.

Examples:

* Slack
* Microsoft Teams
* Webhook
* Email

Flow:

```
Trigger
    ↓
Template
    ↓
Service
    ↓
Slack / Webhook / Email
```

---

# 6. Projects and RBAC

## ArgoCD Projects

Projects isolate applications into separate environments or teams.

For the BankApp project:

* Allowed Git repository:

  * AI-BankApp repository
* Allowed namespaces:

  * bankapp
  * monitoring
* Restricted namespaces:

  * kube-system
  * argocd
  * Any unauthorized namespace

This prevents deployments outside approved environments.

---

## RBAC

Role-Based Access Control limits user permissions.

Example policy:

```
bankapp-developers

✓ View Applications
✓ Sync Applications
✗ Rollback Applications
```

Senior engineers or administrators can perform rollback operations.

---

## How Projects and RBAC Prevent Cross-Team Impact

Projects and RBAC provide isolation between teams in a shared ArgoCD environment. Projects restrict where applications can be deployed and which Git repositories they can use, preventing accidental deployments to unauthorized namespaces such as `kube-system` or `argocd`. RBAC controls what actions users can perform, allowing developers to view and sync only their team's applications while restricting sensitive operations like rollback or project administration. Together, Projects and RBAC ensure each team can manage only its own applications, reducing the risk of accidental changes to another team's workloads and improving security, governance, and operational stability.

---

# Summary

During this deep dive, ArgoCD was configured to use GitOps for automated deployments, App of Apps architecture for centralized application management, Notifications for deployment events, Projects for application isolation, and RBAC for secure team-based access control. These features provide a scalable, secure, and production-ready continuous delivery platform for Kubernetes.








