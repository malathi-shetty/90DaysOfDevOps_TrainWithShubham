#!/usr/bin/env bash

echo "===== FUNCTION BASICS ====="

# -------------------------------
# 1. DEFINE FUNCTION
# -------------------------------
greet() {
  echo "Hello, welcome to DevOps!"
}

# -------------------------------
# 2. CALL FUNCTION
# -------------------------------
greet

echo ""
echo "===== FUNCTION WITH ARGUMENTS ====="

# -------------------------------
# 3. PASS ARGUMENTS
# -------------------------------
add() {
  num1=$1
  num2=$2
  sum=$((num1 + num2))
  echo "Sum: $sum"
}

add 5 3

echo ""
echo "===== RETURN VS ECHO ====="

# -------------------------------
# 4A. RETURN (STATUS ONLY)
# -------------------------------
check_number() {
  if [ "$1" -gt 10 ]; then
    return 0   # success
  else
    return 1   # failure
  fi
}

check_number 15
echo "Return status: $?"   # 0

check_number 5
echo "Return status: $?"   # 1

echo ""
# -------------------------------
# 4B. ECHO (ACTUAL VALUE)
# -------------------------------
multiply() {
  echo $(($1 * $2))
}

result=$(multiply 4 5)
echo "Multiply result: $result"

echo ""
echo "===== LOCAL VARIABLES ====="

# -------------------------------
# 5. LOCAL VARIABLES
# -------------------------------
test_local() {
  local msg="Inside function"
  echo "$msg"
}

test_local
echo "Outside function: ${msg:-Not accessible}"

echo ""
echo "===== FUNCTION WITH VALIDATION ====="

# -------------------------------
# 6. INPUT VALIDATION
# -------------------------------
divide() {
  if [ $# -ne 2 ]; then
    echo "Usage: divide num1 num2"
    return 1
  fi

  if [ "$2" -eq 0 ]; then
    echo "Cannot divide by zero"
    return 1
  fi

  echo $(($1 / $2))
}

divide 10 2
divide 10 0

echo ""
echo "===== PRACTICAL FUNCTION (SERVICE CHECK) ====="

# -------------------------------
# 7. REAL DEVOPS FUNCTION
# -------------------------------
check_service() {
  systemctl is-active --quiet "$1"

  if [ $? -eq 0 ]; then
    echo "$1 is running"
  else
    echo "$1 is NOT running"
  fi
}

check_service ssh

echo ""
echo "===== FUNCTION + LOOP ====="

# -------------------------------
# 8. FUNCTION WITH LOOP
# -------------------------------
print_files() {
  for file in *.sh; do
    echo "File: $file"
  done
}

print_files
