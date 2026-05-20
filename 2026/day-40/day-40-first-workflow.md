# Day 40 – Your First GitHub Actions Workflow

---


## What is GitHub Actions?

GitHub Actions = a robot that runs your code when something happens

Example in real life

You push code:

`You push code → GitHub reacts → robot runs tasks → result shows`

----


## Every GitHub Action always has just 4 things:

### 1. Trigger (WHEN)
on: push

👉 Means: “run when I push code”
> Run the workflow every time code is pushed to the repository (any device, any terminal, any tool).
> You push code → GitHub sees change → workflow starts

**Real-world analogy**

Imagine:

- You drop a letter in a mailbox  (git push)
- Post office receives it (GitHub)
- Machine starts processing it (Actions)

It doesn’t matter:

- which pen you used
- which language you wrote in
- where you dropped it from

Only matters:
👉 letter reached mailbox

### 2. Machine (WHERE)
runs-on: ubuntu-latest

👉 Means: “use a Linux computer in the cloud”
> GitHub should create a fresh Ubuntu Linux machine in the cloud and run my workflow steps there.

**Easy analogy**

Think:

- GitHub = hotel
- runner = temporary room
- ubuntu-latest = type of room
- your workflow = tasks you do inside the room

After job finishes:
👉 room is destroyed

Key DevOps concept (important)

Every run:

- fresh machine 
- no memory from previous run
- clean environment

### 3. Steps (WHAT TO DO)
steps:

👉 Means: “list of tasks”

> A list of tasks that run one after another in order inside the same job.

Important detail (this is key)

If one step fails:
- the next steps do NOT run

Example:

- Step 1 ✅
- Step 2 ❌ (fails)
- Step 3 ⏭️ skipped

**Simple analogy**

Think like cooking:

1. boil water
2. add rice
3. cook for 10 mins
4. serve

If step 2 fails:
👉 everything after it stops


### uses: actions/checkout@v4 means:

“Use a pre-built GitHub Action (version 4) that downloads/clones my repository into the runner machine.”

💡 Important detail you should remember

When a runner starts, it is EMPTY:

- No code ❌
- No files ❌
- Just a blank Ubuntu machine

So this step:

`uses: actions/checkout@v4`

does this:

`Pulls your repo → puts code inside runner → makes files available`

**Simple analogy**

Think like:

- Runner = empty laptop
- checkout = downloading your project folder onto it

Why this step is IMPORTANT

Without it:

- your code is NOT available in workflow
- ls -la shows empty folder
- build/test steps fail

### 4. Commands (ACTION)
run: echo "Hello"

👉 Means: “execute command in terminal”

> Execute this command in the runner’s terminal (shell), which prints Hello to the output log.

Important detail

It doesn’t “run a statement” — it:

- runs a shell command
- inside the GitHub Actions runner machine
- and prints output in logs

**Simple breakdown**
- run → execute terminal command
- echo "Hello" → print text to screen/log

Real DevOps view

When workflow runs:
```bash
Runner starts
↓
executes: echo "Hello"
↓
output goes to GitHub Actions log
```
You see it in the Actions tab.

**Easy analogy**

Think:

`run = typing command in Linux terminal`

---

## Challenge Tasks

### Task 1: Set Up
1. Create a new **public** GitHub repository called `github-actions-practice`
2. Clone it locally
3. Create the folder structure: `.github/workflows/`

<img width="1541" height="880" alt="image" src="https://github.com/user-attachments/assets/c4618cc8-c2f4-4bc1-9e7f-770078e7b44e" />


---

### Task 2: Hello Workflow
Create `.github/workflows/hello.yml` with a workflow that:

<img width="651" height="974" alt="image" src="https://github.com/user-attachments/assets/66ef9f92-339a-4f70-8271-c692252b3924" />

1. Triggers on every `push`
2. Has one job called `greet`
3. Runs on `ubuntu-latest`
4. Has two steps:
   - Step 1: Check out the code using `actions/checkout`
   - Step 2: Print `Hello from GitHub Actions!`

<img width="1739" height="828" alt="image" src="https://github.com/user-attachments/assets/c9e65a71-aa30-4ab8-a231-2e3a36edaed0" />


Push it. Go to the **Actions** tab on GitHub and watch it run.

<img width="1756" height="476" alt="image" src="https://github.com/user-attachments/assets/72a75ab0-11b1-473d-bb5f-bd7207b2203c" />


**Verify:** Is it green? Click into the job and read every step.

   - Yes,it is green

<img width="1903" height="768" alt="image" src="https://github.com/user-attachments/assets/cfaeb893-ae23-42f5-9742-2f5dcb674253" />

<img width="1871" height="909" alt="image" src="https://github.com/user-attachments/assets/f57e9ea9-8b31-44fd-bca3-23c33eb2ba6b" />


```yaml
# Name of the workflow
name: hello workflow

# Trigger the workflow on every push
on:
  push:
    branches:
      - main

# Define the jobs that will run in this workflow
jobs:
  greet:

    # Specify the runner environment
    runs-on: ubuntu-latest

    # Steps represent tasks executed as part of the job
    steps:

      # Step 1: Checkout the repository
      - name: Check repository
        uses: actions/checkout@v4

      # Step 2: Print greeting
      - name: Print greeting
        run: echo "Hello from GitHub Actions!"
```


---

### Task 3: Understand the Anatomy


## `on:`

- Defines the event that triggers the workflow.
- It listen for event `push`

Example:

```yaml id="5yjlwm"
on:
  push:
```

Meaning:

* Run the workflow whenever code is pushed to the repository.

---

## `jobs:`

- Contains one or more jobs that the workflow will execute.
- A `workflow` can have one or multiple jobs
   
Example:

```yaml id="7wd1wa"
jobs:
```

Meaning:

* A workflow can have multiple jobs.
* Each job performs a set of tasks.

---

## `runs-on:`

Specifies the operating system/environment (runner) where the job runs.
   - `ubuntu-latest`,`windows-latest`,`macos-latest`
Example:

```yaml id="5h9l0h"
runs-on: ubuntu-latest
```

Meaning:

* GitHub creates an Ubuntu virtual machine to execute the job.

---

## `steps:`

- Defines the sequence of tasks executed inside a job.
- Steps run one after another inside the job.
Example:

```yaml id="u0mqxo"
steps:
```

Meaning:

* Each step performs one action or command.
* Steps run one after another.

---

## `uses:`

- Uses a prebuilt GitHub Action created by GitHub or the community.
- Checkout action to clone the repo.

Example:

```yaml id="zlt8pk"
uses: actions/checkout@v4
```

Meaning:

* Downloads the repository code into the runner machine.
* Reuses existing automation instead of writing everything manually.

---

## `run:`

- Executes commands directly on the runner
Example:

```yaml id="yulbh2"
run: echo "Hello from GitHub Actions!"
```

Meaning:

* Runs terminal/Linux commands during the workflow.

---

## `name:` (inside a step)

- Give the step a human-readable label in the Actions UI.
Example:

```yaml id="6ffxhy"
- name: Print Greeting
```

Meaning:

* Helps identify the step in the GitHub Actions UI and logs.

---

# Simple Workflow Example

```yaml id="tf52ec"
name: First Workflow

on:
  push:

jobs:
  greet:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Print Greeting
        run: echo "Hello from GitHub Actions!"
```

---

# Easy Analogy

| GitHub Actions Term | Real-Life Analogy       |
| ------------------- | ----------------------- |
| Workflow            | Full recipe             |
| Job                 | One cooking task        |
| Step                | Individual instruction  |
| Runner              | Kitchen                 |
| `uses:`             | Using a ready-made tool |
| `run:`              | Doing manual work       |


---

### Task 4: Add More Steps
Update `hello.yml` to also:
1. Print the current date and time
2. Print the name of the branch that triggered the run (hint: GitHub provides this as a variable)
3. List the files in the repo
4. Print the runner's operating system

| Command                  | Purpose                               |
| ------------------------ | ------------------------------------- |
| `date`                   | Prints current system date/time       |
| `ls -la`                 | Lists all files including hidden ones |
| `$RUNNER_OS`             | Environment variable showing OS       |
| `${{ github.ref_name }}` | GitHub variable for branch name       |


<img width="1074" height="852" alt="image" src="https://github.com/user-attachments/assets/15823fe6-923a-4f3d-ac50-0592f71b02f1" />


```yaml
# Name of the workflow
name: hello workflow

# Trigger the workflow on every push
on:
  push:
    branches:
      - main

# Define the jobs that will run in this workflow
jobs:
  greet:

    # Specify the runner environment
    runs-on: ubuntu-latest

    # Steps represent tasks executed as part of the job
    steps:

      # Step 1: Checkout the repository
      - name: Check repository
        uses: actions/checkout@v4

      # Step 2: Print greeting
      - name: Print greeting
        run: echo "Hello from GitHub Actions!"

      # Step 3: Print the current date and time
      - name: Print current date and time
        run: date

      # Step 4: Print branch name
      - name: Print branch name
        run: |
          echo "Triggered by branch: ${{ github.ref_name }}"

      # Step 5: List repository files
      - name: List repo files
        run: ls -la

      # Step 6: Print runner operating system
      - name: Print runner OS
        run: |
          echo "Runner OS: ${{ runner.os }}"
```

Note:

${{ }} = GitHub expression (compile time)
$RUNNER_OS = shell variable (runtime)

---

### Task 5: Break It On Purpose
1. Add a step that runs a command that will **fail** (e.g., `exit 1` or a misspelled command)
2. Push and observe what happens in the Actions tab
3. Fix it and push again

```yaml
# Name of the workflow
name: hello workflow

# Trigger the workflow on every push
on:
  push:
    branches:
      - main

# Define the jobs that will run in this workflow
jobs:
  greet:

    # Specify the runner environment
    runs-on: ubuntu-latest

    # Steps represent tasks executed as part of the job
    steps:

      # Step 1: Checkout the repository
      - name: Check repository
        uses: actions/checkout@v4

      # Step 2: Print greeting
      - name: Print greeting
        run: echo "Hello from GitHub Actions!"

      # Step 3: Print the current date and time
      - name: Print current date and time
        run: date

      # Step 4: Print branch name
      - name: Print branch name
        run: |
          echo "Triggered by branch: ${{ github.ref_name }}"

      # Step 5: List repository files
      - name: List repo files
        run: ls -la

      # Step 6: Print runner operating system
      - name: Print runner OS
        run: |
          echo "Runner OS: ${{ runner.os }}"

      # Step 7: Intentional failure (optional)
      - name: Break workflow on purpose
        run: exit 1
```

- Error
<img width="559" height="82" alt="image" src="https://github.com/user-attachments/assets/85e0e57e-2bfd-4a58-920e-6c163cc36aa5" />

<img width="1514" height="825" alt="image" src="https://github.com/user-attachments/assets/c56835c4-27ac-4076-bf1a-1d6e4ad62c74" />


- Fix it
<img width="1870" height="867" alt="image" src="https://github.com/user-attachments/assets/94d2c21c-fe5c-43aa-bc06-3bc0ce0b2d11" />


- What does a failed pipeline look like? How do you read the error?

 # Failed Pipeline Observation

When the pipeline fails:
- GitHub shows a red ❌ status on the workflow
- The job stops immediately at the failed step
- Remaining steps are skipped
- Logs show the exact error message and exit code

## How to read the error:
1. Open GitHub Actions tab
2. Click the failed workflow run
3. Click the failed job
4. Expand the step with the red ❌ icon
5. Read terminal output (exit code or command error)

## Key Learning:
A single failing command stops the entire CI pipeline.

---
