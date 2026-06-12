# Day 47 – Advanced Triggers: PR Events, Cron Schedules & Event-Driven Pipelines

## Challenge Tasks

### Task 1: Pull Request Event Types
Create `.github/workflows/pr-lifecycle.yml` that triggers on `pull_request` with **specific activity types**:
1. Trigger on: `opened`, `synchronize`, `reopened`, `closed`
2. Add steps that:
   - Print which event type fired: `${{ github.event.action }}`
   - Print the PR title: `${{ github.event.pull_request.title }}`
   - Print the PR author: `${{ github.event.pull_request.user.login }}`
   - Print the source branch and target branch
3. Add a conditional step that only runs when the PR is **merged** (closed + merged = true)

Test it: create a PR, push an update to it, then merge it. Watch the workflow fire each time with a different event type.

```yaml
name: Pull Request (PR) Lifecycle Events

on:
  pull_request:
    types: [opened, synchronize, reopened, closed]

jobs:
  pr-info:
    runs-on: ubuntu-latest

    steps:
      - name: Show event type
        run:  |
          echo "Event fired: ${{ github.event.action }}"

      - name: PR Title
        run:  |
          echo "Title: ${{ github.event.pull_request.title }}"

      - name: PR Author
        run:  |
          echo "Author: ${{ github.event.pull_request.user.login }}"

      - name: Branch Info
        run: |
          echo "Source branch: ${{ github.head_ref }}"
          echo "Target branch: ${{ github.base_ref }}"

      - name: PR Opened
        if: github.event.action == 'opened'
        run: echo "🟢 PR Opened"

      - name: PR Updated (Synchronize)
        if: github.event.action == 'synchronize'
        run: echo "🔄 PR Updated"

      - name: PR Reopened
        if: github.event.action == 'reopened'
        run: echo "🔁 PR Reopened"

      - name: PR Merged (Post actions)
        if: github.event.action == 'closed' && github.event.pull_request.merged == true
        run: |
          echo "✅ PR #${{ github.event.pull_request.number }} was MERGED"
          echo "Target branch: ${{ github.base_ref }}"
          echo "Merged by: ${{ github.event.pull_request.merged_by.login }}"
          echo "Merge SHA: ${{ github.event.pull_request.merge_commit_sha }}"

      - name: PR Closed without merge
        if: github.event.action == 'closed' && github.event.pull_request.merged == false
        run: |
          echo "⚠️ PR #${{ github.event.pull_request.number }} closed WITHOUT merge"
          echo "Author: ${{ github.event.pull_request.user.login }}"
```


https://github.com/malathi-shetty/github-actions-practice/actions/workflows/pr-lifecycle.yml

https://github.com/malathi-shetty/github-actions-practice/pulls

https://github.com/malathi-shetty/github-actions-practice/pulls?q=is%3Apr+is%3Aclosed

<img width="1327" height="312" alt="image" src="https://github.com/user-attachments/assets/f035c08a-861f-4642-8023-351d950c9223" />

<img width="1920" height="1103" alt="image" src="https://github.com/user-attachments/assets/cdb2f3d8-bd02-4fd1-9d2c-2a7bfed7b5c0" />
<img width="1920" height="1383" alt="image" src="https://github.com/user-attachments/assets/cd861f74-d0ae-4513-a15d-6a6386ef8f7a" />
<img width="1920" height="1243" alt="image" src="https://github.com/user-attachments/assets/c2824f8d-2b41-467b-b2fa-85f949a47c0f" />

<img width="1920" height="1642" alt="image" src="https://github.com/user-attachments/assets/dca6217a-df68-41c7-a00f-61568b765515" />
<img width="1920" height="1363" alt="image" src="https://github.com/user-attachments/assets/57e527b7-0ceb-46ec-975f-cf3328da3ba5" />
<img width="1920" height="923" alt="image" src="https://github.com/user-attachments/assets/87005a47-7c55-4c07-9747-8ac442a978be" />
<img width="1920" height="911" alt="image" src="https://github.com/user-attachments/assets/4c9db638-4e12-4b88-a8a4-4119501f0d55" />







---

### ✅ After pushing branch:

```bash id="9l6wqt"
git push origin feature/pr-validation-success
```

you must ALSO:

### 👉 Open Pull Request in GitHub UI

---

###  Do this now

Go to your repo on GitHub.

You should see a banner like:

```text id="uaf2q7"
feature/pr-validation-success had recent pushes
[Compare & pull request]
```

Click it.

---

###  Create PR

Use:

| Field   | Value                         |
| ------- | ----------------------------- |
| Base    | main                          |
| Compare | feature/pr-validation-success |

---

###  Add PR body

```text id="6nq1oq"
## Changes
- Testing PR validation workflow

## Testing
- Verified workflow execution
```

---

###  Click:

```text id="w0s64u"
Create Pull Request
```

---

### ✅ NOW what happens

Immediately GitHub triggers:

```text id="ct6fn0"
pull_request → opened
```

Then Actions page will show:

```text id="5c5qu8"
PR Validation Checks #4
```

(or next number)

---

###  IMPORTANT UNDERSTANDING

This sequence matters:

```text id="q4xgjh"
git push branch
        ↓
branch exists remotely
        ↓
open PR manually in GitHub UI
        ↓
pull_request event fires
        ↓
workflow runs
```

---


We’ll test:

1. ✅ Successful PR
2. ❌ Bad branch name
3. ❌ Large file
4. ⚠️ Empty PR body warning

---

###  TEST 1 — SUCCESSFUL PR (All checks pass)

---

###  Step 1 — Create valid branch

```bash id="u5vjjz"
git checkout main
git pull origin main

git checkout -b feature/pr-validation-success
```

---

###  Step 2 — Make small change

```bash id="rzyhxq"
echo "Testing successful PR validation" >> test.txt
```

---

###  Step 3 — Commit & push

```bash id="4np5b0"
git add .
git commit -m "Test successful PR validation"
git push origin feature/pr-validation-success
```

---

###  Step 4 — Open PR in GitHub UI

Go to:

```text id="q71qzh"
GitHub Repository → Compare & Pull Request
```

---

###  Step 5 — Add PR description

Paste this:

```text id="wsmn8w"
## Changes
- Added test for PR validation workflow

## Testing
- Verified branch naming
- Verified PR checks workflow
```

---

###  Step 6 — Create Pull Request

---

# ✅ EXPECTED RESULT

All checks should PASS:

| Check             | Result |
| ----------------- | ------ |
| file-size-check   | ✅      |
| branch-name-check | ✅      |
| pr-body-check     | ✅      |

---

---

###  TEST 2 — BAD BRANCH NAME

---

###  Step 1 — Create invalid branch

```bash id="35wr4j"
git checkout main

git checkout -b randombranch
```

---

###  Step 2 — Make small change

```bash id="6tbntd"
echo "Testing invalid branch" >> invalid.txt
```

---

###  Step 3 — Commit & push

```bash id="v6t0oe"
git add .
git commit -m "Test invalid branch"
git push origin randombranch
```

---

###  Step 4 — Open PR

Add normal PR description.

---

### ❌ EXPECTED RESULT

| Check             | Result |
| ----------------- | ------ |
| branch-name-check | ❌ FAIL |
| file-size-check   | ✅      |
| pr-body-check     | ✅      |

---

###  What failed?

This condition:

```yaml id="0ioijv"
^(feature|fix|docs)/
```

rejects:

```text id="p6p8i5"
randombranch
```

---

---

### TEST 3 — LARGE FILE FAILURE

---

###  Step 1 — Create valid branch

```bash id="2pfrje"
git checkout main

git checkout -b feature/large-file-test
```

---

###  Step 2 — Create large file (>1MB)

Linux/macOS:

```bash id="3m4k4v"
dd if=/dev/zero of=bigfile.bin bs=1M count=2
```

---

Windows PowerShell:

```powershell id="urjq4g"
fsutil file createnew bigfile.bin 2097152
```

---

###  Step 3 — Commit & push

```bash id="pp6e2m"
git add .
git commit -m "Add large file for testing"
git push origin feature/large-file-test
```

---

###  Step 4 — Open PR

Add normal PR description.

---

### ❌ EXPECTED RESULT

| Check             | Result |
| ----------------- | ------ |
| file-size-check   | ❌ FAIL |
| branch-name-check | ✅      |
| pr-body-check     | ✅      |

---

###  Why it failed?

This command found large file:

```bash id="zj5s1z"
find . -type f -size +1M
```

---

---

###  TEST 4 — EMPTY PR BODY WARNING

---

### Step 1 — Create valid branch

```bash id="h9qz08"
git checkout main

git checkout -b feature/empty-pr-body
```

---

###  Step 2 — Small change

```bash id="6fllq7"
echo "Testing empty PR body" >> body.txt
```

---

###  Step 3 — Commit & push

```bash id="78h56p"
git add .
git commit -m "Test empty PR body"
git push origin feature/empty-pr-body
```

---

###  Step 4 — Open PR

⚠️ Leave PR description EMPTY

---

### 🟡 EXPECTED RESULT

| Check             | Result          |
| ----------------- | --------------- |
| file-size-check   | ✅               |
| branch-name-check | ✅               |
| pr-body-check     | ⚠️ warning only |

Workflow still succeeds.

---

###  IMPORTANT UNDERSTANDING

## Blocking vs Non-blocking checks

---

## ❌ Blocking

Uses:

```bash id="w68btq"
exit 1
```

This FAILS workflow.

Example:

* bad branch
* large file

---

## ⚠️ Non-blocking

Uses:

```bash id="d0zh10"
::warning::
```

This only shows warning.

Example:

* empty PR description

---



### Task 2: PR Validation Workflow
Create `.github/workflows/pr-checks.yml` — a real-world PR gate:
1. Trigger on `pull_request` to `main`
2. Add a job `file-size-check` that:
   - Checks out the code
   - Fails if any file in the PR is larger than 1 MB
3. Add a job `branch-name-check` that:
   - Reads the branch name from `${{ github.head_ref }}`
   - Fails if it doesn't follow the pattern `feature/*`, `fix/*`, or `docs/*`
4. Add a job `pr-body-check` that:
   - Reads the PR body: `${{ github.event.pull_request.body }}`
   - Warns (but doesn't fail) if the PR description is empty

**Verify:** Open a PR from a badly named branch — does the check fail?

 - Yes, the `branch-name-check` job fails.

```yaml
name: PR Validation Checks

on:
  pull_request:
    branches: [main]

jobs:

  file-size-check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Check file sizes  >1 MB
        run: |
          echo "Checking files larger than 1MB..."
          LARGE_FILES=$(find . -type f -size +1M)

          if [ -n "$LARGE_FILES" ]; then
            echo "::error::The following files exceed 1 MB-Large files found:"
            echo "$LARGE_FILES"
            exit 1
          fi

  branch-name-check:
    runs-on: ubuntu-latest
    steps:
      - name: Validate branch name
        shell: bash
        run: |
          BRANCH="${{ github.head_ref }}"
          echo "Branch: $BRANCH"

          if [[ ! "$BRANCH" =~ ^(feature|fix|docs)/ ]]; then
            echo "::error:: Branch name '$BRANCH' is invalid. Must start with feature/, fix/, or docs/"
            exit 1
          fi

          echo "✅ Branch name valid"

  pr-body-check:
    runs-on: ubuntu-latest
    steps:
      - name: Check PR body - Warn if PR description is empty
        run: |
          PR_BODY="${{ github.event.pull_request.body }}"

          if [ -z "$PR_BODY" ] || [ "$PR_BODY" == "null" ]; then
            echo "::warning:: PR body description is empty (non-blocking warning)"
          else
            echo "✅ PR body present"
          fi
```

<img width="953" height="790" alt="image" src="https://github.com/user-attachments/assets/1c64a40c-13ca-4dda-8e8c-e91c88f2ec15" />
<img width="1920" height="1403" alt="image" src="https://github.com/user-attachments/assets/e17c1198-6c90-4c98-b533-4a702879e3ad" />
<img width="1920" height="983" alt="image" src="https://github.com/user-attachments/assets/27c5fc82-ed01-4197-9339-33cb680c0b1b" />
<img width="1920" height="1003" alt="image" src="https://github.com/user-attachments/assets/19f0c548-c93b-410d-93c1-b7fb7f64e931" />
<img width="1920" height="2132" alt="image" src="https://github.com/user-attachments/assets/00ee5211-f00b-4041-ac7e-517396211825" />
<img width="1117" height="636" alt="image" src="https://github.com/user-attachments/assets/d63b52e2-9b28-4d09-bc99-a0acd78f2240" />
<img width="1041" height="676" alt="image" src="https://github.com/user-attachments/assets/fdbe7545-acf7-49a4-bfd3-d257894172b4" />
<img width="987" height="674" alt="image" src="https://github.com/user-attachments/assets/9de504ac-5ec6-48f8-92e9-49d3397fc21b" />
<img width="1920" height="1642" alt="image" src="https://github.com/user-attachments/assets/2426fc2f-f1c1-4348-a685-22d47eeabe38" />

https://github.com/malathi-shetty/github-actions-practice/actions/workflows/pr-validation-checks.yml

--------



# ⚙️ Workflow Trigger

```yaml id="x9jz3w"
on:
  pull_request:
    branches:
      - main
```

##  Meaning

This workflow runs whenever:

* A PR is opened
* Updated
* Reopened

AND only if the target branch is:

```text id="ktz1f6"
main
```

---

#  Key Concepts Learned

---

# 1️⃣ File Size Validation

## 🎯 Purpose

Prevent large binary files from entering the repository.

---

## 🔹 Command Used

```bash id="q3zw0r"
find . -type f -size +1M
```

### Meaning:

| Option      | Purpose                |
| ----------- | ---------------------- |
| `-type f`   | Search files only      |
| `-size +1M` | Files larger than 1 MB |

---

## 🔹 Failure Logic

```bash id="i6ns6s"
exit 1
```

This stops the workflow and marks the job as FAILED.

---

# 2️⃣ Branch Name Validation

## 🎯 Purpose

Enforce team branch naming standards.

Allowed patterns:

```text id="m1f9s5"
feature/*
fix/*
docs/*
```

---

## 🔹 Variable Used

```text id="yo3shv"
github.head_ref
```

This gives:

> Source branch name of the PR

Example:

```text id="e2p7mz"
feature/login-page
```

---

## 🔹 Regex Used

```bash id="p1h0jw"
^(feature|fix|docs)/
```

### Meaning:

| Pattern   | Meaning              |        |                  |
| --------- | -------------------- | ------ | ---------------- |
| `^`       | Start of branch name |        |                  |
| `(feature | fix                  | docs)` | Allowed prefixes |
| `/`       | Must contain slash   |        |                  |

---

## ❌ Invalid Examples

```text id="ugk82g"
randombranch
bugfix-login
hotfix-auth
```

---

# 3️⃣ PR Body Validation

## 🎯 Purpose

Encourage proper PR descriptions.

---

## 🔹 Variable Used

```text id="0i0wsi"
github.event.pull_request.body
```

This contains:

> PR description text from GitHub UI

---

## 🔹 Warning Logic

```bash id="p0bz7l"
::warning::
```

This shows warning but DOES NOT fail workflow.

---

### ⚠️ Blocking vs Non-Blocking Checks

| Type          | Behavior          |
| ------------- | ----------------- |
| `exit 1`      | FAIL workflow     |
| `::warning::` | Show warning only |

---

###  Testing Performed

---

### ✅ Test 1 — Successful PR

## Branch

```text id="y2xgvl"
feature/pr-validation-success
```

## PR body added

Yes

## Large files

No

---

## Expected Result

| Job               | Status |
| ----------------- | ------ |
| file-size-check   | ✅      |
| branch-name-check | ✅      |
| pr-body-check     | ✅      |

---

### ❌ Test 2 — Invalid Branch Name

## Branch

```text id="l4i1ji"
randombranch
```

---

## Expected Result

| Job               | Status |
| ----------------- | ------ |
| branch-name-check | ❌ FAIL |

---

### ❌ Test 3 — Large File Detection

## File created

```bash id="jjlwm5"
dd if=/dev/zero of=bigfile.bin bs=1M count=2
```

Creates:

```text id="5k5t4y"
2 MB file
```

---

## Expected Result

| Job             | Status |
| --------------- | ------ |
| file-size-check | ❌ FAIL |

---

### ⚠️ Test 4 — Empty PR Body

## PR description

Left empty intentionally

---

## Expected Result

| Job           | Status          |
| ------------- | --------------- |
| pr-body-check | ⚠️ Warning only |

Workflow still succeeds.


---

### Task 3: Scheduled Workflows (Cron Deep Dive)
Create `.github/workflows/scheduled-tasks.yml`:
1. Add a `schedule` trigger with cron: `'30 2 * * 1'` (every Monday at 2:30 AM UTC)
2. Add **another** cron entry: `'0 */6 * * *'` (every 6 hours)
3. In the job, print which schedule triggered using `${{ github.event.schedule }}`
4. Add a step that acts as a **health check** — curl a URL and check the response code


Write in your notes:
- The cron expression for: every weekday at 9 AM IST: `30 3 * * 1-5`
  - Because:
    - IST = UTC + 5:30
    - 9:00 AM IST = 3:30 AM UTC   
- The cron expression for: first day of every month at midnight: `0 0 1 * *`
- Why GitHub says scheduled workflows may be delayed or skipped on inactive repos
   - Scheduled workflows run on shared GitHub-hosted runners.
   - They run only on the default branch.
   - GitHub may delay or skip scheduled workflows on inactive repositories to optimize infrastructure usage and save resources.
 
## curl Command Used
`curl -o /dev/null -s -w "%{http_code}" --max-time 15 "$TARGET_URL"`

## curl Flags Explained

| Flag                | Purpose                     |
| ------------------- | --------------------------- |
| `-s`                | Silent mode                 |
| `-o /dev/null`      | Discard response body       |
| `-w "%{http_code}"` | Print only HTTP status code |
| `--max-time 15`     | Timeout after 15 seconds    |

```yaml
name: Scheduled Tasks

# Scheduled workflows only run on the default branch (usually main)
# workflow_dispatch allows manual testing

on:
  workflow_dispatch:

  schedule:
    # Every Monday at 2:30 AM UTC
    - cron: '30 2 * * 1'

    # Every 6 hours
    - cron: '0 */6 * * *'

jobs:
  scheduled-health-check:
    name: Health Check
    runs-on: ubuntu-latest

    steps:

      # ── Checkout Repository ─────────────────────────────
      - name: Checkout Code
        uses: actions/checkout@v4

      # ── Print Trigger Information ──────────────────────
      - name: Print Trigger Information
        run: |
          echo "Trigger type: ${{ github.event_name }}"

          if [ -z "${{ github.event.schedule }}" ]; then
            echo "Workflow triggered manually"
          else
            echo "Workflow triggered by cron schedule: ${{ github.event.schedule }}"
          fi

          echo "Workflow triggered at: $(date -u)"
          echo "Triggered by: ${{ github.actor }}"

          # Detect which cron schedule fired
          if [ "${{ github.event_name }}" = "schedule" ]; then

            case "${{ github.event.schedule }}" in

              "30 2 * * 1")
                echo "Running: Weekly Monday job (2:30 AM UTC)"
                ;;

              "0 */6 * * *")
                echo "Running: Every-6-hours job"
                ;;

              *)
                echo "Running: Unknown schedule"
                ;;

            esac

          else
            echo "Running: Manual workflow dispatch"
          fi

      # ── Health Check using curl ────────────────────────
      - name: Health Check using curl
        run: |

          TARGET_URL="https://github.com"

          echo "Checking: $TARGET_URL"

          STATUS_CODE=$(curl -o /dev/null -s -w "%{http_code}" --max-time 15 "$TARGET_URL")

          echo "HTTP Response code: $STATUS_CODE"

          if [ "$STATUS_CODE" -eq 200 ]; then
            echo "✅ Health check PASSED (HTTP $STATUS_CODE)"
          else
            echo "::error::Health check FAILED (HTTP $STATUS_CODE)"
            exit 1
          fi

      # ── Report Last Commit Info ────────────────────────
      - name: Report Last Commit Age
        run: |

          LAST_COMMIT_DATE=$(git log -1 --format="%ci")
          LAST_COMMIT_SHA=$(git log -1 --format="%h")

          echo "Last commit: $LAST_COMMIT_SHA"
          echo "Committed at: $LAST_COMMIT_DATE"

      # ── Job Summary ────────────────────────────────────
      - name: Scheduled Run Summary
        run: |

          echo "## Scheduled Health Check" >> "$GITHUB_STEP_SUMMARY"
          echo "" >> "$GITHUB_STEP_SUMMARY"

          echo "| Key | Value |" >> "$GITHUB_STEP_SUMMARY"
          echo "|-----|-------|" >> "$GITHUB_STEP_SUMMARY"

          echo "| Ran at | $(date -u) |" >> "$GITHUB_STEP_SUMMARY"
          echo "| Schedule | \`${{ github.event.schedule }}\` |" >> "$GITHUB_STEP_SUMMARY"
          echo "| HTTP Check | ✅ 200 OK |" >> "$GITHUB_STEP_SUMMARY"

# curl flags explanation:
#
# -s                  Silent mode
# -o /dev/null        Discard response body
# -w "%{http_code}"   Print only HTTP status code
# --max-time 15       Timeout after 15 seconds
```

https://github.com/malathi-shetty/github-actions-practice/actions/workflows/scheduled-tasks.yml

<img width="1920" height="1145" alt="image" src="https://github.com/user-attachments/assets/bfc254ad-bf82-4135-9ef9-8ed4b3ab5fd5" />

<img width="1920" height="4478" alt="image" src="https://github.com/user-attachments/assets/6b742aeb-f200-40b2-98fa-4876f00cad6b" />


---

### Task 4: Path & Branch Filters
Create `.github/workflows/smart-triggers.yml`:
1. Trigger on push but **only** when files in `src/` or `app/` change:
   ```yaml
   on:
     push:
       paths:
         - 'src/**'
         - 'app/**'
   ```
2. Add `paths-ignore` in a second workflow that skips runs when only docs change:
   ```yaml
   paths-ignore:
     - '*.md'
     - 'docs/**'
   ```
3. Add branch filters to only trigger on `main` and `release/*` branches
4. Test it: push a change to a `.md` file — does the workflow skip?
- Yes, the workflow was skipped successfully because `.md` files matched `paths-ignore`.

| Workflow             | Behavior                      |
| -------------------- | ----------------------------- |
| Smart Triggers       | Runs only for src/app changes |
| Docs Ignore Workflow | Skips docs-only changes       |

| Concept        | Meaning                              |
| -------------- | ------------------------------------ |
| `paths`        | Run workflow ONLY for matching files |
| `paths-ignore` | Skip workflow for ignored files      |
| `branches`     | Restrict branches                    |
| `release/*`    | Wildcard branch pattern              |
| `**`           | Recursive folder matching            |



## workflows/smart-triggers.yml
```yaml
name: Smart Triggers

on:
  push:
    branches:
      - main
      - 'release/*'

    paths:
      - 'src/**'
      - 'app/**'

jobs:

  smart-path-check:
    runs-on: ubuntu-latest

    steps:

      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Print Trigger Details
        run: |
          echo "Event       : ${{ github.event_name }}"
          echo "Smart trigger workflow started"
          echo "Branch      : ${{ github.ref_name }}"
          echo "Commit SHA  : ${{ github.sha }}"
          echo ""
          echo "Workflow triggered because src/ or app/ changed."

      - name: List Changed Files
        run: |
          echo "Recent commit files:"
          git diff --name-only HEAD~1 HEAD || true

      - name: Detect Changed Paths
        run: |
          echo "Changed files in this push:"
          git diff --name-only HEAD~1 HEAD 2>/dev/null || echo "(first commit or no previous ref)"

      - name: Build Step Placeholder
        run: |
          echo "✅ Path filter matched — running build"
          echo "Branch : ${{ github.ref_name }}"
          echo "Trigger: ${{ github.event_name }}"
```

## workflows/docs-ignore.yml
```yaml
name: Docs Ignore Workflow

on:
  push:

    branches:
      - main
      - 'release/*'

    paths-ignore:
      - '*.md'
      - 'docs/**'
      - '**/README.md'
      - '.github/CODEOWNERS'
      - 'LICENSE'

jobs:

  ignore-docs-job:
    runs-on: ubuntu-latest

    steps:

      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Workflow Triggered
        run: |
          echo "Workflow executed because non-doc files changed"
          echo "Branch: ${{ github.ref_name }}"
          echo ""
          echo "This workflow is skipped when only docs or markdown files change."
```


 ## When would you use `paths` vs `paths-ignore`?

- Use `paths` when the workflow should run ONLY if specific files or folders change.

Example:
- Run backend tests only when `src/` changes.
- frontend changes
- backend changes
- terraform changes

- Use `paths-ignore` when the workflow should run for most changes but skip unnecessary files.

Example:
- Skip workflows for documentation-only changes.
- README updates
- documentation changes
- changelog edits

| Feature        | Use Case                    |
| -------------- | --------------------------- |
| `paths`        | Include only specific files |
| `paths-ignore` | Exclude specific files      |



| Change Type          | Workflow Behavior |
| -------------------- | ----------------- |
| `README.md` only     | skipped           |
| `docs/info.txt` only | skipped           |
| `config.env`         | runs              |
| `src/app.js`         | runs              |



TEST 1 — Test paths

Goal:
✅ Trigger workflow ONLY when `src/` or `app/` changes.


 Create src File

```bash
mkdir -p src
```

Create file:

```bash

echo "console.log('Hello Smart Trigger');" > src/app.js
```

 Commit & Push

```bash
git add .
git commit -m "Update src application"
git push
```
✅ Expected Result

Go to:

`GitHub → Actions`

You should see:

`Smart Triggers`

RUNNING ✅

Because:

`src/app.js changed`


TEST 2 — Test `paths-ignore`

Goal:
✅ Skip workflow when ONLY markdown/docs files change.


 Modify README

```bash
echo "# Documentation update" >> README.md
```

 Commit & Push

```bash
git add .
git commit -m "Update README documentation"
git push
```
✅ Expected Result

Workflow:

`Docs Ignore Workflow`

SHOULD SKIP ✅

Because:

`only .md file changed`

TEST 3 — Test docs Folder Ignore

 Create docs File

```bash
mkdir -p docs
```

Create file:

```bash

echo "DevOps Notes" > docs/info.txt
```

 Commit & Push

```bash
git add .
git commit -m "Add docs info"
git push
```
✅ Expected Result
`Docs Ignore Workflow`

should SKIP again.

Because:

`docs/** is ignored`

TEST 4 — Non-doc File Change

Goal:
✅ Workflow should run if non-doc file changes.


✅ To PROVE Workflow Still Works

Now modify NON-doc file:


 Create Config File

```bash
echo "PORT=3000" > config.env
```

Commit & Push

```bash
git add .
git commit -m "Add config file"
git push
```

✅ Expected Result

NOW you SHOULD see: 
`Docs Ignore Workflow`

WILL RUN ✅

Because:

`config.env is NOT ignored`


Test Branch Filters

Goal:
Workflow runs ONLY on:

`main`
`release/*`

Create New Branch

```bash
git checkout -b feature/test-branch-filter
```

Modify src File

```bash
echo "branch filter test" >> src/app.js
```

Commit & Push

```bash
git add .
git commit -m "Test branch filter"
git push origin feature/test-branch-filter
```
✅ Expected Result

NO workflow should run ❌

Because:

`feature/* branch is NOT allowed`

TEST 5 — Release Branch

Create Release Branch

```bash
git checkout -b release/v1
```

Modify src File

```bash
echo "release build" >> src/app.js
```

Commit & Push

```bash
git add .
git commit -m "Release branch test"
git push origin release/v1
```

✅ Expected Result
Smart Triggers

WILL RUN ✅
Because:
branch matches `release/*`
src changed

----

<img width="1344" height="677" alt="image" src="https://github.com/user-attachments/assets/222f8542-8f79-4899-85a2-a3b8faeaa6d4" />

<img width="1920" height="1543" alt="image" src="https://github.com/user-attachments/assets/b601f190-66e5-4af3-b49f-5189b3ea3638" />

<img width="784" height="351" alt="image" src="https://github.com/user-attachments/assets/147628f6-ea00-4772-b424-cea3c3f1cbb6" />

<img width="1920" height="1902" alt="image" src="https://github.com/user-attachments/assets/702c3f71-4b9f-4698-9579-d18be72cf270" />

<img width="1313" height="618" alt="image" src="https://github.com/user-attachments/assets/a9f74e9a-611e-4103-8acb-bab1158478f0" />

<img width="466" height="226" alt="image" src="https://github.com/user-attachments/assets/d431eedc-c246-4282-a7f0-430206166496" />

<img width="799" height="528" alt="image" src="https://github.com/user-attachments/assets/47eeb6db-db6d-4ca8-8574-d130bc74f70f" />

<img width="1288" height="530" alt="image" src="https://github.com/user-attachments/assets/336c94cd-ddc8-49c6-9691-38caadc12191" />

<img width="949" height="601" alt="image" src="https://github.com/user-attachments/assets/33cc588e-ded9-40ba-8262-8db64d0643f7" />

<img width="704" height="597" alt="image" src="https://github.com/user-attachments/assets/8fd7e311-4d95-45b7-b8db-1cac16aa30c5" />

https://github.com/malathi-shetty/github-actions-practice/actions/workflows/smart-triggers.yml

https://github.com/malathi-shetty/github-actions-practice/actions/workflows/docs-ignore.yml

---

### Task 5: `workflow_run` — Chain Workflows Together
Create two workflows:
1. `.github/workflows/tests.yml` — runs tests on every push
2. `.github/workflows/deploy-after-tests.yml` — triggers **only after** `tests.yml` completes successfully:
   ```yaml
   on:
     workflow_run:
       workflows: ["Run Tests"]
       types: [completed]
   ```
3. In the deploy workflow, add a conditional:
   - Only proceed if the triggering workflow **succeeded** (`${{ github.event.workflow_run.conclusion == 'success' }}`)
   - Print a warning and exit if it failed

**Verify:** Push a commit — does the test workflow run first, then trigger the deploy workflow?

  ### Result:
- Yes, the `Run Tests` workflow executed first.
- After successful completion, the `Deploy After Tests` workflow started automatically.

| Workflow                 | Purpose                               |
| ------------------------ | ------------------------------------- |
| `tests.yml`              | Run tests on every push               |
| `deploy-after-tests.yml` | Trigger AFTER tests workflow finishes |


## /workflows/tests.yml
```yaml
name: Run Tests

on:
  push:
  pull_request:
  workflow_dispatch:

jobs:

  test-job:
    runs-on: ubuntu-latest

    steps:

      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Print Test Start
        run: |
          echo " Running tests..."
          echo "Branch: ${{ github.ref_name }}"
          echo "Commit: ${{ github.sha }}"

      - name: Simulate Tests
        run: |
          echo "Running sample tests..."

          # Simulated test logic
          echo "Test 1 Passed"
          echo "Test 2 Passed"
          #echo "Test 3 Passed"
          echo "Test failed!"
          exit 1

      - name: Test Success
        run: echo "✅ All tests passed successfully"

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Run tests
        run: |
          echo "Running test suite..."
          python scripts/test_utils.py
          echo "✅ All tests passed"
```

## workflows/deploy-after-tests.yml

```yaml
name: Deploy After Tests

# Trigger only after "Run Tests" workflow completes
on:
  workflow_run:
    workflows:
      - "Run Tests"

    branches:
      - main

    types:
      - completed

jobs:

  deploy-job:
    name: Deploy (post-test gate)
    runs-on: ubuntu-latest

    steps:

      # ── Print workflow details ─────────────────────────────
      - name: Print Workflow Information
        run: |
          echo "Triggered workflow : ${{ github.event.workflow_run.name }}"
          echo "Run ID             : ${{ github.event.workflow_run.id }}"
          echo "Conclusion         : ${{ github.event.workflow_run.conclusion }}"
          echo "Branch             : ${{ github.event.workflow_run.head_branch }}"
          echo "Commit SHA         : ${{ github.event.workflow_run.head_sha }}"

      # ── Block deployment if tests failed ──────────────────
      - name: Stop if tests failed
        if: ${{ github.event.workflow_run.conclusion != 'success' }}

        run: |
          echo ""
          echo "❌ Tests did not pass"
          echo "Deployment blocked"
          echo "::warning::Fix tests before deploying"

          exit 1

      # ── Checkout tested commit ────────────────────────────
      - name: Checkout Tested Commit
        if: ${{ github.event.workflow_run.conclusion == 'success' }}

        uses: actions/checkout@v4

        with:
          ref: ${{ github.event.workflow_run.head_sha }}

      # ── Simulated deployment ──────────────────────────────
      - name: Deploy Application
        if: ${{ github.event.workflow_run.conclusion == 'success' }}

        run: |
          echo "Deploying commit: ${{ github.event.workflow_run.head_sha }}"
          echo ""
          echo "✅ Tests passed"
          echo "🚀 Starting deployment..."
          echo ""

          echo "Simulating deployment steps:"
          echo "1. Pull latest image"
          echo "2. Run migrations"
          echo "3. Restart services"
          echo "4. Health check"

          echo ""
          echo "✅ Deployment successful"

      # ── Deployment summary ────────────────────────────────
      - name: Deployment Summary
        run: |
          echo "## Deploy After Tests Summary" >> "$GITHUB_STEP_SUMMARY"
          echo "" >> "$GITHUB_STEP_SUMMARY"
          echo "| Key | Value |" >> "$GITHUB_STEP_SUMMARY"
          echo "|-----|-------|" >> "$GITHUB_STEP_SUMMARY"
          echo "| Test Result | \`${{ github.event.workflow_run.conclusion }}\` |" >> "$GITHUB_STEP_SUMMARY"
          echo "| Commit SHA | \`${{ github.event.workflow_run.head_sha }}\` |" >> "$GITHUB_STEP_SUMMARY"
          echo "| Branch | \`${{ github.event.workflow_run.head_branch }}\` |" >> "$GITHUB_STEP_SUMMARY"
          echo "| Time | $(date -u) UTC |" >> "$GITHUB_STEP_SUMMARY"
```
<img width="1896" height="843" alt="image" src="https://github.com/user-attachments/assets/9a5ecd15-5fb1-4889-9a9d-d0a85e2a2ff2" />
<img width="1897" height="888" alt="image" src="https://github.com/user-attachments/assets/b804fb50-ca74-4d60-a377-645f92eeb5db" />

<img width="1230" height="453" alt="image" src="https://github.com/user-attachments/assets/6e74467c-8cf1-485a-9bb0-c9a85d249f46" />
<img width="1920" height="2701" alt="image" src="https://github.com/user-attachments/assets/14c80c57-c25a-45c1-a3bc-fe07d44a4980" />

<img width="1920" height="1180" alt="image" src="https://github.com/user-attachments/assets/9acc9583-4cdc-41f8-83d1-3fabe42475c7" />
<img width="1920" height="1902" alt="image" src="https://github.com/user-attachments/assets/c1e9274a-bf5a-4df9-a98f-82cbb04900ae" />

<img width="964" height="801" alt="image" src="https://github.com/user-attachments/assets/76f5f98c-cf6a-4724-b4f4-ac85e37fd1ae" />


https://github.com/malathi-shetty/github-actions-practice/actions/workflows/tests.yml

https://github.com/malathi-shetty/github-actions-practice/actions/workflows/deploy-after-tests.yml

---

### Task 6: `repository_dispatch` — External Event Triggers
1. Create `.github/workflows/external-trigger.yml` with trigger `repository_dispatch`
2. Set it to respond to event type: `deploy-request`
3. Print the client payload: `${{ github.event.client_payload.environment }}`
4. Trigger it using `curl` or `gh`:
   
```bash
gh auth status
gh auth login
gh login activate device
```

## Create Payload File

Run:

```bash
cat > payload.json <<EOF
{
  "event_type": "deploy-request",
  "client_payload": {
    "environment": "production",
    "version": "v1.0",
    "requester": "Malathi"
  }
}
EOF
```

## STEP 2 — Send Dispatch Event

Run:

```bash
gh api repos/malathi-shetty/github-actions-practice/dispatches \
  --method POST \
  --input payload.json
  ```

**Create rollback payload**
```bash
cat > rollback.json <<EOF
{
  "event_type": "rollback-request",
  "client_payload": {
    "environment": "production",
    "version": "v0.9"
  }
}
EOF
```

## Trigger rollback workflow
```bash
gh api repos/malathi-shetty/github-actions-practice/dispatches \
  --method POST \
  --input rollback.json
```

## Expected Output in Actions
```bash
⏪ Rollback request received
Environment : production
Rollback to : v0.9

✅ Rollback triggered successfully
```

## Test Smoke Test Event

Create:

```bash
cat > smoke.json <<EOF
{
  "event_type": "smoke-test-request",
  "client_payload": {
    "environment": "staging"
  }
}
EOF
```
### Run:

```bash
gh api repos/malathi-shetty/github-actions-practice/dispatches \
  --method POST \
  --input smoke.json
```  
### Expected Output
```bash
🔬 Smoke test request received
Environment : staging

✅ Smoke tests passed
   ```

```yaml
name: External Repository Dispatch Trigger

# repository_dispatch lets external systems trigger workflows via the GitHub API.
# It will NOT appear in the triggers list for push/PR — it is API-only.

on:
  repository_dispatch:

    types:
      - deploy-request
      - rollback-request
      - smoke-test-request

jobs:

  handle-external-trigger-job:
    name: Handle ${{ github.event.action }}
    runs-on: ubuntu-latest

    steps:
 # ── Print what the external system sent ──────────────────────────────────
      - name: Print Event Information
        run: |
          echo "External event received!"
          echo "Event Type : ${{ github.event.action }}"
          echo "Triggered By Repository Dispatch"

      - name: Print dispatch context
        run: |
          echo "Environment : ${{ github.event.client_payload.environment }}"
          echo "Triggered By : ${{ github.actor }}"
          echo "Repo              : ${{ github.repository }}"
          echo "=== Client Payload ==="

          echo "version     : ${{ github.event.client_payload.version }}"
          echo "requester   : ${{ github.event.client_payload.requester }}"

  # ── Route to the correct handler based on event type ─────────────────────
      - name: Handle deploy-request
        if: github.event.action == 'deploy-request'
        run: |
          ENV="${{ github.event.client_payload.environment }}"
          VER="${{ github.event.client_payload.version }}"
          echo "🚀 Deploy request received"
          echo "   Environment : ${ENV:-unknown}"
          echo "   Version     : ${VER:-latest}"
          echo ""
          echo "Simulating deployment to ${ENV}..."
          echo "✅ Deploy to ${ENV} triggered successfully"

      - name: Handle rollback-request
        if: github.event.action == 'rollback-request'
        run: |
          echo "⏪ Rollback request received"
          echo "   Environment : ${{ github.event.client_payload.environment }}"
          echo "   Rollback to : ${{ github.event.client_payload.version }}"
          echo "Simulating rollback..."
          echo "✅ Rollback triggered successfully"

      - name: Handle smoke-test-request
        if: github.event.action == 'smoke-test-request'
        run: |
          echo "🔬 Smoke test request received"
          echo "   Environment : ${{ github.event.client_payload.environment }}"
          echo "Simulating smoke tests..."
          echo "✅ Smoke tests passed"

      - name: Summary
        run: |
          echo "## repository_dispatch Summary" >> "$GITHUB_STEP_SUMMARY"
          echo "" >> "$GITHUB_STEP_SUMMARY"
          echo "| Key | Value |" >> "$GITHUB_STEP_SUMMARY"
          echo "|-----|-------|" >> "$GITHUB_STEP_SUMMARY"
          echo "| Event type  | \`${{ github.event.action }}\` |" >> "$GITHUB_STEP_SUMMARY"
          echo "| Environment | \`${{ github.event.client_payload.environment }}\` |" >> "$GITHUB_STEP_SUMMARY"
          echo "| Triggered at | $(date -u) |" >> "$GITHUB_STEP_SUMMARY"

      - name: Simulated Deployment
        run: |
          echo "🚀 Starting deployment..."
          echo "Deploying to environment:"
          echo  "environment : ${{ github.event.client_payload.environment }}"

          echo "Deployment successful!"
```

https://github.com/malathi-shetty/github-actions-practice/actions/workflows/external-trigger.yml

<img width="1684" height="803" alt="image" src="https://github.com/user-attachments/assets/8878c05f-8d79-47b3-ab4c-63ca6d0a599c" />
<img width="1920" height="1522" alt="image" src="https://github.com/user-attachments/assets/26d6ec38-f161-4041-8856-f9af50246050" />
<img width="933" height="468" alt="image" src="https://github.com/user-attachments/assets/27a17419-7a77-4273-b980-fbb19b8c9fcc" />
<img width="1828" height="799" alt="image" src="https://github.com/user-attachments/assets/3642ea84-8f42-4df7-b543-50c75b73e910" />
<img width="1920" height="1503" alt="image" src="https://github.com/user-attachments/assets/2888c262-510f-45e0-b037-727a5cbc8dcc" />
<img width="1698" height="790" alt="image" src="https://github.com/user-attachments/assets/c8cdd862-66b1-4e65-a6bd-4b9a4b2fc95f" />
<img width="1920" height="1483" alt="image" src="https://github.com/user-attachments/assets/1679dc88-9263-49fe-85ed-ff38a13df945" />


### When would an external system (like a Slack bot or monitoring tool) trigger a pipeline?

External systems may trigger GitHub Actions workflows when events outside GitHub require automation.

Examples:
- A Slack bot sends a deployment request.
- A monitoring tool detects a failure and triggers rollback automation.
- Another repository completes a release and triggers deployment in this repository.
- A CI/CD dashboard triggers smoke tests after deployment.


---

## `workflow_call` vs `workflow_run`

### `workflow_call`
- Makes workflows reusable like functions.
- One workflow directly calls another workflow.
- Supports inputs and secrets.
- Best for reusable CI/CD templates.

Example:
- `deploy.yml` calls `test.yml` before deployment.

---

### `workflow_run`
- Triggers automatically after another workflow completes.
- Event-driven workflow chaining.
- Uses workflow completion status (`success`, `failure`, etc.).
- Does not pass inputs directly like `workflow_call`.

Example:
- `Deploy After Tests` runs only after `Run Tests` succeeds.
