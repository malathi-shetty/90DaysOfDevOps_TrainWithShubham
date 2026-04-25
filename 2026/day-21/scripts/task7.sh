#!/usr/bin/env bash

echo "===== TASK 7: ERROR HANDLING & DEBUGGING ====="

# -------------------------------
# 1. STRICT MODE
# -------------------------------
echo ""
echo " Enabling strict mode..."
set -euo pipefail

# -------------------------------
# 2. TRAP (CLEANUP)
# -------------------------------
cleanup() {
  echo " Cleaning up before exit..."
}
trap cleanup EXIT

# -------------------------------
# 3. EXIT CODES
# -------------------------------
echo ""
echo " Exit code demo:"

ls test.txt 2>/dev/null || true
echo "Exit code of ls: $?"

# -------------------------------
# 4. SET -U (UNDEFINED VARIABLE)
# -------------------------------
echo ""
echo " set -u demo:"

VAR="hello"
echo "Defined VAR: $VAR"

# Uncomment to test crash:
# echo "$UNDEFINED_VAR"

# Safe access:
echo "Safe access: ${UNDEFINED_VAR:-default_value}"

# -------------------------------
# 5. SET -E (EXIT ON ERROR)
# -------------------------------
echo ""
echo " set -e demo:"

echo "Trying a failing command..."
# this would stop script if not handled
ls wrongfile 2>/dev/null || echo "Handled error, script continues"

# -------------------------------
# 6. PIPEFAIL DEMO
# -------------------------------
echo ""
echo " pipefail demo:"

if false | true; then
  echo "Pipeline succeeded"
else
  echo "Pipeline failed (caught by pipefail)"
fi

# -------------------------------
# 7. DEBUG MODE
# -------------------------------
echo ""
echo " Debug mode (set -x):"

set -x
echo "Debugging this line"
date
set +x

# -------------------------------
# 8. REAL ERROR HANDLING
# -------------------------------
echo ""
echo " Real-world example:"

FILE="sample.txt"

if [ ! -f "$FILE" ]; then
  echo " ERROR: File does not exist" >&2
  exit 1
fi

cat "$FILE"

echo ""
echo " Script completed successfully"
