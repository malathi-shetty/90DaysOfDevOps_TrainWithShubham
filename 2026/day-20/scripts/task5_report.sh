#!/bin/bash

log_file="$1"

if [ $# -eq 0 ] || [ ! -f "$log_file" ]; then
    echo "Error: Provide valid file"
    exit 1
fi

report="log_report_$(date +%Y-%m-%d).txt"

{
    echo "Date: $(date)"
    echo "Log File: $log_file"
    echo "Total Lines: $(wc -l < "$log_file")"
    echo "Total Errors: $(grep -Ei "ERROR|Failed" "$log_file" | wc -l)"
    echo ""

    echo "--- Top Errors ---"
    grep "ERROR" "$log_file" \
    | awk '{$1=$2=$3=""; print}' \
    | sed 's/^ *//' \
    | sort | uniq -c | sort -rn | head -5

    echo ""
    echo "--- Critical Events ---"
    grep -n "CRITICAL" "$log_file" | sed 's/^\([0-9]*\):/Line \1:/'

} > "$report"

echo "Report generated: $report"
