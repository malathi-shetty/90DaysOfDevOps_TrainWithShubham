#!/bin/bash

echo "=== Local vs Global (String + Number) ==="

echo
echo "Using LOCAL variables"

use_local() {
  local var="I am local"
  local name="Malathi"
  local num=10

  echo "Inside use_local:"
  echo "variables: $var"
  echo "Name: $name"
  echo "Number: $num"
}

echo

use_local

echo "Outside function (local):"
echo "variables: ${var:-Not Accessible}"
echo "Name: ${name:-Not Accessible}"
echo "Number: ${num:-Not Accessible}"

echo
echo "------------"
echo
echo "Using GLOBAL variables"

use_global() {
    var="I am global"
    name="Shrisha"
    num=20

    echo "Inside use_global:"
    echo "variables: $var"
    echo "Name: $name"
    echo "Number: $num"
}

echo 

use_global

echo "Outside function (global):"
echo "variables: $var"
echo "Name: $name"
echo "Number: $num"


