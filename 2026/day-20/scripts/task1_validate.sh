#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Error: No log file path provided."
    exit 1
fi

log_file="$1"

if [ ! -f "$log_file" ]; then
    echo "Error: File does not exist: $log_file"
    exit 1
fi

echo "File is valid!"
