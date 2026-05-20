#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root. Try: sudo ./script.sh"
  exit 1
fi

packages=("nginx" "curl" "wget")

for pkg in "${packages[@]}"
do
  if dpkg -s $pkg &> /dev/null
  then
    echo "$pkg is already installed"
  else
    echo "Installing $pkg..."
    apt-get update -y
    apt-get install -y $pkg
  fi
done
