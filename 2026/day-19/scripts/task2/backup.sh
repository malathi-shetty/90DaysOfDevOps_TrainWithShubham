#!/bin/bash

SRC=$1
DEST=$2
DATE=$(date +%Y-%m-%d)
ARCHIVE="$DEST/backup-$DATE.tar.gz"

if [ -z "$SRC" ] || [ -z "$DEST" ]; then
  echo "Usage: $0 <source_directory> <destination_directory>"
  exit 1
fi

if [ ! -d "$SRC" ]; then
  echo "Error: Source directory does not exist"
  exit 1
fi

mkdir -p "$DEST"

# Create archive
tar -czf "$ARCHIVE" "$SRC"

# Verify archive
if [ $? -eq 0 ]; then
  SIZE=$(du -h "$ARCHIVE" | cut -f1)
  # echo "Backup created: $ARCHIVE"
  # echo "Size: $SIZE"
  echo "$(date) - Backup created: $ARCHIVE"
  echo "$(date) - Size: $SIZE"
else
echo "Backup failed"
  exit 1
fi

# Delete backups older than 14 days
#find "$DEST" -name "backup-*.tar.gz" -mtime +14 -print -delete

echo "$(date) - Deleting old backups:"
find "$DEST" -name "backup-*.tar.gz" -mtime +14 -exec echo "$(date) - Deleted: {}" \; -exec rm {} \;
