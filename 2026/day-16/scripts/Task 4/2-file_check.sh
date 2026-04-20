#!/bin/bash

read -p "Enter filename: " FILE

if [ -f "$FILE" ]
then
	echo "File exists"
else
	echo "File does not exist"
fi
