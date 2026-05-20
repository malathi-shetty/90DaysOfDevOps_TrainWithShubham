# Day 13 – Linux Volume Management (LVM)

##  Objective
Learn how to manage storage using LVM by creating, mounting, and extending logical volumes dynamically.

---

##  Environment
- OS: Ubuntu (EC2)
- User: root
- Disk used: `/dev/nvme1n1` (EBS volume)

---

## Task 1: Check Current Storage

### Commands
```bash
lsblk
pvs
vgs
lvs
df -h
```

### Outcome
- Identified available disk /dev/nvme1n1
- No existing LVM setup

### Task 2: Create Physical Volume
```bash
 pvcreate /dev/nvme1n1
 pvs
```

✔ Disk initialized as Physical Volume

### Task 3: Create Volume Group
```bash
 vgcreate devops-vg /dev/nvme1n1
vgs
```

✔ Volume group created successfully

##  Task 4: Create Logical Volume
```bash
lvcreate -L 500M -n app-data devops-vg
lvs
```

✔ Logical volume created (app-data)

##  Task 5: Format and Mount
```bash
mkfs.ext4 /dev/devops-vg/app-data
mkdir -p /mnt/app-data
mount /dev/devops-vg/app-data /mnt/app-data
df -h /mnt/app-data
```

✔ Filesystem created and mounted successfully

##  Task 6: Extend Logical Volume
```bash
lvextend -L +200M /dev/devops-vg/app-data
resize2fs /dev/devops-vg/app-data
df -h /mnt/app-data
```

✔ Volume extended successfully without downtime

## What I Learned
- LVM uses PV → VG → LV architecture for flexible storage
- Logical volumes can be extended without data loss or downtime
- Filesystem must be resized after LV extension to use new space

## Conclusion

- LVM provides dynamic and scalable storage management, making it essential for DevOps and production environments.

---


##  Learning Resources

-  **Conceptual Understanding:** 
  👉 [Understanding Linux Storage (AWS EBS + LVM)](https://90-days-devops-with-shubham.hashnode.dev/understanding-linux-storage-aws-ebs-with-lvm)

-  **Hands-on Lab:**  
  👉 [Linux LVM Lab](https://90-days-devops-with-shubham.hashnode.dev/linux-lvm-lab)

---

#90DaysOfDevOps #DevOpsKaJosh #TrainWithShubham 
