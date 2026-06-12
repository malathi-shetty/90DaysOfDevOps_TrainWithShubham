# Day 46 – Reusable Workflows & Composite Actions

## Challenge Tasks

### Task 1 — Understanding `workflow_call`

#### What Is a Reusable Workflow?

A reusable workflow is a GitHub Actions workflow that can be called from another workflow, 
allowing teams to reuse the same CI/CD automation logic across multiple repositories or 
workflows instead of rewriting it repeatedly.

A reusable workflow is simply a normal workflow YAML file whose trigger is `workflow_call`.

Think of it like a function in programming:

* The reusable workflow = function definition
* The caller workflow = function call
* `inputs:` = function parameters
* `outputs:` = return values
* `secrets:` = sensitive parameters passed securely

Because of this, reusable workflows help teams follow the DRY (Don't Repeat Yourself) principle in CI/CD pipelines.

---

#### What Is the `workflow_call` Trigger?

`workflow_call` is a special GitHub Actions trigger that allows one workflow to be executed by another workflow 
instead of being triggered by events like `push`, `pull_request`, or `schedule`.

Example:

```yaml
on:
  workflow_call:
```

A reusable workflow becomes inactive ("inert") until another workflow calls it using `uses:`.

It can also define:

* `inputs:` → values passed from the caller workflow
* `secrets:` → secure secrets passed from the caller
* `outputs:` → values returned back to the caller workflow

Example:

```yaml
on:
  workflow_call:
    inputs:
      app_name:
        type: string
        required: true

    secrets:
      docker_token:
        required: true

    outputs:
      build_version:
        value: ${{ jobs.build.outputs.build_version }}
```

---

### Calling a Reusable Workflow vs Using a Regular Action (`uses:`)

There are two different ways `uses:` works in GitHub Actions:

| Feature                     | Reusable Workflow               | Regular Action                             |
| --------------------------- | ------------------------------- | ------------------------------------------ |
| Used at                     | Workflow/job level              | Step level                                 |
| Syntax location             | `jobs.<job_id>.uses`            | `steps.uses`                               |
| Purpose                     | Reuse complete workflows        | Reuse individual tasks                     |
| Granularity                 | Entire workflow                 | Single step                                |
| Can contain jobs?           | ✅ Yes, multiple jobs            | ❌ No                                    |
| Can contain multiple steps? | ✅ Yes                           | ✅ Usually                               |
| Runner behavior             | Each job gets its own runner/VM | Runs inside parent job runner              |
| Triggered by                | `workflow_call`                 | `uses:` in a step                          |
| Secret handling             | Dedicated `secrets:` block      | Usually passed through `env:` or `with:`   |
| Common examples             | Full build/deploy pipeline      | Checkout code, Docker login, setup Node.js |

#### Examples

Reusable workflow:

```yaml
jobs:
  build:
    uses: ./.github/workflows/reusable-build.yml
```

Regular action:

```yaml
steps:
  - uses: actions/checkout@v4
```

---

#### Where Must a Reusable Workflow File Live?

Reusable workflows must live inside:

```text
.github/workflows/
```

Examples:

#### Same repository

```text
.github/workflows/reusable-build.yml
```

#### Cross-repository reusable workflow

```yaml
uses: org/repo/.github/workflows/file.yml@main
```

The `.github/workflows/` location is mandatory and cannot be changed.

---

action             |

-----

### Task 2: Create Your First Reusable Workflow
Create `.github/workflows/reusable-build.yml`:
1. Set the trigger to `workflow_call`
2. Add an `inputs:` section with:
   - `app_name` (string, required)
   - `environment` (string, required, default: `staging`)
3. Add a `secrets:` section with:
   - `docker_token` (required)
4. Create a job that:
   - Checks out the code
   - Prints `Building <app_name> for <environment>`
   - Prints `Docker token is set: true` (never print the actual secret)

**Verify:** This file alone won't run — it needs a caller. That's next.

**Verification:**
- The workflow file exists
- GitHub detects it
- BUT it will NOT run yet

Why?
Because reusable workflows need a caller workflow.
I did NOT see this workflow automatically execute in Actions.
That is expected behavior.

| Feature             | Why It's Useful          |
| ------------------- | ------------------------ |
| `description:`      | Better documentation     |
| workflow outputs    | Pass data back to caller |
| dynamic job names   | Cleaner Actions UI       |
| `$GITHUB_OUTPUT`    | Modern output handling   |
| `${{ github.sha }}` | Access GitHub context    |

```yaml
# Name shown in the GitHub Actions UI
name: Reusable Build Workflow

# Defines how this workflow is triggered
on:
  # This workflow can only be called by another workflow
  workflow_call:

    # Inputs are parameters passed from the caller workflow
    inputs:

      # Application name input
      app_name:
        description: Name of the application being built
        required: true
        type: string

      # Deployment environment input
      environment:
        description: Target deployment environment
        required: true
        default: staging
        type: string

    # Secrets passed securely from caller workflow
    secrets:

      # Docker token secret
      docker_token:
        required: true

    # Outputs returned back to the caller workflow
    outputs:

      # Expose build_version output
      build_version:
        description: Versioned tag generated during the build

        # Gets value from the build job output
        value: ${{ jobs.build.outputs.build_version }}

# Workflow jobs section
jobs:

  # Build job ID
  build:

    # Dynamic job name displayed in Actions tab
    name: Build ${{ inputs.app_name }}

    # GitHub-hosted runner
    runs-on: ubuntu-latest

    # Job-level outputs
    outputs:

      # Expose step output as job output
      build_version: ${{ steps.version.outputs.build_version }}

    # Steps executed inside the job
    steps:

      # Step 1: Checkout repository code
      - name: Checkout code
        uses: actions/checkout@v4

      # Step 2: Print workflow information
      - name: Print build info
        run: |
          echo "Building ${{ inputs.app_name }} for ${{ inputs.environment }}"
          echo "Environment: ${{ inputs.environment }}"

      # Step 3: Verify secret exists without exposing it
      - name: Verify docker token
        run: |
          echo "Docker token is set: ${{ secrets.docker_token != '' }}"

      # Step 4: Generate build version
      - name: Generate build version

        # Step ID used for outputs
        id: version

        run: |

          # Get first 7 characters of commit SHA
          SHORT_SHA=$(echo "${{ github.sha }}" | cut -c1-7)

          # Create version string
          BUILD_VERSION="v1.0-${SHORT_SHA}"

          # Save output for later jobs/workflows
          echo "build_version=${BUILD_VERSION}" >> "$GITHUB_OUTPUT"

          # Print generated version
          echo "Generated build version: ${BUILD_VERSION}"
```

<img width="1342" height="502" alt="image" src="https://github.com/user-attachments/assets/efeadd4f-76b0-4ab6-9964-2a0e6dfcbbd9" />


---

### Task 3: Create a Caller Workflow
Create `.github/workflows/call-build.yml`:
1. Trigger on push to `main`
2. Add a job that uses your reusable workflow:
   ```yaml
   jobs:
     build:
       uses: ./.github/workflows/reusable-build.yml
       with:
         app_name: "my-web-app"
         environment: "production"
       secrets:
         docker_token: ${{ secrets.DOCKER_TOKEN }}
   ```
3. Push to `main` and watch it run

**Verify:** In the Actions tab, do you see the caller triggering the reusable workflow? Click into the job 
— can you see the inputs printed?
 - The caller workflow triggers the reusable workflow correctly in the Actions tab, and the inputs (`app_name`, `environment`) are printed as expected inside the run logs.

https://github.com/malathi-shetty/github-actions-practice/actions/runs/26337294905/job/77533043984

```yaml
# Workflow name shown in GitHub Actions
name: Call Reusable Build Workflow

# Trigger workflow on push to main
on:
  push:
    branches:
      - main

# Jobs section
jobs:

  build:

    # Call reusable workflow
    uses: ./.github/workflows/reusable-build.yml

    # Pass input values
    with:
      app_name: "my-web-app"
      environment: "production"

    # Pass repository secret
    secrets:
      docker_token: ${{ secrets.DOCKER_TOKEN }}
```
<img width="733" height="775" alt="image" src="https://github.com/user-attachments/assets/543029ef-8ef3-4a77-a3a1-9395d777b0de" />


---

### Task 4: Add Outputs to the Reusable Workflow
Extend `reusable-build.yml`:
1. Add an `outputs:` section that exposes a `build_version` value
2. Inside the job, generate a version string (e.g., `v1.0-<short-sha>`) and set it as output
3. In your caller workflow, add a second job that:
   - Depends on the build job (`needs:`)
   - Reads and prints the `build_version` output

**Verify:** Does the second job print the version from the reusable workflow?
   -  The second job successfully prints the `build_version` generated in the reusable workflow.

```yaml
# Workflow name shown in GitHub Actions
name: Reusable Build Workflow

# This workflow can ONLY be triggered by another workflow.
# It cannot run directly on push, pull_request, or schedule.
on:
  workflow_call:

    # ── Inputs passed from caller workflow ─────────────────────────────
    inputs:

      # Application name input
      app_name:
        description: Name of the application being built
        required: true
        type: string

      # Deployment environment input
      environment:
        description: Target deployment environment
        required: false
        default: staging
        type: string

    # ── Secrets passed securely from caller workflow ──────────────────
    secrets:

      # Docker access token
      DOCKER_TOKEN:
        required: true

    # ── Workflow outputs exposed back to caller workflow ──────────────
    #
    # Output Chain:
    #
    # Step Output
    #     ↓
    # Job Output
    #     ↓
    # Workflow Output
    #
    # workflow_call output reads from:
    # jobs.<job-id>.outputs.<output-name>
    outputs:

      # Final reusable workflow output
      build_version:
        description: Generated build version during the build

        # Read value from job output
        value: ${{ jobs.build.outputs.build_version }}

# ── Jobs ──────────────────────────────────────────────────────────────
jobs:

  # Build job ID
  build:

    # Dynamic job name shown in Actions UI
    name: Build ${{ inputs.app_name }}

    # GitHub-hosted runner
    runs-on: ubuntu-latest

    # ── Job outputs ───────────────────────────────────────────────────
    #
    # Job output reads from:
    # steps.<step-id>.outputs.<output-name>
    outputs:

      # Expose step output as job output
      build_version: ${{ steps.version.outputs.build_version }}

    # ── Steps ─────────────────────────────────────────────────────────
    steps:

      # Checkout repository source code
      - name: Checkout code
        uses: actions/checkout@v4

      # Print reusable workflow inputs
      - name: Print build info
        run: |
          echo "Building ${{ inputs.app_name }} for ${{ inputs.environment }}"

      # ── Secret Safety Best Practice ─────────────────────────────────
      #
      # Safe:
      # Only confirm whether the secret exists.
      #
      # Dangerous:
      # Never print actual secrets in logs.
      #
      # Even though GitHub masks secrets automatically,
      # partially encoded or transformed values may bypass masking.
      #
      # Best practice:
      # Print only true/false status.
      - name: Verify docker token
        run: |
          if [ -n "${{ secrets.DOCKER_TOKEN }}" ]; then
            echo "Docker token is set: true"
          else
            echo "Docker token is set: false"
          fi

      # ── Generate reusable workflow output ───────────────────────────
      - name: Generate build version

        # Step ID required for outputs
        id: version

        run: |

          # Take first 7 characters of commit SHA
          SHORT_SHA=$(echo "${{ github.sha }}" | cut -c1-7)

          # Create reusable version string
          BUILD_VERSION="v1.0-${SHORT_SHA}"

          # ── Step Output ─────────────────────────────────────────────
          #
          # Step outputs are stored using:
          # $GITHUB_OUTPUT
          #
          # Accessible later as:
          # steps.version.outputs.build_version
          echo "build_version=${BUILD_VERSION}" >> "$GITHUB_OUTPUT"

          # Print generated version
          echo "Generated build version: ${BUILD_VERSION}"

      # ── GitHub Actions Job Summary ──────────────────────────────────
      #
      # Writes markdown output into the "Summary" tab in Actions UI.
      - name: Build summary
        run: |
          echo "## Reusable Build Summary" >> "$GITHUB_STEP_SUMMARY"
          echo "" >> "$GITHUB_STEP_SUMMARY"
          echo "| Key | Value |" >> "$GITHUB_STEP_SUMMARY"
          echo "|-----|-------|" >> "$GITHUB_STEP_SUMMARY"
          echo "| App | \`${{ inputs.app_name }}\` |" >> "$GITHUB_STEP_SUMMARY"
          echo "| Environment | \`${{ inputs.environment }}\` |" >> "$GITHUB_STEP_SUMMARY"
          echo "| Version | \`${{ steps.version.outputs.build_version }}\` |" >> "$GITHUB_STEP_SUMMARY"
```

- Changes in call-build.yml:

```yaml
print-version:

  runs-on: ubuntu-latest

  needs: build

  steps:

    - name: Print version output
      run: |
        echo "Build version: ${{ needs.build.outputs.build_version }}"
```

```bash
Caller Workflow
        │
        ▼
Reusable Workflow
        │
        ▼
Generate build_version
        │
        ▼
Return output to caller
        │
        ▼
Second job prints version
```


https://github.com/malathi-shetty/github-actions-practice/actions/runs/26337294905/job/77533048483


<img width="1309" height="376" alt="image" src="https://github.com/user-attachments/assets/129654c4-eea3-4ae6-bda1-578aa73927a9" />

<img width="967" height="595" alt="image" src="https://github.com/user-attachments/assets/70a43256-fcd3-4ec0-b522-deb3a4a15122" />


---

### Task 5: Create a Composite Action

```bash
.github/
│
├── workflows/
│   ├── reusable-build.yml
│   ├── call-build.yml
│   └── composite-demo.yml
│
└── actions/
    └── setup-and-greet/
        └── action.yml
```

## What Is a Composite Action? (Simple Definition)

A **composite action** is:

> A composite action is a reusable group of steps that runs inside the SAME job.
- No separate VM
- Only steps allowed
- Used via uses: ./path

**Think of it like:**
`Reusable mini-script inside a job`

**Important properties:**
- Runs inside the caller job
- Does NOT create a new VM
- Contains only steps (no jobs)
- Called using uses: inside a step

## Why Composite Action Exists (Simple Analogy)

Think like this:
| Concept           | Real-world analogy                 |
| ----------------- | ---------------------------------- |
| Step              | One instruction                    |
| Composite Action  | A small checklist (group of steps) |
| Reusable Workflow | A full factory line                |

## WHY THREE LEVELS EXIST (VERY IMPORTANT CONCEPT)

GitHub Actions has **3 execution layers**:

**Composite output flow:**
`STEP → JOB → WORKFLOW`

🔹 Step level
- Runs shell commands
- Temporary execution
- Output stored in file

🔹 Job level
- Collects step outputs
- Runs on a VM

🔹 Workflow level
- Calls reusable workflows
- Collects job outputs

### OUTPUT FLOW 
```bash
Step Output
   ↓
Job Output
   ↓
Workflow Output
```


### Why all 3 are needed?

Because each layer is isolated:

| Level    | Scope           |
| -------- | --------------- |
| Step     | Local shell     |
| Job      | VM runtime      |
| Workflow | Caller workflow |


- If you skip any level → value will NOT reach caller.

But for composite:
```bash
step inside composite
   ↓
GITHUB_OUTPUT
   ↓
steps.<id>.outputs
   ↓
caller workflow step
```
BUT IMPORTANT:

Composite action outputs behave like:
> “step outputs wrapped in a reusable step container”

NOT a new job layer.

---

## REAL CONNECTION (HOW YOUR CODE WORKS)
**Composite Action flow**
```bash
Caller Workflow
    ↓ (uses:)
Composite Action
    ↓
Steps inside action run in SAME VM
    ↓
Output written to GITHUB_OUTPUT
    ↓
Caller reads: steps.<id>.outputs
```

**Reusable Workflow flow**
```bash
Caller Workflow
    ↓ (jobs.uses)
Reusable Workflow starts
    ↓
Job runs on NEW VM
    ↓
Step generates output
    ↓
Job output collects it
    ↓
Workflow output returns it
    ↓
Caller reads via needs.<job>.outputs
```

## WHAT YOU SEE IN ACTIONS TAB

When reusable workflow runs:

```bash
Caller Workflow
   │
   ├── Job 1: call reusable workflow
   │        └── (expands internal workflow jobs)
   │
   └── Job 2: consume output
```

👉 GitHub shows reusable workflow as a "nested expandable block"

## CALLER SYNTAX REFERENCE (VERY IMPORTANT)
**Same repo**
`uses: ./.github/workflows/reusable-build.yml`

**External repo**
`uses: org/repo/.github/workflows/build.yml@main`

## SECRET SAFETY RULE (IMPORTANT PRACTICE)
**Safe:**
```bash
echo "Secret exists: true/false"
```
**Unsafe:**
```bash
echo "${{ secrets.DOCKER_TOKEN }}"
```

Why?
Even masked secrets can leak via:
- string splitting
- logs
- transformations

## FINAL MENTAL MODEL (MOST IMPORTANT)
**Composite Action**
```bash
Small reusable STEP GROUP
Runs inside same job
```
**Reusable Workflow**
```bash
- Full CI/CD PIPELINE
- Multiple jobs
- Own VM per job
```

**Normal Step**
```bash
- Single command
- No reuse
```

## ONE LINE DIFFERENCE
- Step → single command
- Composite Action → reusable step bundle
- Reusable Workflow → reusable full pipeline

## WHEN TO USE WHAT
**Use Composite Action when:**
- setup scripts
- login steps
- greeting / printing
- reusable small logic

**Use Reusable Workflow when:**
- build → test → deploy
- multiple jobs
- full CI/CD pipelines

Create a **custom composite action** in your repo at `.github/actions/setup-and-greet/action.yml`:
1. Define inputs: `name` and `language` (default: `en`)
2. Add steps that:
   - Print a greeting in the specified language
   - Print the current date and runner OS
   - Set an output called `greeted` with value `true`
3. Use the composite action in a new workflow with `uses: ./.github/actions/setup-and-greet`

**Verify:** Does your custom action run and print the greeting?
   - The custom composite action executes successfully and prints the greeting based on the provided language input.

```yaml
# Composite Action Name
name: Setup and Greet

# Description shown in GitHub Marketplace/UI
description: Custom composite action that greets the user in the given language and exposes a greeted output.

# ── Inputs ────────────────────────────────────────────────────────────
inputs:

  # User name input
  name:
    description: Name of the person or service to greet
    required: true

  # Greeting language
  language:
    description: Greeting language (en, es, fr, hi, de)
    required: false
    default: en

# ── Outputs ───────────────────────────────────────────────────────────
outputs:

  greeted:
    description: Whether greeting completed successfully

    # Read value from step output
    value: ${{ steps.greet.outputs.greeted }}

# ── Composite Action Steps ────────────────────────────────────────────
runs:

  # Composite action type
  using: "composite"

  steps:

    # ── Step 1: Print Greeting ───────────────────────────────────────
    - name: Print greeting

      # Step ID required for outputs
      id: greet

      shell: bash

      run: |

        # Greeting based on selected language
        if [ "${{ inputs.language }}" = "en" ]; then
          echo "Hello, ${{ inputs.name }}! 👋"

        elif [ "${{ inputs.language }}" = "es" ]; then
          echo "Hola, ${{ inputs.name }}! 👋"

        elif [ "${{ inputs.language }}" = "fr" ]; then
          echo "Bonjour, ${{ inputs.name }}! 👋"

        elif [ "${{ inputs.language }}" = "hi" ]; then
          echo "नमस्ते, ${{ inputs.name }}! 👋"

        elif [ "${{ inputs.language }}" = "de" ]; then
          echo "Hallo, ${{ inputs.name }}! 👋"

        else
          echo "Hi, ${{ inputs.name }}! 👋"
        fi

        # Set composite action output
        echo "greeted=true" >> "$GITHUB_OUTPUT"

    # ── Step 2: Print Current Date ───────────────────────────────────
    - name: Print current date

      shell: bash

      run: |
        echo "Current date: $(date)"

    # ── Step 3: Print Runner OS ──────────────────────────────────────
    - name: Print runner OS

      shell: bash

      run: |
        echo "Runner OS: $RUNNER_OS"

    # ── Step 4: Print GitHub Context ─────────────────────────────────
    - name: Print context

      shell: bash

      run: |
        echo "Date      : $(date -u)"
        echo "Runner OS : ${{ runner.os }}"
        echo "Repository: ${{ github.repository }}"
        echo "Actor     : ${{ github.actor }}"
```

```yaml
name: Use Composite Action (Debug Mode)

on:
  push:
    branches:
      - main

  workflow_dispatch:

jobs:
  greet:
    name: Run composite action demo (debug)
    runs-on: ubuntu-latest

    steps:
      # ── CLEAN CHECKOUT (IMPORTANT FOR DEBUGGING) ──
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          clean: true

      # ── DEBUG: Show repo structure ──
      - name: Show .github structure
        run: |
          echo "===== TREE .github ====="
          tree .github || ls -R .github

      # ── DEBUG: Confirm composite action folder exists ──
      - name: Verify composite action folder
        run: |
          echo "===== LIST .github/actions/setup-and-greet ====="
          ls -R .github/actions/setup-and-greet

      # ── DEBUG: Confirm action.yml is tracked by git ──
      - name: Check git tracked files for action.yml
        run: |
          echo "===== GIT LS-FILES FILTER ====="
          git ls-files | grep action.yml || echo "action.yml NOT tracked in git"

      # ── RUN COMPOSITE ACTION (EN) ──
      - name: Greet in English
        id: greet-en
        uses: ./.github/actions/setup-and-greet
        with:
          name: "Malathi"
          language: "en"

      # ── RUN COMPOSITE ACTION (ES) ──
      - name: Greet in Spanish
        id: greet-es
        uses: ./.github/actions/setup-and-greet
        with:
          name: "DevOps Engineer"
          language: "es"

      # ── RUN COMPOSITE ACTION (HI) ──
      - name: Greet in Hindi
        id: greet-hi
        uses: ./.github/actions/setup-and-greet
        with:
          name: "GitHub Actions"
          language: "hi"

      # ── DEBUG OUTPUT CHECK ──
      - name: Check outputs
        run: |
          echo "EN greeted: ${{ steps.greet-en.outputs.greeted }}"
          echo "ES greeted: ${{ steps.greet-es.outputs.greeted }}"
          echo "HI greeted: ${{ steps.greet-hi.outputs.greeted }}"

      # ── FINAL STATUS ──
      - name: Final verification
        run: |
          echo "Workflow completed successfully"
```

```bash
ubuntu@ip-172-31-5-100:~/github-actions-practice$ git ls-files | grep action.yml
.github/actions/setup-and-greet/action.yml
.github/workflows/use-composite-action.yml

ubuntu@ip-172-31-5-100:~/github-actions-practice$ ls -R .github/actions/setup-and-greet
.github/actions/setup-and-greet:
action.yml

ubuntu@ip-172-31-5-100:~/github-actions-practice$ tree .github
.github
├── actions
│   └── setup-and-greet
│       └── action.yml
└── workflows
    ├── artifact-between-jobs.yml
    ├── artifacts.yml
    ├── cache.yml
    ├── call-build.yml
    ├── conditionals.yml
    ├── day-42-task1-runners.yml
    ├── day-42-task2-ubuntu-tools.yml
    ├── docker-publish.yml
    ├── docker-secrets-env-vars.yml
    ├── env-vars.yml
    ├── hello.yml
    ├── job-outputs.yml
    ├── label-runner.yml
    ├── manual.yml
    ├── matrix-fail-fast.yml
    ├── multi-job.yml
    ├── old-matrix-os.yml
    ├── old-matrix.yml
    ├── pr-check.yml
    ├── real-tests.yml
    ├── reusable-build.yml
    ├── schedule.yml
    ├── secrets.yml
    ├── self-hosted-runner-complete-pipeline.yml
    ├── self-hosted.yml
    ├── smart-pipeline.yml
    └── use-composite-action.yml

4 directories, 28 files
```
https://github.com/malathi-shetty/github-actions-practice/actions/runs/26337294903

<img width="1920" height="3540" alt="image" src="https://github.com/user-attachments/assets/23424ec3-bd4a-41a8-b08c-0859ea48d4bb" />


# Composite Action Directory Rule (VERY IMPORTANT)

A composite action must live inside a folder, and GitHub only recognizes it if the file inside is named:

`action.yml   OR   action.yaml`

✔️ Correct structure
`.github/actions/setup-and-greet/action.yml`

❌ Incorrect usage (common mistake)
`uses: ./.github/actions/setup-and-greet/action.yml   # ❌ WRONG`

✔️ Correct usage
`uses: ./.github/actions/setup-and-greet   # ✅ correct (points to folder)`

## Key idea:

- GitHub looks for `action.yml` automatically inside the folder
- You NEVER point directly to the file

---

### Task 6: Reusable Workflow vs Composite Action
Fill this in your notes:

| Feature                                     | Reusable Workflow                                                  | Composite Action                                                 |
| ------------------------------------------- | ------------------------------------------------------------------ | ---------------------------------------------------------------- |
| **Triggered by**                            | `on: workflow_call`                                                | `uses: ./path-to-action` inside a step                           |
| **Can contain jobs?**                       | ✅ Yes — multiple jobs                                              | ❌ No — only steps inside a single job                            |
| **Can contain multiple steps?**             | ✅ Yes (inside each job → multi-job + multi-step)                 | ✅ Yes, multiple steps, but only one execution flow (multi-step only (single job context))                                      |
| **Lives where?**                            | `.github/workflows/`                                               | `.github/actions/<name>/`                                        |
| **Can accept secrets directly?**            | ✅ Yes — via `secrets:` in `workflow_call`                          | Composite actions don’t define secrets — they only receive them from caller context. |
| **Runs on its own runner?**                 | ✅ Yes — each job gets a fresh VM                                   | ❌ No — runs inside caller job’s runner                           |
| **Can use `needs:` between internal jobs?** | ✅ Yes                                                              | ❌ Not applicable                                                 |
| **Max structure depth**                     | Multi-job workflows only (no infinite DAG expansion)                         | Low (single-job step sequence only)                              |
| **Best for**                                | Full CI/CD pipelines (build → test → deploy) reusable across repos | Small reusable step logic (setup, login, install, notify, greet) |


# Decision Guide (Very Important)

## Use Reusable Workflow when:

- You need multiple jobs
- You need build/test/deploy pipeline
- You need job dependencies (needs:)
- You want full CI/CD reuse across repos

## Use Composite Action when:

- You only need reusable steps inside a job
- You want to reduce duplicate YAML
- You are doing setup tasks
- install tools
login to services
print info
small utilities

## Key Concept Summary

| Concept                         | What it actually means                                                       |
| ------------------------------- | ---------------------------------------------------------------------------- |
| `on: workflow_call`             | Makes workflow reusable (called by other workflows)                          |
| `inputs:` (workflow_call)       | Typed parameters passed from caller                                          |
| `secrets:` (workflow_call)      | Encrypted secrets passed from caller (not accessible outside secure context) |
| `outputs:` (workflow_call)      | Data returned from reusable workflow to caller                               |
| `uses: ./.github/workflows/...` | Calls reusable workflow                                                      |
| `needs:`                        | Creates dependency between jobs                                              |
| `uses: ./action-path`           | Calls composite action inside a step                                         |
| `runs: using: composite`        | Declares composite action type                                               |
| `$GITHUB_OUTPUT`                | Passes step output to next steps/jobs                                        |



- Reusable Workflow → reusable multi-job pipeline
- Reusable workflows do NOT increase GitHub DAG nesting depth
They are still subject to normal workflow limits
They only support job-level composition, not arbitrary graph depth expansion

- Composite Action → reusable steps inside a job
- Composite Action can accept secrets directly” 
Composite actions:
- do NOT have secrets: block like workflows
- cannot receive encrypted secret metadata
- BUT they CAN access secrets via:
  
```bash
env:
  TOKEN: ${{ secrets.MY_SECRET }}
```

OR:

```bash
with:
  token: ${{ secrets.MY_SECRET }}
```

## Key truth:

- Composite actions **can use secrets**, but they are just passed in, not “declared securely inside action definition”.
- Composite action inherits full GitHub Actions context
- So secrets are not “passed through action”, they are already available in caller job scope
- Composite action does NOT receive secrets — it simply runs inside a job that already has them.

# Composite Action

```bash
Caller Job (1 VM)
   ↓
Composite Action (just grouped steps)
   ↓
Runs in SAME shell environment
   ↓
Outputs go back to calling step
```

# Reusable Workflow

```bash
Caller Workflow
   ↓
New Job starts (new VM)
   ↓
Multiple steps run
   ↓
Job output
   ↓
Workflow output returned to caller
```
### Overview

Today’s focus is learning how teams avoid duplicate CI/CD pipelines by creating reusable automation components.

GitHub Actions provides two major reuse mechanisms:

| Mechanism         | File Location                       | Invoked By            |
| ----------------- | ----------------------------------- | --------------------- |
| Reusable Workflow | `.github/workflows/*.yml`           | `uses:` inside a job  |
| Composite Action  | `.github/actions/<name>/action.yml` | `uses:` inside a step |

---

### Files Created Today

| File                                         | Purpose                                         |
| -------------------------------------------- | ----------------------------------------------- |
| `.github/workflows/reusable-build.yml`       | Reusable workflow triggered via `workflow_call` |
| `.github/workflows/call-build.yml`           | Caller workflow that invokes reusable workflow  |
| `.github/actions/setup-and-greet/action.yml` | Custom composite action                         |
| `.github/workflows/use-composite-action.yml` | Workflow using the composite 
