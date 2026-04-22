#!/bin/bash

check_disk() {
  echo "Disk Usage:"
  df -h /
}

check_memory() {
  echo "Memory Usage:"
  free -h
}

# Main
check_disk
echo "------------------"
check_memory
