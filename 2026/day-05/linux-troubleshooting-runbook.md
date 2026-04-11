Target Service
---

Service used: nginx
Status: Running

Commands Ran + Observations
---

1. Environment Basics
- uname -a → System info
  - Ubuntu Linux, x86_64, modern kernel

- lsb_release -a → OS details
  - Ubuntu 24.04 LTS confirmed

2. Filesystem
- mkdir /tmp/runbook-demo
- cp /etc/hosts /tmp/runbook-demo/hosts-copy && ls -l
  - Filesystem writable, file copied successfully

3. CPU / Memory
- top
  - No CPU spikes, system stable

- free -h
  - Memory usage normal, no swap usage

4. Disk / IO
- df -h
  - ~40% disk used, enough free space

- du -sh /var/log
  - Logs size normal, no disk pressure

5. Network
- ss -tulpn | grep nginx
  - Nginx listening on port 80

- curl -I http://localhost
  - HTTP 200 OK → service reachable

6. Logs
- journalctl -u nginx -n 50
  - No recent errors

- tail -n 50 /var/log/nginx/error.log
  - Only [notice] logs → normal behavior
  - Not all logs are errors — [notice] means normal operation, not a failure.

---

**If This Worsens**
- Restart service → sudo systemctl restart nginx
- Check logs → journalctl -u nginx -n 100
- Deep debug → increase log level / use strace

--------

https://90-days-devops-with-shubham.hashnode.dev/day-05-my-first-real-linux-troubleshooting-drill

------

#90DaysOfDevOps
#DevOpsKaJosh
#TrainWithShubham
#Happy Learning
