### Task 1: Self-Assessment Checklist
- **Can do confidently**
- **Need to revisit**
- **Haven't done yet**

#### Linux
- [**Can do confidently**] Navigate the file system, create/move/delete files and directories
- [**Can do confidently** ] Manage processes — list, kill, background/foreground
- [ **Can do confidently**] Work with systemd — start, stop, enable, check status of services
- [**Can do confidently** ] Read and edit text files using vi/vim or nano
- [ **Can do confidently**] Troubleshoot CPU, memory, and disk issues using top, free, df, du
- [ **Need to revisit**] Explain the Linux file system hierarchy (/, /etc, /var, /home, /tmp, etc.)
- [**Can do confidently** ] Create users and groups, manage passwords
- [ **Can do confidently**] Set file permissions using chmod (numeric and symbolic)
- [ **Can do confidently**] Change file ownership with chown and chgrp
- [ **Need to revisit**] Create and manage LVM volumes
- [ **Can do confidently**] Check network connectivity — ping, curl, netstat, ss, dig, nslookup
- [**Need to revisit** ] Explain DNS resolution, IP addressing, subnets, and common ports

#### Shell Scripting
- [**Need to revisit** ] Write a script with variables, arguments, and user input
- [ **Need to revisit** ] Use if/elif/else and case statements
- [**Need to revisit** ] Write for, while, and until loops
- [**Need to revisit** ] Define and call functions with arguments and return values
- [**Need to revisit** ] Use grep, awk, sed, sort, uniq for text processing
- [**Need to revisit** ] Handle errors with set -e, set -u, set -o pipefail, trap
- [**Can do confidently**] Schedule scripts with crontab

#### Git & GitHub
- [**Can do confidently** ] Initialize a repo, stage, commit, and view history
- [ **Can do confidently**] Create and switch branches
- [ **Can do confidently**] Push to and pull from GitHub
- [ **Can do confidently**] Explain clone vs fork
- [**Need to revisit** ] Merge branches — understand fast-forward vs merge commit
- [ **Need to revisit**] Rebase a branch and explain when to use it vs merge
- [ **Need to revisit**] Use git stash and git stash pop
- [ **Can do confidently**] Cherry-pick a commit from another branch
- [ **Need to revisit**] Explain squash merge vs regular merge
- [**Need to revisit**] Use git reset (soft, mixed, hard) and git revert
- [ **Need to revisit**] Explain GitFlow, GitHub Flow, and Trunk-Based Development
- [ **Can do confidently**] Use GitHub CLI to create repos, PRs, and issues

---

### Task 2: Revisit Weak Spots

### Weak Spot: Shell Scripting, LVM (Linux), Git & GitHub

## Weak Spot 1: Shell Scripting

**What I Re-did:**

- Wrote a script using variables and arguments
- Practiced if/elif/else
- Created loops (for, while)
- Used grep and awk for filtering

**What I Re-learned:**

- $1, $2 are used to pass arguments into scripts
- if [ condition ] must have spaces (common mistake)
- for loop is used for fixed iterations, while for conditions
- Combining commands like grep | awk is powerful for filtering logs

**What I Still Struggle With:**

- Writing scripts without syntax errors
- Remembering loop structure quickly

**Action Plan:**

- Write 1 small script daily (5–10 lines)
- Practice without looking at notes

## Weak Spot 2: LVM (Linux)

**What I Re-did:**

- Created physical volume using pvcreate
- Created volume group using vgcreate
- Created logical volume using lvcreate
- Formatted and mounted it

**What I Re-learned:**

- LVM flow: PV → VG → LV → Mount
- Storage can be resized without downtime
- Need filesystem (mkfs) before mounting

**What I Still Struggle With:**

- Remembering command sequence without notes

**Action Plan:**

- Practice full LVM setup again from scratch
- Write steps in cheat sheet

 ##  Weak Spot 3: Git (Merge vs Rebase)

**What I Re-did:**

- Created branches and commits
- Used git merge
- Used git rebase
- Checked history using git log --oneline --graph

**What I Re-learned:**

- Merge keeps history, rebase rewrites history
- Rebase creates cleaner linear history
- Merge is safer for shared branches

**What I Still Struggle With:**

- When to use rebase in real projects

**Action Plan:**

- Practice both on dummy repo
- Visualize commit history after each action

---

### Task 3: Quick-Fire Questions
Answer these from memory (no Googling). Then verify your answers:

1. What does `chmod 755 script.sh` do?
- Owner → read, write, execute (7)
- Group → read, execute (5)
- Others → read, execute (5)

Makes the script executable for everyone, editable only by owner

2. What is the difference between a process and a service?
- Process = any running program (e.g., python, nginx)
- Service = long-running background process managed by system (e.g., nginx via systemd)

All services are processes, but not all processes are services

3. How do you find which process is using port 8080?
```bash
- ss -tulnp | grep 8080
OR
lsof -i :8080
```
This shows the exact process using the port

4. What does `set -euo pipefail` do in a shell script?
- `-e` → makes a script `exit` immediately if any command fails,
- -`u` → `error` if an undefined variable is used,
- `-o pipefail` → `fail` if any command in a pipeline fails.
Makes scripts safer

5. What is the difference between `git reset --hard` and `git revert`?
- `git reset --hard`→ removes commit from history + deletes changes (dangerous)
- `git revert`: creates a new commit to undo changes (safe),keeps original commit in history

6. What branching strategy would you recommend for a team of 5 developers shipping weekly?
- GitHub Flow or Trunk-Based Development
- Trunk-Based Development becasue it keeps things simple ,reduces merge conflicts and supports frequent releases. 

Reason:
- Simple
- Fast releases
- Less conflicts

7. What does `git stash` do and when would you use it?
- git stash → saves uncommitted work temporarily,  so you can use when switching branches without committing

Use when:
- Work is incomplete
- Need to switch context quickly

8. How do you schedule a script to run every day at 3 AM?
- using crontab 0 3 * * * /path/to/script.sh
- Runs daily at 3:00 AM

9. What is the difference between `git fetch` and `git pull`?
- `git fetch` → downloads changes only without merging,
- while `git pull` → fetch + merge

10. What is LVM and why would you use it instead of regular partitions?
- LVM (Logical Volume Manager) is a way 
  - Allows flexible disk management
  - Can resize storage without downtime
  - Combines multiple disks into one
- Regular partitions are fixed in size and hard to change while LVM lets you easily resize or combine disk space whenever you need.

---

### Task 4: Organize Your Work
1. [✅] Make sure all your daily submissions (day-1 through day-27) are committed and pushed 
2. [✅] Check that your `git-commands.md` is up to date
3. [✅] Check that your shell scripting cheat sheet is complete 
4. [✅] Verify your GitHub profile and repos are clean (from Day 27) 

---

### Task 5: Teach It Back

## 1. Git Branching (Simple Analogy)

Think of Git like a Google Doc
- The main version = main branch
- Now imagine:
  You want to try something new without breaking the original

- So you make a copy of the doc

That copy = branch

Example:
- Main doc → working website
- You create a branch → “new-feature”
- You make changes there

If it works:
  - You merge it back into main

If it fails:
  - You just delete the branch (main is safe)

Simple line:

Branching = working on a copy so you don’t break the original

---

## 2. Explain file permissions to a new Linux user

Think of a house

There are 3 types of people:

1. Owner (you)
2. Group (your family)
3. Others (strangers)

Permissions:
- Read (r) → can look inside the house 
- Write (w) → can move/change things 
- Execute (x) → can actually live/use it 

Understanding chmod 755

In Linux, file permissions are controlled using numbers.

Each number represents permissions for:

- Owner
- Group
- Others

**What does 755 mean?**

It is split like this:
```bash
7       5    5
|       |    |
Owner Group Others
```
**How numbers work:**

Each number is a combination of:

- 4 → Read (r)
- 2 → Write (w)
- 1 → Execute (x)

**Breakdown:**
- 7 = 4 + 2 + 1 → Read + Write + Execute (rwx)
- 5 = 4 + 1 → Read + Execute (r-x)
- 5 = 4 + 1 → Read + Execute (r-x)

So, chmod 755 script.sh means:
- Owner → can read, write, execute
- Group → can read and execute
- Others → can read and execute

Note:
- This works for files and directories
- For scripts → allows everyone to run the script
- Only the owner can modify it

- 755 gives full access to the owner and read/execute access to everyone else.

**Example:**

`chmod 755 file`

- You (owner) → full access
- Others → can only see and use, not change

**Simple line:**

File permissions = who can see, change, or use something

---

## 3. Explain what a crontab is and why sysadmins use it

Think of an alarm clock or daily routine

You tell it:

`Wake me up at 3 AM every day`

You don’t manually do it — it happens automatically.

 In Linux:
`Crontab = a scheduler`

You tell the system:

- Run a backup script every day at 3 AM
- Clean logs every week

Example:
```bash
0 3 * * * backup.sh
```

Means: run at 3:00 AM daily
```bash
┌──────── Minute (0 - 59)
│ ┌────── Hour (0 - 23)
│ │ ┌──── Day of Month (1 - 31)
│ │ │ ┌── Month (1 - 12)
│ │ │ │ ┌ Day of Week (0 - 7)
│ │ │ │ │
0 3 * * * backup.sh
```
Meaning:
- 0 → At minute 0
- 3 → At 3 AM
- `* * *` → Every day, every month, every weekday

- Runs backup.sh every day at 3:00 AM

### Simple line:
- Crontab = automatic task scheduler (like an alarm for tasks)

### how do you check cron jobs?”
`crontab -l`
