#!/bin/bash

log_file="$1"

if [ $# -eq 0 ] || [ ! -f "$log_file" ]; then
    echo "Error: Provide valid file"
    exit 1
fi

error_count=$(grep -Ei "ERROR|Failed" "$log_file" | wc -l)

echo "Total Error Count: $error_count"
