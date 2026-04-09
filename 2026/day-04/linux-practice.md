# Day 04 – Linux Practice: Processes, Services & Logs

---

# 🔹 Process Checks

## Commands Used

### 1. List running processes

```bash
ps aux | head
```

**Output:**

```
USER       PID %CPU %MEM COMMAND
root         1  0.0  0.1 /sbin/init
root       234  0.1  0.3 /usr/lib/systemd/systemd-journald
```

---

### 2. Find process by name

```bash
pgrep ssh
```

**Output:**

```
1023
```

---

### 3. Detailed SSH process check

```bash
pgrep -a sshd
ps aux | grep sshd
```

---

### 4. Check current shell process

```bash
ps -p $$
```

---

* `ps` → Show current terminal processes
* `ps -a` → Show all terminal processes
* `ps aux` → Detailed process list
* `ps aux | grep ssh` → Filter SSH processes
* `ps aux --sort=-%cpu | head -n 5` → Top CPU processes
* `ps aux --sort=-%mem | head -n 5` → Top memory processes
* `ps -C sshd` → Exact process match

### Real-time Monitoring

```bash
top
```

---

# 🔹 Service Checks (Inspecting SSH Service)


### 5. Check service status

```bash
systemctl status ssh
```

**Output:**

```
● ssh.service - OpenSSH server daemon
   Active: active (running)
```

---

### 6. List running services

```bash
systemctl list-units --type=service --state=running | head
```

Shows all currently running services

**Output:**

```
ssh.service   loaded active running OpenSSH server daemon
cron.service  loaded active running background jobs
```

---

### 7. Check if service is enabled

```bash
systemctl is-enabled ssh
```

---

# 🔹 Log Checks



### 8. View SSH logs

```bash
journalctl -u ssh --no-pager | tail -n 5
```

---

### 9. Check system logs

```bash
tail -n 20 /var/log/syslog
```

---

### 10. Check authentication logs

```bash
tail -n 10 /var/log/auth.log
```

Used for:

* SSH login attempts
* Failed connections
* Security monitoring

Example:

```
Connection reset by 111.x.x.x [preauth]
```

---


* `journalctl` → View logs
* `journalctl -xe` → Detailed errors
* `journalctl -u ssh` → SSH logs
* `journalctl -u ssh --since "1 hour ago"` → Time-based logs
* `tail -f /var/log/auth.log` → Live monitoring

---

# 🔹 Service Inspection (SSH)

* Service Name: `ssh`
* Purpose: Remote login
* Status: Running
* Port: 22

### What we checked:

* Service status → running
* Processes → sshd active
* Logs → connection attempts visible
* Port → listening

---

# 🔹 Troubleshooting Flow

## Scenario: SSH not working

### Steps:

1. Check process

```bash
pgrep ssh
```

2. Check service

```bash
systemctl status ssh
```

3. Restart service

```bash
systemctl restart ssh
```

4. Check logs

```bash
journalctl -u ssh --since "10 minutes ago"
```

5. Verify port

```bash
ss -tuln | grep :22
```

---

**How do you troubleshoot a service?**

* Check status
* Check process
* Check logs
* Restart service
* Verify

---

# 🔹 Nginx Practice (Real-world Scenario)

## Install (if not installed)

```bash
sudo apt install nginx
```

---

## Break it

```bash
sudo systemctl stop nginx
```

---

## Troubleshoot

```bash
systemctl status nginx
curl localhost
journalctl -u nginx
```

 Website not loading → check nginx

---

## Fix

```bash
sudo systemctl start nginx
```

---

# 🔹 Key Learnings

* Processes → what is running

* Services → what should be running

* Logs → what actually happened

* `/var/log/auth.log` → security & login activity

* `systemctl list-units --type=service --state=running` → shows running services

* SSH logs show real-world bot traffic 

---

Completed:

* Process commands
* Service commands
* Log commands
* SSH inspection
* Troubleshooting steps
* Real-world nginx practice

---

#90DaysOfDevOps #DevOpsKaJosh #TrainWithShubham #Happy Learning
