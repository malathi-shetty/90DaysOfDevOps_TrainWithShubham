#!/bin/bash

set -euo pipefail

# -------------------------------
# Task 1: Input & Validation
# -------------------------------
if [ $# -eq 0 ]; then
    echo "Error: No log file provided."
    exit 1
fi

log_file="$1"

if [ ! -f "$log_file" ]; then
    echo "Error: File does not exist: $log_file"
    exit 1
fi

# -------------------------------
# Setup
# -------------------------------
date_now=$(date +%Y-%m-%d)
report_file="log_report_${date_now}.txt"

# -------------------------------
# Task 2: Error Count
# -------------------------------
error_count=$(grep -Ei "ERROR|Failed" "$log_file" | wc -l)

echo "Total Error Count: $error_count"

# -------------------------------
# Task 3: Critical Events
# -------------------------------
echo ""
echo "--- Critical Events ---"

critical_events=$(grep -n "CRITICAL" "$log_file" | sed 's/^\([0-9]*\):/Line \1:/')
echo "$critical_events"

# -------------------------------
# Task 4: Top 5 Error Messages
# -------------------------------
echo ""
echo "--- Top 5 Error Messages ---"

top_errors=$(grep "ERROR" "$log_file" \
    | awk '{$1=$2=$3=""; print}' \
    | sed 's/^ *//' \
    | sort \
    | uniq -c \
    | sort -rn \
    | head -5)

echo "$top_errors"

# -------------------------------
# Task 5: Summary Report
# -------------------------------
total_lines=$(wc -l < "$log_file")

{
    echo "===== Log Analysis Report ====="
    echo "Date of analysis: $(date)"
    echo "Log file name: $log_file"
    echo "Total lines processed: $total_lines"
    echo "Total error count: $error_count"
    echo ""

    echo "------------ Top 5 Error Messages ------------"
    echo "$top_errors"
    echo ""

    echo "------------ Critical Events ------------"
    echo "$critical_events"
    echo ""
} | tee "$report_file"

echo ""
echo "Summary report generated: $report_file"

# -------------------------------
# Task 6: Archive Logs
# -------------------------------
archive_dir="./archive"
mkdir -p "$archive_dir"

mv "$log_file" "$archive_dir/"

echo "Log file moved to $archive_dir/"
echo "Log analysis completed."
