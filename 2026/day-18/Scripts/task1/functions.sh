#!/bin/bash

# Function to greet
greet() {
  echo "Hello, $1!"
}

# Function to add numbers
add() {
  local sum=$(( $1 + $2 ))
  echo "Sum: $sum"
}

# Calling functions
greet "Malathi"
add 5 7
