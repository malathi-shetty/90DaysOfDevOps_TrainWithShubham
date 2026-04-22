# Day 18 – Shell Scripting: Functions & Slightly Advanced Concepts

## Task 1: Basic Functions
1. Create `functions.sh` with:
   - A function `greet` that takes a name as argument and prints `Hello, <name>!`
   - A function `add` that takes two numbers and prints their sum
   - Call both functions from the script
   
   [functions.sh](Scripts/task1/functions.sh)

   

   
 <img width="518" height="463" alt="image" src="https://github.com/user-attachments/assets/39099bf2-4048-4109-a924-e39490effb44" />


---

## Task 2: Functions with Return Values
1. Create `disk_check.sh` with:
   - A function `check_disk` that checks disk usage of `/` using `df -h`
   - A function `check_memory` that checks free memory using `free -h`
   - A main section that calls both and prints the results
   
   [disk_check.sh](Scripts/task2/disk_check.sh)
   
   
  <img width="740" height="512" alt="image" src="https://github.com/user-attachments/assets/96d9ee65-de62-46d7-ab27-47acd8a94d16" />


---

## Task 3: Strict Mode — `set -euo pipefail`
1. Create `strict_demo.sh` with `set -euo pipefail` at the top
2. Try using an **undefined variable** — what happens with `set -u`?
3. Try a command that **fails** — what happens with `set -e`?
4. Try a **piped command** where one part fails — what happens with `set -o pipefail`?

**Document:** What does each flag do?
- `set -e` → Exit if any command fails
- `set -u` → Error on undefined variables
- `set -o` pipefail → Pipeline fails if any command fails

   [set-e.sh](Scripts/task3/set-e.sh)

  <img width="526" height="138" alt="image" src="https://github.com/user-attachments/assets/0be1b0e9-5a33-43b1-bcbb-886ffc94b9cc" />


 [set-u.sh](Scripts/task3/set-u.sh)

 <img width="533" height="141" alt="image" src="https://github.com/user-attachments/assets/f03b5c7b-f15b-4e3a-8a0c-5606c03539cc" />


 [pipefail.sh](Scripts/task3/pipefail.sh)
   
<img width="527" height="140" alt="image" src="https://github.com/user-attachments/assets/8afaaaaa-2bed-44ff-8087-1836a29091a1" />

   
---

## Task 4: Local Variables
1. Create `local_demo.sh` with:
   - A function that uses `local` keyword for variables
   - Show that `local` variables don't leak outside the function
   - Compare with a function that uses regular variables
   
   [local_demo.sh](Scripts/task4/local_demo.sh)

   
  <img width="512" height="522" alt="image" src="https://github.com/user-attachments/assets/0b047b76-364a-4b6f-b144-de98f85d6f4d" />


---

## Task 5: Build a Script — System Info Reporter
Create `system_info.sh` that uses functions for everything:
1. A function to print **hostname and OS info**
2. A function to print **uptime**
3. A function to print **disk usage** (top 5 by size)
4. A function to print **memory usage**
5. A function to print **top 5 CPU-consuming processes**
6. A `main` function that calls all of the above with section headers
7. Use `set -euo pipefail` at the top

   [system_info.sh](Scripts/task5/system_info.sh)

<img width="612" height="752" alt="image" src="https://github.com/user-attachments/assets/53769923-8779-467c-9a8d-a9d47941e3be" />


---

## What I Learned

* Functions make scripts modular and reusable
* set -euo pipefail prevents silent failures
* Local variables avoid unintended side effects

  -------

#90DaysOfDevOps #DevOpsKaJosh #TrainWithShubham
