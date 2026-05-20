#! /bin/bash 

read -p "Enter a number: " Number

if [ $Number -gt 0 ]
then
	echo "The number is positive"
elif [ $Number -lt 0 ]
then 
	echo "The number is negative"
else
	echo "The number is zero"
fi
