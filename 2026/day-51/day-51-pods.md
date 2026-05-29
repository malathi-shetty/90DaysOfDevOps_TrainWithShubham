# Day 51 – Kubernetes Manifests and Your First Pods

## The Anatomy of a Kubernetes Manifest

Every Kubernetes resource is defined using a YAML manifest with four required top-level fields:

```yaml
apiVersion: v1          # Which API version to use
kind: Pod               # What type of resource
metadata:               # Name, labels, namespace
  name: my-pod
  labels:
    app: my-app
spec:                   # The actual specification (what you want)
  containers:
  - name: my-container
    image: nginx:latest
    ports:
    - containerPort: 80
```

- `apiVersion` — tells Kubernetes which API group to use. For Pods, it is `v1`.
- `kind` — the resource type. Today it is `Pod`. Later you will use `Deployment`, `Service`, etc.
- `metadata` — the identity of your resource. `name` is required. `labels` are key-value pairs used for organization and selection.
- `spec` — the desired state. For a Pod, this means which containers to run, which images, which ports, etc.

---

## Challenge Tasks

### Task 1: Create Your First Pod (Nginx)
Create a file called `nginx-pod.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80
```

Apply it:
```bash
kubectl apply -f nginx-pod.yaml
```

Verify:
```bash
kubectl get pods
kubectl get pods -o wide
```

<img width="947" height="242" alt="image" src="https://github.com/user-attachments/assets/615de16c-1629-4d9f-bcef-5ab492339c6e" />


Wait until the STATUS shows `Running`. Then explore:

### Detailed info about the pod
```bash
kubectl describe pod nginx-pod
```
- It shows pod metadata,
- node & network info,
- container details,
- readiness/status,
- mounted volumes,
- scheduling constraints, and
- lifecycle events.

<img width="1076" height="789" alt="image" src="https://github.com/user-attachments/assets/919ac9ea-4ac6-48b0-a596-20a5622a8fbb" />


### Read the logs
```bash
kubectl logs nginx-pod
```
It shows:
- Container initialization logs
- Configuration steps
- Nginx startup logs


### Get a shell inside the container
```bash
kubectl exec -it nginx-pod -- /bin/bash
```

### Inside the container, run:
```bash
curl localhost:80
exit
```
**Verify:** Can you see the Nginx welcome page when you curl from inside the pod?

 - Yes, I can see the Nginx welcome page from inside the pod.

<img width="1079" height="729" alt="image" src="https://github.com/user-attachments/assets/078d334e-8010-488f-a5a9-549d75eb97b0" />


---

### Task 2: Create a Custom Pod (BusyBox)
Write a new manifest `busybox-pod.yaml` from scratch (do not copy-paste the nginx one):

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: busybox-pod
  labels:
    app: busybox
    environment: dev
spec:
  containers:
  - name: busybox
    image: busybox:latest
    command: ["sh", "-c", "echo Hello from BusyBox && sleep 3600"]
```

Apply and verify:
```bash
kubectl apply -f busybox-pod.yaml
kubectl get pods
kubectl logs busybox-pod
```



#### Notice the `command` field — BusyBox does not run a long-lived server like Nginx. Without a command that keeps it running, the container would exit immediately and the pod would go into `CrashLoopBackOff`.

The `command` field overrides the default container startup command.

Unlike Nginx, BusyBox does not run a long-lived process by default.
Without a command that keeps the container alive, the container would exit immediately, 
and Kubernetes would continuously restart it, eventually causing the pod to enter a `CrashLoopBackOff` state.

#### What this command does

`echo Hello from BusyBox && sleep 3600`
- `echo Hello from BusyBox`
  - Prints a message to the container logs
- `sleep 3600`
  - Keeps the container running for 3600 seconds (1 hour)

**Verify:** Can you see "Hello from BusyBox" in the logs?

#### Check the container logs:
`kubectl logs busybox-pod`

#### Expected Output
`Hello from BusyBox`

#### Result
Yes, I can see `"Hello from BusyBox"` in the logs.


<img width="1281" height="307" alt="image" src="https://github.com/user-attachments/assets/8cff7e4c-21d8-411c-a390-15cce8958b32" />


---

### Task 3: Imperative vs Declarative


#### Imperative vs Declarative

| Imperative Approach     | Declarative Approach       |
|-------------------------|----------------------------|
| Command-based           | YAML-based                 |
| Quick and temporary     | Recommended for production |
| Manually executed       | Desired-state driven       |
| Harder to track changes | Easy to version control    |
| Faster for testing      | Better for automation      |
| Example: kubectl run    | Example: kubectl apply -f  |

You have been using the declarative approach (writing YAML, then `kubectl apply`). Kubernetes also supports imperative commands:

```bash
# Create a pod without a YAML file
kubectl run redis-pod --image=redis:latest

# Check it
kubectl get pods
```

<img width="1296" height="212" alt="image" src="https://github.com/user-attachments/assets/a6c50ed0-b144-4db7-8982-a4edc8cb3a1f" />

### What Happens Internally?
```bash
kubectl run
     │
     ▼
API Server
     │
     ▼
Validates Request
     │
     ▼
Stores State in etcd
     │
     ▼
Scheduler Selects Node
     │
     ▼
kubelet Pulls Image
     │
     ▼
Container Runtime Starts Container
     │
     ▼
Pod Running
```


Now extract the YAML that Kubernetes generated:
```bash
kubectl get pod redis-pod -o yaml
```

### generated-pod.yaml
```bash
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: test-pod
  name: test-pod
spec:
  containers:
  - image: nginx
    name: test-pod
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```

<img width="874" height="1840" alt="image" src="https://github.com/user-attachments/assets/bcc92690-8588-4c0c-ba92-ef9e7303da1b" />

Compare this output with your hand-written manifests. Notice how much extra metadata Kubernetes adds automatically (status, timestamps, uid, resource version).

### What Extra Information Does Kubernetes Add?

Compared to hand-written manifests, Kubernetes automatically adds:
 - uid
 - resourceVersion
 - creationTimestamp
 - managedFields
 - status
 - podIP
 - nodeName
 - conditions
These fields are dynamically managed by Kubernetes.


## Hand-Written YAML vs Generated YAML
### Hand-Written Manifest

Usually contains only the desired state:
 - apiVersion:
 - kind:
 - metadata:
 - spec:

### Generated YAML

Contains:
 - Desired state
 - Current state
 - Runtime metadata
 - Scheduling information
 - Networking information
 - Status information

You can also use dry-run to generate YAML without creating anything:
```bash
kubectl run test-pod --image=nginx --dry-run=client -o yaml
```
### Why Dry-Run is Powerful

Dry-run is extremely useful because it allows you to:
  - Quickly scaffold YAML manifests
  - Avoid writing manifests from scratch
  - Learn Kubernetes YAML structure
  - Generate templates for customization
  - Validate commands safely


<img width="1684" height="393" alt="image" src="https://github.com/user-attachments/assets/3932e6b3-0a9f-46f2-8828-53fa23da7806" />


This is a powerful trick — use it to quickly scaffold a manifest, then customize it.

**Verify:** Save the dry-run output to a file and compare its structure with your nginx-pod.yaml. What fields are the same? What is different?

## Verification

### What Fields Are the Same?

Both the hand-written manifest and the Kubernetes-generated YAML contain the basic Kubernetes structure:

```yaml
apiVersion:
kind:
metadata:
spec:
```

These fields define the desired state of the Pod.

---

## Common Fields Present in Both

### Basic Pod Information

```text
apiVersion: v1
kind: Pod
```

These define:

* Which Kubernetes API version to use
* What type of resource is being created

---

### Metadata Fields

```text
metadata.name: nginx-pod
metadata.labels.app: nginx
```

These define:

* Pod name
* Labels used for grouping and selection

---

### Container Definition Fields

```text
spec.containers[0].name: nginx
spec.containers[0].image: nginx:latest
spec.containers[0].ports[0].containerPort: 80
```

These define:

* Container name
* Container image
* Exposed container port

---

### Understanding the Field Path Notation

The following syntax:

```text
metadata.name
spec.containers[0].image
```

is called:

```text
Field Path / Object Path Notation
```

This notation is commonly used in:

* Documentation
* Notes
* Interview explanations
* YAML comparisons

It is **NOT actual YAML syntax**.

---

### Actual YAML Equivalent

For example:

```text
metadata.name: nginx-pod
```

means:

```yaml
metadata:
  name: nginx-pod
```

Another example:

```text
spec.containers[0].image: nginx:latest
```

means:

```yaml
spec:
  containers:
  - image: nginx:latest
```

---

### Easy Analogy

Think of YAML like folders and files:

```text
metadata/
   └── name

spec/
   └── containers/
           └── image
```

Field path notation is simply a shortcut for writing nested YAML paths:

```text
metadata.name
spec.containers[0].image
```

instead of writing the full YAML tree every time.

---

### What Fields Are Different?

The generated YAML contains many additional fields automatically added by Kubernetes.

These fields are usually **NOT written manually**.

---

### Automatically Added Metadata

```text
creationTimestamp:
managedFields:
resourceVersion:
uid:
status:
```

These fields contain:

* Object creation time
* Internal Kubernetes management information
* Resource version tracking
* Unique object identifiers
* Current runtime status

---

### Additional Runtime & Cluster Fields

The generated YAML may also contain:

* Restart policies
* DNS policies
* Scheduler information
* Security context defaults
* Node assignment details
* Service account information
* Tolerations
* Runtime networking details

---

### Example Additional Fields

```text
metadata.annotations
namespace
imagePullPolicy
restartPolicy
dnsPolicy
schedulerName
nodeName
terminationGracePeriodSeconds
serviceAccount
enableServiceLinks
status
```

---

### Why Kubernetes Adds These Fields

Kubernetes automatically enriches objects with:

* Runtime information
* Scheduling information
* Networking details
* Security defaults
* Current state tracking

This helps Kubernetes manage the Pod lifecycle automatically.

---

### Important Understanding

###  Hand-Written YAML

Usually contains only the:

```text
Desired State
```

Example:

```yaml
apiVersion:
kind:
metadata:
spec:
```

You define:

* What you want Kubernetes to create

---

### Generated YAML

Contains:

```text
Desired State + Current State + Runtime Metadata
```

Kubernetes automatically adds:

* Scheduling details
* Cluster-generated identifiers
* Current Pod status
* Runtime defaults

---

### Key Learning

* Hand-written manifests are clean and minimal
* Generated YAML is verbose and runtime-aware
* Kubernetes automatically manages many internal fields
* Field path notation is used only for explanation/documentation
* Actual YAML structure is hierarchical and indentation-based

---

### Easy Analogy

### Declarative Approach

```text
"I want this final result."
```

Example:

* Write YAML
* Kubernetes figures out HOW to achieve it

Like:

```text
Ordering food from a menu
```

You specify:

* What you want

The kitchen handles:

* How it is prepared

---

### Imperative Approach

```text
"Do these exact steps now."
```

Like:

```text
Cooking manually step-by-step yourself
```

You control every command directly.

---

### Key Learning

* Declarative approach is preferred in production environments
* Imperative approach is useful for quick testing and debugging
* Dry-run is one of the most useful Kubernetes tricks
* Kubernetes automatically manages runtime metadata
* Generated YAML is much more detailed than hand-written manifests



---

### Task 4: Validate Before Applying
Before applying a manifest, you can validate it:

Before applying a manifest, you can validate it:

# Check if the YAML is valid without actually creating the resource
kubectl apply -f nginx-pod.yaml --dry-run=client

# Validate against the cluster's API (server-side validation)
kubectl apply -f nginx-pod.yaml --dry-run=server
Now intentionally break your YAML (remove the image field or add an invalid field) and run dry-run again. See what error you get.

Verify: What error does Kubernetes give when the image field is missing?

---

Before applying a Kubernetes manifest, it is a good practice to validate the YAML file first.

Kubernetes provides two types of validation:

* Client-side validation
* Server-side validation

---

### Validation Commands

```bash
# Check if the YAML is valid locally without creating the resource
kubectl apply -f nginx-pod.yaml --dry-run=client

# Validate against the Kubernetes API server
kubectl apply -f nginx-pod.yaml --dry-run=server
```

---

### Client-Side vs Server-Side Validation

| Validation Type    | Description                                     | Checks                                  |
| ------------------ | ----------------------------------------------- | --------------------------------------- |
| `--dry-run=client` | Validation happens locally using kubectl        | YAML syntax and basic structure         |
| `--dry-run=server` | Validation happens on the Kubernetes API Server | Full API validation and required fields |

---

### Easy Analogy

### Client-Side Validation

```text
Checking your exam paper format before submitting
```

It checks:

* Basic structure
* Formatting
* Syntax

But it does NOT fully verify whether Kubernetes can actually run the resource.

---

### Server-Side Validation

```text
Teacher actually evaluating the paper officially
```

The Kubernetes API Server checks:

* Required fields
* Object schema
* API compatibility
* Whether the resource is valid for the cluster

---

### Breaking the YAML Intentionally

To test validation, I intentionally removed the `image` field from the container definition.

Modified YAML:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    ports:
    - containerPort: 80
```

---

### Validation Results

### Client-Side Validation

```bash
kubectl apply -f nginx-pod.yaml --dry-run=client
```

Result:

```text
pod/nginx-pod configured (dry run)
```

Client-side validation did NOT detect the missing image field because it mainly validates syntax and basic structure locally.

---

### Server-Side Validation

```bash
kubectl apply -f nginx-pod.yaml --dry-run=server
```

Result:

```text
The Pod "nginx-pod" is invalid: spec.containers[0].image: Required value
```

This error was detected because the Kubernetes API Server performs full schema validation.

---

### Verification

### What Error Does Kubernetes Give When the Image Field is Missing?

```text
The Pod "nginx-pod" is invalid:
spec.containers[0].image: Required value
```

<img width="1422" height="439" alt="image" src="https://github.com/user-attachments/assets/208873a1-23f2-4753-9b88-56e4fc1a8c03" />

---

###  What Happens Internally During Validation?

```text
kubectl apply
      │
      ▼
Client-Side Validation
      │
      ▼
API Server
      │
      ▼
Server-Side Schema Validation
      │
      ▼
Accept or Reject Resource
```

---

## Failure Flow Summary

### Missing Required Field (`image`)

```text
Manifest Applied
      │
      ▼
API Server Validates Object
      │
      ▼
Required Field Missing
      │
      ▼
Validation Failed
      │
      ▼
Resource Rejected
```

---

### Key Learning

* `--dry-run=client` performs local validation only
* `--dry-run=server` performs full Kubernetes API validation
* Server-side validation is more reliable
* Missing required fields are caught by the API Server
* Validation helps prevent broken resources from being deployed
* Dry-run is extremely useful for safe testing and debugging

---

### Task 5: Pod Labels and Filtering
Labels are how Kubernetes organizes and selects resources. You added labels in your manifests — now use them:


### List all pods with their labels
kubectl get pods --show-labels

<img width="1382" height="419" alt="image" src="https://github.com/user-attachments/assets/35bb0e28-7ac0-4278-9d9e-c3d365946911" />



### Filter pods by label
kubectl get pods -l app=nginx
kubectl get pods -l environment=dev

### Add a label to an existing pod
kubectl label pod nginx-pod environment=production

### Verify
kubectl get pods --show-labels

### Remove a label
kubectl label pod nginx-pod environment-


<img width="887" height="594" alt="image" src="https://github.com/user-attachments/assets/6ed3ae65-48e0-48cd-addc-0b1981f2cddd" />


Write a manifest for a third pod with at least 3 labels (app, environment, team). Apply it and practice filtering.

---

```bash
apiVersion: v1
kind: Pod
metadata:
  name: alpine-pod
  labels:
    app: alpine
    environment: testing
    team: devops
spec:
  containers:
  - name: alpine
    image: alpine:latest
    command:
    - sh
    - -c
    - sleep 3600
```

Labels are key-value pairs attached to Kubernetes resources.

They are used to:

* Organize resources
* Filter resources
* Select resources
* Group workloads logically

Labels are extremely important in Kubernetes because Services, Deployments, monitoring tools, and network policies rely heavily on them.

---

### What Are Labels?

Labels are metadata attached to Kubernetes objects.

Example:

```yaml id="sljlwm"
labels:
  app: nginx
  environment: production
  team: backend
```

Here:

* `app` → identifies the application
* `environment` → identifies environment type
* `team` → identifies ownership

---

### Easy Analogy

Think of labels like tags on files or folders.

```text id="u4ay8v"
Pod = File
Labels = Tags/Stickers attached to the file
```

Example:

```text id="h5b8rz"
[nginx-pod]
 ├── app=nginx
 ├── environment=production
 └── team=backend
```

Now Kubernetes can easily search/filter resources using those tags.

---

### List All Pods with Labels

```bash id="i55wiv"
kubectl get pods --show-labels
```

This displays all pods along with their labels.

---

### Filter Pods by Labels

### Filter by App Label

```bash id="k76j8j"
kubectl get pods -l app=nginx
```

This returns only pods where:

```text id="rz1f6y"
app=nginx
```

---

### Filter by Environment Label

```bash id="zdgx3n"
kubectl get pods -l environment=dev
```

This returns only pods where:

```text id="vnt7i6"
environment=dev
```

---

### Understanding Label Filtering

```text id="m0vfyy"
-l = label selector
```

Kubernetes searches for matching labels.

---

### ASCII Example

```text id="9xqf3h"
Pods:
 ├── nginx-pod
 │     └── app=nginx
 │
 ├── busybox-pod
 │     └── environment=dev
 │
 └── alpine-pod
       ├── app=alpine
       ├── environment=testing
       └── team=devops
```

Filtering:

```bash id="9mjlwm"
kubectl get pods -l environment=testing
```

returns:

```text id="u2u6l1"
alpine-pod
```

because only that pod matches the label.

---

### Add a Label to an Existing Pod

```bash id="h5oxfq"
kubectl label pod nginx-pod environment=production
```

This dynamically adds a new label to the running pod.

---

###  Verify Labels

```bash id="n8x1m9"
kubectl get pods --show-labels
```

Example output:

```text id="9p4vyw"
NAME         READY   STATUS    LABELS
nginx-pod    1/1     Running   app=nginx,environment=production
```

---

### Remove a Label

```bash id="ry2x6d"
kubectl label pod nginx-pod environment-
```

The `-` at the end removes the label.

---

### Third Pod Manifest with Multiple Labels

Created `third-pod.yaml`:

```yaml id="r7jz7w"
apiVersion: v1
kind: Pod
metadata:
  name: alpine-pod
  labels:
    app: alpine
    environment: testing
    team: devops
spec:
  containers:
  - name: alpine
    image: alpine:latest
    command: ["sh", "-c", "sleep 3600"]
```

Apply the manifest:

```bash id="o6fd6m"
kubectl apply -f third-pod.yaml
```

---

### Filter the Third Pod

```bash id="thz0t8"
kubectl get pods -l environment=testing
```

Result:

```text id="oq7qk9"
alpine-pod
```

---

### Multi-Label Filtering

You can filter using multiple labels together.

Example:

```bash id="p7a3ef"
kubectl get pods -l app=alpine,team=devops
```

This acts like an:

```text id="s3b1q5"
AND condition
```

Meaning:

* app must equal alpine
* AND team must equal devops

---

### What Happens Internally?

```text id="c7kz3e"
kubectl get pods -l app=nginx
          │
          ▼
API Server Receives Label Selector
          │
          ▼
Searches Matching Labels
          │
          ▼
Returns Matching Pods
```

---

### Why Labels Are Important

Labels are the foundation of Kubernetes resource selection.

They are used by:

* Deployments
* ReplicaSets
* Services
* Network Policies
* Monitoring tools
* CI/CD pipelines

---

###  Real-World Example

A Service may use:

```yaml id="slf8yk"
selector:
  app: nginx
```

This tells Kubernetes:

```text id="cl2byi"
"Send traffic to all Pods having app=nginx"
```

---

### Key Learning

* Labels are key-value metadata
* Labels help organize and group resources
* `-l` is used for label filtering
* Labels can be added or removed dynamically
* Multiple labels can be combined using AND conditions
* Kubernetes heavily depends on labels for resource selection
* Services and Deployments use labels internally


---

### Task 6: Clean Up
Delete all the pods you created:

```bash
# Delete by name
kubectl delete pod nginx-pod
kubectl delete pod busybox-pod
kubectl delete pod redis-pod

# Or delete using the manifest file
kubectl delete -f nginx-pod.yaml

# Verify everything is gone
kubectl get pods
```

<img width="1214" height="350" alt="image" src="https://github.com/user-attachments/assets/0a0fef52-ff38-48a4-8259-e96d540d89f0" />


**What happens when you delete a standalone Pod?**

---

### Task 6: Clean Up

After completing the exercises, delete all the Pods that were created.

---

###  Delete Pods by Name

```bash id="lw4q0m"
kubectl delete pod nginx-pod
kubectl delete pod busybox-pod
kubectl delete pod redis-pod
```

Kubernetes will terminate and remove the Pods from the cluster.

---

###  Delete Using the Manifest File

You can also delete resources using the same YAML manifest file that created them.

```bash id="9jw06m"
kubectl delete -f nginx-pod.yaml
```

This method is very useful in real-world DevOps workflows because:

* Infrastructure remains reproducible
* Cleanup becomes easier
* CI/CD pipelines can automatically create and destroy resources

---

###  Verify Everything Is Deleted

```bash id="y8swwr"
kubectl get pods
```

Expected output:

```text id="e1m78y"
No resources found in default namespace.
```

---

###  What Happens When You Delete a Standalone Pod?

When a standalone Pod is deleted:

```text id="7xjv8l"
Pod Deleted
     │
     ▼
No Controller Managing It
     │
     ▼
Pod Permanently Removed
```

The Pod is gone forever because no controller exists to recreate it.

---

###  Important Understanding

A standalone Pod is unmanaged.

Kubernetes does NOT automatically recreate it after deletion.

This is why standalone Pods are mostly used for:

* Learning
* Testing
* Debugging
* Temporary workloads

---

###  Easy Analogy

###  Standalone Pod

```text id="v6a7nr"
Deleting a temporary file manually
```

Once deleted:

* it is gone permanently

---

###  Deployment-Managed Pod

```text id="mjlwmf"
A photocopy machine maintaining 3 copies continuously
```

If one copy disappears:

```text id="c0j7h4"
Controller notices missing Pod
        │
        ▼
Automatically creates a new Pod
```

This self-healing behavior is why Deployments are used in production.

---

###  ASCII Comparison

###  Standalone Pod

```text id="hy3xg9"
User
 │
 ▼
Pod
 │
 ▼
Deleted
 │
 ▼
Gone Forever
```

---

###  Deployment-Managed Pod

```text id="b79ikq"
Deployment
     │
     ▼
ReplicaSet
     │
     ▼
Pods
```

If a Pod is deleted:

```text id="f9crk2"
Deployment
     │
     ▼
Detects Missing Pod
     │
     ▼
Creates New Pod Automatically
```

---

###  What Happens Internally During Pod Deletion?

```text id="sblgzc"
kubectl delete pod nginx-pod
          │
          ▼
API Server Receives Delete Request
          │
          ▼
Pod Marked for Termination
          │
          ▼
kubelet Stops Containers
          │
          ▼
Resources Cleaned Up
          │
          ▼
Pod Removed from etcd
```

---

###  Failure Flow Summary

###  Standalone Pod Deletion

```text id="g3u7zg"
Pod Deleted
     │
     ▼
No ReplicaSet / Deployment
     │
     ▼
No Automatic Recovery
     │
     ▼
Application Gone
```

---

###  Why Deployments Are Preferred in Production

Deployments provide:

* Self-healing
* Scaling
* Rolling updates
* Rollbacks
* Desired state management

Without Deployments:

* Pods are fragile
* Manual recovery is required
* Applications are not highly available

---

###  Key Learning

* Pods can be deleted by name or manifest file
* Standalone Pods are not automatically recreated
* Kubernetes controllers manage self-healing behavior
* Deployments are preferred for production workloads
* Deleting a standalone Pod removes it permanently
* Controllers continuously maintain the desired state

