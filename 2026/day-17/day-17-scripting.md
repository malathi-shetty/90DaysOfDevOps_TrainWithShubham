# Day 17 – Shell Scripting: Loops, Arguments & Error Handling

---

##  Task 1: For Loop

### 1. for_loop.sh
```bash
#!/bin/bash

fruits=("apple" "banana" "orange" "mango" "grape")

for fruit in "${fruits[@]}"
do
  echo "Fruit: $fruit"
done
```

Output
```bash
Fruit: apple
Fruit: banana
Fruit: orange
Fruit: mango
Fruit: grape
```



[for_loop.sh](day-17/scripts/task1/for_loop.sh)

<img width="561" height="408" alt="image" src="https://github.com/user-attachments/assets/2d371608-3028-4716-a21b-25ecfd9cc21b" />


### 2. count.sh
```bash
#!/bin/bash

for i in {1..10}
do
  echo $i
done
```

Output
```bash
1
2
3
4
5
6
7
8
9
10
```

[count.sh](day-17/scripts/task1/count.sh)

<img width="546" height="402" alt="image" src="https://github.com/user-attachments/assets/c9992807-86f8-4297-b20a-fc69722197e1" />


---

## **Task 2: While Loop**
### 1. countdown.sh
```bash#!/bin/bash

echo "Enter a number:"
read num

while [ $num -ge 0 ]
do
  echo $num
  ((num--))
done

echo "Done!"
```
Output
```
Enter a number: 5
5
4
3
2
1
0
Done!
```

[countdown.sh](day-17/scripts/task2/countdown.sh)

<img width="575" height="587" alt="image" src="https://github.com/user-attachments/assets/6fd32172-1b78-49c8-b732-76ff8e9c3d09" />


---

## **Task 3: Command-Line Arguments**
### 1. greet.sh
```bash#!/bin/bash

if [ -z "$1" ]
then
  echo "Usage: ./greet.sh <name>"
else
  echo "Hello, $1!"
fi
```

Output
```bash./greet.sh John
Hello, John!
```

[greet.sh](day-17/scripts/task3/greet.sh)

<img width="540" height="368" alt="image" src="https://github.com/user-attachments/assets/cb96d76c-73cc-44d3-96b2-6cdb91f7c779" />

---

###  2. args_demo.sh
```bash
#!/bin/bash

echo "Script Name: $0"
echo "Total Arguments: $#"
echo "All Arguments: $@"
```

Output
```bashScript Name: ./args_demo.sh
Total Arguments: 3
All Arguments: one two three
```

[args_demo.sh](day-17/scripts/task3/args_demo.sh)

<img width="747" height="475" alt="image" src="https://github.com/user-attachments/assets/7f137d9b-e59e-4bf9-9c42-16ea4423893e" />


---

## **Task 4: Install Packages via Script**
###  1. install_packages.sh
```bash
#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root"
  exit 1
fi

# Detect package manager
if command -v apt-get >/dev/null 2>&1; then
  PKG_MANAGER="apt"
elif command -v dnf >/dev/null 2>&1; then
  PKG_MANAGER="dnf"
elif command -v yum >/dev/null 2>&1; then
  PKG_MANAGER="yum"
else
  echo "No supported package manager found"
  exit 1
fi

echo "Using package manager: $PKG_MANAGER"

packages=("nginx" "curl" "wget")

# Update once
if [ "$PKG_MANAGER" = "apt" ]; then
  apt-get update -y
elif [ "$PKG_MANAGER" = "dnf" ]; then
  dnf makecache -y
else
  yum makecache -y
fi

# Install loop
for pkg in "${packages[@]}"
do
  if [ "$PKG_MANAGER" = "apt" ]; then
    dpkg -s "$pkg" &> /dev/null && echo "$pkg already installed" || apt-get install -y "$pkg"
  else
    rpm -q "$pkg" &> /dev/null && echo "$pkg already installed" || \
    [ "$PKG_MANAGER" = "dnf" ] && dnf install -y "$pkg" || yum install -y "$pkg"
  fi
done
```
Output (example)
```bash
Using package manager: apt
nginx already installed
Installing curl...
Installing wget...
```

[install_packages.sh](day-17/scripts/task4/install_packages.sh)

<img width="977" height="1237" alt="image" src="https://github.com/user-attachments/assets/bcda6ebe-57e9-4717-997d-3aad1eade80f" />


---

## **Task 5: Error Handling**
### 1. safe_script.sh
```bash
#!/bin/bash

set -e

mkdir /tmp/devops-test || echo "Directory already exists"
cd /tmp/devops-test || { echo "Failed to enter directory"; exit 1; }
touch test.txt || { echo "Failed to create file"; exit 1; }

echo "Script executed successfully ✔"
```
Output
```bash
Script executed successfully ✔

(Second run)

Directory already exists
Script executed successfully ✔
```

[safe_script.sh](day-17/scripts/task5/safe_script.sh)

<img width="637" height="723" alt="image" src="https://github.com/user-attachments/assets/fb082ebc-32cf-43a0-8fbc-2154c5eeafcb" />


### 2. Modify install_packages.sh (Root Check Only)
   ```bash
   #!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Not root. Try: sudo ./script.sh""
  exit 1
fi

echo "Running as root ✔"
```

[install_packages.sh](day-17/scripts/task5/install_packages.sh)

<img width="621" height="533" alt="image" src="https://github.com/user-attachments/assets/837c48db-5cb9-4a8e-88f7-55c32f87259b" />


---

**What I Learned**
- Used for loops to iterate over lists and number ranges
- Used while loops for countdown logic with user input
- Handled command-line arguments using $1, $#, $@, $0
- Took user input using read
- Automated package installation using scripts
- Detected OS package managers (apt, dnf, yum)
- Implemented root user validation using $EUID
- Used set -e for fail-fast error handling
- Used || to handle command failures gracefully

**Issue Faced & Fix**
- Used commas in Bash arrays → caused script failure
- Fixed by using space-separated values in arrays

**Summary**

This day focused on:
- Automating repetitive tasks using loops
- Making scripts dynamic using arguments
- Writing safer scripts with proper error handling
