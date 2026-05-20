#!/usr/bin/env bash

echo "===== TASK 6: REAL-WORLD ONE-LINERS (HANDS-ON) ====="

# -------------------------------
# SETUP (create test files)
# -------------------------------
echo ""
echo "Setting up test environment..."

mkdir -p logs
echo "ERROR something failed" > logs/app1.log
echo "INFO running fine" >> logs/app1.log
echo "CRITICAL system down" > logs/app2.log
echo "error disk issue" > logs/app3.log

echo "Setup done."
ls logs

# -------------------------------
# 1. COUNT LINES IN LOG FILES
# -------------------------------
echo ""
echo "1️⃣ Count lines in all log files:"
wc -l logs/*.log

# -------------------------------
# 2. COUNT ERRORS (case-insensitive)
# -------------------------------
echo ""
echo "2️⃣ Count ERROR occurrences:"
grep -Ei "error|fail" logs/*.log | wc -l

# -------------------------------
# 3. TOP ERROR MESSAGES
# -------------------------------
echo ""
echo "3️⃣ Top error messages:"
grep -i "error" logs/*.log \
| awk '{$1=$2=$3=""; print}' \
| sed 's/^ *//' \
| sort | uniq -c | sort -rn

# -------------------------------
# 4. MONITOR DISK USAGE
# -------------------------------
echo ""
echo "4️⃣ Disk usage > 1% (demo threshold):"
df -h | awk '$5+0 > 1 {print $0}'

# -------------------------------
# 5. CHECK SERVICE STATUS
# -------------------------------
echo ""
echo "5️⃣ Check service (ssh):"
systemctl is-active --quiet ssh && echo "SSH running" || echo "SSH not running"

# -------------------------------
# 6. FIND OLD FILES (DRY RUN)
# -------------------------------
echo ""
echo "6️⃣ Find old log files (>0 days for demo):"
find logs -name "*.log" -mtime +0 -print

# -------------------------------
# 7. REPLACE TEXT IN FILE
# -------------------------------
echo ""
echo "7️⃣ Replace ERROR → FIXED:"
sed -i 's/ERROR/FIXED/g' logs/app1.log
cat logs/app1.log

# -------------------------------
# 8. ARCHIVE LOGS
# -------------------------------
echo ""
echo "8️⃣ Archive logs:"
tar -czf logs_backup_$(date +%F).tar.gz logs
ls *.gz

# -------------------------------
# 9. REAL-TIME LOG MONITOR (SIMULATED)
# -------------------------------
echo ""
echo "9️⃣ Simulating live logs (Ctrl+C to stop)..."

# simulate logs in background
(
  while true; do
    echo "$(date) ERROR random failure" >> logs/live.log
    sleep 2
  done
) &

# monitor
tail -f logs/live.log | grep -E "ERROR|CRITICAL"
