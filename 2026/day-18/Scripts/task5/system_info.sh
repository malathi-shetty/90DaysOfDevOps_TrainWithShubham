#!/bin/bash
set -euo pipefail

# Reusable header function
print_header() {
    echo "========================================"
    echo "$1"
    echo "========================================"
}

# Hostname & OS Info
system_info() {
    print_header "Hostname & OS Info"
    echo "Hostname : $(hostname)"
    echo "Kernel   : $(uname -r)"
    echo "OS       : $(lsb_release -ds 2>/dev/null || uname -o)"
    echo
}

# Uptime
system_uptime() {
    print_header "System Uptime"
    uptime
    echo
}

# Disk Usage (Top 5)
disk_usage() {
    print_header "Top 5 Disk Usage"
    df -h | sort -hr -k5 | head -n 6
    echo
}

# Memory Usage
memory_usage() {
    print_header "Memory Usage"
    free -h | awk 'NR==2 {print "Used: " $3 " | Free: " $4 " | Available: " $7}'
    echo
}

# Top CPU Processes
top_cpu_processes() {
    print_header "Top 5 CPU Processes"
    ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6
    echo
}

# Main function
main() {
    system_info
    system_uptime
    disk_usage
    memory_usage
    top_cpu_processes
}

main
