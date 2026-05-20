#!/usr/bin/env bash

# Validate input
if [ -z "$1" ]; then
    echo "Usage: $0 <name>"
    exit 1
fi

NAME="$1"

echo "Hello $NAME"

# User input
read -p "Enter your city: " CITY
echo "You are from $CITY"

# File test with quoting
FILE="my file.txt"
touch "$FILE"

if [ -f "$FILE" ]; then
    echo "File created successfully"
fi

# Exit status demo
ls /wrong-path
echo "Exit code: $?"

ls /tmp
echo "Exit code: $?"
