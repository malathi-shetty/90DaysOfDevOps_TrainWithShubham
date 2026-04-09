**1. Process Management**

Manage running processes, system performance, and job control

Core Commands
- ps → Show running processes
 - Example: ps → shows processes in your terminal

- ps aux → List all running processes with details
 - Example: ps aux → shows all apps like Chrome, VS Code

- top → Real-time system and process monitor
 - Example: top → live CPU/memory usage

- htop → Interactive process viewer
 - Example: htop → colorful task manager

- uptime → Show system load and uptime
 - Example: uptime → shows how long system is running

Process Control
- kill <PID> → Terminate a process
 - Example: kill 1234 → stop process with PID 1234

- kill -9 <PID> → Force kill
 - Example: kill -9 1234 → force stop stuck app

- killall <name> → Kill all processes by name
 - Example: killall chrome → close all Chrome

- pkill <name> → Kill process by name
 - Example: pkill nginx → stop nginx server

- pidof <name> → Get PID
 - Example: pidof nginx → get nginx PID

- pgrep <name> → Find PID
 - Example: pgrep python → find Python process

Priority Management
- nice -n 10 <cmd> → Start process with lower priority
 - Example: nice -n 10 python app.py → run with less CPU priority

- renice <priority> -p <PID> → Change priority
 - Example: renice 5 -p 1234 → change priority of process

Job Control
- jobs → Show background jobs
 - Example: jobs → list running background tasks

- bg → Resume job in background
 - Example: bg %1 → resume job 1 in background

- fg → Bring job to foreground
 - Example: fg %1 → bring job back to screen

- & → Run in background
 - Example: python app.py & → run app in background

Monitoring & Logs
- watch df -h → Monitor disk usage
 - Example: watch df -h → updates disk usage every 2 sec

- tail -n 100 → Show last 100 lines
 - Example: tail -n 100 logs.txt → see recent logs

- tail -f <file> → Live log monitoring
 - Example: tail -f app.log → watch logs live

 ---

**2. File System & File Management**

Navigate directories, manage files, and control permissions

Navigation & Listing
- pwd → Show current directory
 - Example: pwd → /home/user

- ls → List files
 - Example: ls → shows files

- ls -l → Detailed list
 - Example: ls -l → shows permissions & size

- ls -a → Show hidden files
 - Example: ls -a → shows .git, .env

- ls -la / ls -lah → Full details
 - Example: ls -lah → readable file sizes

- cd <dir> → Change directory
 - Example: cd /var/log

File & Directory Operations
- mkdir <dir> → Create directory
 - Example: mkdir project

- mkdir -p /a/b/c → Create nested folders
 - Example: mkdir -p app/src/utils

- touch <file> → Create empty file
 - Example: touch index.html

- cp <src> <dest> → Copy file
 - Example: cp file.txt backup.txt

- cp -r <src> <dest> → Copy folder
 - Example: cp -r project backup

- mv <src> <dest> → Move/rename
 - Example: mv file.txt new.txt

- rm <file> → Delete file
 - Example: rm test.txt

- rm -rf <dir> → Force delete folder
 - Example: rm -rf node_modules

Disk Usage
- df -h → Disk usage
 - Example: df -h → shows free disk space

- du -sh <dir> → Folder size
 - Example: du -sh project

- du -sh * → All folder sizes
 - Example: du -sh *

File Viewing
- cat <file> → Show file content
 - Example: cat file.txt

- less <file> → View page by page
 - Example: less large.log

- wc <file> → Count lines/words
 - Example: wc file.txt

Search
- find /path -name "file" → Search file
 - Example: find /home -name "test.txt"

- locate <file> → Fast search
 - Example: locate test.txt

Permissions & Ownership
- chmod 755 <file> → Change permissions
 - Example: chmod 755 script.sh

- chown user:group <file> → Change owner
 - Example: chown root:root file.txt

Utility
- clear → Clear terminal
 - Example: clear

---

**3. Networking & Troubleshooting**

Diagnose network issues and connections

Connectivity
- ping <host> → Check connectivity
 - Example: ping google.com

Network Info
- ip addr / ip a → Show IP
 - Example: ip a

- ip addr show → Full details
 - Example: ip addr show

- hostname -I → System IP
 - Example: hostname -I

Ports & Connections
- ss -tuln → Listening ports
 - Example: ss -tuln

- netstat -tulnp → Ports with PID
 - Example: netstat -tulnp

- netstat → General stats
 - Example: netstat

DNS & Routing
- dig <domain> → DNS info
 - Example: dig google.com

- nslookup <domain> → DNS query
 - Example: nslookup google.com

- traceroute <host> → Route path
 - Example: traceroute google.com

HTTP & Downloads
- curl <url> → Fetch response
 - Example: curl https://google.com

- curl -I <url> → Headers only
 - Example: curl -I https://google.com

- wget <url> → Download file
 - Example: wget https://example.com/file.zip

Logs
- tail -n 100 → Last lines
 - Example: tail -n 100 /var/log/syslog

- tail -f /var/log/syslog → Live logs
 - Example: tail -f /var/log/syslog

---

**4. User Management**
- who → Logged-in users
 - Example: who

- users → Current users
 - Example: users

- id → User info
 - Example: id

- usermod -aG gp1 ab1 → Add user to group
 - Example: usermod -aG docker ubuntu

- groupadd <group> → Create group
 - Example: groupadd devops

---

**5. Services (System Control)**

- systemctl status <service>
 - Example: systemctl status nginx

- systemctl start <service>
 - Example: systemctl start nginx

- systemctl stop <service>
 - Example: systemctl stop nginx

- systemctl is-active <service>
 - Example: systemctl is-active nginx

 ---------

#90DaysOfDevOps #DevOpsKaJosh #TrainWithShubham #Happy Learning

- systemctl enable --now <service>
 - Example: systemctl enable --now nginx
