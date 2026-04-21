#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || {
    echo "sudo is required but not installed."
    exit 1
  }

  echo "sudo is available ✔"
  echo "Re-running as root..."
  exec sudo "$0" "$@"
fi

echo "Running as root ✔"

# Show OS info
echo "OS Information:"
cat /etc/os-release
echo "-----------------------------"

# Check package managers
for mgr in apt-get dnf yum
do
  if command -v "$mgr" >/dev/null 2>&1; then
    echo "$mgr is installed ✔"
  else
    echo "$mgr is NOT installed"
  fi
done

echo "-----------------------------"

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
  PKG_MANAGER="apt"
  UPDATE_CMD="apt-get update -y"
  INSTALL_CMD="apt-get install -y"
  CHECK_CMD="dpkg -s"

elif command -v dnf >/dev/null 2>&1; then
  PKG_MANAGER="dnf"
  UPDATE_CMD="dnf makecache -y"
  INSTALL_CMD="dnf install -y"
  CHECK_CMD="rpm -q"

elif command -v yum >/dev/null 2>&1; then
  PKG_MANAGER="yum"
  UPDATE_CMD="yum makecache -y"
  INSTALL_CMD="yum install -y"
  CHECK_CMD="rpm -q"

else
  echo "No supported package manager found"
  exit 1
fi

echo "Using package manager: $PKG_MANAGER"
echo "-----------------------------"

packages=("nginx" "curl" "wget")

# Run update once
eval "$UPDATE_CMD"

# Install loop (clean version)
for pkg in "${packages[@]}"
do
  if $CHECK_CMD "$pkg" &> /dev/null
  then
    echo "$pkg is already installed ✔"
  else
    echo "Installing $pkg..."
    eval "$INSTALL_CMD $pkg"
  fi
done

echo "-----------------------------"
echo "All tasks completed 🎉"
