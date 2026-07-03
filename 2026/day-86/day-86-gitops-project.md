# Day 86 -- GitOps Project: End-to-End CI/CD Pipeline with AI-BankApp

---

## Challenge Tasks

clone & create: https://github.com/shettymalathib/AI-BankApp-DevOps.git

### Task 1: Study the AI-BankApp's GitOps CI Pipeline
Open `.github/workflows/gitops-ci.yml` from the AI-BankApp repo. This is a production-grade GitOps CI pipeline.

**The workflow triggers on:**
```yaml
on:
  push:
    #branches: [feat/gitops]
    branches: [master]
    paths:
      - 'src/**'
      - 'pom.xml'
      - 'Dockerfile'
  workflow_dispatch:
```

It only runs when application code changes (`src/`, `pom.xml`, `Dockerfile`) -- not when Kubernetes manifests change. This prevents infinite loops since the pipeline itself updates manifests.

```bash
Check:

ls -l mvnw

You'll probably see something like

-rw-r--r-- 1 malathi ...

instead of

-rwxr-xr-x

Fix it:

chmod +x mvnw

Now verify

ls -l mvnw

It should become

-rwxr-xr-x

Now run

./mvnw clean package -DskipTests -B

Next run 
 docker compose up -d

then run

./mvnw test -B


```

<img width="2257" height="1151" alt="image" src="https://github.com/user-attachments/assets/e9b0e4d6-fa12-4d4c-96a0-a792ec118284" />
<img width="1627" height="912" alt="image" src="https://github.com/user-attachments/assets/9d28c536-a962-4976-9ded-74d7fac2548d" />
<img width="1742" height="312" alt="image" src="https://github.com/user-attachments/assets/06efa552-d00d-4c0f-8dea-135909bef34b" />
<img width="2257" height="1240" alt="image" src="https://github.com/user-attachments/assets/0aff25c1-cfae-4ee7-8005-2a9cfc3791d9" />


**The pipeline steps:**

| Step | What it does |
|------|-------------|
| Checkout code | Clones the repo |
| Set up JDK 21 | Installs Java 21 with Maven cache |
| Build with Maven | `./mvnw clean package -DskipTests -B` |
| Run tests | `./mvnw test -B` (non-blocking: `continue-on-error: true`) |
| Set image tag | Uses `git rev-parse --short HEAD` as the tag (e.g., `1c7cb0e`) |
| Login to DockerHub | Authenticates with secrets |
| Build and push image | Pushes `trainwithshubham/ai-bankapp-eks:latest` and `:sha` |
| Update K8s manifest | Uses `sed` to update the image tag in `k8s/bankapp-deployment.yml` |
| Commit updated manifest | Commits the change with `[skip ci]` to avoid re-triggering |

**The critical GitOps step** is the last two:
```yaml
- name: Update Kubernetes deployment manifest
  run: |
    sed -i "s|image: ${{ env.DOCKERHUB_REPO }}:.*|image: ${{ env.DOCKERHUB_REPO }}:${{ steps.tag.outputs.sha_short }}|" k8s/bankapp-deployment.yml

- name: Commit updated manifest
  run: |
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add k8s/bankapp-deployment.yml
    git diff --staged --quiet || git commit -m "ci: update bankapp image to ${{ steps.tag.outputs.sha_short }} [skip ci]"
    git push
```

<img width="1911" height="827" alt="image" src="https://github.com/user-attachments/assets/78a2238f-31c9-4f65-aad4-a132980c53d6" />


**Why `[skip ci]`?** Without it, the commit that updates the manifest would trigger the pipeline again, which would update the manifest again -- an infinite loop. `[skip ci]` tells GitHub Actions to ignore this commit.

**The handoff to ArgoCD:**
```
GitHub Actions commits new image tag to k8s/bankapp-deployment.yml
         |
    ArgoCD detects the new commit (within 3 minutes)
         |
    ArgoCD compares: cluster has old image, Git has new image
         |
    ArgoCD syncs: performs a rolling update
         |
    New pods start with the new image, old pods terminate
         |
    Zero downtime deployment complete
```


---

### Task 2: Set Up the Pipeline on Your Fork
To run the full pipeline, you need your own fork with GitHub Secrets.

**1. Fork the repo** (if not done on Day 84):
```
https://github.com/TrainWithShubham/AI-BankApp-DevOps -> Fork
```

**2. Create a DockerHub access token:**
- Go to https://hub.docker.com/settings/security
- Create a new access token with Read/Write permissions
- Note the token

**3. Add GitHub Secrets to your fork:**
- Go to your fork > Settings > Secrets and variables > Actions
- Add these secrets:
  - `DOCKERHUB_USERNAME` -- your DockerHub username
  - `DOCKERHUB_TOKEN` -- the access token from step 2

<img width="1652" height="866" alt="image" src="https://github.com/user-attachments/assets/c2332bc8-e309-41cf-a230-b6b013eb21ea" />



**4. Update the workflow to push to your DockerHub repo:**
Edit `.github/workflows/gitops-ci.yml` in your fork:
```yaml
env:
  DOCKERHUB_REPO: <your-dockerhub-username>/ai-bankapp-eks
```
<img width="637" height="467" alt="image" src="https://github.com/user-attachments/assets/59ab3fa7-aec9-4c11-b324-b4d9841ed9ab" />

<img width="1201" height="266" alt="image" src="https://github.com/user-attachments/assets/0da560f4-85f9-4a1a-83ca-d2f94e2fce90" />


**5. Update the ArgoCD Application to watch your fork:**
```bash
argocd app set bankapp --repo https://github.com/<your-username>/AI-BankApp-DevOps.git
```

<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/3d653194-6a52-4564-896e-2fb4fbf874a6" />


**6. Update the Kubernetes deployment to pull from your DockerHub:**
Edit `k8s/bankapp-deployment.yml`:
```yaml
image: <your-dockerhub-username>/ai-bankapp-eks:latest
```

Commit and push all changes to your fork's `feat/gitops` branch.

<img width="2557" height="1337" alt="image" src="https://github.com/user-attachments/assets/a6867d31-eb59-4eba-aa4e-592fec45e244" />
<img width="2505" height="1087" alt="image" src="https://github.com/user-attachments/assets/b96fd4ad-63ce-4e7f-9e74-0ac294dba3b8" />


---

### Task 3: Trigger the Full Pipeline
Make a visible code change in the application. Edit a file in `src/`:

For example, edit `src/main/resources/templates/fragments/layout.html` -- change the page title or footer text to include your name:
```html
<!-- Find the title or footer and add your touch -->
<title>AI BankApp - Built by YourName</title>
```

Commit and push:
```bash
git add src/
git commit -m "feat: customize app title"
git push origin feat/gitops
```

<img width="895" height="417" alt="image" src="https://github.com/user-attachments/assets/cbdd358a-1706-4d0f-a510-1cb3deb1c921" />


**Watch the pipeline:**
1. Go to your fork > Actions tab
2. The "GitOps CI - Build & Push to DockerHub" workflow should be running
3. Watch each step: build -> test -> push -> update manifest -> commit

**After the pipeline completes:**
- Check the last commit on your `feat/gitops` branch -- you should see a commit from `github-actions[bot]` with the message `ci: update bankapp image to <sha> [skip ci]`
- The `k8s/bankapp-deployment.yml` file now has the new image tag

<img width="1897" height="605" alt="image" src="https://github.com/user-attachments/assets/b274c355-99bf-4e7e-aabf-2c92fb18850e" />
<img width="702" height="205" alt="image" src="https://github.com/user-attachments/assets/2d963da1-4d19-4647-847b-8ced2fca6449" />
<img width="832" height="140" alt="image" src="https://github.com/user-attachments/assets/126bb4ab-202f-4027-9bac-747d9bff1d17" />


**Watch ArgoCD sync:**
```bash
argocd app get bankapp --refresh
argocd app wait bankapp
```



Or watch in the ArgoCD UI -- you will see a new sync event with the updated revision.

Check the pods:
```bash
kubectl get pods -n bankapp -w
```

<img width="772" height="200" alt="image" src="https://github.com/user-attachments/assets/8ef31338-969b-4519-8fd6-ae221a1922bf" />


You should see a rolling update -- new pods starting with the new image while old pods terminate gracefully.

Verify the change is live:
```bash
kubectl port-forward svc/bankapp-service -n bankapp 8080:8080

or

kubectl port-forward -n bankapp svc/bankapp-service 9090:8080

```

<img width="1141" height="391" alt="image" src="https://github.com/user-attachments/assets/4a0618cb-071c-448c-84d0-a7edcf7d08e7" />


Open `http://localhost:8080` or http://localhost:9090` and confirm your title change is visible.

**You just completed a full GitOps cycle:** code change -> CI builds image -> updates manifest -> ArgoCD deploys to production. Zero manual intervention.

<img width="2557" height="1382" alt="image" src="https://github.com/user-attachments/assets/2a5c6f5f-b223-4e3b-bf73-c5d4e60b4fbf" />


<img width="2547" height="1377" alt="image" src="https://github.com/user-attachments/assets/f72a67aa-b379-442f-b500-d0c544915762" />

<img width="812" height="202" alt="image" src="https://github.com/user-attachments/assets/bfb20398-d2e2-416e-a8d3-346ac0a266a9" />


---

### Task 4: Test Drift Detection and Recovery
GitOps means the cluster must always match Git. Test what happens when someone makes unauthorized changes.

**Scenario 1 -- Someone scales down the app directly:**
```bash
kubectl scale deployment bankapp -n bankapp --replicas=1
```

<img width="977" height="121" alt="image" src="https://github.com/user-attachments/assets/3a2a4f63-cce0-406a-be63-4fbd2798e3df" />


Check ArgoCD:
```bash
argocd app get bankapp
```

<img width="1367" height="867" alt="image" src="https://github.com/user-attachments/assets/71286b16-53c2-4560-9dee-540e741cce95" />


Status should show `OutOfSync`. With `selfHeal: true`, ArgoCD will correct it within 3 minutes. Monitor:
```bash
kubectl get pods -n bankapp -w
```

<img width="770" height="442" alt="image" src="https://github.com/user-attachments/assets/e903c3f3-fe18-4ff6-96ce-5de9a701b6dc" />


The replica count will return to 4 (or whatever the manifest specifies).

**Scenario 2 -- Someone updates the image tag directly:**
```bash
kubectl set image deployment/bankapp bankapp=nginx:latest -n bankapp
```

<img width="1057" height="52" alt="image" src="https://github.com/user-attachments/assets/a4177ce2-ce3c-491f-ac60-5bbfbe9f8c17" />


ArgoCD detects the drift and reverts it to the image tag from Git. The BankApp pods restart with the correct image.

**Scenario 3 -- Someone deletes a critical resource:**
```bash
kubectl delete service bankapp-service -n bankapp
```

<img width="880" height="45" alt="image" src="https://github.com/user-attachments/assets/aa802e87-6840-4218-8138-0b1d98ea346f" />


ArgoCD recreates it from Git.

**View all drift events:**
```bash
argocd app history bankapp
```

<img width="687" height="292" alt="image" src="https://github.com/user-attachments/assets/4e2a8f21-3dbd-45cd-9112-2b4a9503a3ff" />


In the ArgoCD UI, click the application and look at the "Events" tab. Every self-heal action is logged with the before/after state.


**Document:** In each scenario, how long did ArgoCD take to detect and fix the drift? What would happen if `selfHeal` was disabled?


| Scenario         | Drift Introduced                | ArgoCD Recovery                                 |
| ---------------- | ------------------------------- | ----------------------------------------------- |
| Scale Deployment | Scaled replicas from 3 to 1     | Restored deployment to 3 replicas automatically |
| Image Update     | Changed image to `nginx:latest` | Reverted image to Git-defined tag automatically |
| Delete Service   | Deleted `bankapp-service`       | Recreated the Service from Git automatically    |

## Recovery time observed

| Scenario         | Approximate Recovery Time |
| ---------------- | ------------------------- |
| Replica count    | ~1–2 minutes              |
| Image change     | Less than 30 seconds      |
| Service deletion | 2–10 seconds              |

## What if selfHeal were disabled?

> ArgoCD would still detect the application as OutOfSync, but it would not automatically restore the desired state.
> Manual synchronization from the ArgoCD UI or with argocd app sync bankapp would be required.


---

### Task 5: Reflect on the Complete DevOps Pipeline
Step back and look at everything you have built across the entire 90-day challenge that connects to this GitOps pipeline:

```
[Developer writes code]
    |
[Git push to GitHub]  ........... Day 22-28: Git & GitHub
    |
[GitHub Actions CI]   ........... Day 40-49: GitHub Actions
    |-- Build with Maven
    |-- Run tests
    |-- Build Docker image  ..... Day 29-37: Docker
    |-- Push to DockerHub
    |-- Update K8s manifest
    |-- Commit back to Git
    |
[ArgoCD detects change] ........ Day 84-86: GitOps
    |
[ArgoCD syncs to EKS]  ........ Day 81-83: EKS
    |-- Rolling update
    |-- Health checks pass
    |-- HPA scales as needed ... Day 78-80: Helm (HPA, values)
    |
[Prometheus scrapes metrics] ... Day 73-77: Observability
    |-- Grafana dashboards
    |-- Alerts if something breaks
    |
[App is live with zero downtime]
```

Every block in this challenge connects to the next. This is what a DevOps pipeline looks like in production.

```bash

# Task 5: Reflection on the Complete DevOps Pipeline

During this 90 Days of DevOps challenge, I built a complete end-to-end DevOps pipeline that automates the entire software delivery lifecycle—from writing code to deploying a production-ready application on Kubernetes using GitOps.

## Complete Pipeline

```
Developer writes code
        │
        ▼
Git Push to GitHub
(Day 22–28: Git & GitHub)
        │
        ▼
GitHub Actions CI Pipeline
(Day 40–49: GitHub Actions)
        │
        ├── Build the application using Maven
        ├── Execute automated tests
        ├── Build Docker image
        ├── Push image to DockerHub
        ├── Update Kubernetes deployment manifest
        └── Commit updated manifest back to Git
        │
        ▼
ArgoCD GitOps
(Day 84–86: GitOps)
        │
        ▼
Amazon EKS Cluster
(Day 81–83: Kubernetes on AWS EKS)
        │
        ├── Detect Git changes automatically
        ├── Synchronize cluster state
        ├── Perform rolling updates
        ├── Execute readiness and liveness probes
        └── Maintain desired state using self-healing
        │
        ▼
Horizontal Pod Autoscaler
(Day 78–80)
        │
        └── Automatically scales application pods based on workload
        │
        ▼
Monitoring & Observability
(Day 73–77)
        │
        ├── Prometheus collects application metrics
        ├── Grafana visualizes dashboards
        └── Alerts help detect failures quickly
        │
        ▼
Production Application
        │
        ├── Zero-downtime deployments
        ├── Automated recovery from configuration drift
        ├── Continuous deployment through GitOps
        └── Highly available Kubernetes application
```

## What I Learned

Throughout this challenge, I learned how each DevOps component integrates with the next to create a fully automated software delivery pipeline.

* Git and GitHub enabled version control and collaboration.
* GitHub Actions automated the CI pipeline by building, testing, containerizing, and publishing the application.
* Docker provided a consistent runtime environment across development and production.
* Kubernetes orchestrated the application containers and ensured high availability.
* Amazon EKS simplified the management of a production-grade Kubernetes cluster.
* Helm helped package and manage Kubernetes resources while enabling reusable deployments.
* ArgoCD implemented GitOps by continuously comparing the cluster state with the Git repository and automatically reconciling any differences.
* Prometheus and Grafana provided monitoring, metrics collection, and observability for the deployed application.

## GitOps Drift Recovery Testing

I validated GitOps self-healing by performing the following drift scenarios:

1. Scaled the deployment manually using `kubectl scale`. ArgoCD detected the drift and restored the deployment to the desired replica count.
2. Changed the application image manually using `kubectl set image`. ArgoCD reverted the deployment back to the image version defined in Git.
3. Deleted the `bankapp-service`. ArgoCD automatically recreated the missing Kubernetes Service from the Git repository.

These experiments demonstrated that Git remains the single source of truth and that unauthorized changes are automatically corrected.

## Final Outcome

At the end of the challenge, I successfully built a complete production-style DevOps platform consisting of:

* Spring Boot AI Bank Application
* MySQL and Redis integration
* Docker containerization
* GitHub Actions CI pipeline
* DockerHub image registry
* Amazon EKS Kubernetes cluster
* Helm-based deployments
* ArgoCD GitOps continuous deployment
* Automatic drift detection and self-healing
* Prometheus monitoring
* Grafana dashboards
* Rolling updates with minimal downtime
* Automated infrastructure reconciliation

This project provided practical experience with a modern DevOps workflow that closely resembles enterprise production environments, where every code change is automatically built, tested, deployed, monitored, and continuously reconciled through GitOps.

```

---

### Task 6: Complete Teardown
**Delete everything. This is the end of the EKS and ArgoCD block.**

Delete ArgoCD applications:
```bash
argocd app delete bankapp --cascade -y
argocd app delete monitoring --cascade -y 2>/dev/null
argocd app delete envoy-gateway --cascade -y 2>/dev/null
argocd app delete root-app --cascade -y 2>/dev/null
```

The `--cascade` flag tells ArgoCD to delete all Kubernetes resources managed by each application.

Wait for cleanup:
```bash
kubectl get all -n bankapp 2>/dev/null
kubectl get all -n monitoring 2>/dev/null
```

<img width="1357" height="952" alt="image" src="https://github.com/user-attachments/assets/5c13cf11-487a-4e3e-8df1-38e0c6627171" />


**Destroy the EKS cluster with Terraform:**
```bash
cd AI-BankApp-DevOps/terraform
terraform destroy
```

<img width="426" height="47" alt="image" src="https://github.com/user-attachments/assets/a16dd7ee-ff44-4138-894d-a5727ad0254a" />

Confirm deletion (type `yes`). This takes 10-15 minutes.

**Verify in the AWS Console:**
- EKS: no clusters
- EC2: no instances, no load balancers, no EBS volumes
- VPC: the `bankapp-eks` VPC is gone
- IAM: clean up roles with `eksctl` or `bankapp-eks` in the name


<img width="2552" height="1372" alt="image" src="https://github.com/user-attachments/assets/3b7b249c-e6ed-41c1-b37d-43c450864ece" />



**Final cost check:** Review AWS Billing Dashboard. All EKS charges should stop within the hour.

**Map the 3-day ArgoCD journey:**

| Day | What You Built |
|-----|---------------|
| 84 | ArgoCD setup, first GitOps deploy, self-healing |
| 85 | Sync waves, rollbacks, App of Apps, notifications, RBAC |
| 86 | Full CI/CD pipeline, code-to-production, drift detection, teardown |

---

# Documentation

---

# GitOps Pipeline Architecture

```text
                    Developer
                        │
                        ▼
              Git Push to GitHub
                        │
                        ▼
             GitHub Actions CI Pipeline
                        │
        ┌───────────────┼────────────────┐
        │               │                │
        ▼               ▼                ▼
 Build Maven      Run Tests      Build Docker Image
        │
        ▼
 Push Image to DockerHub
        │
        ▼
 Update Kubernetes Deployment YAML
        │
        ▼
 Commit Updated Manifest to GitHub
        │
        ▼
 Git Repository (Single Source of Truth)
        │
        ▼
               ArgoCD
        │
 Detect Git Changes
        │
        ▼
 Sync to Amazon EKS Cluster
        │
        ▼
 Rolling Update
        │
        ▼
 Readiness & Liveness Checks
        │
        ▼
 Healthy Application
        │
        ▼
 Prometheus + Grafana Monitoring
```

---

# GitHub Actions Workflow

The GitHub Actions workflow automates the complete Continuous Integration process.

## Step 1 – Trigger

The workflow starts automatically whenever code is pushed to the `master` branch.

---

## Step 2 – Checkout Repository

The latest application source code is checked out from GitHub.

---

## Step 3 – Setup Java

Java 21 is installed using GitHub Actions.

---

## Step 4 – Build Application

The Spring Boot application is compiled using Maven.

```bash
./mvnw clean package
```

---

## Step 5 – Run Tests

Application tests are executed to validate the build.

```bash
./mvnw test
```

---

## Step 6 – Build Docker Image

Docker Buildx creates the application image.

Example:

```
shettymalathi113/ai-bankapp-eks:d71a1f9
```

---

## Step 7 – Push Image

The Docker image is pushed to DockerHub.

---

## Step 8 – Update Kubernetes Manifest

GitHub Actions automatically replaces the image tag inside

```
k8s/bankapp-deployment.yml
```

Example

Before

```yaml
image: shettymalathi113/ai-bankapp-eks:e144f11
```

After

```yaml
image: shettymalathi113/ai-bankapp-eks:d71a1f9
```

---

## Step 9 – Commit Manifest

The GitHub Actions Bot commits the updated deployment manifest back into Git.

Example commit

```
ci: update image to d71a1f9 [skip ci]
```

---

## Step 10 – ArgoCD Synchronization

ArgoCD continuously watches the Git repository.

Once it detects the new image tag:

- Syncs automatically
- Performs rolling update
- Waits for health probes
- Marks application Healthy

No manual deployment is required.

---

# GitHub Actions Workflow Screenshot

<img width="2296" height="1202" alt="image" src="https://github.com/user-attachments/assets/98acf86b-e65c-4cb9-b95f-7990d8ffa6a8" />
<img width="1920" height="2313" alt="image" src="https://github.com/user-attachments/assets/a69bb8d5-bb2d-41d4-94fc-d72eb676832b" />


---

# GitHub Actions Bot Commit

<img width="1387" height="287" alt="image" src="https://github.com/user-attachments/assets/311575d9-c557-4d45-826e-28a758df693c" />


---

# ArgoCD Synchronization

<img width="2552" height="862" alt="image" src="https://github.com/user-attachments/assets/115d9e91-86cb-4386-a72b-50233952456f" />


```
Application: bankapp

Status:
Healthy

Sync:
Synced
```

---

# Drift Detection Testing

GitOps ensures the cluster always matches Git.

---

## Scenario 1 – Manual Scaling

Command

```bash
kubectl scale deployment bankapp \
-n bankapp \
--replicas=1
```

Result

ArgoCD detected the drift and restored the deployment to the desired replica count automatically.

Status

✅ Passed

Approximate recovery time

**1–2 minutes**

---

## Scenario 2 – Manual Image Change

Command

```bash
kubectl set image deployment/bankapp \
bankapp=nginx:latest \
-n bankapp
```

Result

ArgoCD reverted the image back to

```
shettymalathi113/ai-bankapp-eks:998e111
```

Status

✅ Passed

Approximate recovery time

**Less than 30 seconds**

---

## Scenario 3 – Delete Service

Command

```bash
kubectl delete service bankapp-service \
-n bankapp
```

Result

ArgoCD recreated the service automatically.

Status

✅ Passed

Approximate recovery time

**2–10 seconds**

---

# Full DevOps Pipeline

```text
Developer
    │
    ▼
GitHub
    │
    ▼
GitHub Actions
    │
    ├── Maven Build
    ├── Tests
    ├── Docker Build
    ├── Docker Push
    └── Update Kubernetes YAML
             │
             ▼
        Git Repository
             │
             ▼
          ArgoCD
             │
             ▼
 Amazon EKS Kubernetes Cluster
             │
             ▼
 Rolling Updates
             │
             ▼
 Prometheus Metrics
             │
             ▼
 Grafana Dashboards
             │
             ▼
 Production Application
```

---

# Key Takeaways

During the GitOps block I learned:

- Git became the single source of truth.
- GitHub Actions automated the CI pipeline.
- Docker images were versioned using Git commit hashes.
- Kubernetes deployments were managed declaratively.
- ArgoCD continuously monitored Git.
- Drift detection automatically corrected unauthorized changes.
- Rolling updates enabled zero-downtime deployments.
- GitOps eliminated manual deployments.
- Every infrastructure change was fully auditable.
- Self-healing ensured the cluster always matched Git.

---

# Teardown Verification

The following cleanup was completed:

- Deleted ArgoCD Applications
- Removed BankApp namespace resources
- Destroyed Amazon EKS cluster using Terraform
- Verified removal of EC2 instances
- Verified removal of Load Balancers
- Verified removal of EBS volumes
- Verified removal of VPC resources
- Checked AWS Billing Dashboard

---

# Screenshots

Include the following screenshots:

- GitHub Actions successful workflow
- DockerHub image pushed
- github-actions[bot] commit
- ArgoCD Synced application
- Drift Detection – Replica recovery
- Drift Detection – Image recovery
- Drift Detection – Service recreation
- Terraform destroy completed
- AWS Console showing EKS deleted
- AWS Billing verification

---

# Conclusion

This project completed the GitOps section of the 90 Days of DevOps challenge by implementing a production-style continuous delivery pipeline. The entire workflow—from code commit to deployment on Amazon EKS—became fully automated using GitHub Actions, Docker, Kubernetes, and ArgoCD. Drift detection and self-healing ensured the cluster continuously matched the desired state defined in Git, demonstrating the core principles of GitOps in a real-world environment.
