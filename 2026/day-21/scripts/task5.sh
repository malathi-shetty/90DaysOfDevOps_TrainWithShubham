#!/usr/bin/env bash

echo "===== TEXT PROCESSING DEMO ====="

LOG_FILE="sample.log"

# -------------------------------
# 1. CREATE SAMPLE FILE
# -------------------------------
echo "Creating sample log file..."

cat <<EOF > "$LOG_FILE"
INFO Server started
ERROR Failed to connect
WARNING Disk almost full
ERROR Timeout occurred
INFO User login
CRITICAL System crash
error lowercase test
EOF

echo "Sample log created: $LOG_FILE"

echo ""
echo "===== GREP EXAMPLES ====="

# -------------------------------
# 2. GREP
# -------------------------------
echo "All ERROR (case-insensitive):"
grep -i "error" "$LOG_FILE"

echo ""
echo "Count ERROR:"
grep -c "ERROR" "$LOG_FILE"

grep -c "WARNING" "$LOG_FILE"

echo ""
echo "Show line numbers:"
grep -n "ERROR" "$LOG_FILE"

echo ""
echo "Exclude INFO:"
grep -v "INFO" "$LOG_FILE"

echo ""
echo "Multiple patterns:"
grep -E "ERROR|CRITICAL" "$LOG_FILE"
grep "CRITICAL" "$LOG_FILE"

echo ""
echo "===== AWK EXAMPLES ====="

# -------------------------------
# 3. AWK
# -------------------------------
echo "Print first column:"
awk '{print $1}' "$LOG_FILE"

echo ""
echo "Print message only:"
awk '{$1=""; print}' "$LOG_FILE"

echo ""
echo "Filter ERROR lines:"
awk '/ERROR/ {print}' "$LOG_FILE"

echo ""
echo "BEGIN and END:"
awk 'BEGIN {print "Start"} {print $1} END {print "End"}' "$LOG_FILE"

echo ""
echo "===== SED EXAMPLES ====="

# -------------------------------
# 4. SED
# -------------------------------
echo "Replace ERROR with ISSUE:"
sed 's/ERROR/ISSUE/g' "$LOG_FILE"

echo ""
echo "Delete line 2:"
sed '2d' "$LOG_FILE"

echo ""
echo "===== CUT EXAMPLES ====="

# -------------------------------
# 5. CUT
# -------------------------------
echo "Extract first column:"
cut -d " " -f1 "$LOG_FILE"

echo ""
echo "===== SORT + UNIQ ====="

# -------------------------------
# 6. SORT + UNIQ
# -------------------------------
echo "Sorted:"
sort "$LOG_FILE"

echo ""
echo "Unique counts:"
sort "$LOG_FILE" | uniq -c

echo ""
echo "===== TR EXAMPLES ====="

# -------------------------------
# 7. TR
# -------------------------------
echo "Uppercase:"
echo "hello devops" | tr 'a-z' 'A-Z'

echo ""
echo "Remove digits:"
echo "abc123xyz" | tr -d '0-9'

echo ""
echo "===== WC EXAMPLES ====="

# -------------------------------
# 8. WC
# -------------------------------
echo "Line count:"
wc -l "$LOG_FILE"

echo "Word count:"
wc -w "$LOG_FILE"

echo ""
echo "===== HEAD / TAIL ====="

# -------------------------------
# 9. HEAD / TAIL
# -------------------------------
echo "First 3 lines:"
head -n 3 "$LOG_FILE"

echo ""
echo "Last 3 lines:"
tail -n 3 "$LOG_FILE"

echo ""
echo "===== REAL DEVOPS PIPELINE ====="

# -------------------------------
# 10. PIPELINE (IMPORTANT)
# -------------------------------
echo "Top ERROR messages:"

grep -i "error" "$LOG_FILE" \
| awk '{$1=""; print}' \
| sed 's/^ *//' \
| sort \
| uniq -c \
| sort -rn \
| head -3

echo ""
echo "===== DONE ====="
