#!/bin/bash

set -e

LOG_FILE="/home/ubuntu/maintenance.log"
LOG_DIR="/var/log/myapp"
SRC="/home/ubuntu/day-19/task2/project_data"
DEST="/home/ubuntu/day-19/task2/project_backups"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check required scripts
if [ ! -f "/home/ubuntu/day-19/task1/log_rotate.sh" ]; then
  log "ERROR: log_rotate.sh not found"
  exit 1
fi

if [ ! -f "/home/ubuntu/day-19/task2/backup-exp.sh" ]; then
  log "ERROR: backup script not found"
  exit 1
fi

log "========== Maintenance Started =========="

# Log rotation
log "Running log rotation on: $LOG_DIR"
/home/ubuntu/day-19/task1/log_rotate.sh "$LOG_DIR" >> "$LOG_FILE" 2>&1
log "Log rotation completed"

# Backup
log "Running backup..."
/home/ubuntu/day-19/task2/backup-exp.sh "$SRC" "$DEST" >> "$LOG_FILE" 2>&1
log "Backup completed"

log "========== Maintenance Completed =========="
echo "----------------------------------------" >> "$LOG_FILE"

