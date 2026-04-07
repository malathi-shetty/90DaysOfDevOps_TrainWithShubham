Process Management
- ps aux — List all running processes with details
- top — Real-time system and process monitor
- htop — Interactive process viewer (better than top)
- pidof <name> — Get PID of a process by name
- kill <PID> — Terminate a process by PID
- kill -9 <PID> — Force kill a process
- pkill <name> — Kill processes by name
- nice -n 10 <cmd> — Start process with lower priority
- renice <priority> -p <PID> — Change priority of running process
- jobs — Show background jobs
- bg — Resume job in background
- fg — Bring job to foreground

File System
- ls -la — List files with permissions, size, hidden files
- cd <dir> — Change directory
- pwd — Show current directory
- du -sh * — Show folder sizes
- df -h — Show disk usage (human-readable)
- find /path -name "file" — Search files by name
- locate <file> — Fast file search (indexed)
- cp -r src dest — Copy directories
- mv src dest — Move/rename files
- rm -rf <dir> — Delete directory forcefully
- chmod 755 <file> — Change file permissions
- chown user:group <file> — Change file ownership
- tail -f <file> — Live view of file updates (logs)
- less <file> — View file page by page

Networking & Troubleshooting
- ping <host> — Check connectivity to a host
- ip addr — Show network interfaces and IPs
- ss -tuln — Show listening ports and connections
- netstat -tulnp — Display network connections with PIDs
- curl <url> — Fetch HTTP response from a URL
- dig <domain> — DNS lookup details
- nslookup <domain> — Query DNS records
- traceroute <host> — Trace network path to host
- wget <url> — Download files from the web
- hostname -I — Show system IP address


Log command:
- tail -f /var/log/syslog — Monitor logs in real time

Networking command:
- ping google.com — Quickly verify internet connectivity
