# Day 55 – Persistent Volumes (PV) and Persistent Volume Claims (PVC)

## Challenge Tasks

### Task 1: See the Problem — Data Lost on Pod Deletion
1. Write a Pod manifest that uses an `emptyDir` volume and writes a timestamped message to `/data/message.txt`
2. Apply it, verify the data exists with `kubectl exec`
3. Delete the Pod, recreate it, check the file again — the old message is gone

**Verify:** Is the timestamp the same or different after recreation?


#  Create the Pod with `emptyDir`

Create a file:

### `emptydir-pod.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-demo
spec:
  containers:
    - name: writer
      image: busybox
      command: ["/bin/sh", "-c"]
      args:
        - while true; do
            date >> /data/message.txt;
            sleep 5;
          done
      volumeMounts:
        - name: data-volume
          mountPath: /data
  volumes:
    - name: data-volume
      emptyDir: {}
```

---

#  Verification Answer

###  Is the timestamp same or different?

 **Answer: DIFFERENT**

---

Why this happens

* `emptyDir` lives **only as long as the Pod exists**
* When Pod is deleted:

  * volume is wiped
  * data is lost permanently
* New Pod = fresh empty directory

---

#  Final Observation

| Action         | Data State             |
| -------------- | ---------------------- |
| First Pod runs | timestamps exist       |
| Pod deleted    | data erased            |
| Pod recreated  | fresh new file         |
| Compare output |  completely different |

<img width="985" height="1002" alt="image" src="https://github.com/user-attachments/assets/b0ccf83b-a67a-4ff2-975e-2a17fe432236" />


---

### Task 2: Create a PersistentVolume (Static Provisioning)
1. Write a PV manifest with `capacity: 1Gi`, `accessModes: ReadWriteOnce`, `persistentVolumeReclaimPolicy: Retain`, and `hostPath` pointing to `/tmp/k8s-pv-data`
2. Apply it and check `kubectl get pv` — status should be `Available`

Access modes to know:
- `ReadWriteOnce (RWO)` — read-write by a single node
- `ReadOnlyMany (ROX)` — read-only by many nodes
- `ReadWriteMany (RWX)` — read-write by many nodes

`hostPath` is fine for learning, not for production.

**Verify:** What is the STATUS of the PV?


# Create PersistentVolume YAML

### `pv.yaml`

```yaml id="pv8k21"
apiVersion: v1
kind: PersistentVolume
metadata:
  name: manual-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /tmp/k8s-pv-data
```

---



#  Verification Answer

###  What is the STATUS of the PV?

 **Answer: `Available`**

```
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-55$ kubectl get pv
NAME        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
manual-pv   1Gi        RWO            Retain           Available                          <unset>                          9s

```
---

#  Why it is “Available”

* PV is created successfully
* No PVC has claimed it yet
* So Kubernetes marks it as **Available**

---

#  Key Concept

| State     | Meaning                                        |
| --------- | ---------------------------------------------- |
| Available | PV is free and ready                           |
| Bound     | PV is claimed by PVC                           |
| Released  | PVC deleted, but PV not reused (Retain policy) |

---



<img width="1572" height="207" alt="image" src="https://github.com/user-attachments/assets/5925b36f-749d-4164-9e33-42a17f2e64bb" />


---

### Task 3: Create a PersistentVolumeClaim
1. Write a PVC manifest requesting `500Mi` of storage with `ReadWriteOnce` access
2. Apply it and check both `kubectl get pvc` and `kubectl get pv`
3. Both should show `Bound` — Kubernetes matched them by capacity and access mode

**Verify:** What does the VOLUME column in `kubectl get pvc` show?

`pvc.yaml`
```bash
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: ""
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

### Results

#### PVC

```text
NAME     STATUS   VOLUME      CAPACITY   ACCESS MODES
my-pvc   Bound    manual-pv   1Gi        RWO
```

#### PV

```text
NAME        STATUS   CLAIM
manual-pv   Bound    default/my-pvc
```

---

### Verifications

###  What does the VOLUME column in `kubectl get pvc` show?

```text
manual-pv
```

This is the name of the PersistentVolume that Kubernetes matched with your PVC.

###  Are the PV and PVC bound?

 Yes

* PVC Status = `Bound`
* PV Status = `Bound`

---

### Result?

1. PVC requested:

   * 500Mi
   * ReadWriteOnce

2. PV provided:

   * 1Gi
   * ReadWriteOnce

3. Kubernetes found a matching PV and bound them together.

Relationship:

```text
PVC (my-pvc)
      │
      ▼
PV (manual-pv)
      │
      ▼
/tmp/k8s-pv-data (hostPath)
```




<img width="1560" height="273" alt="image" src="https://github.com/user-attachments/assets/d8408744-bba1-4f22-9c28-a168ad2764b2" />





---

### Task 4: Use the PVC in a Pod — Data That Survives
1. Write a Pod manifest that mounts the PVC at `/data` using `persistentVolumeClaim.claimName`
2. Write data to `/data/message.txt`, then delete and recreate the Pod
3. Check the file — it should contain data from both Pods

**Verify:** Does the file contain data from both the first and second Pod?

`pvc-pod.yaml`
```
apiVersion: v1
kind: Pod
metadata:
  name: pvc-demo
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
    - 'echo "First Pod: $(date)" >> /data/message.txt; sleep 3600'
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: my-pvc
```

### Current file contents:

```text
First Pod: Tue Jun  2 10:40:30 UTC 2026
```
---

## Modify the Manifest

Edit `pvc-pod.yaml` and change:

```yaml
args:
- 'echo "First Pod: $(date)" >> /data/message.txt; sleep 3600'
```

to

```yaml
args:
- 'echo "Second Pod: $(date)" >> /data/message.txt; sleep 3600'
```

---

Output proves persistence:

```text
First Pod: Tue Jun  2 10:40:30 UTC 2026
Second Pod: Tue Jun  2 10:44:58 UTC 2026
```

#### Verification

**Does the file contain data from both the first and second Pod?**

**Yes.**

The file contains:

* Data written by the first Pod
* Data written by the second Pod after the first Pod was deleted
* After deleting and recreating the Pod, the data remained because the PVC and PV were preserved.
* Data persisted across Pod recreation.

This demonstrates that the data was stored on the PV through the PVC and survived Pod deletion.



---

### Learned

#### `emptyDir`

```text
Pod deleted
    ↓
Volume deleted
    ↓
Data lost
```

#### PV + PVC

```text
Pod deleted
    ↓
PVC remains
    ↓
PV remains
    ↓
Data preserved
```

---

### Current State

```bash
kubectl get pv
```

Output:

```text
manual-pv   Bound
```

```bash
kubectl get pvc
```

Output:

```text
my-pvc      Bound
```

And  Pod is successfully using that persistent storage.

---


<img width="1015" height="583" alt="image" src="https://github.com/user-attachments/assets/16550d91-53aa-40de-8f76-687ec27718ec" />

---

### Task 5: StorageClasses and Dynamic Provisioning
1. Run `kubectl get storageclass` and `kubectl describe storageclass`
2. Note the provisioner, reclaim policy, and volume binding mode
3. With dynamic provisioning, developers only create PVCs — the StorageClass handles PV creation automatically

**Verify:** What is the default StorageClass in your cluster?

## Your StorageClass Details

From your output:

```bash
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-55$ kubectl get storageclass
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  3d4h
```

#### Verifications

####  What is the default StorageClass in your cluster?

 **standard**

---

####  What is the provisioner?

 **rancher.io/local-path**

This provisioner automatically creates local-path-backed Persistent Volumes when a PVC requests storage.

---

####  What is the reclaim policy?

 **Delete**

```text
ReclaimPolicy: Delete
```

Meaning:

* When the PVC is deleted,
* The dynamically provisioned PV will also be deleted automatically.

---

####  What is the volume binding mode?

 **WaitForFirstConsumer**

```text
VolumeBindingMode: WaitForFirstConsumer
```

Meaning:

* Kubernetes waits until a Pod actually uses the PVC.
* Then it creates/binds the storage on the appropriate node.

---

<img width="1006" height="290" alt="image" src="https://github.com/user-attachments/assets/d341a46e-6248-4031-929d-e573be8cd884" />

---

### Task 6: Dynamic Provisioning
1. Write a PVC manifest that includes `storageClassName: standard` (or your cluster's default)
2. Apply it — a PV should appear automatically in `kubectl get pv`
3. Use this PVC in a Pod, write data, verify it works

**Verify:** How many PVs exist now? Which was manual, which was dynamic?

`dynamic-pvc.yaml`
```bash
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  storageClassName: standard
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 500Mi
```

### Result

Initially:

```text
dynamic-pvc = Pending
```

Because your StorageClass uses:

```text
VolumeBindingMode: WaitForFirstConsumer
```

`dynamic-pod.yaml`
```bash
apiVersion: v1
kind: Pod
metadata:
  name: dynamic-pod
spec:
  containers:
  - name: app
    image: busybox
    command: ["/bin/sh", "-c"]
    args:
    - 'echo "Dynamic PVC Test: $(date)" >> /data/message.txt; sleep 3600'
    volumeMounts:
    - name: storage
      mountPath: /data
  volumes:
  - name: storage
    persistentVolumeClaim:
      claimName: dynamic-pvc
```

After creating `dynamic-pod`, Kubernetes automatically:

1. Saw that `dynamic-pvc` was being used.
2. Asked the `rancher.io/local-path` provisioner to create storage.
3. Created a new PV automatically.
4. Bound the PVC to that PV.

---

## Verification Results

### Dynamic PVC

```text
dynamic-pvc   Bound
```

### Dynamic PV

```text
pvc-ca95c210-6371-4036-ae08-26e4c8166f82
```

This PV was automatically created by the StorageClass.

---

### Data Verification

Your output:

```text
Dynamic PVC Test: Tue Jun  2 11:04:59 UTC 2026
```

 The Pod successfully wrote data to the dynamically provisioned volume.

---

### Verifications

###  How many PVs exist now?

```text
2
```

From your output:

```text
manual-pv
pvc-ca95c210-6371-4036-ae08-26e4c8166f82
```

---

###  Which was manual and which was dynamic?

| PV Name                                    | Type                              |
| ------------------------------------------ | --------------------------------- |
| `manual-pv`                                | Manual (Static Provisioning)      |
| `pvc-ca95c210-6371-4036-ae08-26e4c8166f82` | Dynamic (Created by StorageClass) |

---

## Compare the Two PVs

| Property       | Manual PV   | Dynamic PV         |
| -------------- | ----------- | ------------------ |
| Created by     | You         | StorageClass       |
| Name           | `manual-pv` | `pvc-ca95c210-...` |
| Reclaim Policy | `Retain`    | `Delete`           |
| StorageClass   | None        | `standard`         |
| Provisioning   | Static      | Dynamic            |

---

```bash
persistentvolumeclaim/dynamic-pvc created
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-55$ kubectl get pvc
NAME          STATUS    VOLUME      CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
dynamic-pvc   Pending                                         standard       <unset>                 5s
my-pvc        Bound     manual-pv   1Gi        RWO                           <unset>                 32m

pod/dynamic-pod created
ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-55$ kubectl get pods
NAME                    READY   STATUS    RESTARTS       AGE
dynamic-pod             1/1     Running   0              56s
emptydir-demo           1/1     Running   0              66m
nginx-7f8fbb96d-q64d5   1/1     Running   1 (130m ago)   20h
pvc-demo                1/1     Running   0              20m

ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-55$ kubectl get pvc
NAME          STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
dynamic-pvc   Bound    pvc-ca95c210-6371-4036-ae08-26e4c8166f82   500Mi      RWO            standard       <unset>                 109s
my-pvc        Bound    manual-pv                                  1Gi        RWO                           <unset>                 34m

ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-55$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                 STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
manual-pv                                  1Gi        RWO            Retain           Bound    default/my-pvc                       <unset>                          51m
pvc-ca95c210-6371-4036-ae08-26e4c8166f82   500Mi      RWO            Delete           Bound    default/dynamic-pvc   standard       <unset>                          58s

ubuntu@ip-172-31-45-40:~/90DaysOfDevOps_TrainWithShubham/2026/day-55$ kubectl exec -it dynamic-pod -- cat /data/message.txt
Dynamic PVC Test: Tue Jun  2 11:04:59 UTC 2026

```

<img width="1309" height="540" alt="image" src="https://github.com/user-attachments/assets/22a12560-266a-481f-835a-d94c03e47369" />

---

### Task 7: Clean Up
1. Delete all pods first
2. Delete PVCs — check `kubectl get pv` to see what happened
3. The dynamic PV is gone (Delete reclaim policy). The manual PV shows `Released` (Retain policy).
4. Delete the remaining PV manually

**Verify:** Which PV was auto-deleted and which was retained? Why?



# Step 1: Delete the Pods Using the PVCs

Delete the Pods you created:

```bash
kubectl delete pod pvc-demo
kubectl delete pod dynamic-pod
kubectl delete pod emptydir-demo
```

Verify:

```bash
kubectl get pods
```

Should no longer see those Pods.

---

# Step 2: Delete the PVCs

Delete both claims:

```bash
kubectl delete pvc my-pvc
kubectl delete pvc dynamic-pvc
```



Check:

```bash
kubectl get pvc
```

Expected:

```text
No resources found
```

---

# Step 3: Inspect the PVs

Run:

```bash
kubectl get pv
```

Expected behavior:

### Dynamic PV

```text
pvc-ca95c210-6371-4036-ae08-26e4c8166f82
```

should disappear automatically because:

```text
Reclaim Policy = Delete
```

### Manual PV

```text
manual-pv
```

should remain and change to:

```text
STATUS = Released
```

because:

```text
Reclaim Policy = Retain
```

Example:

```text
NAME        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS
manual-pv   1Gi        RWO            Retain           Released
```

---

# Step 4: Delete the Remaining PV

Since `manual-pv` is retained, delete it manually:

```bash
kubectl delete pv manual-pv
```

Verify:

```bash
kubectl get pv
```

Expected:

```text
No resources found
```

---



#### Verifications

####  Which PV was auto-deleted?

 **Dynamic PV**

```text
pvc-ca95c210-6371-4036-ae08-26e4c8166f82
```

**Why?**

* It was created dynamically by the `standard` StorageClass.
* Its reclaim policy was:

```text
Delete
```

When  deleted `dynamic-pvc`, Kubernetes automatically deleted the dynamically provisioned PV.

---

####  Which PV was retained?

 **manual-pv**

```text
manual-pv
```

After deleting `my-pvc`, you observed:

```text
STATUS = Released
```

because its reclaim policy was:

```text
Retain
```

Kubernetes kept the PV and its data, requiring manual cleanup.

---

### Evidence from  Output

After deleting PVCs:

```text
NAME        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS
manual-pv   1Gi        RWO            Retain           Released
```

Notice:

* Dynamic PV is gone 
* Manual PV remains as `Released` 

Then you manually removed it:

```bash
kubectl delete pv manual-pv
```

Final check:

```bash
kubectl get pv
```

Output:

```text
No resources found
```

 Cleanup completed successfully.

---



#### Learnings Learned

| Concept              | Takeaway                                   |
| -------------------- | ------------------------------------------ |
| `emptyDir`           | Data disappears when Pod is deleted        |
| PV                   | Actual storage resource                    |
| PVC                  | Request for storage                        |
| Static Provisioning  | PV created manually                        |
| Dynamic Provisioning | PV created automatically via StorageClass  |
| RWO                  | Read/write on a single node                |
| Retain               | Keep PV after PVC deletion                 |
| Delete               | Remove PV automatically after PVC deletion |
| PV Lifecycle         | Available → Bound → Released               |

<img width="1640" height="621" alt="image" src="https://github.com/user-attachments/assets/ec50128c-c9e5-43c6-ad0f-032f20bb4075" />


---

# Documentation

**Why containers need persistent storage**

- Containers are `ephemeral`, so any data stored inside them is lost when the container or Pod is deleted.
- `Persistent storage` keeps data outside the container lifecycle for databases, logs, or user files.


**What PVs and PVCs are and how they relate**

`PersistentVolume (PV)`
- A piece of storage in the cluster.
- A PersistentVolume represents storage available to the cluster and can be provisioned manually or dynamically.

`PersistentVolumeClaim (PVC)`
- A request for storage by a user
- Specifies size, access mode, storage class.
- Kubernetes binds a PVC to a PV that matches its request.

`Relation:` PVC requests storage -> bound to a PV -> pod uses PVC to access storage.
```bash
Pod
 ↓
PVC (Storage Request)
 ↓
PV (Actual Storage)
 ↓
Disk / Cloud Volume
```
**Static vs dynamic provisioning**

`Static Provisioning`
- PV is created manually by admin before the PVC exists.
- PVC claims it later.

`Dynamic Provisioning`
- PV is created automatically when a PVC is created,using a StorageClass.
- Saves time and avoids manual PV management.

`Example` PVC with storageClassName: standard -> Kubernetes automatically provisions a PV.



**Access modes and reclaim policies**


| Mode                    | Meaning                                  | Use Case                         |
| ----------------------- | ---------------------------------------- | -------------------------------- |
| **ReadWriteOnce** | Mounted **read-write by a single node**  | Most databases                   |
| **ReadOnlyMany**  | Mounted **read-only by multiple nodes**  | Config files, shared static data |
| **ReadWriteMany** | Mounted **read-write by multiple nodes** | Shared storage for multiple pods |


| Policy      | What happens when PVC is deleted       | 
| ----------- | -------------------------------------- | 
| **Delete**  | PV is automatically deleted            |               
| **Retain**  | PV is kept (data persists)             |


## Key takeaway: 
- Pods are ephemeral, but Persistent Volumes allow data to survive Pod restarts and deletions.
