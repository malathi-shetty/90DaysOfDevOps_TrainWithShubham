# Day 89 -- Production AI Agents: KubeHealer and AIOps
---

## Challenge Tasks

### Task 1: Understand AIOps and Production Guardrails (Module 4)
Before building production agents, understand the rules:

1. **What is AIOps?**
   - Using AI to automate IT operations: monitoring, diagnosis, remediation
   - Not replacing humans -- augmenting them with intelligent automation
   - The agent handles routine issues (image typos, resource limits) while escalating complex ones

2. **Production guardrails every AI agent needs:**

| Guardrail | Why | Example |
|-----------|-----|---------|
| **Human approval** | Agents should not make destructive changes without permission | "I found 3 broken pods. Here are the fixes. Approve?" |
| **Scope limits** | Agents should only operate in allowed namespaces/clusters | Cannot touch `kube-system` or production databases |
| **Audit trail** | Every action must be recorded | Temporal workflow history: every tool call, every decision |
| **Rollback capability** | Every fix must be reversible | Agent creates patches, not replacements |
| **Timeout and retry limits** | Agents must not loop forever | Max 3 retries per pod, timeout after 5 minutes |
| **Escalation path** | When the agent cannot fix it, alert a human | "config-app needs a ConfigMap I cannot create. Escalating." |

3. **Why durable execution (Temporal) matters:**
   - Without durability: if the agent crashes mid-diagnosis, you lose all progress and state
   - With Temporal: every step is recorded. If the worker crashes and restarts, Temporal replays completed steps from history and resumes
   - This is critical for agents that modify infrastructure -- you cannot afford partial fixes

4. **When to use AI agents vs traditional automation:**

| Use AI Agents When | Use Traditional Automation When |
|--------------------|---------------------------------|
| Problem requires reasoning (diagnose unknown errors) | Problem has a known, fixed solution |
| Multiple possible causes and fixes | One cause, one fix (if X then Y) |
| Natural language output helps humans | No human in the loop |
| Examples: troubleshooting, root cause analysis | Examples: scaling, restarts, deploys |


---


## 1. What is AIOps?

**AIOps (Artificial Intelligence for IT Operations)** is the use of AI to help automate and improve IT operations such as:

* Monitoring systems
* Detecting failures
* Diagnosing root causes
* Suggesting or applying fixes
* Escalating problems that require human intervention

Unlike traditional automation, AIOps can **reason** about problems instead of simply following predefined rules.

### Example

Traditional automation:

```
IF pod status == CrashLoopBackOff
THEN restart pod
```

AI Agent:

```
Pod is CrashLoopBackOff
↓
Read pod events
↓
Analyze logs
↓
Identify root cause (OOMKilled)
↓
Recommend increasing memory
↓
Ask for approval
↓
Apply patch
```

The AI agent doesn't just restart the pod—it understands **why** it failed.

---

## 2. AI Does Not Replace Humans

AIOps is designed to **augment** engineers, not replace them.

Routine issues can be handled automatically:

* Image name typos
* Incorrect resource limits
* Simple configuration mistakes

Complex or risky issues should be escalated:

* Missing secrets
* Missing ConfigMaps
* Database failures
* Security incidents
* Production infrastructure changes

Think of the AI as a junior SRE that performs repetitive work but asks a senior engineer before making important decisions.

---

# 3. Production Guardrails

Production AI agents must operate safely.

| Guardrail                  | Why it Matters                                    | Example                                               |
| -------------------------- | ------------------------------------------------- | ----------------------------------------------------- |
| **Human approval**         | Prevents unsafe automatic changes                 | "Found 3 broken pods. Approve fixes?"                 |
| **Scope limits**           | Restricts where the agent can act                 | Never modify `kube-system` or production databases    |
| **Audit trail**            | Records every action for debugging and compliance | Temporal stores every workflow step                   |
| **Rollback capability**    | Makes fixes reversible                            | Apply `kubectl patch` instead of recreating resources |
| **Timeout & retry limits** | Prevents endless loops                            | Retry at most 3 times, timeout after 5 minutes        |
| **Escalation path**        | Hands unresolved issues to humans                 | Missing ConfigMap → notify operator                   |

### Why each guardrail matters

### Human Approval

Before making infrastructure changes, the agent pauses and asks:

```
Found 3 broken pods.

Proposed fixes:

1. Fix image typo
2. Increase memory
3. Escalate ConfigMap issue

Approve? (yes/no)
```

This ensures humans remain in control.

---

### Scope Limits

The agent should only modify approved resources.

Example:

 Allowed

```
default
development
staging
```

Not allowed

```
kube-system
kube-public
production databases
```

This prevents accidental damage to critical infrastructure.

---

### Audit Trail

Every decision should be recorded.

Temporal records:

* Workflow start
* Pod scan
* Claude diagnosis
* Proposed fix
* Human approval
* Patch execution
* Workflow completion

This creates a complete history for debugging and compliance.

---

### Rollback Capability

Good agents make **small, reversible changes**.

Instead of deleting and recreating a pod:



```
kubectl delete pod web-app
kubectl apply -f pod.yaml
```

Use a patch:



```
kubectl patch pod web-app ...
```

If something goes wrong, reverting the patch is much easier.

---

### Timeout and Retry Limits

Agents should never get stuck in infinite loops.

Example policy:

* Maximum 3 repair attempts per pod
* Stop after 5 minutes
* Escalate if still failing

This avoids repeatedly applying ineffective fixes.

---

### Escalation Path

Some issues require human judgment.

Example:

```
config-app
```

fails because:

```
ConfigMap "app-config" not found
```

The agent should **not** create a ConfigMap automatically because it doesn't know the correct configuration values.

Instead, it reports:

```
Missing ConfigMap detected.

Manual intervention required.

Escalating to operator.
```

---

# 4. Why Durable Execution (Temporal) Matters

Without Temporal:

```
Worker starts
↓
Scans cluster
↓
Diagnoses pod 1
↓
Diagnoses pod 2
↓
Worker crashes
```

Everything is lost.

The workflow must restart from the beginning.

---

With Temporal:

```
Worker starts
↓
Scan completed ✓
↓
Diagnosis completed ✓
↓
Worker crashes
↓
Restart worker
↓
Temporal replays history
↓
Resume exactly where it stopped
```

Nothing is lost.

This is especially important because infrastructure changes should not be partially executed or repeated accidentally.

---

# 5. AI Agents vs Traditional Automation

| Use AI Agents When                       | Use Traditional Automation When                    |
| ---------------------------------------- | -------------------------------------------------- |
| The problem requires reasoning           | The solution is already known                      |
| Multiple possible root causes exist      | One cause has one fixed solution                   |
| Human-readable explanations are valuable | No human interaction is needed                     |
| Troubleshooting unknown failures         | Restarting services, scaling replicas, deployments |

### AI Agent Example

```
Pod failed.

Possible causes:
- Wrong image
- OOMKilled
- Missing Secret
- Missing ConfigMap
- Network issue

Reason through logs and events
↓

Choose the correct fix
```

---

### Traditional Automation Example

```
CPU > 80%

↓

Scale deployment to 5 replicas
```

No reasoning is required because the action is predefined.

---

# Key Takeaways

* **AIOps** uses AI to monitor, diagnose, and remediate IT issues while keeping humans in control.
* **Production guardrails** (approval, scope limits, audit trails, rollback, retries/timeouts, and escalation) are essential for safe AI-driven operations.
* **Temporal** provides durable execution, allowing workflows to survive crashes and resume without losing progress.
* Use **AI agents** for problems that require reasoning and decision-making, and use **traditional automation** for deterministic, repetitive tasks.


---

### Task 2: Set Up KubeHealer
KubeHealer lives in a separate repository. Clone it:

```bash
git clone https://github.com/TrainWithShubham/kubehealer.git
cd kubehealer
```

<img width="857" height="317" alt="image" src="https://github.com/user-attachments/assets/3da3cc60-eeb0-4ed6-b779-975ae8293a93" />


**Prerequisites:**
- Docker (for Temporal)
- Kind (for Kubernetes cluster)
- Python 3.10+
- An Anthropic API key (Claude Sonnet 4 -- sign up at https://console.anthropic.com)
- Download temporal cli & check version
    - wget "https://temporal.download/cli/archive/latest?platform=linux&arch=amd64"
    - mv "latest?platform=linux&arch=amd64" temporal-cli.tar.gz
    - sudo mv temporal /usr/local/bin/
    - sudo chmod +x /usr/local/bin/temporal
    - temporal --version


<img width="2321" height="1252" alt="image" src="https://github.com/user-attachments/assets/27bfa568-b283-4e0a-b820-947a888b4f56" />

<img width="1122" height="272" alt="image" src="https://github.com/user-attachments/assets/96da9e4b-9a4e-46c5-8066-8a43faa429ef" />
<img width="946" height="377" alt="image" src="https://github.com/user-attachments/assets/7637f948-f7c7-4ff8-a771-6abe674175c0" />


<img width="1437" height="1127" alt="image" src="https://github.com/user-attachments/assets/392769ed-c522-43bd-ba70-fb0df473abae" />



**Create the cluster and deploy broken apps:**

1. Create the cluster and deploy broken apps:
```bash
./setup.sh
```
This creates a Kind cluster called `kubehealer` and deploys 3 intentionally broken apps. You should see:

```
Pod status:
  web-app-xxx       0/1     ErrImagePull
  memory-hog-xxx    0/1     CrashLoopBackOff
  config-app-xxx    0/1     CreateContainerConfigError
```

<img width="972" height="1246" alt="image" src="https://github.com/user-attachments/assets/73c126fc-30e4-4b16-9e28-c110d750ad5c" />


2. Start Temporal (durable execution engine):
```bash
temporal server start-dev
```

This runs Temporal locally. The UI is available at `http://localhost:8233`.

<img width="697" height="327" alt="image" src="https://github.com/user-attachments/assets/340e884e-ccb9-4e71-9ea1-cbbd74c8995f" />

## Open a browser and visit:
`http://localhost:8233`

<img width="2560" height="1272" alt="image" src="https://github.com/user-attachments/assets/f067ac83-c32f-49dd-a3eb-5edfd51c22dd" />


3. Set up the Python environment:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

<img width="637" height="47" alt="image" src="https://github.com/user-attachments/assets/60997efe-e743-47f2-bedb-cff6c5691ab3" />
<img width="1476" height="892" alt="image" src="https://github.com/user-attachments/assets/c4766688-b621-4149-ae09-a0915130e987" />
<img width="647" height="977" alt="image" src="https://github.com/user-attachments/assets/10a84c70-b6d0-4938-8c69-63ba031e7613" />



4. Set your Anthropic API key:
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

```bash
How to get an Anthropic API key
Go to the Anthropic Console. - https://platform.claude.com/dashboard
Sign in or create an account.
Navigate to the API Keys section.
Click Create Key.
Copy the generated key (it typically begins with sk-ant-).
Use it in your terminal:
```

<img width="2550" height="1327" alt="image" src="https://github.com/user-attachments/assets/164bd05b-1269-46ff-bcf9-86bd22b2afe2" />

<img width="2547" height="1321" alt="image" src="https://github.com/user-attachments/assets/1f705984-d6cd-4141-9936-374218799db5" />
<img width="2552" height="661" alt="image" src="https://github.com/user-attachments/assets/f12a8f5d-a0b5-4d18-b7f1-cbec86f9af81" />

<img width="1676" height="35" alt="image" src="https://github.com/user-attachments/assets/5d319770-3c3f-4815-b87c-7c54f4e73795" />


---

### Task 3: Deploy Broken Applications



In this task, you'll deploy **three intentionally broken Kubernetes Pods**. Each one represents a common real-world issue that KubeHealer should detect and handle differently:

*  **web-app** → Image typo (**agent can fix**)
*  **memory-app** → Out of Memory (**agent can fix**)
*  **config-app** → Missing ConfigMap (**agent should escalate**)

---

# Step 1: Verify Your Cluster is Running

Before deploying anything, check that your Kind cluster is available:

```bash
kubectl get nodes
```

Expected output:

```text
NAME                                 STATUS   ROLES           AGE
kubehealer-demo-control-plane        Ready    control-plane   10m
```

---

# Step 2: Deploy App 1 – Image Typo

Create the first broken Pod:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-app
  namespace: default
spec:
  containers:
  - name: web
    image: ngnix:latest
    ports:
    - containerPort: 80
EOF
```

Expected output:

```text
pod/web-app created
```

---

## Why is it broken?

The image name contains a typo:



```text
ngnix:latest
```

Correct image:



```text
nginx:latest
```

Kubernetes will repeatedly try to pull the image.

Since it doesn't exist, the pod enters:

```text
ImagePullBackOff
```

---

## Verify

```bash
kubectl get pod web-app
```

Initially you may see:

```text
ContainerCreating
```

Wait a few seconds and check again:

```bash
kubectl get pod web-app
```

Expected:

```text
NAME      READY   STATUS             RESTARTS
web-app   0/1     ImagePullBackOff   0
```

---

## Inspect the Failure

Run:

```bash
kubectl describe pod web-app
```

Near the bottom, you'll find events similar to:

```text
Failed to pull image "ngnix:latest"

Error response from daemon:

pull access denied
```

This is the information KubeHealer will send to Claude for diagnosis.

---

# Step 3: Deploy App 2 – OOM Crash

Create the second broken Pod:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: memory-app
  namespace: default
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      limits:
        memory: "1Mi"
    command: ["sh", "-c", "echo 'starting' && sleep 3600"]
EOF
```

Expected:

```text
pod/memory-app created
```

---

## Why is it broken?

The container has a memory limit of:

```text
1Mi
```

Nginx needs significantly more memory just to start.

The Linux kernel kills the container due to an **Out of Memory (OOM)** condition.

The pod repeatedly restarts and eventually enters:

```text
CrashLoopBackOff
```

---

## Verify

```bash
kubectl get pod memory-app
```

Initially:

```text
Running
```

After a few restarts:

```text
NAME          READY   STATUS             RESTARTS
memory-app    0/1     CrashLoopBackOff   3
```

---

## Inspect the Failure

Run:

```bash
kubectl describe pod memory-app
```

Look for events such as:

```text
OOMKilled
Back-off restarting failed container
```

KubeHealer will diagnose this as an insufficient memory limit and propose increasing it (e.g., to **128Mi**).

---

# Step 4: Deploy App 3 – Missing ConfigMap

Create the third broken Pod:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: config-app
  namespace: default
spec:
  containers:
  - name: app
    image: nginx:alpine
    envFrom:
    - configMapRef:
        name: app-config
EOF
```

Expected:

```text
pod/config-app created
```

---

## Why is it broken?

The pod expects this ConfigMap:

```text
app-config
```

But it doesn't exist.

Because Kubernetes can't populate the environment variables, the container never starts.

The pod enters:

```text
CreateContainerConfigError
```

---

## Verify

```bash
kubectl get pod config-app
```

Expected:

```text
NAME         READY   STATUS                          RESTARTS
config-app   0/1     CreateContainerConfigError      0
```

---

## Inspect the Failure

Run:

```bash
kubectl describe pod config-app
```

Near the bottom:

```text
ConfigMap "app-config" not found
```

Unlike the previous two issues, KubeHealer should **not** create the missing ConfigMap automatically because it cannot safely infer the required configuration values. Instead, it should escalate this issue for human intervention.

---

# Step 5: Check All Pods

Now list all Pods:

```bash
kubectl get pods
```

Expected output:

```text
NAME         READY   STATUS                         RESTARTS
web-app      0/1     ImagePullBackOff              0
memory-app   0/1     CrashLoopBackOff              3
config-app   0/1     CreateContainerConfigError    0
```

> **Note:** The exact restart count for `memory-app` may vary (e.g., 2, 3, or more) depending on how long you've waited.

---

# Step 6: Optional – Get More Details

You can gather additional information that KubeHealer will also use.

List Pods with more details:

```bash
kubectl get pods -o wide
```
<img width="1585" height="362" alt="image" src="https://github.com/user-attachments/assets/d776bea3-f74c-4107-b701-d841f5f3566b" />


View events:

```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

<img width="2432" height="1242" alt="image" src="https://github.com/user-attachments/assets/4a79654e-cada-46c2-9462-7a72a3978eaa" />


Describe each Pod:

```bash
kubectl describe pod web-app
kubectl describe pod memory-app
kubectl describe pod config-app
```

<img width="2425" height="1220" alt="image" src="https://github.com/user-attachments/assets/7f4981c9-a75a-4d77-ae1d-f8d277e2c549" />
<img width="2412" height="1265" alt="image" src="https://github.com/user-attachments/assets/57d7d63a-6642-4bc5-bc1c-0f98dc041e94" />
<img width="1331" height="1175" alt="image" src="https://github.com/user-attachments/assets/98f019dc-d6fc-45ad-a936-e1109e8b61a8" />


---

# Summary of the Three Failures

| Pod            | Problem                      | Kubernetes Status            | Can KubeHealer Fix? | Expected Action                       |
| -------------- | ---------------------------- | ---------------------------- | ------------------- | ------------------------------------- |
| **web-app**    | Image typo (`ngnix`)         | `ImagePullBackOff`           |  Yes               | Patch image to `nginx:latest`         |
| **memory-app** | Memory limit too low (`1Mi`) | `CrashLoopBackOff`           |  Yes               | Increase memory limit (e.g., `128Mi`) |
| **config-app** | Missing `ConfigMap`          | `CreateContainerConfigError` |  No                | Escalate to human                     |

---




KubeHealer needs something to fix. Deploy three intentionally broken applications:

### Deploy App 1 – Image Typo
<img width="677" height="76" alt="image" src="https://github.com/user-attachments/assets/39dfc29d-3afa-4dc7-9082-9045ada31f70" />
<img width="777" height="357" alt="image" src="https://github.com/user-attachments/assets/9a77608a-9a30-4bef-bfe2-b985192dcb09" />
<img width="2411" height="1215" alt="image" src="https://github.com/user-attachments/assets/1f21fd1b-c07a-418c-ae6e-3976c35094c4" />

### Deploy App 2 – OOM Crash
<img width="847" height="427" alt="image" src="https://github.com/user-attachments/assets/f1744bd7-439a-4ae3-8525-1e0b3ac8ce05" />
<img width="2410" height="1262" alt="image" src="https://github.com/user-attachments/assets/e1dc2a0c-5840-477e-83b9-3be60ab29459" />


### Deploy App 3 – Missing ConfigMap
<img width="1022" height="402" alt="image" src="https://github.com/user-attachments/assets/a93f08c0-d730-4e09-aa5e-80e5c62c0f02" />
<img width="1297" height="1175" alt="image" src="https://github.com/user-attachments/assets/6fcb5260-f862-4c5a-ac8b-b1709bda0261" />


---

### Task 4: Run KubeHealer
Start the Temporal worker (the agent):
```bash
python3 worker.py
```

<img width="706" height="216" alt="image" src="https://github.com/user-attachments/assets/7f32fa9a-838d-4324-a533-c946a4c8aac7" />


Start the CLI
```bash
python3 cli.py
```
```
you> how many pods are running?
you> what's wrong with web-app?
you> show me the logs for memory-hog
you> heal my cluster
you> approve all fixes
```

<img width="1187" height="1146" alt="image" src="https://github.com/user-attachments/assets/8cde444f-9b55-4cf2-9a53-f9965aed5246" />
<img width="1260" height="580" alt="image" src="https://github.com/user-attachments/assets/31a5368b-36fe-4cf0-8e66-5d8bf0656e22" />


**Watch the agent work.** It will:

1. **Scan** -- list all pods, identify broken ones
2. **Diagnose** -- for each broken pod, call `kubectl describe`, read events, send to Claude
3. **Propose fixes:**
   - `web-app`: "Image typo. Fix: change `ngnix:latest` to `nginx:latest`"
   - `memory-app`: "OOMKilled. Fix: increase memory limit to 128Mi"
   - `config-app`: "Missing ConfigMap `app-config`. Cannot fix automatically -- requires manual ConfigMap creation"
4. **Ask for approval** -- presents all fixes and waits for human input

In the terminal, you will see:
```
Found 3 broken pods.

Proposed fixes:
1. web-app: Fix image typo (ngnix -> nginx)
2. memory-app: Increase memory limit (1Mi -> 128Mi)
3. config-app: CANNOT FIX - needs manual ConfigMap creation

Approve all fixes? [yes/no]:
```

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: web-app
  namespace: default
spec:
  containers:
  - name: web
    image: nginx:latest
    ports:
    - containerPort: 80
EOF
```
```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: memory-app
  namespace: default
spec:
  containers:
  - name: app
    image: nginx:alpine
    resources:
      limits:
        memory: "128Mi"
    command: ["sh", "-c", "echo 'starting' && sleep 3600"]
EOF
```



Type `yes`. The agent:
- Patches `web-app` with the correct image
- Patches `memory-app` with increased memory
- Skips `config-app` and reports it needs human attention

Verify:
```bash
kubectl get pods
```

<img width="781" height="712" alt="image" src="https://github.com/user-attachments/assets/241b95fb-43a0-4a6a-a1f7-e9402902da6a" />


`web-app` and `memory-app` should now be Running. `config-app` still broken (as expected).




### Fix config-app manually

The agent told you config-app needs a ConfigMap. Create it:

```bash
kubectl create configmap app-config --from-literal=APP_ENV=production --from-literal=APP_DEBUG=false
kubectl rollout restart deployment config-app
```

Verify:
```bash
kubectl get pods
```

`Now all 3 pods should be healthy.`

<img width="1366" height="372" alt="pods" src="https://github.com/user-attachments/assets/e4aa451a-348b-4950-8e95-01dc6b5ba9cc" />
<img width="736" height="267" alt="image" src="https://github.com/user-attachments/assets/1c24423d-0bbe-457e-8ef7-b442f872c8ef" />
<img width="2560" height="4900" alt="image" src="https://github.com/user-attachments/assets/c81b87f2-011d-4729-a260-7b172515d8ab" />


> The KubeHealer conversational interface successfully scanned and diagnosed all three intentionally broken pods.
> The automated healing workflow could not proceed because the Anthropic API returned an "insufficient credits" error during the diagnosis activity.
> As a result, the approval and patching stages could not be demonstrated. In a fully funded Anthropic account, the workflow would request approval, patch the image typo and memory limit, and escalate the missing ConfigMap.


### Task 5: Test Crash Recovery (Temporal Durability)
This is the production-grade feature. Temporal makes the agent crash-resistant.

**Redeploy the broken apps:**
```bash
./setup.sh
```

<img width="1916" height="1146" alt="image" src="https://github.com/user-attachments/assets/76483230-f14a-4e38-af69-16233b36281b" />

<img width="1725" height="247" alt="image" src="https://github.com/user-attachments/assets/1a6588b5-2643-46b6-abee-74e4110c1076" />
<img width="1240" height="1132" alt="image" src="https://github.com/user-attachments/assets/ade2f0ae-22fe-4c58-ad49-97660320f206" />
<img width="1337" height="1262" alt="image" src="https://github.com/user-attachments/assets/0bfda301-d03e-4bf1-b8a7-08bdb2209050" />
<img width="1632" height="1227" alt="image" src="https://github.com/user-attachments/assets/2032b8b7-d123-4feb-bf1d-f797e817360d" />
<img width="937" height="431" alt="image" src="https://github.com/user-attachments/assets/c837e7d7-6891-4e04-b3e5-38216fed1b79" />


**Start healing**
In the CLI:
```bash
you> heal my cluster
```
Watch the agent start scanning and diagnosing.


<img width="1612" height="1267" alt="image" src="https://github.com/user-attachments/assets/8d812b47-add9-41ba-a2c0-699b771ec617" />


**Kill the worker**

While the agent is mid-diagnosis, go to Terminal (worker) and press **Ctrl+C**.

The workflow is now stuck. Open http://localhost:8233 -- you'll see the workflow in "Running" state with some activities completed and the current one pending.

<img width="1262" height="772" alt="image" src="https://github.com/user-attachments/assets/80ae91d3-d01d-448e-819b-d9a65bbe6f92" />


**Restart the worker**

```bash
python worker.py
```

<img width="887" height="357" alt="image" src="https://github.com/user-attachments/assets/b510b614-295a-4491-a457-bf0b3c930be6" />


Go back to the Temporal UI. The workflow resumes immediately. Activities that already completed (scan, some diagnoses) are NOT re-executed -- Temporal replays them from cached results. Only the remaining work runs.

<img width="2545" height="1380" alt="image" src="https://github.com/user-attachments/assets/97f42269-9dd1-4d99-859e-2f340851d728" />
<img width="2557" height="942" alt="image" src="https://github.com/user-attachments/assets/deb83654-2566-4e84-a5a8-3b04624f6f79" />


The CLI gets the response as if nothing happened.

This is durable execution. The agent's state lives in Temporal, not in the Python process.

<img width="1412" height="212" alt="image" src="https://github.com/user-attachments/assets/0721dbf8-9d83-418e-b094-b509518d1ff7" />
<img width="775" height="366" alt="image" src="https://github.com/user-attachments/assets/b9fe4090-815b-465b-bf85-a9d4923cfffc" />


**Kill the CLI**

You can also kill the CLI (Ctrl+C) and restart it:

```bash
python cli.py
```

It reconnects to the same conversation. Your chat history is preserved.


<img width="852" height="1272" alt="image" src="https://github.com/user-attachments/assets/d0892311-b4cd-426e-83d3-e14fbc260606" />



**Temporal UI**

Open http://localhost:8233 in your browser.

Click on any completed workflow. Go to the History tab. You'll see every event:

- `WorkflowExecutionStarted`
- `ActivityTaskScheduled` (call_claude)
- `ActivityTaskCompleted` (Claude's response)
- `ActivityTaskScheduled` (list_pods -- Claude called a tool)
- `ActivityTaskCompleted` (pod list returned)
- `ActivityTaskScheduled` (call_claude -- with tool result)
- `ActivityTaskCompleted` (Claude's final answer)
- ...and so on for every interaction

<img width="2537" height="1097" alt="image" src="https://github.com/user-attachments/assets/56aa09e8-8137-423c-8d16-bc3b5521dec9" />


This is the audit trail. Every Claude call, every kubectl command, every fix -- all recorded automatically.



That statement means:

**Temporal acts as the audit trail for the AI agent workflow.**

Instead of manually adding logging everywhere, Temporal automatically records the complete history of the workflow execution.

For KubeHealer, this includes:

```
Workflow Started
        |
        ↓
Scan Kubernetes Cluster
        |
        ↓
kubectl get pods
        |
        ↓
Found unhealthy pods
        |
        ↓
kubectl describe pod web-app
        |
        ↓
Send diagnosis request to Claude
        |
        ↓
Claude response:
"Image typo: ngnix → nginx"
        |
        ↓
Human approval received
        |
        ↓
kubectl patch web-app
        |
        ↓
Pod fixed
        |
        ↓
Workflow Completed
```

In the Temporal UI **History** tab, every step is stored as an event:

* `WorkflowExecutionStarted`

  * When the agent workflow began

* `ActivityTaskScheduled`

  * A task was requested (example: diagnose pod)

* `ActivityTaskStarted`

  * Worker started executing that task

* `ActivityTaskCompleted`

  * Task finished successfully with output

* `ActivityTaskFailed`

  * Task failed (example: Anthropic API error)

* `WorkflowExecutionCompleted`

  * Workflow finished successfully

---

For KubeHealer specifically, the audit trail answers questions like:

**"Why did the agent change this pod?"**

You can inspect:

```
Claude analysis:
"web-app failed because image name is ngnix instead of nginx"

↓

Approval:
"yes"

↓

Action:
kubectl patch pod web-app

↓

Result:
Pod Running
```

---

**"What happened when the worker crashed?"**

Temporal shows:

```
Diagnosis completed ✓

Worker stopped

Worker restarted

Workflow resumed
```

No manual recovery log was needed.

---

**"Who approved the production change?"**

The workflow history contains the approval event.

---

This is why production AI agents need durable execution:

* AI reasoning is recorded
* Tool calls are recorded
* Infrastructure changes are recorded
* Failures are recorded
* Recovery points are recorded

For your Day 89 report, you can write:

> Temporal provides the audit trail for KubeHealer. Every workflow step, including Kubernetes tool calls, Claude diagnosis requests, approval decisions, fixes, and failures, is automatically recorded in workflow history. This allows operators to understand exactly what the AI agent did, why it made a decision, and how the infrastructure changed.



---

### Task 6: Reflect on the Agentic AI Journey
Map the 3-day progression:

| Day | Module | What You Built | Pattern |
|-----|--------|---------------|---------|
| 87 | 0-2 | Docker Error Explainer + Docker Agent | Basic LLM -> ReAct Agent |
| 88 | 3, 6 | Multi-tool Agent + MCP Server + CI/CD Analyzer | Multi-domain tools, MCP protocol |
| 89 | 4-5 | KubeHealer -- production self-healing agent | Temporal durability, human approval, guardrails |

**The evolution:**
```
Day 87: LLM explains errors (passive)
   |
Day 88: Agent diagnoses across Docker/K8s/CI (autonomous investigation)
   |
Day 89: Agent diagnoses AND fixes with approval (autonomous action)
```

**Key principles for production AI agents:**
1. **Tools are just CLI wrappers** -- any command you run can become a tool
2. **The ReAct pattern is universal** -- works for any domain
3. **MCP standardizes tool access** -- write once, use everywhere
4. **Guardrails are not optional** -- approval, scope limits, audit trails
5. **Durability matters** -- Temporal prevents lost state during infrastructure changes
6. **Know when NOT to use AI** -- simple if/then automation is better for known problems


**Clean up:**
```bash
kind delete cluster --name kubehealer
# Stop Temporal (Ctrl+C the server)
deactivate
```

<img width="812" height="135" alt="image" src="https://github.com/user-attachments/assets/be269369-8c6c-4445-800c-295f212fdd5c" />


---

# Documentation:

# Day 89 - KubeHealer: Production AI Agents and AIOps

## Overview

Day 89 focuses on building a production-grade AI operations (AIOps) agent.

KubeHealer is an autonomous Kubernetes troubleshooting agent that:

- Scans Kubernetes clusters for unhealthy workloads
- Diagnoses root causes using Claude
- Proposes remediation actions
- Waits for human approval
- Applies safe fixes
- Uses Temporal for durable workflow execution

This moves AI agents from passive assistants into systems that can safely take operational actions.

---

# 1. AIOps Principles

## What is AIOps?

AIOps (Artificial Intelligence for IT Operations) combines AI with infrastructure operations to automate:

- Monitoring
- Failure detection
- Root cause analysis
- Remediation
- Incident response

The goal is not to replace engineers.

AI agents augment engineers by handling repetitive operational tasks while escalating complex or risky problems.

Examples:

Automatically handle:

- Incorrect container images
- Resource limit problems
- Basic Kubernetes failures

Escalate:

- Security issues
- Missing business configuration
- Production database changes

---

# Production Guardrails

Production AI agents require safety controls.

## 1. Human Approval

AI agents should not perform destructive infrastructure changes without approval.

Example:

```
Found 3 broken pods.

Proposed fixes:

1. web-app: Fix image typo
2. memory-app: Increase memory limit
3. config-app: Requires manual intervention

Approve fixes? yes/no
```

---

## 2. Scope Limits

The agent should only operate on allowed resources.

Examples:

Allowed:

```
development namespace
staging namespace
```

Restricted:

```
kube-system
production databases
critical infrastructure
```

---

## 3. Audit Trail

Every action must be recorded.

Temporal stores:

- Workflow execution history
- Tool calls
- Claude responses
- Kubernetes operations
- Failures and retries

This answers:

"What did the AI agent do?"

---

## 4. Rollback Capability

AI agents should make reversible changes.

Preferred:

```
kubectl patch
```

Avoid:

```
delete and recreate everything
```

Small changes reduce risk.

---

## 5. Timeout and Retry Limits

Agents should not run forever.

Example:

- Maximum 3 retries
- Workflow timeout after 5 minutes
- Escalate after repeated failures

---

## 6. Escalation Path

Agents must know their limits.

Example:

```
config-app requires ConfigMap app-config.

Cannot safely create configuration automatically.

Escalating to human operator.
```

---

# 2. KubeHealer Architecture

Architecture:

```
                 Claude API
                     |
                     |
             AI Diagnosis Engine
                     |
                     |
              KubeHealer Agent
                     |
        +------------+------------+
        |                         |
    Temporal                 kubectl
    Workflow                 Commands
        |                         |
        |                         |
 Durable Execution          Kubernetes Cluster
```

---

## Components

## Claude

Used for:

- Root cause analysis
- Understanding Kubernetes errors
- Suggesting fixes

---

## kubectl

Used as the infrastructure tool layer.

Examples:

```
kubectl get pods

kubectl describe pod

kubectl patch pod
```

Tools are simply wrappers around commands engineers already use.

---

## Temporal

Temporal provides:

- Durable execution
- Workflow history
- Crash recovery
- Automatic retries
- Audit trail

If the worker crashes, Temporal restores workflow state and continues from the last completed step.

---

# 3. Broken Applications and Agent Diagnosis

Three intentionally broken Kubernetes applications were deployed.

---

# Application 1: web-app

## Problem

Incorrect container image:

```
ngnix:latest
```

instead of:

```
nginx:latest
```

## Kubernetes Status

```
ImagePullBackOff
```

## Agent Diagnosis

Root cause:

```
Image name typo.
Docker registry cannot find ngnix image.
```

## Fix

Change:

```
ngnix:latest
```

to:

```
nginx:latest
```

Result:

```
web-app -> Running
```

---

# Application 2: memory-app

## Problem

Memory limit too low:

```
memory: 1Mi
```

## Kubernetes Status

```
CrashLoopBackOff
```

## Agent Diagnosis

Root cause:

```
Container is OOMKilled because memory limit is too small.
```

## Fix

Increase memory:

```
1Mi
```

to:

```
128Mi
```

Result:

```
memory-app -> Running
```

---

# Application 3: config-app

## Problem

Missing ConfigMap:

```
app-config
```

does not exist.

## Kubernetes Status

```
CreateContainerConfigError
```

## Agent Diagnosis

Root cause:

```
Required ConfigMap is missing.
```

## Agent Decision

Cannot automatically fix.

Reason:

The agent cannot safely guess application configuration values.

Action:

```
Escalate to human operator.
```

---

# 4. Agent Approval Screenshot

Insert screenshot here:

```
![KubeHealer Approval](images/kubehealer-approval.png)
```

Expected output:

```
Found 3 broken pods.

Proposed fixes:

1. web-app: Fix image typo
2. memory-app: Increase memory limit
3. config-app: Cannot fix automatically

Approve all fixes? yes/no
```

---

# 5. Temporal Workflow Screenshot

Insert screenshot here:

```
![Temporal Workflow History](images/temporal-history.png)
```

Temporal records:

- Workflow started
- Activities executed
- Claude calls
- kubectl commands
- Fix attempts
- Failures
- Completion status

This is the complete audit trail.

---

# 6. Crash Recovery with Temporal

Without Temporal:

```
Agent starts

↓

Diagnoses problems

↓

Worker crashes

↓

Progress lost
```

With Temporal:

```
Agent starts

↓

Scan completed

↓

Diagnosis completed

↓

Worker crashes

↓

Worker restarted

↓

Temporal replays history

↓

Workflow resumes
```

Temporal prevents losing progress during infrastructure operations.

---

# 7. AI Agents vs Traditional Automation

| AI Agents | Traditional Automation |
|---|---|
| Unknown problems | Known problems |
| Requires reasoning | Fixed rules |
| Multiple possible causes | Single solution |
| Human explanations useful | No reasoning required |
| Troubleshooting | Scheduled tasks |

Examples:

AI Agent:

```
Why is my Kubernetes pod failing?
```

Traditional automation:

```
If CPU > 80%, increase replicas.
```

---

# 8. Agentic AI Connection to the 90-Day Challenge

## Days 29-37: Docker

Docker troubleshooting commands became AI tools.

Examples:

```
docker ps

docker logs

docker inspect
```

---

## Days 40-49: GitHub Actions

CI/CD Analyzer agents can:

- Read workflow failures
- Diagnose pipeline issues
- Suggest fixes

---

## Days 50-67: Kubernetes

Kubernetes knowledge became the foundation for KubeHealer.

Tools:

```
kubectl get

kubectl describe

kubectl patch
```

---

## Days 73-77: Observability

Future agents can connect with:

- Prometheus
- Loki
- Metrics
- Logs

for deeper diagnosis.

---

## Days 84-86: ArgoCD

AI agents can assist GitOps workflows:

- Trigger syncs
- Detect drift
- Suggest rollbacks

---

# Final Reflection

The progression of Agentic AI:

```
Day 87

LLM explains errors

(Passive)


        |

        v


Day 88

Agent investigates using tools

(Autonomous investigation)


        |

        v


Day 89

Agent diagnoses and fixes with approval

(Autonomous action with guardrails)
```

Key lessons:

- Tools are CLI wrappers
- ReAct works across domains
- MCP standardizes tool usage
- Guardrails are mandatory
- Temporal provides durability
- AI should be used where reasoning is required

KubeHealer demonstrates what production AIOps looks like:
an AI system that observes, reasons, acts safely, and keeps humans in control.
