# Day 41 – Triggers & Matrix Builds

## Challenge Tasks

### Task 1: Trigger on Pull Request
1. Create `.github/workflows/pr-check.yml`
2. Trigger it only when a pull request is **opened or updated** against `main`
3. Add a step that prints: `PR check running for branch: <branch name>`
4. Create a new branch, push a commit, and open a PR
5. Watch the workflow run automatically

**Verify:** Does it show up on the PR page?
- Workflow runs automatically on PR creation/update
- It appears in the PR “Checks” tab
   - Yes, it appears on the PR page

<img width="1843" height="954" alt="image" src="https://github.com/user-attachments/assets/9848a80b-0d9c-40ab-a1ca-be5aebd0a4f8" />

<img width="1198" height="778" alt="image" src="https://github.com/user-attachments/assets/707c719f-b3b0-4920-b8d1-79a29ca749db" />

<img width="1743" height="363" alt="image" src="https://github.com/user-attachments/assets/4c516071-6d95-4d83-b116-c4c7d7e51497" />

<img width="1653" height="777" alt="image" src="https://github.com/user-attachments/assets/ead102f8-7968-42a6-9472-58d327d995cb" />

<img width="1333" height="763" alt="image" src="https://github.com/user-attachments/assets/73efdb86-c744-49e5-b5a6-3da8c0de4541" />


**Pull Request Trigger:**

```yaml
# .github/workflows/pr-check.yml

name: PR Check

on:
  pull_request:
    branches:
      - main
    types:
      - opened # runs when PR is created
      - synchronize # runs when new commits are pushed to the PR

jobs:
  pr-check:
    runs-on: ubuntu-latest

    steps:
      - name: Print PR branch name
        run: |
          echo "PR check running for branch: ${{ github.head_ref }}" # ${{ github.head_ref }} → prints the source branch name
```

### Verify File Exists

Run:
```bash
tree
```
Expected:
```bash
.
├── .github
│   └── workflows
│       └── pr-check.yml
└── README.md
```

---

### Task 2: Scheduled Trigger
1. Add a `schedule:` trigger to any workflow using cron syntax
2. Set it to run every day at midnight UTC --> '0 0 * * *'
3. What is the cron expression for every Monday at 9 AM? --> 0 9 * * 1

 
```yaml
name: Scheduled Workflow

# Trigger the workflow every day at midnight UTC
on:
  schedule:
    - cron: "0 0 * * *" # Daily at midnight UTC

jobs:
  scheduled-job:
    runs-on: ubuntu-latest

    steps:
      # Step 1: Checkout the repository
      - name: Check repository
        uses: actions/checkout@v4

      # Step 2: Print scheduled message
      - name: Print message
        run: echo "Scheduled workflow running at midnight UTC"

      # Step 3: Print greeting
      - name: Print greeting
        run: echo "Hello from GitHub Actions!"

      # Step 4: Print current date and time
      - name: Print current date and time
        run: date

      # Step 5: Print branch name
      - name: Print branch name
        run: |
          echo "Triggered by branch: ${{ github.ref_name }}"

      # Step 6: List repository files
      - name: List repo files
        run: ls -la

      # Step 7: Print runner operating system
      - name: Print runner OS
        run: |
          echo "Runner OS: ${{ runner.os }}"

      # Step 8: Print workflow trigger type
      - name: Print trigger type
        run: |
          echo "Workflow triggered by: ${{ github.event_name }}"

      # Step 9: Print current UTC time
      - name: Print current UTC time
        run: date -u

      # Step 10: Simulate health check
      - name: Simulate health check
        run: |
          echo "Running scheduled health check..."
          echo "All systems operational ✅"

      # Step 11: Intentionally fail (optional)
      # - name: Break the workflow on purpose
      #   run: exit 1
```

- cron expression for every Monday at 9 AM is `0 9 * * 1`

### Verify File Exists

Run:
```bash
tree
```
Expected:
```bash
.
├── .github
│   └── workflows
│       └── pr-check.yml
│       └── schedule.yml
└── README.md
```

<img width="931" height="774" alt="image" src="https://github.com/user-attachments/assets/136ecf53-5863-4222-ad65-86e59374946d" />


### Task 3: Manual Trigger
1. Create `.github/workflows/manual.yml` with a `workflow_dispatch:` trigger
2. Add an **input** that asks for an `environment` name (staging/production)
3. Print the input value in a step
4. Go to the **Actions** tab → find the workflow → click **Run workflow**

**Verify:** Can you trigger it manually and see your input printed?
   - Yes, I see input value.




Manual Trigger:

```yaml
name: Manual Deploy Workflow

on:
  workflow_dispatch:
    inputs:
      environment:
        description: "Select the environment"
        required: true
        default: "staging"
        type: choice
        options:
          - staging
          - production

      version:
        description: "Version or tag to deploy"
        required: false
        default: "latest"
        type: string

      dry_run:
        description: "Perform dry run only"
        required: true
        default: "false"
        type: choice
        options:
          - "false"
          - "true"

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Print deployment inputs
        run: |
          echo "Selected environment: ${{ github.event.inputs.environment }}"
          echo "Version: ${{ github.event.inputs.version }}"
          echo "Dry run: ${{ github.event.inputs.dry_run }}"

      - name: Simulate deployment
        run: |
          DRY="${{ github.event.inputs.dry_run }}"
          ENV="${{ github.event.inputs.environment }}"
          VER="${{ github.event.inputs.version }}"

          if [ "$DRY" = "true" ]; then
            echo "DRY RUN → Would deploy $VER to $ENV"
          else
            echo "Deploying $VER to $ENV ✅"
          fi
```


<img width="1666" height="654" alt="image" src="https://github.com/user-attachments/assets/86cbc8f2-5ec5-40c3-8f70-5774c6b9b46f" />

<img width="1687" height="823" alt="image" src="https://github.com/user-attachments/assets/31a09358-d9ac-43ab-beaa-85ec4b1425a6" />

<img width="952" height="787" alt="image" src="https://github.com/user-attachments/assets/84afe9fd-372e-4c40-b550-24cd80527edc" />

<img width="403" height="477" alt="image" src="https://github.com/user-attachments/assets/7c8fa940-d81c-4f1d-8c95-d373997ae8b1" />

<img width="1177" height="474" alt="image" src="https://github.com/user-attachments/assets/151dd086-29f3-476f-accc-fa5f4f53b9f2" />

<img width="792" height="784" alt="image" src="https://github.com/user-attachments/assets/f11c8b76-3c66-4fed-8b0c-b1c58154f6e1" />

<img width="1732" height="546" alt="image" src="https://github.com/user-attachments/assets/46bb1ca1-c89b-41b9-b16d-21db7facbfff" />


---

### Task 4: Matrix Builds
Create `.github/workflows/matrix.yml` that:
1. Uses a matrix strategy to run the same job across:
   - Python versions: `3.10`, `3.11`, `3.12`
2. Each job installs Python and prints the version
3. Watch all 3 run in parallel

Then extend the matrix to also include 2 operating systems — how many total jobs run now?


<img width="696" height="282" alt="image" src="https://github.com/user-attachments/assets/a0d0eff6-2e47-41d9-9db5-aeda5539f067" />

<img width="777" height="639" alt="image" src="https://github.com/user-attachments/assets/1d541e26-d4f4-4cd3-a059-2b76a17f93ca" />


Matrix Builds:
```yaml
name: Matrix Build

on:
  workflow_dispatch:

jobs:
  matrix-job:
    runs-on: ubuntu-latest

    strategy:
      matrix:
        python-version: ["3.10", "3.11", "3.12"]

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Print Python version
        run: python --version
```

Extend Matrix Build:
```yaml
name: Matrix Build

on:
  push:
    branches:
      - main

  workflow_dispatch:

jobs:
  test:
    runs-on: ${{ matrix.os }}

    strategy:
      matrix:
        os:
          - ubuntu-latest
          - windows-latest

        python-version:
          - "3.10"
          - "3.11"
          - "3.12"

    steps:
      # Step 1: Checkout repository
      - name: Checkout code
        uses: actions/checkout@v4

      # Step 2: Install Python
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      # Step 3: Print Python version
      - name: Print Python version
        run: python --version

      # Step 4: Print operating system
      - name: Print operating system
        run: echo "Running on ${{ matrix.os }}"
```

<img width="765" height="249" alt="image" src="https://github.com/user-attachments/assets/ed07a725-bf6b-4322-a5fa-e02a3006f7e2" />

<img width="751" height="766" alt="image" src="https://github.com/user-attachments/assets/edb7ee9b-f2b6-496f-9a18-14447ccf2cbb" />

**Total Jobs**

- 2 OS × 3 Python versions = 6 jobs

---

### Task 5: Exclude & Fail-Fast
1. In your matrix, **exclude** one specific combination (e.g., Python 3.10 on Windows)

```bash
        exclude:
          - os: windows-latest
            python-version: "3.10"
```

2. Set `fail-fast: false` — trigger a failure in one job and observe what happens to the rest
3. Write in your notes: What does `fail-fast: true` (the default) do vs `false`?

✔ fail-fast: true (default)
- Stops all jobs if one fails 
✔ fail-fast: false
- Lets all jobs run even if one fails 


  ```yaml
name: Matrix Build with Fail-Fast

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ${{ matrix.os }}

    strategy:
      fail-fast: false

      matrix:
        os:
          - ubuntu-latest
          - windows-latest

        python-version:
          - "3.10"
          - "3.11"
          - "3.12"

        exclude:
          - os: windows-latest
            python-version: "3.10"

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}

      - name: Print Python Version
        run: python --version

      - name: Print environment
        run: |
          echo "OS: ${{ matrix.os }}"
          echo "Python: ${{ matrix.python-version }}"

      - name: Simulate failure
        if: matrix.os == 'ubuntu-latest' && matrix.python-version == '3.11'
        run: |
          echo "Failing Ubuntu + Python 3.11"
          exit 1

      - name: Run tests
        run: python -c "print('All tests passed')"
```
<img width="1065" height="502" alt="image" src="https://github.com/user-attachments/assets/6fad6bbd-5687-4542-89cd-fc714cefc81c" />


---
