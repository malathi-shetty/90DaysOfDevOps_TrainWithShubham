#!/bin/bash

set -e  # Exit immediately if any command fails

# Create directory
mkdir /tmp/devopsTest || echo "Directory already exists"

# Navigate into directory
cd /tmp/devopsTest || {
  echo "Failed to enter directory"
  exit 1
}

# Create a file
touch devops-test.txt || {
  echo "Failed to create file"
  exit 1
}

echo "Script executed successfully ✔"
