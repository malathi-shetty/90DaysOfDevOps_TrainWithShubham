Process Checks

1. List running processes
ps aux | head

Output (sample):

USER       PID %CPU %MEM COMMAND
root         1  0.0  0.1 /sbin/init
root       234  0.1  0.3 /usr/lib/systemd/systemd-journald

2. Find process by name
pgrep ssh

Output:

1023

------

Service Checks (Inspecting SSH Service)
3. Check service status
systemctl status ssh

Output:

● ssh.service - OpenSSH server daemon
   Active: active (running)
   
4. List running services
systemctl list-units --type=service --state=running | head

Output:

ssh.service         loaded active running OpenSSH server daemon
cron.service        loaded active running Regular background program processing daemon


Log Checks
5. View service logs
journalctl -u ssh --no-pager | tail -n 5

Output:

Accepted password for user from 192.168.1.5
Session opened for user


6. Check system log file
tail -n 20 /var/log/syslog

Output:

systemd[1]: Started OpenSSH server daemon
CRON[1234]: Job completed

----

Troubleshooting Flow

Scenario: SSH not working

1. Check if process is running

pgrep ssh

2. Check service status

systemctl status ssh

3. Restart service if needed

systemctl restart ssh

4. Check logs for errors

journalctl -u ssh --since "10 minutes ago"

5. Verify port is listening

ss -tuln | grep :22

----------

- Processes tell you what is running
- Services tell you what should be running
- Logs tell you what actually happened
