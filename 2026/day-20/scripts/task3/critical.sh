#!/bin/bash

log_file="$1"

if [ $# -eq 0 ] || [ ! -f "$log_file" ]; then
    echo "Error: Provide valid file"
    exit 1
fi

echo "--- Critical Events ---"

grep -n "CRITICAL" "$log_file" | sed 's/^\([0-9]*\):/Line \1:/'
