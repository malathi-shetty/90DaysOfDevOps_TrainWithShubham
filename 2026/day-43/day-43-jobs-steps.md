# Day 43 – Jobs, Steps, Env Vars & Conditionals

---

## Challenge Tasks

### Task 1: Multi-Job Workflow
Create `.github/workflows/multi-job.yml` with 3 jobs:
- `build` — prints "Building the app"
- `test` — prints "Running tests"
- `deploy` — prints "Deploying"

Make `test` run only **after** `build` succeeds.
Make `deploy` run only **after** `test` succeeds.

**Verify:** Check the workflow graph in the Actions tab — does it show the dependency chain?

- Yes, it shows the dependency chain.

<img width="1324" height="457" alt="image" src="https://github.com/user-attachments/assets/d87696d3-8547-4c1b-9b3f-01f72e6c412f" />

<img width="1138" height="346" alt="image" src="https://github.com/user-attachments/assets/71c6d687-ce9d-4ac0-899b-23f4ff4bf980" />


`needs:` tells GitHub Actions which job must finish before another job can start.

`needs:` creates dependencies between jobs.

A job waits until the required job finishes successfully.
Yes, it shows the dependency chain.

`build → test → deploy`
- build runs first
- test starts only if build succeeds
- deploy starts only if test succeeds

The needs: keyword is what creates the dependency chain.

```yaml
name: Multi Job Workflow

on:
  push:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Build Step
        run: echo "Building the app"

  test:
    runs-on: ubuntu-latest
    needs: build # ← waits for build to succeed

    steps:
      - name: Test Step
        run: echo "Running tests"

  deploy:
    runs-on: ubuntu-latest
    needs: test # ← waits for test to succeed

    steps:
      - name: Deploy Step
        run: echo "Deploying application"
```

---

### Task 2: Environment Variables
In a new workflow, use environment variables at 3 levels:
1. **Workflow level** — `APP_NAME: myapp`
2. **Job level** — `ENVIRONMENT: staging`
3. **Step level** — `VERSION: 1.0.0`

Print all three in a single step and verify each is accessible.

Then use a **GitHub context variable** — print the commit SHA and the actor (who triggered the run).

<img width="1891" height="586" alt="image" src="https://github.com/user-attachments/assets/cc922a38-852e-4ef5-9741-78ef85341f93" />

<img width="1920" height="1662" alt="image" src="https://github.com/user-attachments/assets/331417ff-57ae-4ce0-a8f2-94fed9af6bd0" />


```yaml
name: Environment Variables

on:
  push:

# Workflow-level environment variable
# ← Available to ALL jobs and ALL steps
env:
  APP_NAME: myapp

jobs:
  env-demo:
    runs-on: ubuntu-latest

    # Job-level environment variable
    # ← Available to ALL steps inside this job
    env:
      ENVIRONMENT: staging

    steps:

      - name: Print All Environment Variables

        # Step-level environment variable
        # ← Available ONLY inside this step
        env:
          VERSION: 1.0.0

        run: |
          echo "Workflow level env: $APP_NAME"
          echo "Job level env: $ENVIRONMENT"
          echo "Step level env: $VERSION"

          # GitHub Context Variables
          echo "Commit SHA: ${{ github.sha }}"
          echo "Actor: ${{ github.actor }}"

      - name: Print Variables Again

        # Step-level variable again
        # ← Must be redefined if needed in another step
        env:
          VERSION: 1.0.0

        run: |
          echo "App Name: $APP_NAME"        # ✅ workflow scope works
          echo "Environment: $ENVIRONMENT" # ✅ job scope works
          echo "Version: $VERSION"         # ✅ step scope works

      - name: Print GitHub Context Variables
        run: |
          echo "Commit SHA: ${{ github.sha }}"
          echo "Triggered By: ${{ github.actor }}"

      - name: Next Step
        run: |
          echo $APP_NAME      # ✅ works (workflow scope)
          echo $ENVIRONMENT   # ✅ works (job scope)
          echo $VERSION       # ❌ empty (step scope ended)
```

---

### Task 3: Job Outputs
1. Create a job that **sets an output** — e.g., today's date as a string
2. Create a second job that **reads that output** and prints it
3. Pass the value using `outputs:` and `needs.<job>.outputs.<name>`


<img width="1159" height="366" alt="image" src="https://github.com/user-attachments/assets/4d91e0ae-fed4-493e-a9d3-d248e16da930" />

<img width="1023" height="595" alt="image" src="https://github.com/user-attachments/assets/6d66ca88-5e30-4c55-aed1-f08d015315f8" />


Why would you pass outputs between jobs?
You pass outputs between jobs when:

- One job generates information another job needs
- Build artifacts, version numbers, tags, or deployment URLs must be shared
- Jobs run on separate runners and cannot directly share shell variables
- Each job runs separately, so Job 2 cannot see what Job 1 created.
- Outputs are used to pass that result from Job 1 to Job 2.

Example:

- Job 1 – Build Docker image
    - This job builds the image and creates a tag for example:myapp:1.0.0

- Job 2 – Push image to registry
    - This job must know which image tag was created so it can push the correct image.

- Job 3 – Deploy the app
    - The deployment job also needs the same tag myapp:1.0.0 to deploy that exact image.

Why pass outputs?
    - The tag created in Job 1 is passed as an output so the other jobs know exactly which Docker image to use.

Outputs allow one job to send data to another job.

Example:

```yaml
outputs:
  today: ${{ steps.date_step.outputs.today }}
```
Access output in another job:

```yaml
${{ needs.generate-date.outputs.today }}
```
Outputs are useful for:

- Sharing generated values
- Deployment information
- Build versions
- Dynamic configuration

```yaml
name: Job Outputs

on:
  push:
    branches:
      - main
      
jobs:
  generate-date:
    runs-on: ubuntu-latest

    outputs:
      today: ${{ steps.date_step.outputs.today }}

    steps:
      - name: Generate Date
        id: date_step  # Step ID used to reference its output
        run: echo "today=$(date)" >> $GITHUB_OUTPUT  # This creates a step output called 'today' with the current date

  use-date:
    runs-on: ubuntu-latest
    needs: generate-date  # This job depends on the 'generate-date' job

    steps:
      - name: Print Date
        run: |
          echo "Date from previous job:"
          echo "Today's date is: ${{ needs.generate-date.outputs.today }}"  # Access the output from the 'date' job using: needs.<job_id>.outputs.<job_output_name>
```

---

### Task 4: Conditionals
In a workflow, add:
1. A step that only runs when the branch is `main`
2. A step that only runs when the previous step **failed**
3. A job that only runs on **push** events, not on pull requests
4. A step with `continue-on-error: true` — what does this do?

Example:

`if: github.ref == 'refs/heads/main'`

Conditionals control whether:
- A job runs
- A step runs

Useful functions:
- success()
- failure()
- always()


### What does `continue-on-error: true` do?

`continue-on-error: true` allows the workflow to continue even if a step fails.

Without it:
- The job stops immediately when a step fails.

With it:
- The workflow continues running the remaining steps.

 <img width="1447" height="664" alt="image" src="https://github.com/user-attachments/assets/e6bd61b7-a03d-4c1c-ae92-127915da1e19" />

<img width="553" height="376" alt="image" src="https://github.com/user-attachments/assets/e9e0c6d5-0e17-414e-9785-50fbe9d8f764" />

<img width="1920" height="1787" alt="image" src="https://github.com/user-attachments/assets/8bfd055f-c56e-401b-96f8-14e3612a4ea2" />

```yaml
name: Conditionals Demo

on:
  # Trigger workflow on push events
  push:

    # Run only when pushing to main branch
    branches: [main]

  # Trigger workflow on pull request events
  pull_request:

    # Run PR workflow only for main branch
    branches: [main]

jobs:

  # Job runs ONLY for push events
  # ← Skips execution during pull_request events
  conditional-push-only-job:
    runs-on: ubuntu-latest

    # Job-level conditional
    # ← Executes only if event type is push
    if: github.event_name == 'push'

    steps:

      # Simple confirmation step
      - name: Confirm this is a push event
        run:  |
          echo "This job only runs on push — event was: ${{ github.event_name }}"

  # Main demo job for conditionals
  conditionals-demo:
    runs-on: ubuntu-latest

    steps:

      # Default step
      # ← Runs every time
      - name: Always runs
        run: echo "This step always runs regardless of branch or event"

      # Step-level conditional
      # ← Runs only when branch is main
      - name: Run only on main branch
        if: github.ref == 'refs/heads/main'
        run: echo "This runs only on main branch — ${{ github.ref }}"

      # Opposite branch condition
      # ← Runs only on non-main branches
      - name: Run only on non-main branches
        if: github.ref != 'refs/heads/main'
        run: echo "On feature branch — ${{ github.ref }} (not main)"

      # Intentional failure step
      # ← Step fails but workflow continues
      - name: Intentional Failure Step (continue-on-error)
        run: exit 1

        # Prevents workflow from stopping on failure
        continue-on-error: true

      # Another risky step with step ID
      # ← ID allows checking the step outcome later
      - name: Intentionally failing step (continue-on-error)

        # Step ID used for referencing outputs/outcome
        id: risky-step

        # Continue workflow even if this step fails
        continue-on-error: true

        run: |
          echo "Attempting risky operation..."
          exit 1

      # Runs when ANY previous step failed
      # ← failure() checks overall previous step status
      - name: Run when previous step failed
        if: failure()

        run: echo "Previous step failed - Job continued because of continue-on-error"

      # Step-specific failure check
      # ← Runs only if risky-step failed
      - name: Run only when risky-step failed
        if: steps.risky-step.outcome == 'failure'

        run: |
          echo "risky-step failed — running recovery/notification step"
          echo "Outcome was: ${{ steps.risky-step.outcome }}"

      # Step-specific success check
      # ← Runs only if risky-step succeeded
      - name: Run only when risky-step succeeded
        if: steps.risky-step.outcome == 'success'

        run: echo "risky-step passed — no recovery needed"

      # Final workflow step
      # ← Proves workflow continued after failures
      - name: Final Step
        run: echo "Workflow continues because continue-on-error is true"
```

---

### Task 5: Putting It Together
Create `.github/workflows/smart-pipeline.yml` that:
1. Triggers on push to any branch
2. Has a `lint` job and a `test` job running in parallel
3. Has a `summary` job that runs after both, prints whether it's a `main` branch push or a feature branch push, and prints the commit message

The `summary` job waits for both `lint` and `test` jobs using `needs: [lint, test]`.

- Add app.py and requirements.txt in https://github.com/malathi-shetty/github-actions-practice/tree/main/Day-43

```yaml
# Workflow name shown in GitHub Actions tab
name: Smart Pipeline

# Workflow trigger
on:

  # Run workflow on every push event
  push:

jobs:

  # Lint Job
  # ← Runs independently in parallel with test job
  lint:

    # GitHub-hosted Ubuntu runner
    runs-on: ubuntu-latest

    steps:

      # Print lint start message
      - name: Lint Code

        run: |
          echo "Running lint checks on branch: ${{ github.ref_name }}"

      # Checkout repository code
      # ← Downloads repo contents into runner
      - name: Checkout Code
        uses: actions/checkout@v4

      # Install Python on runner
      - name: Setup Python
        uses: actions/setup-python@v5

        # Action input parameters
        with:

          # Python version to install
          python-version: "3.12"

      # Install project dependencies
      - name: Install Dependencies

        run: |
          pip install -r Day-43/requirements.txt

      # Run Python linter
      - name: Run Linter

        run: |
          flake8 Day-43/app.py

  # Test Job
  # ← Runs in parallel with lint job
  test:

    # Ubuntu runner
    runs-on: ubuntu-latest

    steps:

      # Print test start message
      - name: Run Tests

        run: |
          echo "Running tests"

      # Checkout source code
      - name: Checkout Code
        uses: actions/checkout@v4

      # Example test step
      - name: Execute Test Suite

        run: |
          echo "Running test suite on branch: ${{ github.ref_name }}"
          echo "✅ All tests passed"

  # Summary Job
  # ← Runs only AFTER lint and test jobs succeed
  summary:

    # Ubuntu runner
    runs-on: ubuntu-latest

    # Job dependency chain
    # ← Waits for lint and test jobs
    needs: [lint, test]

    steps:

      # Print pipeline execution summary
      - name: Print Pipeline Summary

        run: |
          echo "==============================="
          echo "       Pipeline Summary"
          echo "==============================="

          # GitHub context variables
          echo "Commit SHA    : ${{ github.sha }}"
          echo "Triggered by  : ${{ github.actor }}"
          echo "Branch        : ${{ github.ref_name }}"
          echo "Event         : ${{ github.event_name }}"

          # Static status messages
          echo "Lint status   : ✅ passed"
          echo "Test status   : ✅ passed"

      # Branch detection logic
      - name: Branch Information

        run: |

          # Print current branch name
          echo "Branch name: ${{ github.ref_name }}"

          # Conditional branch check
          if [[ "${GITHUB_REF}" == "refs/heads/main" ]]; then

            # Runs for main branch
            echo "This is a main branch push"

          else

            # Runs for feature branches
            echo "This is a feature branch push"

          fi

      # Print latest commit message
      - name: Print Commit Message

        run: |

          # Print heading
          echo "Commit Message:"

          # GitHub commit message context
          echo "${{ github.event.commits[0].message }}"
```

<img width="1606" height="495" alt="image" src="https://github.com/user-attachments/assets/5b9886c3-78a9-4a68-993e-0c9a0f909f5e" />

<img width="1920" height="2581" alt="image" src="https://github.com/user-attachments/assets/a32520be-f216-42e5-9f27-a5a2d677952f" />

<img width="1920" height="1882" alt="image" src="https://github.com/user-attachments/assets/32abba48-6cd5-4c22-8942-61eb4c0af5fc" />

<img width="1920" height="1682" alt="image" src="https://github.com/user-attachments/assets/6e05fbb9-ce8b-4f9e-baf7-511619ffb42f" />


---
