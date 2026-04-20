#!/bin/bash

SERVICE="nginx"

read -p "Do you want to check the status of $SERVICE? (y/n): " CHOICE

if [ "$CHOICE" = "y" ]
then
    if systemctl list-units --type=service | grep -q "$SERVICE"
    then
        systemctl status $SERVICE | grep "Active"
    else
        echo "Service $SERVICE is not installed."
    fi
elif [ "$CHOICE" = "n" ]
then
    echo "Skipped."
else
    echo "Invalid input."
fi
