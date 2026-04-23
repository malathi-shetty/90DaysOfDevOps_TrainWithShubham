#!/bin/bash
# Use Bash shell to execute this script

SRC=$1
# First argument → source directory (data to backup)

DEST=$2
# Second argument → destination directory (where backup will be stored)

DATE=$(date +%Y-%m-%d)
# Get current date in format: YYYY-MM-DD

ARCHIVE="$DEST/backup-$DATE.tar.gz"
# Create backup filename with timestamp inside destination folder

# Check if user provided both arguments
if [ -z "$SRC" ] || [ -z "$DEST" ]; then
  # -z checks if value is empty

  echo "Usage: $0 <source_directory> <destination_directory>"
  # $0 = script name → shows how to use script

  exit 1
  # Stop script with error
fi

# Check if source directory exists
if [ ! -d "$SRC" ]; then
  # -d checks if it's a directory
  # ! means NOT → so "if directory does NOT exist"

  echo "Error: Source directory does not exist"

  exit 1
  # Stop script because source is required (cannot backup nothing)
fi

# Create destination directory if it does not exist
mkdir -p "$DEST"
# -p → no error if folder already exists
# Destination can be created automatically ✅
# Source cannot be created ❌ (must already contain real data)

# Create compressed backup archive
tar -czf "$ARCHIVE" "$SRC"
# -c → create archive
# -z → compress using gzip
# -f → filename
# Result → backup-YYYY-MM-DD.tar.gz

# Check if tar command succeeded
if [ $? -eq 0 ]; then
  # $? → exit status of last command
  # 0 = success, non-zero = failure

  SIZE=$(du -h "$ARCHIVE" | cut -f1)
  # du -h → shows file size (human readable)
  # cut -f1 → extracts only size (e.g., 4.0K)

  echo "Backup created: $ARCHIVE"
  # Show backup file name

  echo "Size: $SIZE"
  # Show backup size

else
  echo "Backup failed"
  # If tar failed, print error

  exit 1
  # Stop script
fi

# Delete backups older than 14 days
echo "Deleting old backups:"
# Just a message to make output clearer

find "$DEST" -name "backup-*.tar.gz" -mtime +14 -print -delete
# find files in destination:
# -name → match backup files
# -mtime +14 → older than 14 days
# -print → show which files are being deleted
# -delete → remove them
