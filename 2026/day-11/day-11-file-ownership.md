## Day 11 – File Ownership Challenge (chown & chgrp)

---

**Files & Directories Created**
- devops-file.txt
- team-notes.txt
- project-config.yaml
- app-logs/
- heist-project/
   -  vault/gold.txt
   - plans/strategy.conf
- bank-heist/
  - access-codes.txt
  - blueprints.pdf
  - escape-plan.txt

---


## Task 1: Understanding Ownership

Command

```bash
ls -l
```

Format
```bash
-rw-r--r-- 1 owner group size date filename
```

Meaning of Each Column

| Column      | Description                |
| ----------- | -------------------------- |
| Permissions | File access rights         |
| Links       | Number of hard links       |
| Owner       | User who owns the file     |
| Group       | Group associated with file |
| Size        | File size                  |
| Date        | Last modified              |
| Filename    | File name                  |

---

Owner vs Group
- Owner → The user who owns the file (has primary control)
- Group → A set of users who share access permissions to the file

Difference Between Owner and Group
- The owner can modify permissions and control the file
- The group allows multiple users to access the file based on group permissions
- Useful in team environments where shared access is required
  
---

## Task 2: Basic chown Operations

```bash
touch devops-file.txt
ls -l devops-file.txt

sudo useradd lisbon
sudo useradd Rio

sudo chown lisbon devops-file.txt
ls -l devops-file.txt

sudo chown Rio devops-file.txt
ls -l devops-file.txt
```

Ownership Changes
devops-file.txt: user:user → lisbon:user → Rio:user

---

 ## Task 3: Basic chgrp Operations

 ```bash
touch team-notes.txt
ls -l team-notes.txt

sudo groupadd heist-team
sudo chgrp heist-team team-notes.txt

ls -l team-notes.txt
```

Ownership Changes
- team-notes.txt → user:user → user:heist-team

---

## Task 4: Combined Owner & Group Change

```bash
touch project-config.yaml
sudo useradd professor

sudo chown professor:heist-team project-config.yaml

mkdir app-logs
sudo chown Rio:heist-team app-logs
```


Change Summary
project-config.yaml → professor:heist-team
app-logs/ → Rio:heist-team

Ownership Changes
project-config.yaml → professor:heist-team
app-logs/ → Rio:heist-team
ls -l

---

## Task 5: Recursive Ownership

```bash
mkdir -p heist-project/vault
mkdir -p heist-project/plans

touch heist-project/vault/gold.txt
touch heist-project/plans/strategy.conf

sudo groupadd planners

sudo chown -R professor:planners heist-project/

ls -lR heist-project/
```


**Ownership Changes**

All files and directories inside heist-project/ changed to:

Owner: professor
Group: planners

---

## Task 6: Practice Challenge

```bash
sudo useradd denver 
sudo useradd stockholm
sudo useradd helsinki

sudo groupadd vault-team
sudo groupadd tech-team

mkdir bank-heist

touch bank-heist/access-codes.txt
touch bank-heist/blueprints.pdf
touch bank-heist/escape-plan.txt

sudo chown denver:vault-team bank-heist/access-codes.txt
sudo chown stockholm:tech-team bank-heist/blueprints.pdf
sudo chown helsinki:vault-team bank-heist/escape-plan.txt

ls -l bank-heist/
```


Ownership Changes Summary

| File                | Owner     | Group           |
| ------------------- | --------- | --------------- |
| devops-file.txt     | Rio       | (default group) |
| team-notes.txt      | your-user | heist-team      |
| project-config.yaml | professor | heist-team      |
| app-logs/           | professor | heist-team      |
| gold.txt            | professor | planners        |
| strategy.conf       | professor | planners        |
| access-codes.txt    | denver    | vault-team      |
| blueprints.pdf      | stockholm | tech-team       |
| escape-plan.txt     | helsinki  | vault-team      |



```bash
ls -l

touch devops-file.txt
sudo useradd -m lisbon Rio
sudo chown lisbon devops-file.txt
sudo chown Rio devops-file.txt

touch team-notes.txt
sudo groupadd heist-team
sudo chgrp heist-team team-notes.txt

touch project-config.yaml
sudo useradd -m professor
sudo chown professor:heist-team project-config.yaml

mkdir app-logs
sudo chown Rio:heist-team app-logs

mkdir -p heist-project/vault heist-project/plans
touch heist-project/vault/gold.txt
touch heist-project/plans/strategy.conf
sudo groupadd planners
sudo chown -R professor:planners heist-project/

mkdir bank-heist
touch bank-heist/access-codes.txt bank-heist/blueprints.pdf bank-heist/escape-plan.txt
sudo useradd -m denver stockholm helsinki
sudo groupadd vault-team tech-team
sudo chown lisbon:vault-team bank-heist/access-codes.txt
sudo chown Rio:tech-team bank-heist/blueprints.pdf
sudo chown :vault-team bank-heist/escape-plan.txt

```

## Users & Groups

**Users**

- lisbon
- Rio
- professor
- denver
- stockholm
- helsinki

**Groups**
- heist-team
- planners
- vault-team
- tech-team

---

## Files & Directories Created

**Files**

- devops-file.txt
- team-notes.txt
- project-config.yaml
- heist-project/vault/gold.txt
- heist-project/plans/strategy.conf
- bank-heist/access-codes.txt
- bank-heist/blueprints.pdf
- bank-heist/escape-plan.txt

**Directories**

- app-logs/
- heist-project/
- heist-project/vault/
- heist-project/plans/
- bank-heist/

---

What I Learned
- Owner vs Group → Owner has full control, group enables shared access
- chown vs chgrp → chown changes owner (and group), chgrp changes only group
- Recursive ownership (-R) is critical for managing full project directories

  ---
  #90DaysOfDevOps #DevOpsKaJosh #TrainWithShubham #Happy Learning
