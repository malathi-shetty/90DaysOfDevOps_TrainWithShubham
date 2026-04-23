#!/bin/bash

LOG_DIR=$1

if [ -z "$LOG_DIR" ]; then
  echo "Usage: $0 <log_directory>"
  exit 1
fi

if [ ! -d "$LOG_DIR" ]; then
  echo "Error: Directory does not exist: $LOG_DIR"
  exit 1
fi

# Compress logs older than 7 days
COMPRESSED=$(find "$LOG_DIR" -name "*.log" -mtime +7 -exec gzip {} \; -print | wc -l)

# Delete compressed logs older than 30 days
DELETED=$(find "$LOG_DIR" -name "*.gz" -mtime +30 -delete -print | wc -l)

echo "Compressed files: $COMPRESSED"
echo "Deleted files: $DELETED"
