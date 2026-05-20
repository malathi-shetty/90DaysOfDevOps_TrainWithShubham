#!/bin/bash

log_file="$1"

if [ $# -eq 0 ] || [ ! -f "$log_file" ]; then
    echo "Error: Provide valid file"
    exit 1
fi

mkdir -p archive
mv "$log_file" archive/

echo "File moved to archive/"
