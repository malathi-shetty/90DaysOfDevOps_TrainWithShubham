#!/bin/bash

MNTC_LOG="/var/log/maintenance-1.log"

LOG_SCRIPT="/home/ubuntu/day-19/task1/log_rotate.sh"
BACKUP_SCRIPT="/home/ubuntu/day-19/task2/backup-exp.sh"

LOG_DIR="/var/log/myapp"
SRC="/home/ubuntu/day-19/task2/project_data"
DEST="/home/ubuntu/day-19/task2/project_backups"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$MNTC_LOG"
}

rotate_logs() {
    log "Starting log rotation..."
    bash "$LOG_SCRIPT" "$LOG_DIR" 2>&1 | tee -a "$MNTC_LOG"
    log "Log rotation completed."
}

run_backup() {
    log "Starting backup..."
    bash "$BACKUP_SCRIPT" "$SRC" "$DEST" 2>&1 | tee -a "$MNTC_LOG"
    log "Backup completed."
}

# MAIN FLOW (this was missing)
log "========== Maintenance Started =========="

rotate_logs
run_backup

log "========== Maintenance Completed =========="
echo "----------------------------------------" | tee -a "$MNTC_LOG"
