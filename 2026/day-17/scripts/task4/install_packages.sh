#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  # Check if sudo exists
  command -v sudo >/dev/null 2>&1 || {
    echo "sudo is required but not installed."
    exit 1
  }

  echo "Re-running as root..."
  exec sudo "$0" "$@"
fi

packages=("nginx" "curl" "wget")

# Run update once (optimization)
apt-get update -y

for pkg in "${packages[@]}"
do
  if dpkg -s "$pkg" &> /dev/null
  then
    echo "$pkg is already installed"
  else
    echo "Installing $pkg..."
    apt-get install -y "$pkg"
  fi
done
