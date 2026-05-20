#!/bin/bash

log_file="$1"

if [ $# -eq 0 ] || [ ! -f "$log_file" ]; then
    echo "Error: Provide valid file"
    exit 1
fi

echo "--- Top 5 Error Messages ---"

grep "ERROR" "$log_file" \
| awk '{$1=$2=$3=""; print}' \
| sed 's/^ *//' \
| sort \
| uniq -c \
| sort -rn \
| head -5
