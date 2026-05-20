# Day 42 – Runners: GitHub-hosted & Self-Hosted
---

**Overview**

Every GitHub Actions workflow needs a **runner**, which is simply a machine that executes your CI/CD jobs.

There are two types of runners:

| Type                     | Meaning                                                          |
| ------------------------ | ---------------------------------------------------------------- |
| **GitHub-hosted runner** | Temporary virtual machine created and managed by GitHub          |
| **Self-hosted runner**   | Your own machine (EC2, laptop, VPS, etc.) registered with GitHub |

**Key Difference**
- GitHub-hosted = “borrow a fresh cloud machine per job”
- Self-hosted = “use your own always-on machine”

**Workflow Files Created**

| File                     | Purpose                                        |
| ------------------------ | ---------------------------------------------- |
| `multi-os.yml`           | Run jobs on Ubuntu, Windows, macOS in parallel |
| `preinstalled-tools.yml` | Explore tools available in Ubuntu runners      |
| `self-hosted.yml`        | Run workflows on EC2/self-hosted runner        |


## Challenge Tasks

### Task 1: GitHub-hosted Runners (Multi OS)
1. Create a workflow with 3 jobs, each on a different OS:
   - `ubuntu-latest`
   - `windows-latest`
   - `macos-latest`
2. In each job, print:
   - The OS name
   - The runner's hostname
   - The current user running the job
3. Watch all 3 run in parallel


```yaml
name: Task 1 - Multi OS GitHub Hosted Runners

on:
  workflow_dispatch:

jobs:
  ubuntu-job:
    runs-on: ubuntu-latest
    steps:
      - name: Print Ubuntu Info
        run: |
          echo "OS: Ubuntu"
          echo "Runner OS: ${{ runner.os }}"
          hostname
          whoami
  windows-job:
    runs-on: windows-latest
    steps:
      - name: Print Windows Info
        run: |
          echo "OS: Windows"
          echo "Runner OS: ${{ runner.os }}"
          hostname
          whoami
  macos-job:
    runs-on: macos-latest
    steps:
      - name: Print macOS Info
        run: |
          echo "OS: macOS"
          echo "Runner OS: ${{ runner.os }}"
          hostname
          whoami
```

<img width="1914" height="823" alt="image" src="https://github.com/user-attachments/assets/3efb74b0-9631-48e4-8124-5494fa57e096" />

<img width="408" height="687" alt="image" src="https://github.com/user-attachments/assets/ded681be-1696-47d2-aa57-f5f8514a7064" />

<img width="712" height="829" alt="image" src="https://github.com/user-attachments/assets/d944e636-293a-4cd0-981c-021ab6370fc8" />

<img width="592" height="687" alt="image" src="https://github.com/user-attachments/assets/534c4709-8ebd-4faa-b279-52e30b53573a" />


https://github.com/malathi-shetty/github-actions-practice/actions/runs/26156019695

## **What is a GitHub-hosted runner? Who manages it?**

- `GitHub-hosted` runner is a **temporary virtual machine provided by GitHub** that runs GitHub Actions workflows.

- `GitHub-hosted` runners are managed by GitHub on Microsoft Azure infrastructure.

- Responsible for:
 - Creating the virtual machine
 - Installing software
 - Maintaining security
 - Deleting the machine after the job completes.

**Characteristics:**

 - Fully managed by GitHub
 - Created fresh for every job
 - Automatically deleted after execution
 - Comes pre-installed with common DevOps tools

Think of it like:
- `“A disposable cloud laptop that appears when needed and disappears after use.”`

**Who manages it?**

Everything is handled by GitHub:
 - OS provisioning
 - Security patching
 - Tool installation
 - Scaling infrastructure
 - Deleting machines after use

You only write YAML — GitHub handles the rest.

**What happens internally?**

All jobs run in parallel:

```bash
Ubuntu job   → Cloud VM 1
Windows job  → Cloud VM 2
Mac job      → Cloud VM 3
```
Each VM is independent.

**Useful Variables**

| Variable           | Meaning                       |
| ------------------ | ----------------------------- |
| `${{ runner.os }}` | OS type (Linux/Windows/macOS) |
| `hostname`         | Machine name of runner        |
| `whoami`           | Current user                  |


---

### Task 2: Explore What's Pre-installed
1. On the `ubuntu-latest` runner, run a step that prints:
   - Docker version
   - Python version
   - Node version
   - Git version
2. Look up the GitHub docs for the full list of pre-installed software on `ubuntu-latest`


<img width="1884" height="913" alt="image" src="https://github.com/user-attachments/assets/6a49b7de-a3be-466e-b608-3d48157e2874" />

```bash
name: Task 2 - Ubuntu Preinstalled Tools

on:
  workflow_dispatch:

jobs:
  ubuntu-tools:
    runs-on: ubuntu-latest

    steps:
      - name: Full Ubuntu environment check
        run: |
          echo "===== SYSTEM ====="
          uname -a
          lsb_release -a

          echo "===== CPU / MEMORY ====="
          free -m

          echo "===== DISK ====="
          df -h

          echo "===== DOCKER ====="
          docker --version

          echo "===== PYTHON ====="
          python3 --version

          echo "===== NODE ====="
          node --version

          echo "===== GIT ====="
          git --version

          echo "===== CURL ====="
          curl --version

          echo "===== GCC ====="
          gcc --version
```

https://github.com/malathi-shetty/github-actions-practice/actions/runs/26156183237/job/76936061725

**What we explored**

GitHub-hosted Ubuntu runners already come with a full DevOps toolset.

## Why does it matter that runners come with tools pre-installed?

- It matters because pre-installed tools make workflows faster and easier to configure.
- Developers can run builds and tests immediately without installing common tools like Docker, Python, Node.js, and Git, while GitHub maintains and updates the environment.

Without them:
- Every workflow would need setup time
- Pipelines would be slow and expensive

With them:
- Instant execution
- No install overhead
- Standardized environment

**Benefits**
- Faster CI/CD pipelines
- No dependency installation needed
- Predictable environment
- Lower execution time (cost-efficient)

**Common tools available**
- Git, GitHub CLI
- Docker
- Python, Node.js, Java, Go
- AWS / Azure / GCP CLIs
- Build tools (gcc, make, cmake)
- Utilities (curl, jq, wget, unzip)


---

### Task 3: Set Up a Self-Hosted Runner
1. Go to your GitHub repo → Settings → Actions → Runners → **New self-hosted runner**
2. Choose Linux as the OS
3. Follow the instructions to download and configure the runner on:
   - Your local machine, OR
   - A cloud VM (EC2, Utho, or any VPS)
4. Start the runner — verify it shows as **Idle** in GitHub

**Verify:** Your runner appears in the Runners list with a green dot.


**What is a self-hosted runner?**

A self-hosted runner is:
> A machine you own that connects to GitHub and executes workflows.

**Examples:**
- EC2 instance
- VPS server
- Personal laptop
- On-prem server

### Setup process

```bash
mkdir actions-runner && cd actions-runner

curl -O https://github.com/actions/runner/releases/download/v2.x.x/actions-runner-linux-x64.tar.gz

tar xzf actions-runner-linux-x64.tar.gz

./config.sh --url https://github.com/<repo> --token <token>
```

### Start runner
`./run.sh`

OR install as service:

```bash
sudo ./svc.sh install
sudo ./svc.sh start
```
### Verification

**GitHub → Settings → Actions → Runners**

You should see:
`my-linux-runner → Idle`

<img width="1908" height="1059" alt="image" src="https://github.com/user-attachments/assets/c93a9067-9a9f-4bf1-80ab-45353899a5a1" />

<img width="1522" height="1280" alt="image" src="https://github.com/user-attachments/assets/953c0285-5554-412e-bf0a-a356cff32540" />

<img width="921" height="212" alt="image" src="https://github.com/user-attachments/assets/07fafd89-e960-41cd-aeec-3f7892d72ce5" />

<img width="1016" height="607" alt="image" src="https://github.com/user-attachments/assets/c399b6ab-7597-4298-b7cb-21fccf8fa893" />

 <img width="1777" height="784" alt="image" src="https://github.com/user-attachments/assets/a4b6b8f2-d822-4574-9f62-3d4b8532e320" />


https://github.com/malathi-shetty/github-actions-practice/actions/runners?tab=self-hosted

https://github.com/malathi-shetty/github-actions-practice/settings/actions/runners

---

### Task 4: Use Your Self-Hosted Runner
1. Create `.github/workflows/ec2-hosted.yml`
2. Set `runs-on: self-hosted`
3. Add steps that:
   - Print the hostname of the machine (it should be YOUR machine/VM)
   - Print the working directory
   - Create a file and verify it exists on your machine after the run
4. Trigger it and watch it run on your own hardware

**Verify:** Check your machine — is the file there?
   - Yes, file is present


```yaml
name: Self Hosted Runner Test

on:
  workflow_dispatch:

jobs:
  test-runner:
    runs-on: self-hosted

    steps:
      - name: Print hostname
        run: hostname

      - name: Print working directory
        run: pwd

      - name: Create a file
        run: |
          echo "Hello from self-hosted runner" > test-file.txt
          ls -l

      - name: Verify file exists
        run: cat test-file.txt
```

run this on another terminal:

```bash
ubuntu@ip-172-31-29-115:~$ cd ~/actions-runner/_work

ubuntu@ip-172-31-29-115:~/actions-runner/_work$ cd ~/actions-runner

ubuntu@ip-172-31-29-115:~/actions-runner$ ./run.sh
```


https://github.com/malathi-shetty/github-actions-practice/actions/workflows/self-hosted.yml

<img width="826" height="568" alt="image" src="https://github.com/user-attachments/assets/9354425c-b4e2-47a1-9d7b-24afceb1ab5b" />


<img width="1873" height="855" alt="image" src="https://github.com/user-attachments/assets/5e6ad6ad-681b-4ac8-93d6-af842f7033ff" />

**Important concept**

Self-hosted runners:
- DO NOT destroy filesystem after job
- Keep data unless manually cleaned
- Run on your actual machine

---

### Task 5: Labels
1. Add a **label** to your self-hosted runner (e.g., `my-linux-runner`)
2. Update your workflow to use `runs-on: [self-hosted, my-linux-runner]`
3. Trigger it — does it still pick up the job?

<img width="1665" height="834" alt="image" src="https://github.com/user-attachments/assets/7becbea4-423c-481e-a403-983b553dfcb0" />

```yaml
name: Label Based Self Hosted Runner

on:
  workflow_dispatch:

jobs:
  labeled-job:
    runs-on: [self-hosted, my-linux-runner]

    steps:
      - name: Show runner identity
        run: |
          echo "Hostname: $(hostname)"
          echo "User: $(whoami)"
          echo "Date: $(date)"

      - name: Verify label usage
        run: echo "This job ran on labeled self-hosted runner"

      - name: System check
        run: uname -a
```

https://github.com/malathi-shetty/github-actions-practice/actions/workflows/label-runner.yml


**What are labels?**

Labels are tags used to route jobs to specific runners.

**Example:**
- self-hosted
- linux
- my-linux-runner
- gpu
- production

**Usage**
runs-on: [self-hosted, my-linux-runner]

**Why are labels useful when you have multiple self-hosted runners?**

If you have multiple runners:
| Runner   | Label      |
| -------- | ---------- |
| EC2 Dev  | dev        |
| EC2 Prod | production |
| GPU VM   | gpu        |



- Labels are useful when you have multiple self-hosted runners because they help GitHub Actions choose the correct runner for a specific job

- Labels ensure:
 - Correct job → correct machine
 - No accidental production execution
 - Better workload control

------

### Complete Pipeline 

```yaml
name: Day 42 - Self Hosted Runner Complete Task Pipeline

on:
  workflow_dispatch:
  push:
    branches:
      - main

jobs:

  # =========================
  # TASK 4 - BASIC EXECUTION
  # =========================
  task4-basic-execution:
    name: Task 4 - Basic Self Hosted Execution
    runs-on: self-hosted

    steps:
      - name: Show hostname
        run: hostname

      - name: Show working directory
        run: pwd

      - name: Show user
        run: whoami

      - name: System details
        run: |
          echo "==== SYSTEM INFO ===="
          uname -a
          echo "==== MEMORY ===="
          free -m
          echo "==== DISK ===="
          df -h

      - name: Create test file
        run: |
          echo "Self-hosted runner test file" > test-file.txt
          echo "Created at: $(date)" >> test-file.txt

      - name: Display file
        run: cat test-file.txt


  # =========================
  # TASK 4 - PROOF & VERIFICATION
  # =========================
  task4-proof-validation:
    name: Task 4 - Proof Validation
    runs-on: self-hosted

    steps:
      - name: Create EC2 proof marker
        run: |
          echo "RUN ON EC2: $(hostname) at $(date)" > /tmp/ec2-proof.txt
          cat /tmp/ec2-proof.txt

      - name: Verify proof file exists
        run: |
          if [ -f /tmp/ec2-proof.txt ]; then
            echo "✅ Proof file exists on EC2"
          else
            echo "❌ Proof file missing"
            exit 1
          fi

      - name: Create permanent execution log
        run: |
          mkdir -p ~/ci-logs
          echo "$(date) | Job executed on $(hostname)" >> ~/ci-logs/execution.log

      - name: Print runner identity
        run: |
          echo "Runner Name: $RUNNER_NAME"
          echo "Hostname: $(hostname)"


  # =========================
  # TASK 5 - LABEL BASED RUNNER
  # =========================
  task5-label-based-runner:
    name: Task 5 - Label Based Execution
    runs-on: [self-hosted, my-linux-runner]

    steps:
      - name: Runner identity check
        run: |
          echo "Hostname: $(hostname)"
          echo "User: $(whoami)"
          echo "Date: $(date)"

      - name: Network check
        run: |
          curl -I https://github.com || true

      - name: Create artifact file
        run: |
          mkdir -p artifacts
          echo "Pipeline executed on $(hostname)" > artifacts/proof.txt

      - name: Verify artifact
        run: cat artifacts/proof.txt

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: task-output
          path: artifacts/


  # =========================
  # FINAL - UNIFIED OUTPUT (DOWNLOADABLE)
  # =========================
  task6-unified-output:
    name: Task 6 - Unified Output Bundle
    runs-on: self-hosted

    steps:
      - name: Create unified output folder
        run: |
          mkdir -p output

          echo "RUN ON EC2: $(hostname) at $(date)" > output/ec2-proof.txt
          echo "$(date) | Job executed on $(hostname)" > output/execution.log
          uname -a > output/system.txt
          echo "Self-hosted runner test file" > output/test-file.txt

      - name: Show output files
        run: ls -la output

      - name: Upload full output bundle
        uses: actions/upload-artifact@v4
        with:
          name: day42-full-output
          path: output/
```

https://github.com/malathi-shetty/github-actions-practice/actions/workflows/self-hosted-runner-complete-pipeline.yml

**Output:**

```bash
ubuntu@ip-172-31-29-115:~/actions-runner/_work/github-actions-practice/github-actions-practice$ cat artifacts/proof.txt

Pipeline executed on ip-172-31-29-115
```

> Note: “Self-hosted runner executes inside _work directory, not home directory.”


```bash
ubuntu@ip-172-31-29-115:~/github-actions-practice$ cat /tmp/ec2-proof.txt

RUN ON EC2: ip-172-31-29-115 at Wed May 20 11:48:19 UTC 2026

ubuntu@ip-172-31-29-115:~/github-actions-practice$ cat ~/ci-logs/execution.log

Wed May 20 11:47:55 UTC 2026 | Job executed on ip-172-31-29-115
Wed May 20 11:48:19 UTC 2026 | Job executed on ip-172-31-29-115

```

<img width="838" height="226" alt="image" src="https://github.com/user-attachments/assets/60a855d4-bc7f-4a5e-9915-70a63b1f405e" />

> Default behavior: If multiple runners match labels, GitHub picks any available one (not deterministic routing).

---

### Task 6: GitHub-hosted vs Self-Hosted

| Feature     |  GitHub-hosted                                                                      |  Self-hosted                                               |
| ----------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| Management  | Managed by GitHub                                                                     | Managed by you                                               |
| Cost        | Pay per minute (free for public repos, usage-based for private repos depending on OS) | You pay for your own infrastructure (EC2, VPS, server, etc.) |
| Setup       | Zero setup required                                                                   | Manual setup required                                        |
| Tools       | Preinstalled tools (Docker, Node.js, Python, Java, etc.)                              | You install and maintain all tools                           |
| Best for    | Standard CI/CD workflows                                                              | Custom environments, heavy workloads, private networks       |
| Security    | Runs on GitHub-managed infrastructure                                                 | You are responsible for securing the machine                 |
| Maintenance | Fully handled by GitHub                                                               | Fully handled by you                                         |



**Security note**

Self-hosted runners are powerful:
> Never run workflows triggered by pull_request from forks on self-hosted runners without strict controls.
Because jobs execute directly on your machine.

### **Lifecycle Summary**

 - **GitHub-hosted runner:**
`Job → VM created → Run → Destroy VM`

 - **Self-hosted runner:**
`Job → Sent to your machine → Run → Machine stays alive`

---

### Summary

- GitHub-hosted runners → Simple, fast, managed, ideal for most CI/CD pipelines
- Self-hosted runners → Flexible, powerful, but requires maintenance and security control
