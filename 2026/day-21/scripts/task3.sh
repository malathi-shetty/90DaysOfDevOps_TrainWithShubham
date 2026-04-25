#!/usr/bin/env bash

echo "===== FOR LOOP (List) ====="
for i in 1 2 3
do
  echo "Value: $i"
done

echo ""
echo "===== FOR LOOP (C-Style) ====="
for ((i=1; i<=3; i++))
do
  echo "Counter: $i"
done

echo ""
echo "===== WHILE LOOP ====="
num=3
while [ $num -gt 0 ]
do
  echo "num: $num"
  ((num--))
done

echo ""
echo "===== UNTIL LOOP ====="
count=1
until [ $count -gt 3 ]
do
  echo "count: $count"
  ((count++))
done

echo ""
echo "===== BREAK EXAMPLE ====="
for i in 1 2 3 4
do
  if [ $i -eq 3 ]; then
    echo "Breaking at $i"
    break
  fi
  echo $i
done

echo ""
echo "===== CONTINUE EXAMPLE ====="
for i in 1 2 3
do
  if [ $i -eq 2 ]; then
    echo "Skipping $i"
    continue
  fi
  echo $i
done

echo ""
echo "===== LOOP OVER FILES ====="
for file in *.sh
do
  echo "Script file: $file"
done

echo ""
echo "===== LOOP OVER COMMAND OUTPUT ====="
ls *.sh | while read line
do
  echo "Found file: $line"
done
