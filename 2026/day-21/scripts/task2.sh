#!/usr/bin/env bash

# -------------------------------
# 1. INPUT (args + read)
# -------------------------------

NAME="$1"
NUM="$2"
FILE="$3"
ACTION="$4"

# -------------------------------
# 2. VALIDATION (string checks)
# -------------------------------

if [ -z "$NAME" ]; then
    echo " Name is required"
    exit 1
fi

if [ -n "$NAME" ]; then
    echo " Name provided: $NAME"
fi

# -------------------------------
# 3. STRING COMPARISON
# -------------------------------

if [ "$NAME" = "admin" ]; then
    echo " Welcome Admin"
elif [ "$NAME" != "admin" ]; then
    echo " Normal user"
fi

# -------------------------------
# 4. INTEGER COMPARISON
# -------------------------------

if [ -z "$NUM" ]; then
    echo " Number not provided"
else
    if [ "$NUM" -gt 10 ]; then
        echo "Number is greater than 10"
    elif [ "$NUM" -eq 10 ]; then
        echo "Number is exactly 10"
    else
        echo "Number is less than 10"
    fi
fi

# -------------------------------
# 5. FILE TEST OPERATORS
# -------------------------------

if [ -z "$FILE" ]; then
    echo " No file provided"
else
    if [ -e "$FILE" ]; then
        echo "Path exists"

        [ -f "$FILE" ] && echo "It is a file"
        [ -d "$FILE" ] && echo "It is a directory"

        [ -r "$FILE" ] && echo "Readable"
        [ -w "$FILE" ] && echo "Writable"
        [ -x "$FILE" ] && echo "Executable"
        [ -s "$FILE" ] && echo "Not empty"

    else
        echo " File/Dir does not exist"
    fi
fi


read -p "Enter password: " PASS

if [ "$PASS" = "admin123" ]; then
    echo "Access granted"
else
    echo "Access denied"
fi


# -------------------------------
# 6. LOGICAL OPERATORS
# -------------------------------

echo " Logical check:"

[ "$NUM" -gt 5 ] && [ "$NUM" -lt 20 ] && echo "Number between 5 and 20"

[ -f "$FILE" ] || echo "File missing"

! [ "$NAME" = "root" ] && echo "Not root user"

if [ "$NUM" -lt 1 ] || [ "$NUM" -gt 100 ]; then
    echo "Number must be between 1-100"
fi

# -------------------------------
# 7. CASE STATEMENT
# -------------------------------

case "$ACTION" in
    start)
        echo " Starting service" ;;
    stop)
        echo " Stopping service" ;;
    restart)
        echo " Restarting service" ;;
    status)
        echo " Checking status" ;;
    logs)
    echo "Showing logs" ;;
    *)
        echo "Usage: start | stop | restart | status | logs" ;;
esac
