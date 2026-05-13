
# Day 39 – What is CI/CD?

---

# Why CI/CD Exists

Before CI/CD, software teams deployed applications manually.

As teams and applications grew larger, manual processes started causing major problems:
- deployments became slow,
- bugs reached production,
- developers broke each other’s code,
- and releases became stressful.

CI/CD exists to solve these problems through automation.

---

# What CI/CD Actually Does

CI/CD automates the process of:
1. integrating code changes,
2. testing applications,
3. building software,
4. and deploying updates safely.

Instead of waiting days or weeks to release software, teams can release small changes continuously and confidently.

---

# The Core Goal of CI/CD

CI/CD helps teams:
- detect problems early,
- reduce human error,
- improve software quality,
- speed up releases,
- and make deployments repeatable and reliable.

---

# Why CI/CD Became Necessary

Imagine 5 developers working on the same project.

Without CI/CD:
- code conflicts happen often,
- testing is manual and inconsistent,
- deployments depend on human memory,
- fixing production issues becomes difficult.

As applications scale, manual deployment becomes dangerous.

CI/CD creates a standardized automated workflow so every change follows the same process.

---

# What Happens in a CI/CD Workflow

A typical CI/CD process looks like this:

```text
Developer writes code
        ↓
Code pushed to GitHub
        ↓
Automatic tests run
        ↓
Application builds successfully
        ↓
Docker image/package created
        ↓
Deploy to staging
        ↓
(Optional approval)
        ↓
Deploy to production
```

---

# Simple Explanation of CI/CD

## Continuous Integration (CI)

Developers frequently merge code changes into a shared repository.

Every change is automatically:
- tested,
- validated,
- and checked for errors.

### Goal
Catch problems early.

---

## Continuous Delivery (CD)

After successful testing, the application is automatically prepared for deployment.

The software is always ready to release.

### Goal
Make releases reliable and repeatable.

---

## Continuous Deployment

Every successful change is automatically deployed to production without manual approval.

### Goal
Release updates faster and continuously.

---

# Important Mindset

CI/CD is NOT just a tool.

It is:
- a development practice,
- a workflow philosophy,
- and a culture of automation and fast feedback.

Tools like:
- GitHub Actions
- Jenkins
- GitLab CI/CD
- CircleCI

only help implement the CI/CD process.

---

# Why Pipeline Failures Are Good

A failed pipeline is NOT bad.

It means:
- CI/CD detected a problem early,
- prevented broken code from reaching users,
- and protected production systems.

A failing pipeline is doing its job correctly.

---

# Final Understanding

CI/CD exists because manual software delivery does not scale well.

As teams grow:
- automation becomes essential,
- consistency becomes critical,
- and fast reliable releases become a competitive advantage.

CI/CD helps teams deliver software:
- faster,
- safer,
- and with more confidence.

---

# What CI/CD Means

CI/CD stands for Continuous Integration / Continuous Delivery (or Deployment).

It is a set of engineering practices and automated pipelines that allow software teams to:
- integrate code changes frequently,
- validate them automatically,
- and deliver them to production reliably and repeatedly,
- with minimal manual effort.

Think of CI/CD as an automated assembly line for software.

A car factory doesn't build one car manually from scratch each time — it has a pipeline where parts are added, tested, and inspected at each stage.

CI/CD does the same for code.

---

# Challenge Tasks

# Task 1 – The Problem

Think about a team of 5 developers all pushing code to the same repository and manually deploying to production.

---

# 1. What can go wrong?

Many problems can happen in a manual deployment process:

- One developer’s code may overwrite another developer’s changes
- Bugs may reach production because testing is inconsistent
- Developers may forget deployment steps
- Different environments may have different configurations
- Deployments may fail halfway and leave the application broken
- Rollbacks become difficult during failures
- Human errors increase as deployments become frequent
- Teams waste time fixing deployment issues instead of building features
- Merge conflicts happen when multiple developers push at the same time
- Wrong branch or wrong server may be deployed accidentally
- Important files or configurations may be missed during deployment
- Downtime may happen if broken code reaches production
- Large deployments become risky and difficult to manage

Manual deployments become risky as the team size and codebase grow.

---

## Common Problems in Team-Based Manual Deployments

| Problem | Description |
|----------|-------------|
| **Merge conflicts** | All 5 developers work in isolation for days, then try to merge changes together — creating large conflicts that take hours to resolve |
| **Integration failures** | Developer A’s code works alone, Developer B’s code works alone, but together they break each other silently |
| **Inconsistent environments** | Each developer may use different operating systems, package versions, libraries, or environment variables |
| **Human error in deployment** | Someone deploys the wrong branch, wrong configuration, or wrong server by mistake |
| **No rollback plan** | If deployment fails, recovery requires another manual deployment process |
| **No visibility** | Team members may not know exactly what version is running in production |
| **Slow feedback** | Bugs are discovered days later after developers have already moved on to other work |
| **Fear of deploying** | Teams deploy less frequently because deployments become stressful and risky |

---

# 2. What does "It works on my machine" mean and why is it a real problem?

“It works on my machine” means the application works correctly on the developer’s local computer but fails on another machine or environment.

---

## Why does this happen?

Environments may differ in:
- Operating system
- Installed dependencies
- Package versions
- Environment variables
- Database setup
- Configuration files
- Runtime versions
- Local tools and globally installed packages

---

## Common Causes

- Different OS versions
- Different runtime versions (Node.js, Python, Java, etc.)
- Missing environment variables
- Locally installed global packages not listed in dependencies
- Hardcoded local file paths
- Local databases containing test data that hides bugs
- Different database versions between local and production environments

---

## Why is it a real problem?

This creates:
- inconsistent behavior,
- deployment failures,
- difficult debugging,
- production outages,
- delayed releases,
- and wasted engineering time.

Software must work reliably in all environments — not just on the developer’s laptop.

---

## Real Example

A developer runs the application on:
- macOS,
- Node.js 18,
- PostgreSQL 14,
- and local `.env` settings.

Everything works perfectly.

But production uses:
- Ubuntu 22,
- Node.js 20,
- PostgreSQL 16,
- and different environment variables.

The application suddenly crashes after deployment.

---

## How CI/CD Solves This

CI/CD runs every code change in:
- a clean,
- consistent,
- and controlled environment.

Usually this happens inside:
- Docker containers,
- virtual machines,
- or cloud runners.

This ensures:
- code behaves consistently,
- dependencies are installed correctly,
- and deployment issues are caught before production.

“Works in CI” becomes much closer to:
“Works in production.”

---

# 3. How many times a day can a team safely deploy manually?

Usually only a few times per day — sometimes only once or twice per week depending on complexity.

Manual deployments are:
- slow,
- stressful,
- error-prone,
- difficult to repeat consistently,
- and hard to scale.

As deployment frequency increases, the chance of mistakes also increases.

Without automation, teams cannot safely deploy many times a day.

---

## Deployment Frequency Comparison

| Deployment Method | Safe Frequency |
|-------------------|----------------|
| Manual deployment (copy files, SSH, run scripts) | 1–2 times per week at best |
| Manual deployment with checklist | A few times per week |
| Automated CI/CD pipelines | Dozens or even hundreds of times per day |

---

## Real-World Example

Large technology companies like Amazon deploy to production extremely frequently.

This level of deployment speed is only possible because:
- testing,
- validation,
- infrastructure checks,
- and deployment processes

are fully automated through CI/CD pipelines.

No human manually performs every deployment step.

---

# Task 2 – CI vs CD vs Continuous Deployment

---

# 1. Continuous Integration (CI)

## Definition

Continuous Integration (CI) is the practice of developers frequently merging code changes into a shared repository, often multiple times a day, with every change automatically validated through builds, tests, and quality checks.

Whenever developers push code:
- CI tools like GitHub Actions, Jenkins, GitLab CI/CD, or CircleCI automatically trigger pipelines,
- the application is built and tested,
- and developers receive fast feedback within minutes.

CI helps teams detect problems early before broken code reaches production.

---

## What Happens in CI?

When a developer pushes code or opens a Pull Request (PR):

1. The CI pipeline triggers automatically
2. The latest code is fetched from the shared repository
3. The application is compiled or built
4. Unit tests run
5. Integration tests run
6. Linting and code-style checks execute
7. Security and dependency scans may run
8. Results are reported back immediately

---

## How Often Does CI Happen?

CI usually runs:
- every time code is pushed,
- every time a PR is opened or updated,
- and often multiple times per day.

The goal is continuous validation of code changes.

---

## What Does CI Catch?

CI helps catch:
- build failures,
- syntax errors,
- failed tests,
- dependency issues,
- merge conflicts,
- integration problems,
- style/lint violations,
- and security vulnerabilities in dependencies.

CI answers the question:

> “Does the code work correctly and safely integrate with the existing codebase?”

---

## Main Goal of CI

The primary goal of CI is:

> detect problems early before they reach production.

---

## Real-World CI Examples

### Example 1 — GitHub Actions

A developer pushes code to GitHub.

GitHub Actions automatically:
- installs dependencies,
- runs unit tests,
- checks formatting,
- and verifies the application builds successfully.

If any test fails, the pull request is blocked from merging.

---

### Example 2 — FastAPI

A developer on the [FastAPI GitHub Repository](https://github.com/fastapi/fastapi.git) opens a Pull Request.

GitHub Actions automatically runs:
- the full test suite,
- across multiple Python versions,
- on macOS, Windows, and Ubuntu environments simultaneously.

If tests fail on any platform or Python version, the PR cannot be merged.

---

### Example 3 — Hotstar

Developers push code daily to the shared repository.

Jenkins automatically:
- builds the application,
- runs tests for video playback,
- validates live score features,
- and checks UI functionality.

Any failing test immediately alerts developers so issues are fixed before deployment.

---

# 2. Continuous Delivery (CD)

## Definition

Continuous Delivery extends Continuous Integration by automatically preparing validated code for deployment after all tests pass.

The software is always kept in a deployable and release-ready state.

Unlike CI, Continuous Delivery focuses not only on testing code, but also on:
- packaging,
- release preparation,
- deployment automation,
- and deployment readiness.

Production deployment usually still requires manual approval.

---

## What Happens in Continuous Delivery?

After CI succeeds:

1. The application is packaged
2. A deployable artifact is created
   - Docker image
   - JAR file
   - binary
   - ZIP package
3. Artifacts are stored in a registry or artifact repository
4. The application is automatically deployed to staging or QA
5. Acceptance and smoke tests run
6. The release becomes production-ready

The software is now ready to deploy anytime.

---

## What Does “Delivery” Mean?

“Delivery” means the software is:
- tested,
- validated,
- packaged,
- versioned,
- and ready to deploy to production at any moment.

However:
- a human usually decides when production deployment happens,
- often based on business timing,
- approvals,
- maintenance windows,
- or compliance requirements.

---

## How Continuous Delivery Differs from CI

### Continuous Integration (CI)
Focuses on:
- integrating code changes,
- validating code quality,
- and running automated tests.

CI answers:

> “Does the code work?”

---

### Continuous Delivery
Focuses on:
- preparing validated software for deployment,
- ensuring reliable releases,
- and keeping the application release-ready at all times.

Continuous Delivery answers:

> “Is the application ready to release?”

---

## Main Idea of Continuous Delivery

CI = integrate and test automatically

Continuous Delivery = CI + automatically prepare a deployable release

The keyword is:

> “delivery”

The package reaches the door, but a human decides when to open it.

---

## Real-World Continuous Delivery Examples

### Example 1 — Netflix

After CI tests pass:
- Netflix’s pipeline deploys updates automatically to staging environments,
- engineers validate changes,
- and production releases happen after approval.

This allows Netflix to safely ship features quickly and reliably.

---

### Example 2 — Fintech Company

A fintech company uses Continuous Delivery because production deployments require:
- senior engineer approval,
- scheduled maintenance windows,
- and compliance validation.

The entire pipeline runs automatically until staging.

Production deployment still requires a sign-off.

---

### Example 3 — Docker-Based Delivery Pipeline

After developers push code:
- tests run automatically,
- Docker images are built,
- artifacts are stored,
- and the application deploys automatically to staging.

A release manager later clicks:

> “Deploy to Production”

after final verification.

---

# 3. Continuous Deployment

## Definition

Continuous Deployment goes one step further than Continuous Delivery.

Every code change that successfully passes:
- automated tests,
- validation checks,
- security scans,
- and deployment verification

is automatically deployed directly to production without human intervention.

There is no manual approval step.

---

## What Happens in Continuous Deployment?

Once the pipeline validates a change:

1. The application automatically deploys to production
2. Production smoke tests run
3. Monitoring systems check:
   - latency,
   - error rates,
   - CPU usage,
   - crashes,
   - and service health
4. If anomalies are detected:
   - rollback mechanisms may automatically restore the previous version

The pipeline itself decides when releases happen.

---

## How Continuous Deployment Differs from Continuous Delivery

### Continuous Delivery
- production deployment requires manual approval,
- a human decides when to release.

---

### Continuous Deployment
- production deployment happens automatically,
- no engineer manually triggers deployment after tests pass.

---

## When Teams Use Continuous Deployment

Teams typically use Continuous Deployment when they have:
- strong automated testing,
- high test coverage,
- reliable monitoring,
- fast rollback systems,
- feature flags,
- canary deployments,
- and confidence in pipeline stability.

It is common in:
- SaaS platforms,
- cloud-native systems,
- web applications,
- large technology companies,
- and fast-moving startup environments.

Continuous Deployment is especially useful where:
- rapid iteration,
- fast feedback,
- and high deployment frequency

provide competitive advantages.

---

## Real-World Continuous Deployment Examples

### Example 1 — Amazon

Amazon deploys updates extremely frequently using highly automated deployment systems.

Every successful build can move through:
- testing,
- validation,
- deployment,
- and monitoring

with minimal manual intervention.

---

### Example 2 — GitHub

[GitHub](https://github.com) uses highly automated deployment workflows.

When engineers merge changes:
- code flows automatically through tests,
- builds,
- deployment pipelines,
- and production rollout systems.

Deployments can happen many times per day.

---

### Example 3 — Modern SaaS Platforms

Many modern SaaS companies automatically deploy:
- bug fixes,
- UI improvements,
- configuration changes,
- and backend updates

immediately after all pipeline checks pass.

Users receive updates continuously without waiting for scheduled releases.

---

# Full CI/CD Flow Diagram

```text
👨‍💻 Developer writes code & pushes a commit
        │
        ▼
════════════════════════════════════════════════════════════════════
  CONTINUOUS INTEGRATION (CI)
  "Does the code work at all?"
════════════════════════════════════════════════════════════════════
        │
        ├──▶ Fetch latest code from shared repository
        │
        ├──▶ Build / Compile application
        │         └─ Does the application build successfully?
        │
        ├──▶ Run Unit Tests
        │         └─ Do individual functions behave correctly?
        │
        ├──▶ Run Integration Tests
        │         └─ Do system components work together?
        │
        ├──▶ Run Lint / Style Checks
        │         └─ Is the code clean and consistent?
        │
        ├──▶ Run Security & Dependency Scans
        │         └─ Any known vulnerabilities?
        │
        └──▶ Generate Fast Feedback

RESULT:
✅ All checks pass → Code is safe to merge
❌ Any check fails → Developer is notified immediately

        │
        ▼
════════════════════════════════════════════════════════════════════
  CONTINUOUS DELIVERY (CD)
  "Is the software always ready to ship?"
════════════════════════════════════════════════════════════════════
        │
        ├──▶ Package application
        │         └─ Create Docker image / artifact / binary
        │
        ├──▶ Store artifacts in registry
        │
        ├──▶ Deploy automatically to staging / QA
        │
        ├──▶ Run smoke & acceptance tests
        │
        └──▶ Keep release ready for production

RESULT:
✅ Release is production-ready
🧑 Human approval usually required for production deployment

        │
        ▼
════════════════════════════════════════════════════════════════════
  CONTINUOUS DEPLOYMENT
  "Every validated change goes live automatically"
════════════════════════════════════════════════════════════════════
        │
        ├──▶ Automatically deploy to production
        │
        ├──▶ Run production smoke tests
        │
        ├──▶ Monitor metrics & health
        │         └─ Error rates, crashes, latency, CPU usage
        │
        └──▶ Automatic rollback if problems are detected

RESULT:
✅ New version becomes live automatically
❌ Failure detected → Rollback to previous stable release
```

---

# Quick Comparison Table

| Feature | Continuous Integration | Continuous Delivery | Continuous Deployment |
|----------|------------------------|---------------------|-----------------------|
| Main Focus | Code integration & testing | Deployment readiness | Fully automated production releases |
| Trigger Frequency | Multiple times daily | After successful CI | After successful delivery pipeline |
| Production Deployment | No | Manual approval required | Automatic |
| Goal | Catch problems early | Keep software release-ready | Release changes continuously |
| Human Involvement | Developers commit code | Humans approve production release | Minimal or none |
| Example Action | Run tests & build application | Deploy to staging | Auto deploy to production |
| Ends At | “Merge is safe” | “Release is ready” | “Users already have the update” |

---

# Simple Analogy

Think of CI/CD like an automated factory assembly line.

## Continuous Integration
Checks whether all parts fit together correctly.

---

## Continuous Delivery
Packages the finished product and keeps it ready for shipping.

---

## Continuous Deployment
Automatically ships the finished product to customers immediately after inspection passes.

---

# Task 3 – Pipeline Anatomy

A CI/CD pipeline is made up of several building blocks.  
Each part has a specific responsibility in automating the software delivery process.

---

# 1. Trigger

## Definition

A Trigger is the event that starts a CI/CD pipeline automatically.

It tells the CI/CD system:

> “Something changed — start the workflow.”

Without a trigger, the pipeline would never run.

A trigger can start the pipeline when:
- code is pushed,
- a Pull Request (PR) is opened,
- a scheduled time occurs,
- or a manual action is performed.

---

## Common Pipeline Triggers

- Git push
- Pull Request (PR)
- Merge to main branch
- Scheduled cron job
- Manual button click
- Tag or release creation
- Webhook event

---

## Example

A developer pushes code to GitHub.

GitHub Actions detects the push event and automatically starts the pipeline.

---

## Example GitHub Actions Trigger

```yaml
on:
  push:
    branches: [main, develop]

  pull_request:

  schedule:
    - cron: "0 2 * * *"

  workflow_dispatch:

  release:
    types: [published]
```

---

## Trigger Explanation

| Trigger Type | Purpose |
|---------------|----------|
| `push` | Starts pipeline when code is pushed |
| `pull_request` | Runs validation when PRs are opened or updated |
| `schedule` | Runs jobs automatically at scheduled times |
| `workflow_dispatch` | Allows manual pipeline execution |
| `release` | Triggers workflow when a release is published |

---

# 2. Stage

## Definition

A Stage is a logical phase in the pipeline that groups related work together.

Stages help organize the workflow into clear sections such as:
- Build
- Test
- Security
- Package
- Deploy

Each stage focuses on one major objective.

Stages usually run sequentially:
- the next stage begins only if the previous stage succeeds.

---

## Why Stages Matter

Stages:
- improve readability,
- organize workflow execution,
- separate responsibilities,
- and help teams isolate failures quickly.

Pipelines usually move stage-by-stage in order.

---

## Common Pipeline Stages

| Stage | Purpose |
|--------|----------|
| Build | Compile code, install dependencies, build Docker image |
| Test | Run unit, integration, and end-to-end tests |
| Security | Dependency scanning, SAST, vulnerability scanning |
| Package | Create release artifacts or push images to registry |
| Deploy-Staging | Deploy application to staging environment |
| Deploy-Production | Deploy application to production |

---

## Example

A pipeline may contain:

1. Build Stage
2. Test Stage
3. Deploy Stage

The deploy stage usually runs only if previous stages succeed.

---

# 3. Job

## Definition

A Job is a unit of work inside a stage.

Each job performs a specific task.

A stage may contain:
- one job,
- or multiple jobs running in parallel.

Jobs are usually independent and may execute on separate runners.

---

## Important Characteristics of Jobs

- Each job runs in its own isolated environment
- Jobs within the same stage can run in parallel
- Jobs can depend on other jobs
- Every job usually gets a fresh runner

---

## Examples of Jobs

Inside a Test Stage:
- Run unit tests
- Run integration tests
- Run lint checks

Inside a Build Stage:
- Build Docker image
- Compile application
- Package artifacts

---

## Example GitHub Actions Jobs

```yaml
jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - run: npm test

  lint:
    runs-on: ubuntu-latest
    steps:
      - run: npm run lint

  deploy:
    needs: [unit-tests, lint]
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

---

## Job Explanation

| Job | Purpose |
|-----|----------|
| `unit-tests` | Runs automated unit tests |
| `lint` | Checks coding style and formatting |
| `deploy` | Waits for successful jobs before deployment |

---

# 4. Step

## Definition

A Step is a single command or action inside a job.

Steps are the smallest executable units in a pipeline.

A job is made up of multiple sequential steps.

Steps run one after another in order.

---

## Examples of Steps

Inside a job:
- Checkout code
- Install dependencies
- Run `npm install`
- Execute `npm test`
- Run `docker build`
- Upload artifacts

---

## Example Flow

```text
Job: Run Tests
   ├── Step 1: Checkout code
   ├── Step 2: Install dependencies
   ├── Step 3: Run unit tests
   └── Step 4: Upload test reports
```

---

## Example GitHub Actions Steps

```yaml
steps:
  - name: Checkout code
    uses: actions/checkout@v4

  - name: Install dependencies
    run: npm ci

  - name: Run tests
    run: npm test

  - name: Build Docker image
    run: docker build -t myapp:${{ github.sha }} .
```

---

## Step Explanation

| Step | Purpose |
|------|----------|
| Checkout code | Downloads repository source code |
| Install dependencies | Installs required packages |
| Run tests | Executes automated tests |
| Build Docker image | Creates deployable container image |

---

# 5. Runner

## Definition

A Runner is the machine or environment that executes pipeline jobs.

It provides:
- CPU,
- memory,
- operating system,
- networking,
- and runtime environment

needed to execute the pipeline.

Runners may be:
- virtual machines,
- containers,
- physical servers,
- or Kubernetes-based environments.

---

## Why Runners Matter

Runners provide:
- isolated execution,
- reproducibility,
- and consistency.

Most CI/CD systems use fresh runners for every job so no leftover state from previous runs exists.

This helps avoid:
- hidden bugs,
- stale files,
- cached failures,
- and inconsistent behavior.

---

## Types of Runners

### Hosted Runners

Managed by CI/CD platforms such as:
- GitHub Actions,
- GitLab CI/CD,
- CircleCI.

Examples:
- `ubuntu-latest`
- `windows-latest`
- `macos-latest`

---

### Self-Hosted Runners

Managed by organizations using:
- local servers,
- virtual machines,
- cloud instances,
- or Kubernetes clusters.

---

## Runner Comparison Table

| Runner Type | Description |
|--------------|-------------|
| `ubuntu-latest` | GitHub-hosted Ubuntu VM |
| `windows-latest` | GitHub-hosted Windows VM |
| `macos-latest` | GitHub-hosted macOS VM |
| Self-hosted | Organization-managed infrastructure |

---

## Example

GitHub Actions may run jobs on:
- Ubuntu Linux,
- Windows,
- or macOS virtual machines.

---

# 6. Artifact

## Definition

An Artifact is a file or output produced by a pipeline job.

Artifacts are:
- stored,
- shared,
- downloaded,
- or reused

between stages and jobs.

Since jobs often run on separate runners, artifacts allow outputs from one job to be passed to another.

---

## Common Artifacts

- Docker images
- Compiled binaries
- JAR/WAR files
- ZIP packages
- Build outputs
- Test reports
- Coverage reports
- Log files
- Frontend `dist/` folders

---

## Why Artifacts Matter

Artifacts help pipelines:
- separate build and deployment environments,
- reuse outputs safely,
- avoid rebuilding repeatedly,
- and preserve deployment packages.

---

## Example

A build job creates:
- a Docker image,
- or a compiled application package.

The deploy stage later downloads and deploys that artifact.

---

## Artifact Upload & Download Example

```yaml
# Upload artifact
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: ./dist/

# Download artifact
- uses: actions/download-artifact@v4
  with:
    name: build-output
```

---

# Complete Pipeline Example

```text
PIPELINE
│
├── Trigger
│     └── Developer pushes code to GitHub
│
├── Stage: Build
│   │
│   └── Job: compile
│       ├── Step: checkout code
│       ├── Step: install dependencies
│       ├── Step: compile application
│       └── Step: build Docker image / artifact
│
├── Stage: Test
│   │
│   ├── Job: unit-tests
│   │   ├── Step: run unit tests
│   │   └── Step: upload coverage report
│   │
│   └── Job: lint
│       └── Step: run linter
│
├── Stage: Deploy
│   │
│   └── Job: deploy-staging
│       ├── Step: download build artifact
│       ├── Step: push image to registry
│       └── Step: deploy to staging server
│
├── Runner
│     └── Ubuntu virtual machine executes jobs
│
└── Artifact
      └── Docker image or compiled application package
```

---

# Quick Summary Table

| Component | What It Does |
|------------|---------------|
| Trigger | Starts the pipeline automatically |
| Stage | Logical phase like build, test, security, deploy |
| Job | Unit of work inside a stage |
| Step | Single command or action inside a job |
| Runner | Machine/environment that executes jobs |
| Artifact | Output produced and reused between jobs |

---

# Final Understanding

A CI/CD pipeline works like an automated workflow system.

- Triggers start the pipeline
- Stages organize the workflow
- Jobs perform specific tasks
- Steps execute commands
- Runners provide execution environments
- Artifacts carry outputs between stages

Together, these components automate:
- testing,
- building,
- packaging,
- validation,
- and deployment

in a reliable, repeatable, and scalable way.

---

### Task 4: Draw a Pipeline
Draw a CI/CD pipeline for this scenario:

## Scenario
A developer pushes code to GitHub.  
The application is tested, built into a Docker image, and deployed to a staging server.



# Pipeline Flow Summary

| Stage | Purpose |
|--------|----------|
| Trigger | Starts pipeline when code is pushed |
| Test | Validates code using tests and lint checks |
| Build | Creates Docker image artifact |
| Deploy | Deploys application to staging server |

---

# Key Components Used

| Component | Example |
|------------|----------|
| Trigger | GitHub Push Event |
| Runner | Ubuntu GitHub Actions Runner |
| Artifact | Docker Image |
| Deployment Target | Staging Server |

---

# Final Understanding

This pipeline automates the complete workflow:

1. Developer pushes code
2. CI pipeline validates the application
3. Docker image is built automatically
4. The application is deployed safely to staging

This ensures:
- faster deployments,
- fewer manual errors,
- consistent environments,
- and reliable software delivery.

---

# CI/CD Pipeline Diagram

```
┌──────────────────────────────────────────────────────────────────────────────┐
│           MODERN END-TO-END CI/CD AUTOMATION PIPELINE                      │
│              Developer Workflow • Automated Delivery                       │
└──────────────────────────────────────────────────────────────────────────────┘


                         ┌────────────────────────────┐
                         │  PIPELINE STAGES OVERVIEW │
                         ├────────────────────────────┤
                         │ 1. Pipeline Trigger        │
                         │    Event Detection & Init  │
                         │                            │
                         │ 2. Test & Validation       │
                         │    Quality Checks          │
                         │                            │
                         │ 3. Build Stage             │
                         │    Build & Registry Push   │
                         │                            │
                         │ 4. Deploy Stage            │
                         │    Deploy & Verification   │
                         │                            │
                         │ 5. Staging Server          │
                         │    Running Containers      │
                         │                            │
                         │ 6. Live Staging Env        │
                         │    Release Verification    │
                         └────────────────────────────┘


 Developer
         │
         ▼
 git push / open PR
          │
          ▼
┌──────────────────────┐
│    GIT PLATFORM      │
│   GitHub / GitLab    │
│     repos & PRs      │
└──────────────────────┘
          │
          │ webhook trigger
          ▼
┌──────────────────────┐
│      CI SERVER       │
│ GitHub Actions /     │
│ Jenkins automation   │
└──────────────────────┘
          │
          │ initialize workflows
          ▼


╔══════════════════════════════════════════════════════════════════════════════╗
║ 1. PIPELINE TRIGGER                                                        ║
║    Pipeline Initialization                                                 ║
╚══════════════════════════════════════════════════════════════════════════════╝

┌──────────────────────────────┐   ┌──────────────────────────────┐
│ Job: push-trigger            │   │ Job: pull-request-trigger   │
│ Event: push to main branch   │   │ Event: PR opened/synced     │
│                              │   │                              │
│ Actions:                     │   │ Actions:                     │
│ • detect git push            │   │ • validate PR event          │
│ • start CI pipeline          │   │ • load workflow config       │
│ • allocate runner            │   │ • initialize CI environment  │
│ • checkout repository        │   │ • start pipeline jobs        │
└──────────────────────────────┘   └──────────────────────────────┘

          repository event detected
                         │
                         ▼


╔══════════════════════════════════════════════════════════════════════════════╗
║ 2. TEST & VALIDATION STAGE                                                 ║
║    Quality Checks & Validation                                             ║
╚══════════════════════════════════════════════════════════════════════════════╝

                     ─── parallel test jobs ───

┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐
│ Job: unit-tests      │ │ Job: coverage-upload │ │ Job: lint            │
│ Runner: ubuntu       │ │ Runner: ubuntu       │ │ Runner: ubuntu       │
│                      │ │                      │ │                      │
│ Steps:               │ │ Steps:               │ │ Steps:               │
│ • checkout repo      │ │ • collect coverage   │ │ • checkout repo      │
│ • setup node env     │ │ • compress artifact  │ │ • install deps       │
│ • install packages   │ │ • upload report      │ │ • run eslint         │
│ • run npm test       │ │ • store artifact     │ │ • generate report    │
│ • upload coverage    │ │                      │ │                      │
└──────────────────────┘ └──────────────────────┘ └──────────────────────┘

                 all checks must pass
                         │
                         ▼


╔══════════════════════════════════════════════════════════════════════════════╗
║ 3. BUILD STAGE                                                             ║
║    Container Build & Registry Push                                         ║
╚══════════════════════════════════════════════════════════════════════════════╝

                    ─── build workflow jobs ───

┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐
│ Job: docker-build    │ │ Job: docker-tag      │ │ Job: docker-push     │
│ Runner: ubuntu       │ │ Runner: ubuntu       │ │ Runner: ubuntu       │
│                      │ │                      │ │                      │
│ • setup docker build │ │ • tag image SHA      │ │ • login registry     │
│ • prepare context    │ │ • tag latest         │ │ • push SHA image     │
│ • docker build       │ │ • verify tags        │ │ • push latest image  │
│ • validate image     │ │ • prepare metadata   │ │ • verify upload      │
└──────────────────────┘ └──────────────────────┘ └──────────────────────┘

                         │
                         ▼

                 ┌──────────────────────┐
                 │ CONTAINER REGISTRY   │
                 │ Docker Hub / AWS ECR │
                 │ centralized storage  │
                 └──────────────────────┘

                         │ deployment image available
                         ▼


╔══════════════════════════════════════════════════════════════════════════════╗
║ 4. DEPLOY STAGE                                                            ║
║    Deploy to Staging & Verification                                        ║
╚══════════════════════════════════════════════════════════════════════════════╝

┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐
│ Job: ssh-connect     │ │ Job: docker-pull     │ │ Job: compose-deploy  │
│                      │ │                      │ │                      │
│ • load SSH key       │ │ • authenticate       │ │ • update image tag   │
│ • connect staging    │ │ • pull SHA image     │ │ • compose up -d      │
│ • verify access      │ │ • verify download    │ │ • verify services    │
│ • init deployment    │ │ • remove old images  │ │ • recreate containers│
└──────────────────────┘ └──────────────────────┘ └──────────────────────┘

                ┌──────────────────────┐
                │ Job: smoke-test      │
                │                      │
                │ • wait for startup   │
                │ • call health API    │
                │ • validate response  │
                │ • verify container   │
                │ • generate report    │
                └──────────────────────┘

                         │
                         ▼


╔══════════════════════════════════════════════════════════════════════════════╗
║ 5. STAGING SERVER                                                          ║
║    Running Containers                                                      ║
╚══════════════════════════════════════════════════════════════════════════════╝

 ✓ staging application live
 ✓ QA / team review
 ✓ monitor logs & metrics
 ✓ user acceptance testing
 ✓ optional production approval

                         │
                         ▼


╔══════════════════════════════════════════════════════════════════════════════╗
║ 6. LIVE STAGING ENVIRONMENT                                                ║
╚══════════════════════════════════════════════════════════════════════════════╝

 LIVE Staging Application
 ────────────────────────────────────────────────────────────────────────────
 • application accessible
 • performance monitoring
 • user validation complete

                         │ deployment verified
                         ▼

                    🚀 PRODUCTION RELEASE READY 🚀

 • all checks completed
 • code tested, built & deployed
 • ready for production release


───────────────────────────────────────────────────────────────────────────────
 Reliable Automation • Faster Delivery • Consistent Quality
 Secure Deployment • Scalable Workflow • Team Collaboration
───────────────────────────────────────────────────────────────────────────────
```

---

### Task 5: Explore in the Wild
1. Open any popular open-source repo on GitHub (Kubernetes, React, FastAPI — pick one you know)

I explored the [FastAPI](https://github.com/fastapi/fastapi.git) GitHub Repository
 and examined its GitHub Actions workflows inside the `.github/workflows/` directory.

A GitHub Actions workflow file usually contains:

- triggers (`on:`),
- jobs,
- steps,
- runners,
- environment variables,
- secrets,
- and automation tasks.

GitHub Actions workflows are stored in:

`.github/workflows/`

2. Find their `.github/workflows/` folder

GitHub Actions workflows are stored in:

`.github/workflows/`

Repository Chosen
| Item            | Value                                                                           |
| --------------- | ------------------------------------------------------------------------------- |
| Repository      | [FastAPI Repository](https://github.com/fastapi/fastapi.git) |
| CI/CD Tool Used | GitHub Actions                                                                  |
| Workflow Folder | `.github/workflows/`                                                            |



3. Open one workflow YAML file

I explored two workflow examples:

[FastAPI test.yml Workflow](https://github.com/fastapi/fastapi/blob/master/.github/workflows/test.yml)
[FastAPI deploy-staging.yml Workflow](https://github.com/fastapi/full-stack-fastapi-template/blob/master/.github/workflows/deploy-staging.yml)

4. Write in your notes:
## Workflow Example 1 — test.yml
### What triggers it?
The workflow is triggered automatically when:

```yaml
on:
  push:
    branches:
      - master

  pull_request:
    types:
      - opened
      - synchronize

  schedule:
    - cron: "0 0 * * 1"
```

Trigger Explanation

This workflow starts when:

- code is pushed to the `master` branch,
- a pull request is opened or updated,
- or the scheduled weekly run executes every Monday at midnight.

This is a very common CI practice in large open-source projects.

Additional trigger types commonly used in GitHub Actions:

- `workflow_dispatch` → manual trigger button
- release/tag events
- deployment events
- webhook events

  ---
  
### How many jobs does it have?

This workflow contains 5 main jobs.

| Job                | Purpose                                        |
| ------------------ | ---------------------------------------------- |
| `changes`          | Detects whether important source files changed |
| `test`             | Runs the full test suite using matrix builds   |
| `benchmark`        | Runs performance benchmarks                    |
| `coverage-combine` | Combines test coverage reports                 |
| `check`            | Final validation gate before merge             |

---

### What does it do? (best guess)
The workflow automates FastAPI’s validation and quality assurance process.

It mainly:

- validates pull requests,
- installs dependencies,
- runs tests,
- performs linting,
- measures performance,
- generates coverage reports,
- and prevents broken code from being merged.

Detailed Workflow Behavior
1. Path Filtering (changes job)

The workflow first checks whether important source files changed.

If only:

- documentation,
- markdown files,
- or non-code files changed,

the expensive test pipeline is skipped.

This saves:

- GitHub Actions minutes,
- CI resources,
- and execution time.

This is a real-world CI optimization pattern.

2. Matrix Testing (test job)

The workflow runs tests across multiple combinations of:

- Python versions,
- operating systems,
- and environments.

Example matrix:

- Python 3.10
- Python 3.12
- Python 3.13
- Python 3.14

Operating systems:

- Ubuntu
- macOS
- Windows

This creates many parallel test jobs automatically.

Purpose:

- ensure FastAPI works consistently everywhere.

3. Benchmark Testing (benchmark job)

This job measures:

- API performance,
- response speed,
- and framework efficiency.

It helps detect performance regressions before release.

4. Coverage Validation (coverage-combine job)

This job:

- downloads coverage reports,
- merges coverage artifacts,
- and validates code coverage thresholds.

The workflow can fail if coverage drops below required levels.

5. Final Gate (check job)

The check job acts as the final pipeline gate.

It passes only if:

- all previous jobs succeed,
- tests pass,
- benchmarks pass,
- and coverage validation succeeds.

This job is commonly used with:

- GitHub branch protection rules,
- required PR checks,
- and merge restrictions.

## Key Insight From This Workflow

FastAPI uses advanced CI optimization techniques such as:

- path filtering,
- matrix testing,
- parallel jobs,
- coverage aggregation,
- and branch protection gates.

This shows how real-world open-source projects build scalable CI pipelines.

---

## Workflow Example 2 — deploy-staging.yml

## Workflow Link

[Deploy to Staging Workflow](https://github.com/fastapi/full-stack-fastapi-template/blob/master/.github/workflows/deploy-staging.yml)

## Workflow Content

```yaml
name: Deploy to Staging

on:
  push:
    branches:
      - master

jobs:
  deploy:
    runs-on:
      - self-hosted
      - staging

    steps:
      - name: Checkout
        uses: actions/checkout@v6

      - run: docker compose build

      - run: docker compose up -d
```
What Triggers It?

The deployment workflow runs when:

code is pushed to the master branch.
How Many Jobs Does It Have?

The workflow contains:

1 job → deploy
What Does It Do?

This workflow:

- deploys the application to a staging environment,
- runs on a self-hosted staging server,
builds Docker containers,
and starts the application using Docker Compose.
Important Things I Noticed

The workflow uses:

GitHub Secrets,
environment variables,
Docker Compose,
self-hosted runners,
and automated staging deployments.

Example secrets:
```bash
${{ secrets.DOMAIN_STAGING }}
${{ secrets.POSTGRES_PASSWORD }}
${{ secrets.SECRET_KEY }}
```
This keeps sensitive credentials secure.

---

## CI/CD Tools Landscape

| Tool           | Type                          | Best For                                 |
| -------------- | ----------------------------- | ---------------------------------------- |
| GitHub Actions | Cloud-native YAML pipelines   | GitHub repositories                      |
| GitLab CI/CD   | Built into GitLab             | Enterprise/self-hosted teams             |
| Jenkins        | Open-source automation server | Large organizations needing full control |
| CircleCI       | Cloud CI platform             | Fast parallel builds                     |
| ArgoCD         | GitOps CD tool                | Kubernetes deployments                   |
| Tekton         | Kubernetes-native pipelines   | Cloud-native CI/CD                       |



For this challenge, GitHub Actions is the easiest and most commonly used option.

---

## Important CI/CD Concepts I Learned
### CI/CD Is a Practice, Not Just a Tool

Tools like:

- GitHub Actions,
- Jenkins,
- GitLab CI/CD,
- CircleCI

only implement CI/CD practices.

The real goal is:

- frequent integration,
- automated testing,
- reliable deployment,
- and fast feedback.

---

### Continuous Integration vs Continuous Delivery vs Continuous Deployment


| Type                   | Meaning                                       |
| ---------------------- | --------------------------------------------- |
| Continuous Integration | Automatically merge & test code               |
| Continuous Delivery    | Software is always release-ready              |
| Continuous Deployment  | Every successful change deploys automatically |

---

### Important Pipeline Behaviors
### Parallel Jobs

Jobs inside the same stage can run in parallel.

Example:

- linting,
- testing,
- and benchmarking

can all execute simultaneously.

This makes pipelines faster.

---

### Sequential Stages

Stages usually run sequentially:

- Test → Build → Deploy

Deployments happen only if earlier stages succeed.

---

### Fresh Runners

Every job gets a fresh runner environment.

This prevents:

- leftover files,
- cached broken states,
- and inconsistent builds.

---

### Artifacts

Artifacts are used to pass files between jobs.

Examples:

- test reports,
- Docker images,
- coverage reports,
- build outputs.

---

### Job Dependencies (needs:)

Example:

`needs: [test, lint]`

This means:

a job waits until other jobs complete successfully.

---

### Deployment Safety

Production deployments should usually run only from:

- `main`,
- `master`,
- or protected branches.

Example:

`if: github.ref == 'refs/heads/main'`

---

### Secrets Must Never Be Hardcoded

Sensitive data should always use:

- GitHub Secrets,
- encrypted variables,
- or secret managers.

Never store passwords or API keys directly in YAML files.

---

## Useful Tips I Learned

## Manual Trigger

`workflow_dispatch:`

Adds a manual “Run Workflow” button in GitHub.

---

## Matrix Strategy
```yaml
strategy:
  matrix:
    python: [3.10, 3.12, 3.13]
```
Runs tests across multiple versions automatically.

---

## Job Timeout

`timeout-minutes: 15`

Prevents runaway jobs from consuming CI resources forever.

---

## CI Badge

Projects often add CI status badges in `README.md`:

`![CI](https://github.com/user/repo/actions/workflows/ci.yml/badge.svg)`

This shows pipeline health publicly.

---

## What I Learned From Exploring Real Workflows

From exploring FastAPI’s real workflows, I understood that:

- modern projects rely heavily on automation,
- pull requests are automatically validated,
- pipelines become very advanced at scale,
- matrix testing is common,
- CI optimization matters,
- and deployment automation reduces manual work significantly.

I also learned that:

- real pipelines are much more detailed than beginner examples,
- production-grade workflows use secrets and self-hosted runners,
- and CI/CD is essential for maintaining large open-source projects reliably.

---

## Final Understanding

Real-world open-source projects continuously use CI/CD pipelines.

Whenever developers:

- push code,
- open pull requests,
- or create releases,

automated workflows immediately:

- test,
- validate,
- benchmark,
- build,
- and sometimes deploy applications automatically.

This helps teams deliver software:

- faster,
- safer,
- more reliably,
- and with higher confidence.
