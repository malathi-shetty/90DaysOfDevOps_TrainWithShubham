# Day 12 – Breather & Revision (Days 01–11)


## Complete Linux revision checklist

###  Mindset & Plan (Day 01)

**Original Goals:**
- Build strong Linux fundamentals for DevOps
- Understand processes, services, users, permissions

**Current Reflection:**
- Linux commands improved
- Troubleshooting mindset improving
- Need more practice in:
  - `chmod` numeric permissions
  - log reading (`journalctl`)
  - real troubleshooting scenarios

**Tweaks Going Forward:**
- Focus on numeric permissions: `644`, `755`, `750`, `700`
- Practice logs daily using `journalctl`
- Increase hands-on debugging scenarios

---

###  Processes & Services (Days 04–05)

#### Process Inspection Commands
```bash
ps aux
ps aux | head
ps aux | grep <service>
````

**Observation:**

* Shows all running system processes
* Helps identify CPU/memory-heavy processes
* Critical columns: USER, PID, %CPU, %MEM

---

#### Service Health Check

```bash
systemctl status ssh
systemctl status <service>
systemctl is-active <service>
systemctl list-units --type=service
```

**Observation:**

* Shows service state (active/inactive/failed)
* Displays PID, uptime, and logs
* First step in debugging service failures

---

#### Log Analysis

```bash
journalctl -u ssh
journalctl -u ssh -n 20
journalctl -u ssh -f
journalctl -xe
```

**Observation:**

* Provides detailed service logs
* Helps detect errors, crashes, misconfigurations
* `-f` enables real-time monitoring

---

###  File Skills Practice (Days 06–11)

#### File Operations Practiced

```bash
echo "Revision practice" >> notes.txt
echo "DevOps log entry" >> day12-test.log

touch file.txt
cp file.txt backup.txt
mkdir test-dir

ls -l
ls -ld test-dir
```

#### Permissions Practice

```bash
chmod 644 notes.txt
chmod 755 script.sh
chmod 750 project-dir
chmod -R 750 /project-dir
chmod -R 755 /project
chmod +x script.sh
```

#### Ownership Practice

```bash
chown user:group file.txt
chown -R user:group project-dir
sudo chown testuser:testuser file.txt
```

#### Verification Commands

```bash
ls -l
ls -ld
id testuser
```

**Key Takeaway:**

* Always verify using `ls -l`
* Small permission mistakes can break services
* Ownership and permissions must always be checked together

---

###  Cheat Sheet Refresh (Day 03 – FULL INCIDENT TOOLKIT)

####  System Monitoring

```bash
top
htop
uptime
```

####  Process Management

```bash
ps aux
ps aux | grep <service>
ps aux | head
```

####  Disk & Storage

```bash
df -h
du -sh *
du -sh <directory>
```

####  Service Management

```bash
systemctl status <service>
systemctl list-units --type=service
systemctl start <service>
systemctl stop <service>
systemctl restart <service>
systemctl enable <service>
```

####  Logs & Debugging

```bash
journalctl -xe
journalctl -u <service>
journalctl -u <service> -n 20
journalctl -u <service> -f
tail -f <file>
```

####  File & Permissions

```bash
ls -l
chmod <mode>
chmod -R <mode>
chown <user>:<group>
chown -R <user>:<group>
```

####  Networking & Validation

```bash
curl -I localhost
ssh -i <key.pem> user@host
```

####  File Operations

```bash
cp
mv
rm
mkdir
touch
echo "text" >> file
```

---

### 👤 User & Group Sanity Check (Days 09–11)

#### User Creation

```bash
sudo useradd professor
sudo useradd testuser
id professor
id testuser
```

#### Ownership Testing

```bash
sudo chown devtest:devtest notes.txt
sudo chown testuser:testuser file.txt
ls -l notes.txt
ls -l file.txt
```

**Result:**

* User created successfully
* UID/GID assigned correctly
* Ownership updated properly

---

###  Why 750 and not 755?

#### Permission Breakdown

| Value | Meaning              |
| ----- | -------------------- |
| 7     | rwx (full access)    |
| 5     | r-x (read + execute) |
| 0     | --- (no access)      |

---

#### 755 Permission

```bash
chmod 755 file
```

* Owner: full access (rwx)
* Group: read + execute
* Others: read + execute

✔ Use when:

* Public scripts
* Web files
* Shared content

---

#### 750 Permission

```bash
chmod 750 file
```

* Owner: full access (rwx)
* Group: read + execute
* Others: NO access

✔ Use when:

* Internal company files
* DevOps configs
* Sensitive directories
* Production services

---

#### Key Difference

* `755` → Public access
* `750` → Restricted team-only access

---

#### Real-world Mapping

| Scenario           | Permission |
| ------------------ | ---------- |
| Public scripts     | 755        |
| Web static files   | 755        |
| Internal tools     | 750        |
| Production configs | 750        |

---

### 👤 Ownership vs Permissions

```bash
chown → defines WHO owns the file
chmod → defines WHAT they can do
```

---

##  Mini Self-Check (FULL DEVOPS ANSWERS)

---

### 1) Which commands save you the most time right now, and why?

These commands help with **troubleshooting, monitoring, debugging, and fixing issues quickly**:

```bash
ps aux
ps aux | grep <service>
top
htop
systemctl status <service>
systemctl is-active <service>
systemctl list-units --type=service
journalctl -u <service>
journalctl -u <service> -n 20
journalctl -xe
df -h
du -sh *
ls -l
chmod
chown
tail -f <file>
echo "text" >> file
cp
mkdir
touch
uptime
curl -I localhost
ssh -i <key.pem> user@host
```

👉 These commands save time because they provide:

* Instant system visibility
* Fast debugging
* Quick fixes
* Real-time monitoring

---

### 2) How do you check if a service is healthy?

```bash
systemctl status <service>
journalctl -u <service> -n 20
ps aux | grep <service>
curl -I localhost
uptime
```

**Flow:**

* `systemctl status` → check service state
* `journalctl` → check logs
* `ps aux` → confirm process exists
* `curl` → confirm response
* `uptime` → system stability

---

### 3) How do you safely change ownership and permissions?

```bash
ls -l file.txt
sudo chown user:group file.txt
chmod 640 file.txt
ls -l file.txt
```

#### Directory Example:

```bash
sudo chown -R user:group /project-dir
chmod -R 750 /project-dir
```

#### Safe Principles:

* Always check before changes → `ls -l`
* Apply ownership first → `chown`
* Apply permissions second → `chmod`
* Avoid `777`

---

### 4) What will you focus on improving in the next 3 days?

* Master numeric permissions (`755`, `644`, `750`, `700`)
* Improve log reading using `journalctl`
* Practice real-world troubleshooting scenarios
* Strengthen Linux command recall speed
* Learn storage concepts (mounting, LVM)
* Linux networking basics (`ip addr`, `ss -tuln`, `iptables`)
* Improve shell scripting practice
* More Docker hands-on practice

---

##  Key Takeaways

* Repetition builds real confidence
* Verification (`ls -l`, `systemctl status`, `id`) is critical
* Logs are the strongest debugging tool in Linux
* Permissions mistakes can break systems
* Troubleshooting is a step-by-step process, not guessing
* Speed comes from familiarity, not memorization

Refer: https://90-days-devops-with-shubham.hashnode.dev/day-1-11-devops-commands

https://90-days-devops-with-shubham.hashnode.dev/revision-days-01-11

---

#90DaysOfDevOps
#DevOpsKaJosh
#TrainWithShubham
#Happy Learning

