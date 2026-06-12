# Day 45 – Docker Build & Push in GitHub Actions

## Challenge Tasks

### Task 1: Prepare
1. Use the app you Dockerized on Day 36 (or any simple Dockerfile)
2. Add the Dockerfile to your `github-actions-practice` repo (or create a minimal one)
3. Make sure `DOCKER_USERNAME` and `DOCKER_TOKEN` secrets are set from Day 44

| Secret            | Purpose                 |
| ----------------- | ----------------------- |
| `DOCKER_USERNAME` | Docker Hub username     |
| `DOCKER_TOKEN`    | Docker Hub access token |


<img width="1285" height="659" alt="image" src="https://github.com/user-attachments/assets/f41e57d8-cc72-4e77-b8a1-a7cc0e0ea795" />

- These secrets are required for authenticating Docker Hub inside GitHub Actions.

---

### Task 2: Build the Docker Image in CI
Create `.github/workflows/docker-publish.yml` that:
1. Triggers on push to `main`
2. Checks out the code
3. Builds the Docker image and tags it

**Verify:** Check the build step logs — does the image build successfully?

**Verification:** The Docker image built successfully in GitHub Actions logs

<img width="1198" height="1015" alt="image" src="https://github.com/user-attachments/assets/ed8bd94d-8afd-48fc-92c2-551491565f17" />


---

### Task 3: Push to Docker Hub
Add steps to:
1. Log in to Docker Hub using your secrets
2. Tag the image as `username/repo:latest` and also `username/repo:sha-<short-commit-hash>`
3. Push both tags

**Verify:** Go to Docker Hub — is your image there with both tags?

**Verification:**

✔ Image successfully pushed to Docker Hub
✔ Both latest and sha tags are available in the repository

<img width="1384" height="637" alt="image" src="https://github.com/user-attachments/assets/b2ba7289-35f6-44b6-9e1b-1668b3f3c985" />


[Docker-Hub](https://hub.docker.com/repository/docker/shettymalathi113/day45-cicd-app/general)

---

### Task 4: Only Push on Main
Add a condition so the push step only runs on the `main` branch — not on feature branches or PRs.

Test it: push to a feature branch and verify the image is built but NOT pushed.

**Main branch run:**
On the main branch, the image was built and pushed to Docker Hub

https://github.com/malathi-shetty/github-actions-practice/actions/runs/26326257946

<img width="1327" height="856" alt="image" src="https://github.com/user-attachments/assets/3f0815a8-219d-4dc6-a767-1ecc439ccda9" />

**Feature branch run:**
On the feature-test branch, the image was built and the push step was skipped.


https://github.com/malathi-shetty/github-actions-practice/actions/runs/26326257946

<img width="898" height="844" alt="image" src="https://github.com/user-attachments/assets/d5138293-2fe1-448b-ac7a-48c3a30ee0d8" />

A condition was added so that Docker images are only pushed when code is merged into main.

Behavior implemented:
| Branch    | Behavior                   |
| --------- | -------------------------- |
| main      | Build + Push to Docker Hub |
| feature/* | Build only (no push)       |
| PR        | Build only (no push)       |

**Verification**

✔ On main branch → Image was built and pushed successfully
✔ On feature-test branch → Image was built, but push step was skipped

---

### Task 5: Add a Status Badge
1. Get the badge URL for your `docker-publish` workflow from the Actions tab
2. Add it to your `README.md`
3. Push — the badge should show green

A GitHub Actions status badge was added to the README to visually track pipeline health.
```html
<img src="https://github.com/malathi-shetty/github-actions-practice/actions/workflows/docker-publish.yml/badge.svg" alt="Docker CI/CD Status">
```
**Purpose of badge:**
- Shows latest pipeline status (green/red)
- Helps quickly verify CI health
- Useful for project visibility in README

<img width="895" height="205" alt="image" src="https://github.com/user-attachments/assets/e7f8854d-56d4-4211-bf57-20ef9800099b" />



---

### Task 6: Pull and Run It
1. On your local machine (or a cloud server), pull the image you just pushed
2. Run it
3. Confirm it works

After successful push, the image was pulled and tested locally.

Run steps:
```bash
docker pull shettymalathi113/day45-cicd-app:latest

docker run -d -p 3000:3000 --name day45-app shettymalathi113/day45-cicd-app:latest
```
**Verification:**

✔ Container started successfully
✔ Application accessible on port 3000
✔ API endpoints working as expected

<img width="1920" height="1392" alt="image" src="https://github.com/user-attachments/assets/072b0a78-e2b6-436b-8d19-6c10c2cd4249" />




## What is the full journey from `git push` to a running container?

**1. git push** – Code is pushed to GitHub.
**2. GitHub Actions triggers** – The CI/CD workflow starts automatically.
**3. Checkout code**
- `uses: actions/checkout@v4`
- Pulls your repository into the runner machine.
**4. Docker login (required for pushing images to Docker Hub)**
- `uses: docker/login-action@v3`
- Authenticates GitHub Actions with Docker Hub.

**5. Build Docker image using Dockerfile**
- Docker image is created from your source code.
👉 Behavior based on branch:
- **main branch → build + tag + push to Docker Hub**
- **feature branches / PRs → build only (no push)**
**6. Push to Docker Hub (only main branch)**
- Image is uploaded as:
```bash
username/repo:latest
username/repo:sha-<short-commit>
```

## Run the container locally

### Pull and run latest image:
```bash
docker run -d -p 3000:3000 --name day45-app shettymalathi113/day45-cicd-app:latest
```

### Update running container (new image)
```bash
docker stop day45-app
docker rm day45-app

docker pull shettymalathi113/day45-cicd-app:latest

docker run -d -p 3000:3000 --name day45-app shettymalathi113/day45-cicd-app:latest
```

### If port is already in use
```bash
docker ps
docker stop <container_id>
docker rm <container_id>
```

```bash
1. git push
      ↓
2. GitHub Actions triggered
      ↓
3. Checkout repository code
      ↓
4. Docker login (for authentication only)
      ↓
5. Build Docker image
      ↓
6. Branch check:
      ├── main → push image to Docker Hub
      └── feature/PR → build only
      ↓
7. Image stored in Docker Hub
      ↓
8. Pull image locally
      ↓
9. Run container
      ↓
10. Application runs successfully 🚀
```

### Key Understanding
- GitHub Actions builds the image automatically
- Docker login does NOT mean automatic push
- Only main branch pushes to Docker Hub
- Feature/PR branches are used for testing only
- Docker container runs from the pushed image
- Docker images are versioned using SHA tags


```yaml
# =========================================================
# CI/CD PIPELINE - Docker Build & Push (DAY 45)
# =========================================================

name: CI/CD - Docker Build & Publish to Docker Hub

# =========================================================
# WHEN PIPELINE RUNS
# =========================================================
on:

  push:
    branches:
      - main
      - master
      - feature/*   # feature branches → BUILD ONLY (NO PUSH)

  pull_request:
    branches:
      - main
      - master     # PR → BUILD ONLY (NO PUSH)

  workflow_dispatch:

# =========================================================
# GLOBAL VARIABLES
# =========================================================
env:
  DOCKER_IMAGE_NAME: ${{ secrets.DOCKER_USERNAME }}/day45-cicd-app

# =========================================================
# JOB
# =========================================================
jobs:

  build-and-publish:
    runs-on: ubuntu-latest

    steps:

      # =================================================
      # STEP 1: Checkout code
      # =================================================
      - name: Checkout code
        uses: actions/checkout@v4


      # =================================================
      # STEP 2: Checkout application code
      # =================================================
      - name: Checkout application
        uses: actions/checkout@v4
        with:
          repository: malathi-shetty/90DaysOfDevOps_TrainWithShubham
          path: 2026/day-45


      # =================================================
      # STEP 3: Generate short SHA (for image tagging)
      # =================================================
      - name: Generate short SHA
        id: vars
        run: echo "short_sha=$(echo '${{ github.sha }}' | cut -c1-7)" >> "$GITHUB_OUTPUT"


      # =================================================
      # STEP 4: Setup Docker Buildx
      # =================================================
      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v3


      # =================================================
      # STEP 5: Docker Login (ALL BRANCHES)
      # NOTE: Login does NOT push anything by itself
      # =================================================
      - name: Docker Login
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}


      # =================================================
      # STEP 6: Debug workspace (safe view only)
      # =================================================
      - name: Debug workspace
        run: |
          pwd
          echo "Showing only app folder (not full clutter)"
          ls 2026/day-45/2026/day-45
      # =========================================================
      # STEP 7A: MAIN → BUILD + PUSH TO DOCKER HUB
      # =========================================================
      - name: Build, tag & push Docker image (MAIN only)
        if: github.ref == 'refs/heads/main' && github.event_name != 'pull_request'
        uses: docker/build-push-action@v5
        with:
          context: ./2026/day-45/2026/day-45
          push: true
          tags: |
            ${{ env.DOCKER_IMAGE_NAME }}:latest
            ${{ env.DOCKER_IMAGE_NAME }}:sha-${{ steps.vars.outputs.short_sha }}
      # =========================================================
      # STEP 7B: FEATURE + PR → BUILD ONLY (NO PUSH)
      # =========================================================
      - name: Build image only (feature/PR branches)
        if: github.ref != 'refs/heads/main' || github.event_name == 'pull_request'
        uses: docker/build-push-action@v5
        with:
          context: ./2026/day-45/2026/day-45
          push: false
          tags: |
            local-test:latest
      # =================================================
      # STEP 8: SUMMARY (WHAT HAPPENED)
      # =================================================
      - name: Pipeline Summary
        run: |
          echo "## CI/CD RESULT SUMMARY" >> "$GITHUB_STEP_SUMMARY"
          echo "" >> "$GITHUB_STEP_SUMMARY"
          echo "| Branch | ${GITHUB_REF_NAME} |" >> "$GITHUB_STEP_SUMMARY"
          echo "| Commit | ${{ steps.vars.outputs.short_sha }} |" >> "$GITHUB_STEP_SUMMARY"
          echo "| Docker Image | ${{ env.DOCKER_IMAGE_NAME }} |" >> "$GITHUB_STEP_SUMMARY"
          echo "" >> "$GITHUB_STEP_SUMMARY"
          echo "✔ Feature/PR → Build only" >> "$GITHUB_STEP_SUMMARY"
          echo "✔ Main → Build + Push to Docker Hub" >> "$GITHUB_STEP_SUMMARY"
```

<img width="1179" height="616" alt="image" src="https://github.com/user-attachments/assets/9527c53d-44cc-48a7-8a21-c29cfc1090a5" />

<img width="1920" height="1182" alt="image" src="https://github.com/user-attachments/assets/02482cd6-6a0b-4b88-8f20-6b6a6919edae" />

<img width="1920" height="5517" alt="image" src="https://github.com/user-attachments/assets/6f65d7b3-2adb-4bf6-835b-7b5c14856cdd" />


---


# Day 45 – Docker Build & Push in GitHub Actions

---

## Overview

Today we automated Docker image creation using GitHub Actions. Every push to the repository triggers a CI pipeline that builds a Docker image. Only the `main` branch pushes the image to Docker Hub, while feature branches and pull requests are used only for testing builds.

This removes the need for manual:

```bash
docker build
docker tag
docker push
```

Everything is handled automatically by CI.

---

## Project Setup

### Application

A simple Node.js + Express app inside:

```
day-45/app/
```

It exposes two endpoints:

| Route     | Description                   |
| --------- | ----------------------------- |
| `/`       | Returns a welcome message     |
| `/health` | Returns service health status |

---

### Dockerfile

A standard Dockerfile is used to containerize the app.

It follows a clean production approach:

* lightweight base image
* installs dependencies
* runs Node server

---

### GitHub Secrets

To push images to Docker Hub:

| Secret            | Purpose                 |
| ----------------- | ----------------------- |
| `DOCKER_USERNAME` | Docker Hub username     |
| `DOCKER_TOKEN`    | Docker Hub access token |

---

## GitHub Actions Workflow

File used:

```
.github/workflows/docker-publish.yml
```

---

### Triggers

The pipeline runs on:

* Push to `main`
* Push to `feature/*`
* Pull Requests to `main`
* Manual trigger (`workflow_dispatch`)

---

## CI/CD Flow

### Step 1: Checkout Code

The repository code is pulled into the runner.

---

### Step 2: Setup Docker Buildx

Enables modern Docker build features like:

* caching
* faster builds
* improved performance

---

### Step 3: Generate Image Tag

A short Git SHA is generated:

```
abc1234
```

This is used for versioning Docker images.

---

### Step 4: Docker Login

Docker Hub authentication happens using secrets.

👉 Important:

* Login does NOT push images
* It only enables permission if push happens later

---

## Step 5: Build & Push Logic

### 🔵 Main Branch

On `main`:

* Build Docker image
* Tag image:

  ```
  latest
  sha-abc1234
  ```
* Push image to Docker Hub

---

### 🟡 Feature Branch / PR

On all other branches:

* Build Docker image only
* No push to Docker Hub
* Used only for validation

---

## Branch Behavior Summary

| Branch    | Action       |
| --------- | ------------ |
| main      | Build + Push |
| feature/* | Build only   |
| PR        | Build only   |

---

## Docker Hub Output

After successful run:

```
repository: day45-cicd-app

tags:
- latest
- sha-abc1234
```

Both tags point to the same image.

---

## Full CI/CD Flow

```
git push
   ↓
GitHub Actions triggered
   ↓
Checkout code
   ↓
Setup Docker Buildx
   ↓
Generate short SHA
   ↓
Docker login (only credentials prepared)
   ↓
Build image
   ↓
IF main → push to Docker Hub
IF feature/PR → only build
   ↓
Pipeline complete
```

---

## Running the Container

### Pull image

```bash
docker pull <username>/day45-cicd-app:latest
```

### Run container

```bash
docker run -d -p 3000:3000 --name day45-app <username>/day45-cicd-app:latest
```

---

### Update container

```bash
docker stop day45-app
docker rm day45-app

docker pull <username>/day45-cicd-app:latest

docker run -d -p 3000:3000 --name day45-app <username>/day45-cicd-app:latest
```

---

### Check running containers

```bash
docker ps
```

---

## Key Learnings

* GitHub Actions automates Docker workflows
* Login ≠ push (important confusion point)
* Only `main` branch pushes images
* Feature branches are safe for testing builds
* SHA tagging enables version tracking

---

## Final Result

✔ Automatic Docker build
✔ Branch-based deployment control
✔ Docker Hub integration
✔ CI/CD pipeline working end-to-end


