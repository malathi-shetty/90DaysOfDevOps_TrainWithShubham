# Task 8: Bonus — Quick Reference Table
---
Create a summary table like this at the top of your cheat sheet:

## Reference Table:

🔹 Basics

| Topic           | Key Syntax            | Example                      |
| --------------- | --------------------- | ---------------------------- |
| Shebang         | `#!/usr/bin/env bash` | Start script                 |
| Make Executable | `chmod +x file.sh`    | `chmod +x script.sh`         |
| Run Script      | `./file.sh`           | `./script.sh`                |
| Run (Alt)       | `bash file.sh`        | `bash script.sh`             |
| Comment         | `# comment`           | `echo "Hi" # inline comment` |





🔹 Variables & Input

| Topic        | Key Syntax    | Example         |
| ------------ | ------------- | --------------- |
| Variable     | `VAR="value"` | `NAME="DevOps"` |
| Use Variable | `"$VAR"`      | `echo "$NAME"`  |
| Read Input   | `read VAR`    | `read USER`     |




🔹 Arguments & Exit Status

| Topic           | Key Syntax | Example                 |
| --------------- | ---------- | ----------------------- |
| Positional Args | `$1 $2`    | `./script.sh arg1 arg2` |
| Arg Count       | `$#`       | `echo $#`               |
| All Args        | `$@`       | `echo "$@"`             |
| All Args (Alt)  | `$*`       | `echo "$*"`             |
| Script Name     | `$0`       | `echo "$0"`             |
| Exit Status     | `$?`       | `echo $?`               |




🔹 Conditionals

| Topic            | Key Syntax                 | Example                            |       
| ---------------- | -------------------------- | ---------------------------------- | 
| String Equal     | `[ "$a" = "$b" ]`          | `[ "$name" = "Linux" ]`            |      
| String Not Equal | `[ "$a" != "$b" ]`         | `[ "$name" != "Ubuntu" ]`          |      
| Empty Check      | `[ -z "$var" ]`            | `[ -z "$name" ]`                   |      
| Not Empty        | `[ -n "$var" ]`            | `[ -n "$name" ]`                   |       
| Integer Compare  | `[ "$a" -gt 10 ]`          | `[ "$num" -eq 5 ]`                 |     
| File Exists      | `[ -e file ]`              | `[ -e file.txt ]`                  |     
| File Check       | `[ -f file ]`              | Regular file                       |     
| Directory Check  | `[ -d dir ]`               | `[ -d /home ]`                     |      
| If Condition     | `if [ cond ]; then ... fi` | `if [ -f file ]; then echo OK; fi` |       
| Case Statement   | `case var in ... esac`     | *(see below)*                      |      
| AND              | `cmd1 && cmd2`             | `mkdir test && cd test`            |  
| OR               | `cmd1 || cmd2`             | `cd dir || pwd`                    |
| NOT              | `! condition`              | `! [ -f file ]`                    |     
    
**Note:** OR --> cmd1 || cmd2 -->  cd dir || pwd


🔹 Loops
| Topic      | Syntax                        | Example                                    |
| ---------- | ----------------------------- | ------------------------------------------ |
| For Loop   | `for i in list; do ... done`  | `for i in 1 2 3; do echo "$i"; done`       |
| For Files  | `for f in *`                  | `for f in *; do echo "$f"; done`           |
| C-Style    | `for ((i=1;i<=3;i++))`        | `for ((i=1;i<=3;i++)); do touch f$i; done` |
| While Loop | `while [ cond ]; do ... done` | `while [ "$a" -lt 5 ]; do echo "$a"; done` |
| Until Loop | `until [ cond ]; do ... done` | wait until success                         |
| Break      | `break`                       | exit loop                                  |
| Continue   | `continue`                    | skip iteration                             |


🔹 Functions

| Topic             | Key Syntax         | Example                     |
| ----------------- | ------------------ | --------------------------- |
| Function          | `name() { ... }`   | `greet(){ echo "Hi"; }`     |
| Function Args     | `$1 $2`            | `add(){ echo $(($1+$2)); }` |
| Return (Function) | `return <0–255>`   | `return 0`                  |
| Exit (Script)     | `exit <0–255>`     | `exit 1`                    |
| Capture Output    | `result="$(func)"` | `val="$(date)"`             |
| Local Variable    | `local var=value`  | `local count=10`            |


🔹  Text Processing
| Tool | Key Syntax               | Example                            |
| ---- | ------------------------ | ---------------------------------- |
| grep | `grep pattern file`      | `grep -i "error" log.txt`          |
| awk  | `awk '{print $1}' file`  | `awk -F: '{print $1}' /etc/passwd` |
| sed  | `sed 's/old/new/g' file` | `sed -i 's/foo/bar/g' file.txt`    |
| cut  | `cut -d: -f1 file`       | `cut -d: -f1 /etc/passwd`          |
| sort | `sort file`              | `sort -n numbers.txt`              |
| uniq | `sort file \| uniq`      | `sort file \| uniq -c`             |
| tr   | `tr 'a-z' 'A-Z'`         | `echo hi \| tr 'a-z' 'A-Z'`        |
| wc   | `wc -l file`             | `wc -w file.txt`                   |
| head | `head -n 5 file`         | `head -n 10 log.txt`               |
| tail | `tail -f file`           | `tail -f app.log`                  |


🔹 Extras

| Topic                | Syntax            | Example               |
| -------------------- | ----------------- | --------------------- |
| Command Substitution | `$(command)`      | `now=$(date)`         |
| Old Substitution     | `` `command` ``   | `` `date` ``          |
| Safer Test           | `[[ condition ]]` | `[[ "$a" == "$b" ]]`  |
| Arithmetic           | `$((expression))` | `echo $((5+3))`       |
| Redirect Output      | `>`               | `echo hi > file.txt`  |
| Append Output        | `>>`              | `echo hi >> file.txt` |
| Error Redirect       | `2>`              | `cmd 2> error.log`    |
| All Output           | `&>`              | `cmd &> all.log`      |
| Pipe                 | `\|`              | `ls \| grep txt`      |
| Quote Variables      | `"$var"`          | `echo "$name"`        |



# Task 1: Basics (With What + Why + Example)

## 1. Shebang
```bash
#!/bin/bash
# OR (better portable)
#!/usr/bin/env bash
```

**What it does:**
Tells the system which interpreter (shell) should run the script.

**Why it matters:**
Without it, the script may run in the wrong shell → causing syntax errors.

**Example:**
```bash
#!/bin/bash
echo "Running with Bash"
```

## 2. Running a Script
```bash
chmod +x script.sh
./script.sh
bash script.sh
```

**What it does:**

- chmod +x → makes script executable
- ./script.sh → runs using shebang
- bash script.sh → forces Bash execution

**Why it matters:**

- Prevents “Permission denied” errors
- Ensures correct shell is used

Example:
```bash
chmod +x hello.sh
./hello.sh
```

## 3. Comments**
```bash
# This is a comment
echo "Hello"  # inline comment
```

**What it does:**
Adds human-readable notes in scripts (ignored by shell).

**Why it matters:**
Improves readability, debugging, and team collaboration.

Example:
```bash
# Print greeting
echo "Hello DevOps"  # prints message
```

## 4. Variables**
**Declare**
NAME="Malathi"

**What it does:**
Stores data in a variable.

**Why it matters:**
Avoids repetition and makes scripts dynamic.

**Use**
```bash
echo $NAME
```

**What it does:**
Retrieves variable value.

**Why it matters:**
Used in logic, output, file names, etc.

## Quoting
```bash
"$VAR"
'$VAR'
```

**What it does:**

- " " → expands variable
- ' ' → treats as literal text

**Why it matters:**
Prevents bugs with spaces, empty values, and special characters.

**Example:**
```bash
FILE="my file.txt"

[ -f "$FILE" ]   #  safe
[ -f $FILE ]     #  breaks
```

## 5. Reading User Input (read)
```bash
read NAME
read -p "Enter name: " NAME
```

**What it does:**
Takes input from user and stores in variable.

**Why it matters:**
Makes scripts interactive.

**Example:**
```bash
read -p "Enter your name: " NAME
echo "Hello $NAME"
```

## 6. Command-Line Arguments

```bash
$0 $1 $2 $# $@ $?
```

🔹 Meaning
```bash
$0   # script name
$1   # first argument
$2   # second argument
$#   # number of arguments
$@   # all arguments (safe)
$?   # last command exit status
```

🔹 **What it does:**

Allows passing input directly when running the script.

🔹 **Why it matters:**

Used for automation, reusable scripts, and DevOps tools.

🔹 **Example:**
```bash
#!/bin/bash

echo "Script: $0"
echo "First arg: $1"
echo "Total args: $#"
echo "All args: $@"
```

Run:
```bash
./script.sh devops linux
```

## Exit Status ($?)
```bash
ls /wrong-path
echo $?
```
**What it does:**
Stores result of last command.

**Why it matters:**
Used for decision-making and error handling.

| Value | Meaning |
| ----- | ------- |
| 0     | success |
| ≠0    | failure |

## $@ vs $* 
```bash
"$@"   #  preserves arguments separately
"$*"   #  merges into one string
```

**Why it matters:**
Prevents argument handling bugs in real scripts.

---

# Task 2 (Operators & Conditionals)

## String Comparisons
```bash
[ "$a" = "$b" ]    # equal
[ "$a" != "$b" ]   # not equal
[ -z "$a" ]        # empty string
[ -n "$a" ]        # not empty
```

**What**: compares string values
**Why:** used for input validation, flags, decisions

**Example**
```bash
name="linux"

[ "$name" = "linux" ] && echo "Match"
[ -z "$name" ] && echo "Empty"
```

## Integer Comparisons
```bash
[ $a -eq $b ]   # equal
[ $a -ne $b ]   # not equal
[ $a -lt $b ]   # less than
[ $a -gt $b ]   # greater than
[ $a -le $b ]   # less or equal
[ $a -ge $b ]   # greater or equal
```

**What:** compares numeric values
 **Why:** used in loops, limits, thresholds

Example

```bash
num=10


[ $num -gt 5 ] && echo "Greater than 5"
```

## File Test Operators
```bash
[ -f file ]   # file exists
[ -d dir ]    # directory exists
[ -e path ]   # exists (file/dir)
[ -r file ]   # readable
[ -w file ]   # writable
[ -x file ]   # executable
[ -s file ]   # not empty
```
**What:** checks file properties
 **Why:** prevents script failures (missing files, permissions)

**Example**
```bash
FILE="test.txt"

if [ -f "$FILE" ]; then
    echo "File exists"
fi
```

## if / elif / else
```bash
if [ condition ]; then
    command
elif [ condition ]; then
    command
else
    command
fi
```
**What:** conditional branching
**Why:** core decision-making in scripts

**Example**
```bash
FILE="data.txt"

if [ -f "$FILE" ]; then
    echo "File exists"
elif [ -d "$FILE" ]; then
    echo "Directory"
else
    echo "Not found"
fi
```

## Logical Operators

```bash
cmd1 && cmd2   # run cmd2 if cmd1 succeeds
cmd1 || cmd2   # run cmd2 if cmd1 fails
! command      # NOT (reverse result)
```
**What:** combine conditions/commands
**Why:** short, powerful control flow

**Example**
```bash
mkdir test && cd test

cd wrong_dir || echo "Failed"

! ls missing.txt
```

**With Conditions**
```bash
[ -f "file.txt" ] && echo "Exists"
[ -f "file.txt" ] || echo "Missing"
```

## Case Statement
```bash
case $var in
  pattern1)
    command ;;
  pattern2)
    command ;;
  *)
    default ;;
esac
```
**What:** multi-condition branching
**Why:** cleaner than multiple if/elif

**Example**
```bash
action="$1"

case $action in
  start)
    echo "Starting service" ;;
  stop)
    echo "Stopping service" ;;
  restart)
    echo "Restarting service" ;;
  *)
    echo "Usage: start|stop|restart" ;;
esac
```


---

# Task 3: Loops
## 1. For Loop (List-Based)
```bash
for item in list
do
  command
done
```

**What it does:**
Loops through each item in a predefined list.

**Why it matters:**
Used when values are already known (files, users, fixed inputs).

**Example:**
```bash
for i in 1 2 3
do
  echo $i
done
```
## 2. For Loop (C-Style)
```bash
for ((i=1; i<=5; i++))
do
  command
done
```
**What it does:**
Uses a counter-based loop (similar to C/Java).

**Why it matters:**
Best for numeric iterations and controlled loops.

**Example:**
```bash
for ((i=1; i<=3; i++))
do
  echo "Count: $i"
done
```

## 3. While Loop

```bash
while [ condition ]
do
  command
done
```

**What it does:**
Executes commands while condition is true.

**Why it matters:**
Useful when loop depends on runtime conditions.

**Example:**
```bash
num=3
while [ $num -gt 0 ]
do
  echo $num
  ((num--))
done
```

## 4. Until Loop
```bash
until [ condition ]
do
  command
done
```

**What it does:**
Runs until condition becomes true.

**Why it matters:**
Used when waiting for success conditions.

**Example:**
```bash
count=1
until [ $count -gt 3 ]
do
  echo $count
  ((count++))
done
```

## 5. Break
```bashbreak
```
**What it does:**
Exits the loop immediately.

**Why it matters:**
Stops unnecessary iterations.

**Example:**
```bash
for i in 1 2 3 4
do
  if [ $i -eq 3 ]; then
    break
  fi
  echo $i
done
```

## 6. Continue
```bash
continue
```

**What it does:**
Skips current iteration.

**Why it matters:**
Ignores unwanted values.

**Example:**
```bash
for i in 1 2 3
do
  if [ $i -eq 2 ]; then
    continue
  fi
  echo $i
done
```

## 7. Looping Over Files
```bash
for file in *.log
do
  echo "$file"
done
```

**What it does:**
Iterates over matching files.

**Why it matters:**
Common in log processing and automation.

## 8. Looping Over Command Output
```bash
ls *.txt | while read line
do
  echo "$line"
done
```

**What it does:**
Processes command output line-by-line.

**Why it matters:**
Used for dynamic data handling.

---

# Task 4: Functions
## 1. Defining a Function
```bash
function_name() {
  commands
}
```

**What it does:**
Groups reusable commands.

**Why it matters:**
Improves readability and avoids repetition.

**Example:**
```bash
greet() {
  echo "Hello!"
}
```
## 2. Calling a Function
```bash
function_name
```

**What it does:**
Executes the function.

**Why it matters:**
Runs reusable logic anytime.

**Example:**
```bash
greet
```

## 3. Passing Arguments
```bash
function_name() {
  echo "$1"
  echo "$2"
}
```
**What it does:**
Accepts input parameters.

**Why it matters:**
Makes functions flexible.

**Example:**
```bash
add() {
  echo $(($1 + $2))
}

add 2 3
```
## 4. Return Values
```bash
return (status code)
return 0
```
**What it does:**
Returns exit status (0–255).

**Why it matters:**
Used for success/failure checks.

**Example:**
```bash
check() {
  return 1
}

check
echo $?
echo (actual value)
result=$(function_name)
```
**What it does:**
Returns actual output.

**Why it matters:**
Used to capture values.

**Example:**
```bash
get_sum() {
  echo $(($1 + $2))
}

result=$(get_sum 2 3)
echo $result
```
## 5. Local Variables
```bash
local var=value
```
**What it does:**
Limits variable scope.

**Why it matters:**
Prevents conflicts.

**Example:**
```bash
test_func() {
  local x=10
  echo $x
}

test_func
echo $x
```

# Task 5: Text Processing Commands
## 1. grep
```bashgrep [options] "pattern" file
```
**What it does:**
Searches for text patterns.

**Why it matters:**
Essential for logs and debugging.

**Examples:**
```bash
grep -i "error" file
grep -r "TODO" .
grep -c "fail" file
grep -n "ssh" file
grep -v "info" file
grep -E "error|fail" file
```

## 2. awk
```bash
awk 'pattern { action }' file
```
**What it does:**
Processes structured text.

**Why it matters:**
Used for logs and column extraction.

**Examples:**
```bash
awk '{print $1}' file
awk -F: '{print $1}' /etc/passwd
awk '/error/ {print $0}' file
```

## 3. sed
```bash
sed 's/old/new/' file
```
**What it does:**
Edits text streams.

**Why it matters:**
Used in automation and config updates.

Examples:
```bash
sed 's/error/ERROR/' file
sed '2d' file
sed -i 's/foo/bar/g' file
4. cut
cut -d ":" -f1 file
```
**What it does:**
Extracts columns.

**Why it matters:**
Quick data parsing.

## 5. sort / uniq
```bash
sort file
sort -n file
sort file | uniq
sort file | uniq -c
```
**What it does:**
Sorts and removes duplicates.

**Why it matters:**
Used for analysis and reports.

## 6. tr
```bash
 tr 'a-z' 'A-Z'
```
**What it does:**
Transforms characters.

**Why it matters:**
Quick text formatting.

## 7. wc
```bash
 wc -l file
```
**What it does:**
Counts lines, words, chars.

**Why it matters:**
Gives file metrics.

## 8. head / tail
```bash
head -n 5 file
tail -f file
```
**What it does:**
Shows file parts / live logs.

**Why it matters:**
Used in monitoring.

---

# Task 6: Useful One-Liners
## Find old files
```bash
find /var/log -type f -name "*.log" -mtime +15 -delete
```
**What it does:**
Deletes old log files.

**Why it matters:**
Prevents disk overflow.

## Count log lines
```bash
wc -l /var/log/*.log
```
**What it does:**
Counts lines.

**Why it matters:**
Quick log size check.

## Replace text
```bash sed -i 's/old/new/g' *.conf
```
**What it does:**
Replaces text in files.

**Why it matters:**
Bulk config updates.

## Check service
```bash
systemctl is-active nginx && echo "Running" || echo "Stopped"
```
**What it does:**
Checks service status.

**Why it matters:**
Automation scripts.

## Disk usage alert
```bash
df -h | awk '$5+0 > 80 {print}'
```
**What it does:**
Shows high usage disks.

**Why it matters:**
Prevents outages.

## Live error logs
```bash
tail -f /var/log/syslog | grep -E "ERROR|CRITICAL"
```
**What it does:**
Filters logs in real-time.

**Why it matters:**
Production debugging.

---

# Task 7: Error Handling & Debugging
## 1. Exit Codes
```bash
echo $?
exit 0
exit 1
```
**What it does:**
Represents command result.

**Why it matters:**
Used for logic and decisions.

## 2. set -e
```bash
set -e
```
**What it does:**
Stops script on error.

**Why it matters:**
Prevents silent failures.

## 3. set -u
```bash set -u
```
**What it does:**
Errors on undefined variables.

**Why it matters:**
Avoids bugs.

## 4. pipefail
```bash
set -o pipefail
```
**What it does:**
Fails if any pipeline command fails.

**Why it matters:**
Ensures reliability.

## 5. Debug mode
```bash
set -x
```
**What it does:**
Prints commands before execution.

**Why it matters:**
Helps debugging.

## 6. trap
```bash
trap 'cleanup' EXIT
```
**What it does:****
R**uns cleanup on exit.

****Why it matters:****
Ensures safe script termination.

**Example:**
```bash
cleanup() {
  echo "Cleaning..."
}

trap cleanup EXIT
```
