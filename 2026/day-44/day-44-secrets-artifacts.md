# Day 44 – Secrets, Artifacts & Running Real Tests in CI

## Challenge Tasks

### Task 1: GitHub Secrets
1. Go to your repo → Settings → Secrets and Variables → Actions
2. Create a secret called `MY_SECRET_MESSAGE`
3. Create a workflow that reads it and prints: `The secret is set: true` (never print the actual value)
4. Try to print `${{ secrets.MY_SECRET_MESSAGE }}` directly — what does GitHub show?

- GitHub automatically masks detected secret values in logs by replacing them with ***, but masking should never be relied on as the only protection mechanism.

Why this matters:

Sometimes transformed secrets may bypass masking.

Example:
```bash
echo "${TOKEN:0:5}"
```
- GitHub may NOT detect partial secret exposure.


<img width="1920" height="1717" alt="image" src="https://github.com/user-attachments/assets/c4faaf09-fb7b-4ff2-88c6-1998f809eaef" />

<img width="1237" height="636" alt="image" src="https://github.com/user-attachments/assets/e163de4e-8198-46af-aba4-8fdada833697" />

<img width="1236" height="672" alt="image" src="https://github.com/user-attachments/assets/5b22a38b-24d8-4961-8ebc-9c88d8aadb9f" />

<img width="1300" height="538" alt="image" src="https://github.com/user-attachments/assets/9fd48625-1e7a-47e1-9654-c011d33b4b29" />

<img width="1900" height="481" alt="image" src="https://github.com/user-attachments/assets/c2968bed-a868-4df2-a5af-ae0fb088d94c" />

<img width="1920" height="2082" alt="image" src="https://github.com/user-attachments/assets/959f963e-441f-43d3-b91d-f6249823e1a9" />


Why should you never print secrets in CI logs?

- CI logs are public or accessible to many team members.

- Printing secrets can expose API keys, tokens, or passwords.

```yaml
# Human-friendly name shown in GitHub Actions UI
# Think of this like the title of your workflow
name: GitHub Secrets Demo


# Defines WHEN this workflow should run
on:

  # workflow_dispatch means:
  # "Allow me to run this workflow manually from GitHub Actions tab"
  workflow_dispatch:


# jobs = collection of tasks/work units
# A workflow can have one or many jobs
jobs:


  # Name/ID of this specific job
  # GitHub internally uses this identifier
  secrets-job:


    # Defines which machine GitHub should create
    # ubuntu-latest = latest Ubuntu Linux virtual machine
    #
    # Think of this like:
    # "GitHub, give me a fresh temporary Linux computer"
    runs-on: ubuntu-latest


    # steps = list of commands/actions executed one by one
    steps:


      # Step 1
      # Friendly display name shown in logs
      - name: Check if secret exists is set (safe way)


        # run = execute shell commands inside the Linux machine
        #
        # | means:
        # "Multi-line shell script starts below"
        run: |


          # if statement in shell scripting
          #
          # -n means:
          # "Check if string length is NOT zero"
          #
          # Translation:
          # "Does this secret contain any value?"
          #
          # ${{ secrets.MY_SECRET_MESSAGE }}
          # tells GitHub:
          # "Fetch the secret safely from GitHub secret vault"
          #
          # VERY IMPORTANT:
          # Secret value is injected only during runtime
          # It is NOT stored in the YAML file
          if [ -n "${{ secrets.MY_SECRET_MESSAGE }}" ]; then


            # echo prints text to terminal/logs
            #
            # If secret exists → print success message
            echo "The secret is set: true"


          # else runs when condition is false
          #
          # Meaning:
          # "Secret does not exist or is empty"
          else


            # Print false message
            echo "The secret is set: false"


          # fi = closes the if block
          # ("if" spelled backwards)
          fi



      # Step 2
      # Another step inside same job
      - name: Try printing secret directly (GitHub will mask it)


        # Execute shell commands
        run: |


          # Attempt to print secret directly
          #
          # GitHub detects secret values automatically
          # and masks them in logs
          #
          # Real value:
          # hello-devops
          #
          # What logs show:
          # ***
          #
          # This prevents accidental leakage
          echo "Attempting direct print: ${{ secrets.MY_SECRET_MESSAGE }}"


          # Normal echo statement
          # Just informational text
          echo "(GitHub replaces the value with *** in the logs)"
```

---

### Task 2: Use Secrets as Environment Variables
1. Pass a secret to a step as an environment variable
2. Use it in a shell command without ever hardcoding it
3. Add `DOCKER_USERNAME` and `DOCKER_TOKEN` as secrets (you'll need these on Day 45)

<img width="1855" height="934" alt="image" src="https://github.com/user-attachments/assets/c4a082a1-1404-4192-b80f-823df5cf9d84" />

<img width="1147" height="469" alt="image" src="https://github.com/user-attachments/assets/feea2955-0813-4259-9745-9e3b0c159b4b" />

<img width="1920" height="1463" alt="image" src="https://github.com/user-attachments/assets/a3a092e5-b1ca-44e0-8a80-b8cdcc71a819" />

```yaml
# Workflow name shown in GitHub Actions UI
name: Docker Secrets Demo


# Defines when workflow should run
on:

  # Allows manual execution from Actions tab
  workflow_dispatch:


# jobs = collection of tasks
jobs:


  # Job ID
  secrets-job:


    # GitHub creates a temporary Ubuntu Linux VM
    runs-on: ubuntu-latest


    # steps = commands executed one-by-one
    steps:


      # Step name shown in logs
      - name: Use secrets as environment variables


        # env:
        # Creates temporary environment variables
        # available ONLY inside this step
        #
        # Left side  = variable name inside shell
        # Right side = value fetched securely from GitHub Secrets
        env:


          # Demo secret
          SECRET_MSG: ${{ secrets.MY_SECRET_MESSAGE }}


          # Docker username secret
          DOCKER_USER: ${{ secrets.DOCKER_USERNAME }}


          # Docker access token secret
          DOCKER_PASS: ${{ secrets.DOCKER_TOKEN }}


        # Execute shell commands
        run: |


          # Print Docker username safely
          #
          # $DOCKER_USER means:
          # "Read value from environment variable"
          echo "Docker username is: $DOCKER_USER"


          # Print ONLY the length of token
          # Never print actual secret/token value
          #
          # ${#VARIABLE}
          # means:
          # "Length of the string"
          echo "Docker token length: ${#DOCKER_PASS}"


          # Print length of demo secret safely
          echo "Secret message length: ${#SECRET_MSG}"


          # SAFER Docker login method
          #
          # Why safer?
          # Password is passed secretly via stdin
          # instead of appearing directly in command arguments
          #
          # BAD:
          # docker login -u user -p password
          #
          # GOOD:
          # echo "$DOCKER_PASS" | docker login --password-stdin
          echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
```

---

### Task 3: Upload Artifacts
1. Create a step that generates a file — e.g., a test report or a log file
2. Use `actions/upload-artifact` to save it
3. After the workflow runs, download the artifact from the Actions tab


<img width="1414" height="631" alt="image" src="https://github.com/user-attachments/assets/bb7cb85b-e27f-4726-9704-4ab37326eeac" />

<img width="1920" height="1622" alt="image" src="https://github.com/user-attachments/assets/f66a01d9-1a8c-4045-bd82-67a00ec11354" />

<img width="1900" height="856" alt="image" src="https://github.com/user-attachments/assets/4a508de5-1e93-4a3f-ae29-f592f4703e53" />


**Verify:** Can you see and download it from GitHub?

- Yes, I've seen it and downloaded it.

```yaml
# Workflow name shown in GitHub Actions UI
name: Upload Artifacts Demo


# Defines when workflow runs
on:

  # Allows manual trigger from Actions tab
  workflow_dispatch:


# jobs = collection of tasks
jobs:


  # Job ID
  artifact-job:


    # GitHub creates temporary Ubuntu Linux VM
    runs-on: ubuntu-latest


    # Steps run one-by-one
    steps:


      # Step 1:
      # Create a report file
      - name: Generate test report


        # Execute shell commands
        run: |


          # mkdir = make directory
          #
          # -p means:
          # "Create parent folders if missing"
          mkdir -p reports


          # Create file and write first line
          #
          # > means:
          # "Create/overwrite file"
          echo "Tests run: 10 completed successfully" > reports/test-report.txt


          # Append second line into same file
          #
          # >> means:
          # "Append to existing file"
          echo "Status: ALL PASSED" >> reports/test-report.txt


          # Show file contents in logs
          cat reports/test-report.txt



      # Step 2:
      # Upload generated file as artifact
      - name: Upload artifact


        # uses:
        # Runs a prebuilt GitHub Action
        #
        # actions/upload-artifact@v4
        # Official GitHub Action for uploading artifacts
        uses: actions/upload-artifact@v4


        # with:
        # Inputs/configuration for the action
        with:


          # Name shown in GitHub UI
          #
          # github.run_number = unique workflow run number
          #
          # Example:
          # test-report-5
          name: test-report-${{ github.run_number }}


          # File/folder to upload
          path: reports/


          # Keep artifact for 5 days
          retention-days: 5


          # Fail workflow if file/folder missing
          #
          # Prevents silent success when artifact path is wrong
          if-no-files-found: error
```

---

### Task 4: Download Artifacts Between Jobs
1. Job 1: generate a file and upload it as an artifact
2. Job 2: download the artifact from Job 1 and use it (print its contents)


<img width="1312" height="457" alt="image" src="https://github.com/user-attachments/assets/5a0a01a7-b7fd-4632-88fe-bc73b2722827" />

<img width="816" height="105" alt="image" src="https://github.com/user-attachments/assets/7a87035f-6715-4da9-8b72-af7e706e68a3" />

<img width="1920" height="1163" alt="image" src="https://github.com/user-attachments/assets/4f5a7bdc-320e-4060-8236-e3b0982dc4f5" />

<img width="1920" height="1383" alt="image" src="https://github.com/user-attachments/assets/c34ef860-a510-41f4-9d61-246d9cca3a36" />



When would you use artifacts in a real pipeline?
- Test reports
- Build outputs
- Deployment bundles
- Logs for debugging failed pipelines
- Security scan reports
- Sharing files between jobs

```yaml
# Workflow name shown in GitHub Actions UI
name: Artifact Between Jobs Demo


# Defines when workflow runs
on:

  # Manual trigger from Actions tab
  workflow_dispatch:


# jobs = collection of jobs/tasks
jobs:


  # ==========================================
  # JOB 1
  # Build job creates a file
  # ==========================================
  build:


    # Create temporary Ubuntu Linux VM
    runs-on: ubuntu-latest


    # Steps inside build job
    steps:


      # Step 1:
      # Create a file
      - name: Create build file


        # Execute shell commands
        run: |


          # mkdir -p
          # Create folder if missing
          mkdir -p dist


          # Create file with build info
          #
          # > means overwrite/create file
          echo "app-version=1.0.0" > dist/build-info.txt


          # Show file contents in logs
          cat dist/build-info.txt



      # Step 2:
      # Upload file as artifact
      - name: Upload build artifact


        # Official GitHub Action for artifact upload
        uses: actions/upload-artifact@v4


        # Configuration for upload action
        with:


          # Artifact name stored in GitHub
          name: build-output


          # Folder/file to upload
          path: dist/


          # Fail if folder missing
          if-no-files-found: error



  # ==========================================
  # JOB 2
  # Deploy job downloads artifact
  # ==========================================
  deploy:


    # VERY IMPORTANT
    #
    # needs: build
    #
    # Means:
    # "Run deploy job ONLY AFTER build job succeeds"
    needs: build


    # Create another fresh Ubuntu VM
    #
    # This is NOT same machine as build job
    runs-on: ubuntu-latest


    # Steps inside deploy job
    steps:


      # Step 1:
      # Download artifact uploaded by build job
      - name: Download build artifact


        # Official GitHub Action for downloading artifacts
        uses: actions/download-artifact@v4


        # Configuration for download action
        with:


          # Artifact name to download
          #
          # Must exactly match uploaded artifact name
          name: build-output


          # Where to place downloaded files
          path: downloaded-dist/



      # Step 2:
      # Use downloaded file
      - name: Print downloaded file contents


        # Execute shell commands
        run: |


          # Display downloaded file
          cat downloaded-dist/build-info.txt
```




---

### Task 5: Run Real Tests in CI
Take any script from your earlier days (Python or Shell) and run it in CI:
1. Add your script to the `github-actions-practice` repo
2. Write a workflow that:
   - Checks out the code
   - Installs any dependencies needed
   - Runs the script
   - Fails the pipeline if the script exits with a non-zero code
3. Intentionally break the script — verify the pipeline goes red
4. Fix it — verify it goes green again


<img width="1920" height="3899" alt="image" src="https://github.com/user-attachments/assets/a226b483-e946-4175-bf21-3e4f16ce7a5e" />

<img width="1900" height="850" alt="image" src="https://github.com/user-attachments/assets/7c344eeb-4dbd-4092-b606-343e7c867d53" />

```yaml
# Workflow name shown in GitHub UI
name: Run Real Tests


# Defines when workflow runs
on:

  # Manual trigger
  workflow_dispatch:

  # Also run automatically on push
  push:



# jobs = collection of tasks
jobs:


  # Job ID
  test-job:


    # Create Ubuntu Linux VM
    runs-on: ubuntu-latest


    # Steps executed one-by-one
    steps:


      # ==========================================
      # Step 1:
      # Download repository code into VM
      # ==========================================
      - name: Checkout repository


        # Official GitHub Action for cloning repo
        uses: actions/checkout@v4



      # ==========================================
      # Step 2:
      # Install Python
      # ==========================================
      - name: Setup Python


        # Official Python setup action
        uses: actions/setup-python@v5


        # Configuration for setup-python action
        with:


          # Python version to install
          python-version: "3.11"



      # ==========================================
      # Step 3:
      # Run Python test script
      # ==========================================
      - name: Run test suite


        # Execute shell command
        run: python scripts/test_utils.py



      # ==========================================
      # Step 4:
      # Upload test files as artifact
      # ==========================================
      - name: Upload test output as artifact


        # IMPORTANT:
        # always()
        #
        # Means:
        # Run this step whether tests PASS or FAIL
        #
        # Useful for:
        # logs
        # reports
        # debugging
# Run this step even if previous steps fail or workflow is cancelled.
        if: always()


        # Official GitHub Action for artifact upload
        uses: actions/upload-artifact@v4


        # Configuration
        with:


          # Artifact name shown in GitHub UI
          name: test-output


          # Folder/file to upload
          #
          # Your script exists here:
          # scripts/test_utils.py
          #
          # Uploading whole scripts folder
          path: scripts/


          # Keep artifact for 3 days
          retention-days: 3


          # Fail if folder missing
          if-no-files-found: error
```

```bash
#!/usr/bin/env python3

"""
Simple test suite — used in Day 44 CI pipeline.
Tests basic utility functions:
- even/odd check
- palindrome check
- fizzbuzz

Exit code:
0 = all tests pass
non-zero = failure (pipeline goes red)
"""

import sys


# ==============================
# Utility Functions
# ==============================


# Function 1:
# Check if number is even
def is_even(n):

    # % = modulo operator
    #
    # n % 2
    # returns remainder after division by 2
    #
    # Even number => remainder 0
    return n % 2 == 0



# Function 2:
# Check if word is palindrome
#
# palindrome:
# same forward and backward
#
# Examples:
# madam
# racecar
def is_palindrome(s):

    # Beginner improvement:
    #
    # lower()
    # converts uppercase to lowercase
    #
    # replace(" ", "")
    # removes spaces
    #
    # This allows:
    # "A man a plan a canal Panama"
    # to work correctly
    cleaned = s.lower().replace(" ", "")

    # [::-1]
    # reverses string
    return cleaned == cleaned[::-1]



# Function 3:
# FizzBuzz logic
def fizzbuzz(n):

    # Must check divisible by 15 FIRST
    #
    # because:
    # 15 is divisible by BOTH 3 and 5
    if n % 15 == 0:
        return "FizzBuzz"

    elif n % 3 == 0:
        return "Fizz"

    elif n % 5 == 0:
        return "Buzz"

    else:
        return str(n)



# ==============================
# Simple Test Framework
# ==============================


# Track failed tests
failures = 0


# Track passed tests
passed = 0



# check() compares expected vs actual result
def check(test_name, expected, actual):

    # global means:
    # use variables from outside function
    global passed, failures


    # Test PASSED
    if expected == actual:

        # FIXED:
        # f-string syntax
        #
        # WRONG:
        # print(f "hello")
        #
        # CORRECT:
        # print(f"hello")
        print(f"PASS: {test_name}")

        passed += 1


    # Test FAILED
    else:

        print(f"FAIL: {test_name}")

        print(f"Expected: {expected}")

        print(f"Actual: {actual}")

        failures += 1



# ==============================
# Run Tests
# ==============================


print()


# --------------------------------
# Test is_even()
# --------------------------------

check("2 is even", True, is_even(2))

check("5 is even", False, is_even(5))

check("0 is even", True, is_even(0))

check("-4 is even", True, is_even(-4))


print()



# --------------------------------
# Test palindrome
# --------------------------------

check("madam palindrome", True, is_palindrome("madam"))

check("hello palindrome", False, is_palindrome("hello"))

check("'racecar' is palindrome", True, is_palindrome("racecar"))

check("'hello' is not palindrome", False, is_palindrome("hello"))


# NOW this works correctly
# because we improved function
check(
    "'A man a plan a canal Panama'",
    True,
    is_palindrome("A man a plan a canal Panama")
)

check("empty string is palindrome", True, is_palindrome(""))


print()



# --------------------------------
# Test fizzbuzz
# --------------------------------

check("3 => Fizz", "Fizz", fizzbuzz(3))

check("5 => Buzz", "Buzz", fizzbuzz(5))

check("15 => FizzBuzz", "FizzBuzz", fizzbuzz(15))

check("7 => 7", "7", fizzbuzz(7))

check("fizzbuzz(1) == '1'", "1", fizzbuzz(1))

check("fizzbuzz(30) == 'FizzBuzz'", "FizzBuzz", fizzbuzz(30))


print()



# ==============================
# Final Result
# ==============================


# Print summary FIRST
#
# IMPORTANT:
# must happen BEFORE exit()
#
# because exit() stops program immediately
# GitHub Actions automatically fails a step when a command exits with non-zero status.
print(f"=== Results: {passed} passed, {failures} failed ===")



# If any test failed
# exit with non-zero code
if failures > 0:

    print(f"\nFAILED TESTS: {failures}")

    # Non-zero exit code = CI failure
    #
    # GitHub Actions sees:
    # exit(1)
    #
    # and marks pipeline RED ❌
    sys.exit(1)



# If all tests passed
print("\nALL TESTS PASSED")


# exit(0) means success
#
# GitHub Actions marks pipeline GREEN ✅
sys.exit(0)
```
---

### Task 6: Caching
1. Add `actions/cache` to a workflow that installs dependencies
2. Run it twice — observe the time difference
3. Write in your notes: What is being cached and where is it stored?

<img width="1897" height="450" alt="image" src="https://github.com/user-attachments/assets/5ee01eb9-15ab-4d8f-8249-263feeb461e8" />

<img width="1920" height="5936" alt="image" src="https://github.com/user-attachments/assets/d51fcebe-5b51-4a21-b48e-86d2b2d156ce" />

```yaml
# Workflow name shown in GitHub UI
name: Cache Demo


# Defines when workflow runs
on:

  # Also run automatically on push
  push:
    branches:
      - main

  # Manual trigger
  workflow_dispatch:



# jobs = collection of tasks
jobs:


  # Cache pip dependencies
  # Run twice to observe time difference
  cache-job:


    # Create Ubuntu Linux VM
    runs-on: ubuntu-latest


    # Steps execute one-by-one
    steps:


      # ==========================================
      # Step 1:
      # Download repository code
      # ==========================================
      - name: Checkout repository


        # Official GitHub Action
        uses: actions/checkout@v4



      # ==========================================
      # Step 2:
      # Setup Python
      # ==========================================
      - name: Setup Python


        # Official Python setup action
        uses: actions/setup-python@v5


        with:

          # Python version
          python-version: "3.11"



      # ==========================================
      # Step 3:
      # Cache pip downloads
      # ==========================================
      - name: Cache pip packages


        # Official cache action
        uses: actions/cache@v4


        # Step ID
        #
        # Allows referencing outputs later
        id: pip-cache


        with:


          # What to cache
          #
          # ~/.cache/pip
          #
          # pip stores downloaded packages here
          path: ~/.cache/pip


          # Unique cache key
          #
          # Cache invalidates automatically
          # when requirements.txt changes
          key: ${{ runner.os }}-pip-cache-v1


          # Optional fallback key
          restore-keys: |
            ${{ runner.os }}-pip-



      # ==========================================
      # Step 4:
      # Show cache status
      # ==========================================
      - name: Print cache result


        run: |


          # cache-hit output:
          #
          # true  = cache restored
          # false = cache not found
          if [ "${{ steps.pip-cache.outputs.cache-hit }}" = "true" ]; then

            echo "Cache HIT — packages restored from cache (fast path) ✅"

          else

            echo "Cache MISS — downloading packages fresh (will be cached for next run) ❌"

          fi



      # ==========================================
      # Step 5:
      # Install dependencies
      # ==========================================
      - name: Install dependencies


        run: |


          # Upgrade pip
          python -m pip install --upgrade pip


          # Install packages
          pip install requests pytest black flake8



      # ==========================================
      # Step 6:
      # Verify packages installed
      # ==========================================
      - name: Verify packages


        run: |


          # Show installed package details
          pip show requests


          # Show selected installed packages
          pip list | grep -E "requests|pytest|black|flake8"


          echo "✅ All packages ready"



      # ==========================================
      # Step 7:
      # Quick import test
      # ==========================================
      - name: Run a quick check


        run: |


          # Try importing installed packages
          python -c "import requests, pytest; print('Imports OK ✅')"
```

- What is cached: 
Cached content:
Downloaded pip packages stored in ~/.cache/pip
- Stored in GitHub-managed cloud cache storage associated with the repository and cache key.
Because technically:

- not stored permanently on runner VM
- stored remotely by GitHub
- restored into future workflow runners
  
---

**What I learned from Secret Management**

* Store sensitive data (API keys, passwords, access tokens, credentials) in GitHub Actions Secrets instead of hardcoding them in source code.
* Secrets are encrypted, securely injected at runtime, and masked in workflow logs.
* Secret masking is helpful, but it should never be relied on as the only protection mechanism.
* Even partial or transformed secret values can accidentally leak if printed improperly.
* A safer approach is to pass secrets through environment variables and avoid exposing them in logs entirely.
