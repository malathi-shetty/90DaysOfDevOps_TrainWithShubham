# Day 07 – Linux File System Hierarchy & Scenario-Based Practice

Understand where things live in Linux and practice troubleshooting like a DevOps engineer.

---

## Part 1: Linux File System Hierarchy

### 🔹 Core Directories

| Directory | Purpose | Example | I would use this when... |
|----------|--------|--------|--------------------------|
| `/` | Root of entire filesystem | bin, etc, var | Navigating system-wide issues |
| `/home` | User directories | /home/ubuntu | Debugging user scripts |
| `/root` | Root user home | .bashrc, .ssh | Admin-level operations |
| `/etc` | Configuration files | nginx/, ssh/ | Service/config issues |
| `/var/log` | Log files | syslog, auth.log | Debugging failures |
| `/tmp` | Temporary files | temp files | Testing / temp storage |

---

### Additional Directories

| Directory | Purpose |
|----------|--------|
| `/bin` | Essential commands |
| `/usr/bin` | Installed binaries |
| `/opt` | Third-party apps |

---

##  Troubleshooting Mindset

```
Problem → Check → Logs → Fix → Verify
```

> Logs don’t fail loudly — they fill silently.

---

## Mapping Problems → Directories

```
+----------------------+--------------------------+
| Problem              | Where to Check           |
+----------------------+--------------------------+
| Service failure      | /etc , /var/log         |
| Disk full            | /var                    |
| Crash / error        | /var/log                |
| Script issue         | /home                   |
| System issue         | /proc , /sys            |
+----------------------+--------------------------+
```

###  Directory Output

```bash
ls -l /var/log
# syslog
# auth.log
# nginx/

ls -l /etc
# nginx/
# ssh/
# hostname
```

---

## Scenario Practice

### Scenario 1: Service Not Starting

**Step 1**
```bash
systemctl status myapp
```
Why: Check if service failed or stopped

**Step 2**
```bash
journalctl -u myapp -n 50
```
Why: View recent logs

**Step 3**
```bash
systemctl is-enabled myapp
```
Why: Check auto-start

**Step 4**
```bash
systemctl restart myapp
```
Why: Try restarting after fix

---

###  Scenario 2: High CPU Usage

```bash
top
ps aux --sort=-%cpu | head -10
```

Why: Identify top CPU-consuming process

---

###  Scenario 3: Find Service Logs

```bash
systemctl status docker
journalctl -u docker -n 50
journalctl -u docker -f
```

Why: View logs and monitor in real-time

---

### Scenario 4: Permission Denied

```bash
ls -l /home/user/backup.sh
chmod +x /home/user/backup.sh
./backup.sh
```

Why: Add execute permission

---

##  Quick Debug Flow

<img width="1024" height="1536" alt="image" src="https://github.com/user-attachments/assets/f38ee446-0c7e-4800-a47e-194e65410963" />


---

## Learnings

- A running service doesn’t mean a working service  
- Disk issues don’t crash systems — they degrade them  
- Most issues are solved by checking the right place first  

---

Hashnode blog: https://90-days-devops-with-shubham.hashnode.dev/day-07-linux-file-system-hierarchy-scenario-based-practice

https://90-days-devops-with-shubham.hashnode.dev/day-07-scenario-based-practice

---




#90DaysOfDevOps #DevOpsKaJosh #TrainWithShubham
