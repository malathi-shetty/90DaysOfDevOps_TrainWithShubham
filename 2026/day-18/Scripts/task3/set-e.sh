#!/bin/bash
set -e

echo "Before failure"
false
echo "After failure"   # Won’t run
