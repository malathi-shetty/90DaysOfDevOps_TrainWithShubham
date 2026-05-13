# Day 40 – Your First GitHub Actions Workflow

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


## Task
Today you write your **first GitHub Actions pipeline** and watch it run in the cloud.

This is the moment CI/CD stops being a concept and becomes real.

---

## Expected Output
- A workflow file: `.github/workflows/hello.yml`
- A markdown file: `day-40-first-workflow.md`
- Screenshot of your first green pipeline run

---

## Challenge Tasks

### Task 1: Set Up
1. Create a new **public** GitHub repository called `github-actions-practice`
2. Clone it locally
3. Create the folder structure: `.github/workflows/`

---

### Task 2: Hello Workflow
Create `.github/workflows/hello.yml` with a workflow that:
1. Triggers on every `push`
2. Has one job called `greet`
3. Runs on `ubuntu-latest`
4. Has two steps:
   - Step 1: Check out the code using `actions/checkout`
   - Step 2: Print `Hello from GitHub Actions!`

Push it. Go to the **Actions** tab on GitHub and watch it run.

**Verify:** Is it green? Click into the job and read every step.

---

### Task 3: Understand the Anatomy
Look at your workflow file and write in your notes what each key does:
- `on:`
- `jobs:`
- `runs-on:`
- `steps:`
- `uses:`
- `run:`
- `name:` (on a step)

---

### Task 4: Add More Steps
Update `hello.yml` to also:
1. Print the current date and time
2. Print the name of the branch that triggered the run (hint: GitHub provides this as a variable)
3. List the files in the repo
4. Print the runner's operating system

Push again — watch the new run.

---

### Task 5: Break It On Purpose
1. Add a step that runs a command that will **fail** (e.g., `exit 1` or a misspelled command)
2. Push and observe what happens in the Actions tab
3. Fix it and push again

Write in your notes: What does a failed pipeline look like? How do you read the error?

---

## Hints
- Workflow files live in `.github/workflows/` and must end in `.yml`
- `uses: actions/checkout@v4` checks out your code onto the runner
- `run:` executes shell commands
- GitHub provides built-in variables like `${{ github.ref_name }}` for branch name
- Every push triggers a new run — check the Actions tab

---

## Documentation
Create `day-40-first-workflow.md` with:
- Your workflow YAML
- Screenshot of the green run
- What each `on:`, `jobs:`, `steps:` key does (your own words)

---

## Submission
1. Add `day-40-first-workflow.md` to `2026/day-40/`
2. Commit and push to your fork

---

## Learn in Public
Share your first green pipeline screenshot on LinkedIn. That green checkmark hits different.

`#90DaysOfDevOps` `#DevOpsKaJosh` `#TrainWithShubham`

Happy Learning!
**TrainWithShubham**
