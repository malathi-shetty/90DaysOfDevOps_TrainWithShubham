# Day 19 – Shell Scripting Project: Log Rotation, Backup & Crontab

## Task 1: Log Rotation Script
Create `log_rotate.sh` that:
1. Takes a log directory as an argument (e.g., `/var/log/myapp`)
2. Compresses `.log` files older than 7 days using `gzip`
3. Deletes `.gz` files older than 30 days
4. Prints how many files were compressed and deleted
5. Exits with an error if the directory doesn't exist

   [log_rotate](scripts/task1/log_rotate.sh)

   
   <img width="741" height="793" alt="image" src="https://github.com/user-attachments/assets/60a21097-28b8-4db4-ad8b-50842a135b2c" />

   
---

## Task 2: Server Backup Script
Create `backup.sh` that:
1. Takes a source directory and backup destination as arguments
2. Creates a timestamped `.tar.gz` archive (e.g., `backup-2026-02-08.tar.gz`)
3. Verifies the archive was created successfully
4. Prints archive name and size
5. Deletes backups older than 14 days from the destination
6. Handles errors — exit if source doesn't exist

   [backup](scripts/task2/backup.sh)

   
   <img width="927" height="1181" alt="image" src="https://github.com/user-attachments/assets/950097cb-88e6-4781-b747-3325454b31ff" />

   
---

## Task 3: Crontab
1. Read: `crontab -l` — what's currently scheduled?
2. Understand cron syntax:
   ```
   * * * * *  command
   │ │ │ │ │
   │ │ │ │ └── Day of week (0-7)
   │ │ │ └──── Month (1-12)
   │ │ └────── Day of month (1-31)
   │ └──────── Hour (0-23)
   └────────── Minute (0-59)
   ```
3. Cron entries for:
   - Run `log_rotate.sh` every day at 2 AM     : `0 2 * * *`
   - Run `backup.sh` every Sunday at 3 AM      : `0 3 * * 7`
   - Run a health check script every 5 minutes : `*/5 * * * *`
  
  Edit this file to introduce tasks to be run by cron.
# 
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
# 
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').
# 
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
# 
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
# 
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
# 
# For more information see the manual pages of crontab(5) and cron(8)
# 
# m h  dom mon dow   command

* * * * * /home/ubuntu/day-19/task2/backup-exp.sh /home/ubuntu/day-19/task2/project_data /home/ubuntu/day-19/task2/project_backups

Check output

After 1–2 mins:

ls project_backups
- New backups should appear



---

## Task 4: Combine — Scheduled Maintenance Script
Create `maintenance.sh` that:
1. Calls your log rotation function
2. Calls your backup function
3. Logs all output to `/var/log/maintenance.log` with timestamps
4. Write the cron entry to run it daily at 1 AM : `0 1 * * *`

   [maintenance](scripts/task4/maintenance-1.sh)

  
  <img width="1108" height="1377" alt="image" src="https://github.com/user-attachments/assets/9349e845-2943-40a1-b884-9c8eab3d43d5" />

   
   
   
---

## What I learned

* 1️⃣ Automation over Manual Work

Instead of manually cleaning logs or taking backups, I used Bash scripts + cron to automate everything. This ensures consistency and reduces human error.

2️⃣ File Management & Cleanup (find, -mtime)

Learned how Linux tracks file age and used:

-  -mtime to identify old files
-  -exec, -delete to automate cleanup
- This is essential for log rotation and storage management.

3️⃣ Writing Reusable Scripts
- Used arguments ($1, $2, $#) to make scripts dynamic
- Added validation (if [ ! -d "$DIR" ]) to prevent failures
- This made scripts flexible and production-ready.

4️⃣ Compression & Backup Strategy
- Used tar and gzip to create compressed backups
- Reduced disk usage and improved efficiency
- Implemented automatic deletion of old backups

5️⃣ Cron Automation
- Understood cron syntax (* * * * *)
- Scheduled jobs for off-peak hours (e.g., 0 1 * * *)
- Learned that cron requires absolute paths and proper environment setup

6️⃣ Debugging Real-world Issues
- Fixed path issues (scripts failing silently in cron)
- Handled permission problems (/var/log requires sudo)
- Tested scripts step-by-step before automation

7️⃣ Logging & Monitoring
- Used tee to log output while displaying it in real time
- Created centralized logs (maintenance.log) for tracking execution
- Helped simulate real production monitoring

8️⃣ System Design Thinking

Combined multiple scripts into a single maintenance.sh
→ Made scheduling cleaner and more maintainable
