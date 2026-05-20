# Shell Scripting Basics

## Task 1: First Script
1. Create a file `hello.sh`
2. Add the shebang line `#!/bin/bash` at the top
3. Print `Hello, DevOps!` using `echo`
4. Make it executable and run it

[Hello.sh](scripts/Task%201/hello.sh)

<img width="441" height="227" alt="image" src="https://github.com/user-attachments/assets/ca2fa951-032d-4a8e-9175-5e4eb62021f1" />

---

**What happens if you remove the shebang line?**
- When the shebang (`#!/bin/bash`) is removed, the script may still execute, but the interpreter is no longer explicitly defined.
- `./hello.sh`
   - The system uses the default shell to execute the script.
   - If no shebang is present, the behavior depends on the system’s default shell configuration.
   - In some systems, it may still run using a bash-compatible shell, so output may remain the same.

- `bash hello.sh`
   - The script is explicitly executed using the Bash shell.
   - Shebang is not required in this case because Bash is directly invoked.

- `sh hello.sh`
   - The script is executed using /bin/sh (dash in Ubuntu).
   - If the script contains Bash-specific syntax, it may behave differently or fail.
   - For simple echo commands, it will still work.
 
  ---

   <img width="438" height="263" alt="image" src="https://github.com/user-attachments/assets/e33cfa6f-4eca-4a98-978a-86bbed2735a0" />

<img width="493" height="421" alt="image" src="https://github.com/user-attachments/assets/e6dfc64c-a3a9-44d4-a5b8-701d95a6fcb9" />

---

**Observation**
- Removing the shebang does not always break the script immediately.
- However, it removes the guarantee of which interpreter is used.
- This can lead to different behavior across environments (especially in CI/CD or minimal systems).

---

## Task 2: Variables
1. Create `variables.sh` with:
   - A variable for your `NAME`
   - A variable for your `ROLE` (e.g., "DevOps Engineer")
   - Print: `Hello, I am <NAME> and I am a <ROLE>`
2. Try using single quotes vs double quotes — what's the difference?
 * Using double quote `" "` - Allow **variable expansion**
 * Using single quote `' '` - Treat every character exactly as written

---

**Case 1: Double quotes**

```bash
NAME="Malathi Shetty"
ROLE="DevOps Engineer"

echo "Hello, I am $NAME and I am a $ROLE"
```

Output:

```bash
Hello, I am Malathi Shetty and I am a DevOps Engineer
``` 
👉 Variables are expanded inside double quotes.


[variables.sh](scripts/Task%202/variables.sh)

<img width="520" height="295" alt="image" src="https://github.com/user-attachments/assets/15b82de6-dfbd-47cd-b691-b99fb1c5a997" />

---


**Case 2: Single quotes in variable assignment, double quotes in echo**
```bash
NAME='Malathi Shetty'
ROLE='DevOps Engineer'

echo "Hello, I am $NAME and I am a $ROLE"
``` 
 Output:
```bash
Hello, I am Malathi Shetty and I am a DevOps Engineer
``` 
👉 No impact because variable expansion happens in echo, not in assignment.
✔ Works because variables are still expanded inside double quotes
👉 Important: quotes in assignment do NOT affect variable expansion

[variables3.sh](scripts/Task%202/variables3.sh)

<img width="517" height="255" alt="image" src="https://github.com/user-attachments/assets/43188a8c-323c-4d48-8a5d-fa5e525ecd43" />

---


**Case 3: Single quotes in echo**

```bash
NAME='Malathi Shetty'
ROLE='DevOps Engineer'

echo 'Hello, I am $NAME and I am a $ROLE'
```
Output:
```bash
Hello, I am $NAME and I am a $ROLE
``` 
👉 Variables are NOT expanded inside single quotes.
👉 Output prints literally `$NAME` and `$ROLE`

[variables2.sh](scripts/Task%202/variables2.sh)

<img width="518" height="271" alt="image" src="https://github.com/user-attachments/assets/30c4b99d-af0a-4773-aa78-9432c6e12fd2" />

---


**Case 4: (single quotes everywhere except echo double → mixed case)**

```bash
NAME="Malathi Shetty"
ROLE="DevOps Engineer"

echo 'Hello, I am $NAME and I am a $ROLE'
```

Output:

```bash
Hello, I am $NAME and I am a $ROLE
```

👉 Single quotes prevent variable expansion completely.
👉 Still prints variables as plain text
👉 because echo uses single quotes → no expansion happens


<img width="507" height="222" alt="image" src="https://github.com/user-attachments/assets/f053d055-d910-42ff-9f1f-478c657cb579" />

[variables1.sh](scripts/Task%202/variables1.sh)


| Case            | Variable Expansion? | Reason                        |
| --------------- | ------------------- | ----------------------------- |
| "double quotes" |  Yes               | variables are expanded        |
| 'single quotes' |  No                | everything is treated as text |

👉 IMPORTANT:
- Variable assignment quotes (NAME="Malathi Shetty" or NAME='Malathi Shetty') do NOT affect expansion.
- Double quotes = dynamic output
- Single quotes = static text

---

## Task 3: User Input with read
- Create greet.sh that:
- Asks the user for their name using read
- Asks for their favourite tool
- Prints: Hello <name>, your favourite tool is <tool>


[greet.sh](scripts/Task%203/greet.sh)

```bash
#!/bin/bash

read -p "Enter your name: " NAME
read -p "Enter your favourite tool: " TOOL

echo "Hello $NAME, your favourite tool is $TOOL"
```

Run:
```bash
chmod +x greet.sh
./greet.sh
```

Output:
```bash
Enter your name: Malathi
Enter your favourite tool: k8s
Hello Malathi, your favourite tool is k8s
```
<img width="546" height="333" alt="image" src="https://github.com/user-attachments/assets/a4fc3b18-5bf9-46a2-bd62-578fea2b5f8a" />

---

**Observation**
- `read` is used to take input from the user during script execution.
- `-p` allows us to show a prompt message before taking input.
- Variables store user input and are later used in `echo`.


The read command makes shell scripts interactive by allowing runtime input from users, making scripts dynamic instead of static.

---

## Task 4: If-Else Conditions
1. Create `check_number.sh` that:
   - Takes a number using `read`
   - Prints whether it is **positive**, **negative**, or **zero**
  
   
[1-check_number.sh](scripts/Task%204/1-check_number.sh)

<img width="552" height="582" alt="image" src="https://github.com/user-attachments/assets/2b92f4c0-65c4-44ba-9fd1-bb49f89defd3" />


1. Number Check Script (check_number.sh)

```bash
#!/bin/bash

read -p "Enter a number: " NUMBER

if [ $NUMBER -gt 0 ]
then
    echo "The number is positive"
elif [ $NUMBER -lt 0 ]
then
    echo "The number is negative"
else
    echo "The number is zero"
fi
```

Run:
```bash
chmod +x check_number.sh
./check_number.sh
```

Output:
```bash
Enter a number: 5
The number is positive
Enter a number: -3
The number is negative
Enter a number: 0
The number is zero

```
# Observation
- `read` takes input from user.
- `if-elif-else` is used for decision making.
- `-gt`, `-lt`, `-eq` are numeric comparison operators.

- Conditional statements allow shell scripts to make decisions based on user input.

---

2. File Check Script (file_check.sh)

      
[2-file_check.sh](scripts/Task%204/2-file_check.sh)

<img width="472" height="477" alt="image" src="https://github.com/user-attachments/assets/a15443c0-5aa3-4f5f-ac24-467e1c2a7256" />


```bash
#!/bin/bash

read -p "Enter filename: " FILE

if [ -f "$FILE" ]
then
    echo "File exists"
else
    echo "File does not exist"
fi
```

Run:

```bash
chmod +x file_check.sh
./file_check.sh
```

Output:
Case 1:
```bash
Enter filename: check_number.sh
File exists
```
Case 2:
```bash
Enter filename: test.txt
File does not exist
```
---

Observation
- `-f` checks if a file exists.
- `if [ -f filename ]` is used for file validation.
- Quotes around variables prevent errors if filename is empty or has spaces.

- If-else conditions help scripts make logical decisions, and file test operators like -f allow checking file existence before performing operations.

---


## Task 5: Combine It All
Create `server_check.sh` that:
1. Stores a service name in a variable (e.g., `nginx`, `sshd`)
2. Asks the user: "Do you want to check the status? (y/n)"
3. If `y` — runs `systemctl status <service>` and prints whether it's **active** or **not**
4. If `n` — prints "Skipped."


[server_check.sh](scripts/Task%205/server_check.sh)

<img width="762" height="662" alt="image" src="https://github.com/user-attachments/assets/1feeb24a-612a-40ac-8dbf-e3512e4c21c1" />


Script (server_check.sh)

```bash
#!/bin/bash

SERVICE="nginx"

read -p "Do you want to check the status of $SERVICE? (y/n): " CHOICE

if [ "$CHOICE" = "y" ]
then
    if systemctl list-units --type=service | grep -q "$SERVICE"
    then
        systemctl status $SERVICE | grep "Active"
    else
        echo "Service $SERVICE is not installed."
    fi
elif [ "$CHOICE" = "n" ]
then
    echo "Skipped."
else
    echo "Invalid input."
fi
```

Run:
```bash
chmod +x server_check.sh
./server_check.sh
```

Outputs
```bash
Case 1: User selects y
Do you want to check the status of nginx? (y/n): y
Active: active (running)

Case 2: User selects n
Do you want to check the status of nginx? (y/n): n
Skipped.

Case 3: Invalid input
Do you want to check the status of nginx? (y/n): abc
Invalid input. Please enter y or n.
```

Observation
- `systemctl` is used to check service status.
- `grep "Active"` filters only the status line.
- `if-elif-else` handles user decisions.
- Input validation improves script reliability.

- This script combines variables, user input, conditions, and system commands to simulate a real-world DevOps service monitoring check.

---

## What I learned -


* Learned how to write and execute basic shell scripts using the shebang (`#!/bin/bash`) to define the interpreter.
* Understood the use of variables in Bash and how to store and display dynamic values using `echo`.
* Learned how user input works using the `read` command to make scripts interactive.
* Understood conditional statements (`if`, `elif`, `else`) to perform decision-making in scripts.
* Learned file checking using -f and numeric comparisons like `-gt`, `-lt`, and `-eq`.
* Understood the difference between Bash (`bash`) and Sh (`sh`) and how shell choice affects script execution.
* Learned that system services like `nginx` must exist before using `systemctl`, otherwise scripts may fail due to missing dependencies.





  
