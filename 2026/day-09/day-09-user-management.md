# Day 09 – Linux User & Group Management Challenge

## Users & Groups Created

* Users: tokyo, berlin, professor, nairobi
* Groups: developers, admins, project-team

---

## Group Assignments

| User      | Groups                   |
| --------- | ------------------------ |
| tokyo     | developers, project-team |
| berlin    | developers, admins       |
| professor | admins                   |
| nairobi   | project-team             |

---

## Directories Created

| Directory           | Owner | Group        | Permissions |
| ------------------- | ----- | ------------ | ----------- |
| /opt/dev-project    | root  | developers   | 775         |
| /opt/team-workspace | root  | project-team | 775         |

---

## Commands Used

### Task 1: Create Users

```bash
sudo useradd -m tokyo
sudo passwd tokyo

sudo useradd -m berlin
sudo passwd berlin

sudo useradd -m professor
sudo passwd professor
```

### Verify Users

```bash
cat /etc/passwd | grep -E 'tokyo|berlin|professor'
ls /home/
```

<img width="710" height="487" alt="image" src="https://github.com/user-attachments/assets/2ce165c4-c3f0-4c50-aed0-742ab05866af" />


---

### Task 2: Create Groups

```bash
sudo groupadd developers
sudo groupadd admins
```

### Verify Groups

```bash
cat /etc/group | grep -E 'developers|admins'
```

<img width="672" height="167" alt="image" src="https://github.com/user-attachments/assets/3d16eb36-0411-4f88-bd22-e2ceeedf20c5" />


---

### Task 3: Assign Users to Groups

```bash
sudo usermod -aG developers tokyo

sudo usermod -aG developers berlin
sudo usermod -aG admins berlin

sudo usermod -aG admins professor
```

### Verify Group Membership

```bash
groups tokyo
groups berlin
groups professor
```

<img width="587" height="322" alt="image" src="https://github.com/user-attachments/assets/2f2fcf88-72ff-4b65-b9c4-940e84f5838d" />


---

### Task 4: Shared Directory

```bash
sudo mkdir -p /opt/dev-project
sudo chgrp developers /opt/dev-project
sudo chmod 775 /opt/dev-project
```

### Test Access

```bash
sudo -u tokyo touch /opt/dev-project/tokyo_file
sudo -u berlin touch /opt/dev-project/berlin_file
ls -l /opt/dev-project
```

<img width="743" height="313" alt="image" src="https://github.com/user-attachments/assets/d7c16807-90e8-4eb2-ae21-1569558a3b04" />






---

### Task 5: Team Workspace

```bash
sudo useradd -m nairobi
sudo passwd nairobi

sudo groupadd project-team

sudo usermod -aG project-team nairobi
sudo usermod -aG project-team tokyo

sudo mkdir -p /opt/team-workspace
sudo chgrp project-team /opt/team-workspace
sudo chmod 775 /opt/team-workspace
```

### Test Access

```bash
sudo -u nairobi touch /opt/team-workspace/nairobi_file
ls -l /opt/team-workspace
```

<img width="752" height="448" alt="image" src="https://github.com/user-attachments/assets/7ebe6561-9dbc-4fbc-9e94-10c3f5b2d038" />

## Verify Directory permissions

```bash
ls -ld /opt/dev-project 
ls -l /opt/dev-project

ls -ld /opt/team-workspace
ls -l /opt/team-workspace
```

<img width="658" height="173" alt="image" src="https://github.com/user-attachments/assets/40bbe2a0-501a-4099-9e7a-c9e8f96adf09" />

---

## What I Learned

1. Users can belong to multiple groups and inherit permissions from them.
2. 775 permissions allow team collaboration (owner + group can write).
3. Group ownership (chgrp) + permissions (chmod) control access in Linux.

