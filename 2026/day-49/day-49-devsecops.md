# Day 49 – DevSecOps: Add Security to Your CI/CD Pipeline

## What is DevSecOps?

DevSecOps means:

> Development + Security + Operations

Instead of checking security after deployment, security checks are added directly into the CI/CD pipeline.

**Traditional workflow:**
```bash
Build → Deploy → Later find vulnerabilities
```

**DevSecOps workflow:**
```bash
Build → Scan → Block insecure builds → Deploy safely`
```

This helps catch issues early before they reach production.

---

## Challenge Tasks

### Task 1: Scan Your Docker Image for Vulnerabilities
Your Docker image might use a base image with known security issues. Let's find out.

Add this step to your main branch pipeline (after Docker build, before deploy):
```yaml
- name: Scan Docker Image for Vulnerabilities
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'your-username/your-app:latest'
    format: 'table'
    exit-code: '1'
    severity: 'CRITICAL,HIGH'
```

What this does:
- `trivy` scans your Docker image for known CVEs (Common Vulnerabilities and Exposures)
- `format: 'table'` prints a readable table in the logs
- `exit-code: '1'` means **fail the pipeline** if CRITICAL or HIGH vulnerabilities are found
- If it passes, your image is clean — proceed to push and deploy

The scan checks:
 - OS packages
 - Application libraries
 - Docker image vulnerabilities

If HIGH or CRITICAL vulnerabilities are found:
 - the pipeline fails
 - deployment is blocked

Push and check the Actions tab. Read the scan output.

**Verify:** Can you see the vulnerability table in the logs? Did it pass or fail?


- Failed — vulnerabilities were detected.

- What CVEs (if any) were found? What base image are you using?

- CVEs found:
    CVE-2026-22184, CVE-2024-21538, CVE-2025-64756, CVE-2026-26996, CVE-2026-27903, CVE-2026-27904, CVE-2026-23745, CVE-2026-23950, CVE-2026-24842, CVE-2026-26960, CVE-2026-29786, CVE-2026-31802.

- Base image: Alpine Linux (node:alpine). then change to node:22-alpine




> Merged with this Brownie Points
> 
> Upload Scan Results to GitHub Security Tab
> 
> Add SARIF output to Trivy and upload it — your scan results will appear in the repo's Security tab:
> 
> - uses: aquasecurity/trivy-action@master
>   with:
>     image-ref: 'your-username/your-app:latest'
>     format: 'sarif'
>     output: 'trivy-results.sarif'
> - uses: github/codeql-action/upload-sarif@v3
>   with:
>    sarif_file: 'trivy-results.sarif'




#### Vulnerability & Security Reports
- https://github.com/malathi-shetty/github-actions-capstone/blob/test-trivy-vulns/.github/workflows/main-pipeline.yml
- https://github.com/malathi-shetty/github-actions-capstone/blob/test-trivy-vulns/Dockerfile
- https://github.com/malathi-shetty/github-actions-capstone/actions/runs/26501954363

<img width="1920" height="7282" alt="Vulnerability   Secrets Report" src="https://github.com/user-attachments/assets/3621cb6a-1317-40d1-aff8-021015be1a40" />


<details>
<summary>View Full Workflow</summary>


```bash
name: Main Pipeline

on:
  push:
    branches:
      - main
      - test-trivy-vulns

  pull_request:
    branches:
      - main

  workflow_dispatch:

permissions:
  contents: write
  security-events: write
  pull-requests: write

# =========================================================
# FLOW
# build-test → docker → trivy-scan → dashboard → security-gate → deploy
# =========================================================

jobs:

# =========================================================
# 1. BUILD & TEST
# =========================================================
  build-test:
    name: Build & Test
    uses: ./.github/workflows/reusable-build-test.yml

    with:
      node_version: "20"
      run_tests: true


# =========================================================
# 2. DOCKER BUILD
# =========================================================
  docker:
    name: Docker Build
    needs: build-test
    uses: ./.github/workflows/reusable-docker.yml

    with:
      image_name: "shettymalathi113/github-actions-capstone"
      tag: v1.0.${{ github.run_number }}
      sha_tag: sha-${{ github.sha }}
      push: true

    secrets:
      docker_username: ${{ secrets.DOCKER_USERNAME }}
      docker_token: ${{ secrets.DOCKER_TOKEN }}


# =========================================================
# 3. TRIVY SCAN
# =========================================================
  trivy-scan:
    name: Trivy Scan
    needs: docker
    runs-on: ubuntu-latest

    steps:

      - name: Install Tools
        run: |
          sudo apt-get update
          sudo apt-get install -y jq wget gnupg trivy

      - name: Cache Trivy DB
        uses: actions/cache@v4
        with:
          path: ~/.cache/trivy
          key: trivy-db-${{ runner.os }}

      # =====================================================
      # JSON SCAN (Primary data source for reports and metrics)
      # =====================================================
      - name: Run JSON Scan
        run: |
          trivy image \
            --severity HIGH,CRITICAL \
            --ignore-unfixed \
            --format json \
            --output trivy.json \
            shettymalathi113/github-actions-capstone:v1.0.${{ github.run_number }}

      # =====================================================
      # SARIF SCAN
      # =====================================================
      - name: Run SARIF Scan
        run: |
          trivy image \
            --severity HIGH,CRITICAL \
            --ignore-unfixed \
            --format sarif \
            --output trivy-results.sarif \
            shettymalathi113/github-actions-capstone:v1.0.${{ github.run_number }}

      - uses: actions/upload-artifact@v4
        with:
          name: trivy-json
          path: trivy.json

      - uses: actions/upload-artifact@v4
        with:
          name: trivy-sarif
          path: trivy-results.sarif


# =========================================================
# 4. REPORT GENERATION
# =========================================================
  generate-reports:
    name: Generate Reports
    needs: trivy-scan
    runs-on: ubuntu-latest

    steps:

      - uses: actions/download-artifact@v4
        with:
          name: trivy-json

      # =====================================================
      # Generate Markdown Vulnerability Report
      # =====================================================
      - name: Generate Trivy Markdown Report
        run: |
          echo "## 🔐 Vulnerability Report (Trivy)" > trivy.md
          echo "" >> trivy.md

          echo "| Severity | Package | Vulnerability | Installed Version | Fixed Version |" >> trivy.md
          echo "|----------|---------|---------------|-------------------|---------------|" >> trivy.md

          jq -r '
            .Results[]?.Vulnerabilities[]? |
            "| \(.Severity) | \(.PkgName) | \(.VulnerabilityID) | \(.InstalledVersion) | \(.FixedVersion // "N/A") |"
          ' trivy.json >> trivy.md

      # =====================================================
      # AI NOTES
      # =====================================================
      - name: Generate AI Notes
        run: |
          echo "## 🤖 AI Notes" > ai.md
          echo "- Build completed" >> ai.md
          echo "- Docker image built" >> ai.md
          echo "- Trivy scan executed" >> ai.md

      # =====================================================
      # Publish Security Summary
      # =====================================================
      - name: Publish Summary
        run: |
          echo "## 🔐 Trivy Security Report Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          cat trivy.md >> $GITHUB_STEP_SUMMARY

      - uses: actions/upload-artifact@v4
        with:
          name: reports
          path: |
            trivy.md
            ai.md
            trivy.json


# =========================================================
# 5. SECURITY DASHBOARD
# =========================================================
  security-dashboard:
    name: Security Dashboard
    needs: generate-reports
    runs-on: ubuntu-latest
    continue-on-error: true # Allows dashboard/report generation even if vulnerabilities exist

    steps:

      - uses: actions/download-artifact@v4
        with:
          name: trivy-json

      - name: Compute Metrics
        run: |
          CRITICAL=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' trivy.json)
          HIGH=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length' trivy.json)

          SCORE=$((100 - (CRITICAL*25 + HIGH*10)))
          if [ "$SCORE" -lt 0 ]; then SCORE=0; fi

          echo "CRITICAL=$CRITICAL" >> $GITHUB_ENV
          echo "HIGH=$HIGH" >> $GITHUB_ENV
          echo "SCORE=$SCORE" >> $GITHUB_ENV

      # =====================================================
      # Dashboard Summary
      # =====================================================
      - name: Security Dashboard Summary
        run: |
          echo "## 🛡 Security Dashboard summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY

          echo "📦 JSON Scan Summary" >> $GITHUB_STEP_SUMMARY
          echo "- Critical: $CRITICAL" >> $GITHUB_STEP_SUMMARY
          echo "- High: $HIGH" >> $GITHUB_STEP_SUMMARY

          echo "" >> $GITHUB_STEP_SUMMARY
          echo "🐳 Image Info" >> $GITHUB_STEP_SUMMARY
          echo "- Image: shettymalathi113/github-actions-capstone" >> $GITHUB_STEP_SUMMARY
          echo "- Build: v1.0.${{ github.run_number }}" >> $GITHUB_STEP_SUMMARY
          echo "- Commit: ${{ github.sha }}" >> $GITHUB_STEP_SUMMARY

          echo "" >> $GITHUB_STEP_SUMMARY
          echo "📦 Top Vulnerable Packages" >> $GITHUB_STEP_SUMMARY
          jq -r '.Results[].Vulnerabilities[]? | .PkgName' trivy.json \
          | sort | uniq -c | sort -nr | head -10 \
          | while read c p; do
              echo "- $p → $c issues" >> $GITHUB_STEP_SUMMARY
            done

          echo "" >> $GITHUB_STEP_SUMMARY
          if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
            echo "❌ SECURITY STATUS: BLOCKED" >> $GITHUB_STEP_SUMMARY
          else
            echo "✅ SECURITY STATUS: CLEAN" >> $GITHUB_STEP_SUMMARY
          fi

      # =====================================================
      # Generate HTML Security Dashboard
      # =====================================================
      - name: Generate HTML Dashboard (Readable)
        run: |
          CRITICAL_COUNT=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' trivy.json)
          HIGH_COUNT=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length' trivy.json)

          echo "<html>" > security-dashboard.html
          echo "<head>" >> security-dashboard.html
          echo "<title>Security Dashboard</title>" >> security-dashboard.html

          echo "<style>" >> security-dashboard.html
          echo "body{font-family:Arial;margin:20px;background:#f4f4f4}" >> security-dashboard.html
          echo ".card{background:white;padding:15px;margin:10px;border-radius:10px;box-shadow:0 2px 5px gray}" >> security-dashboard.html
          echo ".critical{color:white;background:#e74c3c;padding:5px;border-radius:5px}" >> security-dashboard.html
          echo ".high{color:white;background:#f39c12;padding:5px;border-radius:5px}" >> security-dashboard.html
          echo ".safe{color:white;background:#2ecc71;padding:5px;border-radius:5px}" >> security-dashboard.html
          echo "</style>" >> security-dashboard.html

          echo "</head><body>" >> security-dashboard.html

          echo "<h1>🛡 Security Dashboard</h1>" >> security-dashboard.html
          echo "<div class='card'><h2>Score: $SCORE / 100</h2></div>" >> security-dashboard.html

          echo "<div class='card'>" >> security-dashboard.html
          echo "<h3>📦 Summary</h3>" >> security-dashboard.html
          echo "<p class='critical'>Critical: $CRITICAL_COUNT</p>" >> security-dashboard.html
          echo "<p class='high'>High: $HIGH_COUNT</p>" >> security-dashboard.html
          echo "</div>" >> security-dashboard.html

          echo "<div class='card'>" >> security-dashboard.html
          echo "<h3>🔥 Critical Vulnerabilities</h3>" >> security-dashboard.html

          jq -r '
            .Results[].Vulnerabilities[]? |
            select(.Severity=="CRITICAL") |
            "<p><b>\(.PkgName)</b> → \(.VulnerabilityID) <br> Fix: \(.FixedVersion // "N/A")</p>"
          ' trivy.json >> security-dashboard.html

          echo "</div>" >> security-dashboard.html

          echo "<div class='card'>" >> security-dashboard.html
          echo "<h3>⚠️ High Vulnerabilities</h3>" >> security-dashboard.html

          jq -r '
            .Results[].Vulnerabilities[]? |
            select(.Severity=="HIGH") |
            "<p><b>\(.PkgName)</b> → \(.VulnerabilityID) <br> Fix: \(.FixedVersion // "N/A")</p>"
          ' trivy.json >> security-dashboard.html

          echo "</div>" >> security-dashboard.html

          echo "</body></html>" >> security-dashboard.html
          
      - uses: actions/upload-artifact@v4
        with:
          name: security-dashboard
          path: security-dashboard.html


# =========================================================
# 6. SECURITY GATE
# =========================================================
  security-gate:
    name: Security Gate
    needs: trivy-scan
    runs-on: ubuntu-latest

    steps:

      - uses: actions/download-artifact@v4
        with:
          name: trivy-json

      - name: Fail Build If Vulnerabilities Found
        run: |
          CRITICAL=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' trivy.json)
          HIGH=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length' trivy.json)

          if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
            echo "❌ BLOCKED: Security issues found"
            exit 1
          fi


# =========================================================
# 7. DEPLOY
# =========================================================
  deploy:
    name: Deploy
    needs: security-gate
    runs-on: ubuntu-latest

    steps:
      - name: Deploy App
        run: |
          echo "🚀 Deploying v1.0.${{ github.run_number }}"
          echo "Application LIVE"
```

```dockerfile
# Intentionally vulnerable image used for negative security testing
FROM node:14-alpine

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Copy application source
COPY --chown=node:node . .

# Use non-root user
USER node

# Expose app port
EXPOSE 3000

# Start application
CMD ["npm", "start"]
```
</details>

## Negative Scenario – Vulnerable Image Detection (`branch-trivy`)
<img width="1353" height="444" alt="image" src="https://github.com/user-attachments/assets/1907e38c-b0da-4461-abef-dcc65e9bdc26" />


<img width="1920" height="3323" alt="image" src="https://github.com/user-attachments/assets/e255af9e-2b40-482b-a3b2-fa4dbc9bf1ec" />

## Positive Scenario – Secure Pipeline Execution (`main`)
<img width="1500" height="484" alt="image" src="https://github.com/user-attachments/assets/b48a5df6-541a-4604-97d4-1cdf0fe1dacb" />



---

<img width="760" height="170" alt="Vulnerability   Secrets Report-3" src="https://github.com/user-attachments/assets/9f027d7b-ce00-4a95-aa2d-0e98478e2fc6" />
<img width="1920" height="911" alt="Vulnerability   Secrets Report-2" src="https://github.com/user-attachments/assets/a1b88e51-791e-40f2-872d-66a914ed7616" />



## Why the Pipeline Failed (Negative Scenario)

Your Trivy scan detected:
- 12 HIGH/CRITICAL vulnerabilities were detected.
Multiple CVEs like:
- CVE-2026-22184, CVE-2024-21538, CVE-2025-64756, ...

### Root cause

Your Docker image is:
```bash
FROM node:14-alpine
```
That’s the main problem.

- Node.js 14 is EOL (End of Life)
- Alpine images often have busybox + musl vulnerabilities
- Older base images accumulate CVEs because they no longer receive security patches.

Trivy is correctly identifying unsupported and vulnerable components. — it is correctly flagging an unsupported, outdated runtime stack.

## Why Multiple CVEs Were Detected

- Most vulnerabilities were not caused by the application code itself.

They come from:
- Alpine OS packages (openssl, musl, busybox, apk-tools)
- Node 14 runtime dependencies
- Transitive system libraries inside the image

As a result, even secure application code can inherit vulnerabilities from outdated base images.

---

### Task 2: Enable GitHub's Built-in Secret Scanning
GitHub can automatically detect if someone pushes a secret (API key, token, password) to your repo.

1. Go to your repo → Settings → **Code security and analysis**
2. Enable **Secret scanning**
3. If available, also enable **Push protection** — this blocks the push entirely if a secret is detected

That's it — no workflow changes needed. GitHub does this automatically.


<img width="1920" height="2597" alt="image" src="https://github.com/user-attachments/assets/aaf5e0d6-3e0c-4252-a968-df809ff29224" />


## Write in your notes:

### What is the difference between Secret Scanning and Push Protection?

#### Secret Scanning
- Detects exposed secrets such as API keys, tokens, and passwords after they are pushed to the repository.
- Monitors commits, branches, and pull requests for leaked credentials.
- Generates alerts when secrets are detected.

#### Push Protection
- Prevents secrets from being pushed to the repository.
- Blocks commits or pushes if sensitive credentials are detected before the push is accepted.
- Helps stop secrets from entering repository history.

---

### What happens if GitHub detects a leaked AWS key in your repository?

- GitHub Secret Scanning detects the exposed AWS access key in commits or pull requests.
- GitHub generates a security alert for repository administrators.
- GitHub may also notify AWS about the leaked credential.
- The exposed key should be rotated or revoked immediately to prevent unauthorized access.



---

### Task 3: Scan Dependencies for Known Vulnerabilities
If your app uses packages (pip, npm, etc.), those packages might have known vulnerabilities.

Add this to your **PR pipeline** (not the main pipeline):
```yaml
- name: Check Dependencies for Vulnerabilities
  uses: actions/dependency-review-action@v4
  with:
    fail-on-severity: critical
```

This checks any **new** dependencies added in the PR against a vulnerability database. If a dependency has a critical CVE, the PR check fails.

Test it:
1. Open a PR that adds a package to your app
2. Check the Actions tab — did the dependency review run?

**Verify:** Does the dependency review show up as a check on your PR?

- Yes, the Dependency Review workflow executed successfully and appeared as a PR check.

<img width="1920" height="2339" alt="image" src="https://github.com/user-attachments/assets/9dbfc8bc-3685-46ee-9aa4-a23b2f00b1ae" />
<img width="1920" height="2765" alt="image" src="https://github.com/user-attachments/assets/e50b4601-b882-4ddf-ac43-154ab67cfd07" />

- https://github.com/malathi-shetty/github-actions-capstone/actions/runs/26462725296

<details>
<summary>View Full Workflow</summary>

## pr-pipeline.yml

```bash
name: PR Pipeline

on:
  pull_request:
    branches:
      - main

    types:
      - opened
      - synchronize

permissions:
  contents: read

jobs:

  # =========================================
  # BUILD + TEST
  # =========================================

  build-test:

    name: Run Build & Test Workflow

    uses: ./.github/workflows/reusable-build-test.yml

    with:
      node_version: "20"
      run_tests: true
      # run_tests: false

  # =========================================
  # DEPENDENCY REVIEW
  # =========================================

  dependency-review:

    name: Dependency Vulnerability Check

    needs: build-test

    runs-on: ubuntu-latest

    steps:

      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Check Dependencies for Vulnerabilities
        uses: actions/dependency-review-action@v4

        with:
          fail-on-severity: critical

  # =========================================
  # PR SUMMARY
  # =========================================

  pr-comment:

    name: PR Summary

    needs:
      - build-test
      - dependency-review

    runs-on: ubuntu-latest

    steps:

      - name: Print PR success message
        run: |
          echo "PR checks passed for branch: ${{ github.head_ref }}"

      - name: Add workflow summary
        run: |

          echo "## PR Pipeline Summary" >> "$GITHUB_STEP_SUMMARY"

          echo "" >> "$GITHUB_STEP_SUMMARY"

          echo "| Key | Value |" >> "$GITHUB_STEP_SUMMARY"
          echo "|-----|-------|" >> "$GITHUB_STEP_SUMMARY"

          echo "| Branch | \`${{ github.head_ref }}\` |" >> "$GITHUB_STEP_SUMMARY"

          echo "| PR Number | \`#${{ github.event.pull_request.number }}\` |" >> "$GITHUB_STEP_SUMMARY"

          echo "| Test Result | \`${{ needs.build-test.outputs.test_result }}\` |" >> "$GITHUB_STEP_SUMMARY"

          echo "| Dependency Review | ✅ Completed |" >> "$GITHUB_STEP_SUMMARY"

          echo "| Docker Build | ❌ Skipped on PRs |" >> "$GITHUB_STEP_SUMMARY"

          echo "| Docker Push | ❌ Skipped on PRs |" >> "$GITHUB_STEP_SUMMARY"

          echo "| Deploy | ❌ Skipped on PRs |" >> "$GITHUB_STEP_SUMMARY"
```

### main-pipeline.yml

```bash
name: Main Pipeline

on:
  push:
    branches:
      - main

  workflow_dispatch:

permissions:
  contents: write

jobs:

  # =========================================
  # BUILD + TEST
  # =========================================

  build-test:
    name: Build & Test

    uses: ./.github/workflows/reusable-build-test.yml

    with:
      node_version: "20"
      run_tests: true

  # =========================================
  # DOCKER BUILD + PUSH
  # =========================================

  docker:
    name: Docker Build

    needs: build-test

    uses: ./.github/workflows/reusable-docker.yml

    with:
      image_name: "shettymalathi113/github-actions-capstone"
      tag: v1.0.${{ github.run_number }}
      sha_tag: sha-${{ github.sha }}
      push: true

    secrets:
      docker_username: ${{ secrets.DOCKER_USERNAME }}
      docker_token: ${{ secrets.DOCKER_TOKEN }}

  # =========================================
  # DEPLOY
  # =========================================

  deploy:
    name: Deploy

    needs: docker

    runs-on: ubuntu-latest

    steps:

      - name: Deploy App
        run: |
          echo "Deploying IMAGE"
          echo "Success"

  # =========================================
  # RUN TRIVY SCAN
  # =========================================

  trivy-scan:
    name: Run Trivy Scan

    needs: docker

    runs-on: ubuntu-latest

    steps:

      # =========================================
      # INSTALL TRIVY
      # =========================================

      - name: Install Trivy
        run: |

          sudo apt-get update

          sudo apt-get install -y \
            wget \
            apt-transport-https \
            gnupg \
            lsb-release \
            jq

          wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | \
          gpg --dearmor | \
          sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

          echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | \
          sudo tee /etc/apt/sources.list.d/trivy.list

          sudo apt-get update

          sudo apt-get install -y trivy

      # =========================================
      # VERIFY TRIVY
      # =========================================

      - name: Verify Trivy
        run: trivy --version

      # =========================================
      # RUN TRIVY SCAN
      # =========================================

      - name: Run Trivy Scan
        run: |

          trivy image \
            --severity HIGH,CRITICAL \
            --ignore-unfixed \
            --format json \
            --output trivy.json \
            shettymalathi113/github-actions-capstone:v1.0.${{ github.run_number }}

      # =========================================
      # UPLOAD JSON
      # =========================================

      - name: Upload Trivy JSON
        uses: actions/upload-artifact@v4

        with:
          name: trivy-json
          path: trivy.json

  # =========================================
  # GENERATE REPORTS
  # =========================================

  generate-reports:
    name: Generate Reports

    needs: trivy-scan

    runs-on: ubuntu-latest

    steps:

      - name: Download Trivy JSON
        uses: actions/download-artifact@v4

        with:
          name: trivy-json

      # =========================================
      # GENERATE TRIVY MARKDOWN
      # =========================================

      - name: Generate Trivy Markdown
        run: |

          echo "## 🔐 Vulnerability Report (Trivy)" > trivy.md
          echo "" >> trivy.md

          echo "| Severity | Package | Vulnerability | Installed Version | Fixed Version |" >> trivy.md
          echo "|---|---|---|---|---|" >> trivy.md

          jq -r '
          .Results[]?.Vulnerabilities[]? |
          "| \(.Severity) | \(.PkgName) | \(.VulnerabilityID) | \(.InstalledVersion) | \(.FixedVersion // "N/A") |"
          ' trivy.json >> trivy.md

      # =========================================
      # GENERATE AI NOTES
      # =========================================

      - name: Generate AI Notes
        run: |

          echo "## 🤖 AI Release Notes" > ai.md
          echo "" >> ai.md
          echo "- Build completed successfully" >> ai.md
          echo "- Docker image built and pushed" >> ai.md
          echo "- Trivy scan completed" >> ai.md
          echo "- README auto updated" >> ai.md

      # =========================================
      # UPLOAD REPORTS
      # =========================================

      - name: Upload Reports
        uses: actions/upload-artifact@v4

        with:
          name: reports

          path: |
            trivy.md
            ai.md
            trivy.json

  # =========================================
  # SECURITY GATE
  # =========================================

  security-gate:
    name: Security Gate

    needs: generate-reports

    runs-on: ubuntu-latest

    steps:

      - name: Download Reports
        uses: actions/download-artifact@v4

        with:
          name: reports

      - name: Fail Build If Vulnerabilities Found
        run: |

          CRITICAL=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' trivy.json)

          HIGH=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length' trivy.json)

          echo "CRITICAL: $CRITICAL"

          echo "HIGH: $HIGH"

          if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
            echo "HIGH or CRITICAL vulnerabilities found"
            exit 1
          fi

  # =========================================
  # UPDATE README
  # =========================================

  update-readme:
    name: Update README

    needs: security-gate

    runs-on: ubuntu-latest

    permissions:
      contents: write

    steps:

      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Download Reports
        uses: actions/download-artifact@v4

        with:
          name: reports

      - name: Update README
        run: |

          python3 << 'EOF'

          from pathlib import Path
          import re

          readme = Path("README.md").read_text()

          trivy = Path("trivy.md").read_text()

          ai = Path("ai.md").read_text()

          readme = re.sub(
              r'<!-- TRIVY-TABLE-START -->.*?<!-- TRIVY-TABLE-END -->',
              f'<!-- TRIVY-TABLE-START -->\n{trivy}\n<!-- TRIVY-TABLE-END -->',
              readme,
              flags=re.S
          )

          readme = re.sub(
              r'<!-- AI-START -->.*?<!-- AI-END -->',
              f'<!-- AI-START -->\n{ai}\n<!-- AI-END -->',
              readme,
              flags=re.S
          )

          Path("README.md").write_text(readme)

          EOF

  # =========================================
  # COMMIT README
  # =========================================

  commit-readme:
    name: Commit README

    needs: update-readme

    runs-on: ubuntu-latest

    permissions:
      contents: write

    steps:

      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Commit README Changes
        run: |

          git config user.name "github-actions"

          git config user.email "github-actions@github.com"

          git add README.md

          git diff --cached --quiet && exit 0

          git commit -m "[skip ci] update trivy report"

          git push
```

### reusable-docker.yml
```
name: Reusable Docker Build and Push

on:
  workflow_call:

    inputs:
      image_name:
        required: true
        type: string

      tag:
        required: true
        type: string

      sha_tag:
        required: false
        type: string
        default: ""

      push:
        required: false
        type: boolean
        default: true

    secrets:
      docker_username:
        required: true

      docker_token:
        required: true

    outputs:
      image_url:
        description: "Docker image URL"
        value: ${{ jobs.docker.outputs.image_url }}

jobs:
  docker:
    runs-on: ubuntu-latest

    outputs:
      image_url: ${{ steps.meta.outputs.image_url }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login DockerHub
        if: inputs.push == true
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.docker_username }}
          password: ${{ secrets.docker_token }}

      - name: Build Tags
        id: tags
        run: |
          TAGS="${{ inputs.image_name }}:${{ inputs.tag }}"

          if [ -n "${{ inputs.sha_tag }}" ]; then
            TAGS="${TAGS},${{ inputs.image_name }}:${{ inputs.sha_tag }}"
          fi

          echo "tags=$TAGS" >> "$GITHUB_OUTPUT"

      - name: Build and Push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ inputs.push }}
          tags: ${{ steps.tags.outputs.tags }}

      - name: Set Output
        id: meta
        run: |
          echo "image_url=${{ inputs.image_name }}:${{ inputs.tag }}" >> "$GITHUB_OUTPUT"
```
</details>

**Note:** The Dependency Review Action only runs on pull requests because it compares dependency changes between the source and target branches.

---

### Task 4: Add Permissions to Your Workflows
By default, workflows get broad permissions. Lock them down.

Add this block near the top of your workflow files (after `on:`):
```yaml
permissions:
  contents: read
```

If a workflow needs to comment on PRs, add:
```yaml
permissions:
  contents: read
  pull-requests: write
```

Update at least 2 of your existing workflow files with a `permissions` block.

## Write in your notes: 

### Why is it a good practice to limit workflow permissions?
- Limiting workflow permissions follows the principle of least privilege.
- Workflows should only receive the minimum permissions required to perform their tasks.
- Restricting permissions reduces the impact of compromised workflows or malicious third-party actions.
- It helps protect repository contents, branches, workflows, and secrets from unauthorized modifications.

### What could go wrong if a compromised action has write access to your repository?
- A malicious or compromised action could:
- Modify application source code
- Push unauthorized commits
- Alter CI/CD workflows
- Steal repository secrets or tokens
- Delete branches or tags
- Inject malicious code into deployments
- Compromise the entire repository and CI/CD pipeline

---

### Task 5: See the Full Secure Pipeline
Look at what your pipeline does now:

```
PR opened
  → build & test
  → dependency vulnerability check     ← NEW (Day 49)
  → PR checks pass or fail

Merge to main
  → build & test
  → Docker build
  → Trivy image scan (fail on CRITICAL) ← NEW (Day 49)
  → Docker push (only if scan passes)
  → deploy

Always active
  → GitHub secret scanning              ← NEW (Day 49)
  → push protection for secrets         ← NEW (Day 49)
```

Draw this diagram in your notes. You just built a **DevSecOps pipeline** — security is now part of your automation, not an afterthought.



------

```bash
# =========================================================
# FLOW
# validate-secrets
#        ↓
# build-test
#        ↓
# docker
#        ↓
# trivy-scan
#    ↙      ↘
# reports   dashboard
#      ↘    ↙
#    security-gate
#          ↓
#       deploy
# =========================================================
```


```bash
PR opened
  → build & test
      ✅ Covered

  → dependency vulnerability check
      ✅ Covered
      (Trivy + dependency scanning)

  → PR checks pass or fail
      ✅ Covered
      (security gate + workflow status)
Merge to main
  → build & test
      ✅ Covered

  → Docker build
      ✅ Covered

  → Trivy image scan (fail on CRITICAL)
      ✅ Covered

  → Docker push (only if scan passes)
      ✅ Covered

  → deploy
      ✅ Covered
Always active
  → GitHub secret scanning
      ✅ Covered

  → push protection for secrets
      ✅ Covered
```
---

<img width="2084" height="1328" alt="mermaid-diagram" src="https://github.com/user-attachments/assets/b76742ef-c32e-4a09-a720-96d085eacc65" />

---

<img width="1920" height="4355" alt="serif" src="https://github.com/user-attachments/assets/68f45883-c438-4470-a9ce-1573b9de8437" />
<img width="1920" height="2062" alt="Security-Dashboard-05-27-2026_02_41_PM" src="https://github.com/user-attachments/assets/e1b68ab8-9764-441e-bd89-0f8cf6124bd0" />
<img width="922" height="316" alt="Screenshot 2026-05-27 005917" src="https://github.com/user-attachments/assets/fabe6d14-0acc-4ca4-94df-8daf4aa1b0c1" />



---

### Note:

- Secret scanning detects sensitive information such as API keys, tokens, and passwords accidentally committed to source code, helping prevent credential leaks.
- Dependency Review analyzes project dependencies to identify vulnerable, outdated, or risky packages before they are merged into the main branch.

- DevSecOps is the practice of integrating security into every stage of the software development and deployment lifecycle.
- Development, Security, and Operations teams collaborate to identify and remediate security issues early in the CI/CD lifecycle.


- https://github.com/malathi-shetty/github-actions-capstone/security/code-scanning
- https://github.com/malathi-shetty/github-actions-capstone/security

<img width="922" height="316" alt="image" src="https://github.com/user-attachments/assets/a16b042a-9a78-44ad-85b4-cf611b609a06" />
<img width="1018" height="460" alt="image" src="https://github.com/user-attachments/assets/1bbeccb1-1822-403b-b45b-38deffa05f0d" />

----


# Brownie Points (Optional — For the Curious)
Pin Actions to Commit SHAs
Tags like @v4 can be moved by the action author. For extra security, pin to the exact commit:

### Instead of this:
`uses: actions/checkout@v4`

### Use this:
`uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1`
This protects against supply chain attacks where a tag is silently changed.

<details>
<summary>View Full Workflow</summary>

```bash
name: Reusable Docker Build and Push

on:
  workflow_call:

    inputs:
      image_name:
        required: true
        type: string

      tag:
        required: true
        type: string

      sha_tag:
        required: false
        type: string
        default: ""

      push:
        required: false
        type: boolean
        default: true

    secrets:
      docker_username:
        required: true

      docker_token:
        required: true

    outputs:
      image_url:
        description: "Docker image URL"
        value: ${{ jobs.docker.outputs.image_url }}

jobs:
  docker:
    runs-on: ubuntu-latest

    outputs:
      image_url: ${{ steps.meta.outputs.image_url }}

    steps:
      - uses: actions/checkout@v4

      - name: Setup Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login DockerHub
        if: inputs.push == true
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.docker_username }}
          password: ${{ secrets.docker_token }}

      - name: Build Tags
        id: tags
        run: |
          TAGS="${{ inputs.image_name }}:${{ inputs.tag }}"

          if [ -n "${{ inputs.sha_tag }}" ]; then
            TAGS="${TAGS},${{ inputs.image_name }}:${{ inputs.sha_tag }}"
          fi

          echo "tags=$TAGS" >> "$GITHUB_OUTPUT"

      - name: Build and Push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ inputs.push }}
          tags: ${{ steps.tags.outputs.tags }}

      - name: Set Output
        id: meta
        run: |
          echo "image_url=${{ inputs.image_name }}:${{ inputs.tag }}" >> "$GITHUB_OUTPUT"
```

```bash
name: Main Pipeline

on:
  push:
    branches:
      - main

  pull_request:
    branches:
      - main

  workflow_dispatch:

  # =====================================================
  #  Weekly scheduled security scan
  #  Runs every Monday at 09:00 UTC
  # =====================================================
  schedule:
    - cron: "0 9 * * 1"

permissions:
  contents: write
  security-events: write
  pull-requests: write

# =========================================================
# DEVSECOPS PIPELINE FLOW
#
# build-test
#      ↓
# docker-build
#      ↓
# trivy-scan
#      ↓
# reports + dashboard (parallel)
#      ↓
# sha-audit
#      ↓
# security-gate
#      ↓
# deploy
#
# =========================================================

jobs:

# =========================================================
# 1. BUILD & TEST
# =========================================================
  build-test:
    name: Build & Test

    uses: ./.github/workflows/reusable-build-test.yml

    with:
      node_version: "20"
      run_tests: true


# =========================================================
# 2. DOCKER BUILD
# =========================================================
  docker:
    name: Docker Build

    needs: build-test

    uses: ./.github/workflows/reusable-docker.yml

    with:
      image_name: "shettymalathi113/github-actions-capstone"
      tag: v1.0.${{ github.run_number }}
      sha_tag: sha-${{ github.sha }}
      push: true

    secrets:
      docker_username: ${{ secrets.DOCKER_USERNAME }}
      docker_token: ${{ secrets.DOCKER_TOKEN }}


# =========================================================
# 3. TRIVY SECURITY SCAN
# =========================================================
  trivy-scan:
    name: Trivy Scan

    needs: docker

    runs-on: ubuntu-latest

    permissions:
      contents: read
      security-events: write
      pull-requests: write

    steps:

      # =====================================================
      # PINNED SHA - CHECKOUT
      # =====================================================
      - name: Checkout Repository
        uses: actions/checkout@c2d88d3ecc89a9ef08eebf45d9637801dcee7eb5
        # v4


      # =====================================================
      # INSTALL TOOLS
      # =====================================================
      - name: Install jq + Trivy
        run: |
          sudo apt-get update
          sudo apt-get install -y jq trivy


      # =====================================================
      # PINNED SHA - CACHE
      # =====================================================
      - name: Cache Trivy DB
        uses: actions/cache@27d5ce7f107fe9357f9df03efb73ab90386fccae
        # v4

        with:
          path: ~/.cache/trivy
          key: trivy-db-${{ runner.os }}
          restore-keys: |
            trivy-db-${{ runner.os }}-


      # =====================================================
      # # JSON Vulnerability Scan
      # =====================================================
      - name: Run JSON Scan
        run: |
          trivy image \
            --severity HIGH,CRITICAL \
            --ignore-unfixed \
            --format json \
            --output trivy.json \
            shettymalathi113/github-actions-capstone:v1.0.${{ github.run_number }}


      # =====================================================
      # SARIF Vulnerability Scan
      # =====================================================
      - name: Run SARIF Scan
        run: |
          trivy image \
            --severity HIGH,CRITICAL \
            --ignore-unfixed \
            --format sarif \
            --output trivy-results.sarif \
            shettymalathi113/github-actions-capstone:v1.0.${{ github.run_number }}


      # =====================================================
      # PINNED SHA - UPLOAD ARTIFACT
      # =====================================================
      - name: Upload JSON Artifact
        uses: actions/upload-artifact@65462800fd760344b1a7b4382951275a0abb4808
        # v4

        with:
          name: trivy-json
          path: trivy.json


      - name: Upload SARIF Artifact
        uses: actions/upload-artifact@65462800fd760344b1a7b4382951275a0abb4808
        # v4

        with:
          name: trivy-sarif
          path: trivy-results.sarif


      # =====================================================
      # Upload SARIF Results to GitHub Security Tab
      # =====================================================
      - name: Upload SARIF Results
        uses: github/codeql-action/upload-sarif@v3

        with:
          sarif_file: trivy-results.sarif


      # =====================================================
      #  SARIF Security Validation
      # =====================================================
      - name: SARIF Security Gate
        run: |
          COUNT=$(jq '[.runs[].results[]? | select(.level=="error")] | length' trivy-results.sarif)

          echo "SARIF Issues: $COUNT"

          if [ "$COUNT" -gt 0 ]; then
            echo "❌ BLOCKED by SARIF Gate"
            exit 1
          fi


# =========================================================
# 4. GENERATE REPORTS
# =========================================================
  generate-reports:
    name: Generate Reports

    needs: trivy-scan

    runs-on: ubuntu-latest

    steps:

      # =====================================================
      # PINNED SHA - DOWNLOAD ARTIFACT
      # =====================================================
      - name: Download Trivy JSON
        uses: actions/download-artifact@fa0a91b85d4f404e444e00e005971372dc801d16
        # v4

        with:
          name: trivy-json


      # =====================================================
      # BUILD REPORTS
      # =====================================================
      - name: Build Reports
        run: |
          echo "## 📦 Trivy Report" > trivy.md

          jq -r '.Results[]?.Vulnerabilities[]? |
          "| \(.Severity) | \(.PkgName) | \(.VulnerabilityID) | \(.InstalledVersion) | \(.FixedVersion // "N/A") |"' \
          trivy.json >> trivy.md

          echo "" >> trivy.md
          echo "Generated automatically by GitHub Actions" >> trivy.md

          echo "## 🤖 AI Security Summary" > ai.md
          echo "- Security scan completed" >> ai.md
          echo "- Reports generated successfully" >> ai.md


      # =====================================================
      # PINNED SHA - UPLOAD REPORTS
      # =====================================================
      - name: Upload Reports
        uses: actions/upload-artifact@65462800fd760344b1a7b4382951275a0abb4808
        # v4

        with:
          name: reports
          path: |
            trivy.md
            ai.md


# =========================================================
# 5. SECURITY DASHBOARD
# =========================================================
  security-dashboard:
    name: Security Dashboard

    needs: trivy-scan

    runs-on: ubuntu-latest

    steps:

      - name: Download Trivy JSON
        uses: actions/download-artifact@fa0a91b85d4f404e444e00e005971372dc801d16
        # v4

        with:
          name: trivy-json


      # =====================================================
      # SECURITY SUMMARY
      # =====================================================
      - name: JSON Scan Summary
        run: |
          echo "## 🛡 Security Dashboard" >> $GITHUB_STEP_SUMMARY

          CRITICAL=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' trivy.json)
          HIGH=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length' trivy.json)

          echo "" >> $GITHUB_STEP_SUMMARY
          echo "| Severity | Count |" >> $GITHUB_STEP_SUMMARY
          echo "|---|---|" >> $GITHUB_STEP_SUMMARY
          echo "| Critical | $CRITICAL |" >> $GITHUB_STEP_SUMMARY
          echo "| High | $HIGH |" >> $GITHUB_STEP_SUMMARY


# =========================================================
# 6. SHA AUDIT DASHBOARD
# =========================================================
  sha-audit:
    name: SHA Compliance Audit

    runs-on: ubuntu-latest

    steps:

      - name: Checkout Repository
        uses: actions/checkout@c2d88d3ecc89a9ef08eebf45d9637801dcee7eb5

      # =====================================================
      # FETCH LIVE SHAS
      # =====================================================
      - name: Fetch Latest SHAs
        run: |

          CHECKOUT_SHA=$(git ls-remote https://github.com/actions/checkout.git | head -1 | awk '{print $1}')

          CACHE_SHA=$(git ls-remote https://github.com/actions/cache.git | head -1 | awk '{print $1}')

          UPLOAD_SHA=$(git ls-remote https://github.com/actions/upload-artifact.git | head -1 | awk '{print $1}')

          DOWNLOAD_SHA=$(git ls-remote https://github.com/actions/download-artifact.git | head -1 | awk '{print $1}')

          echo "================================================="
          echo "LIVE SHA AUDIT"
          echo "================================================="

          echo "Checkout: $CHECKOUT_SHA"
          echo "Cache: $CACHE_SHA"
          echo "Upload: $UPLOAD_SHA"
          echo "Download: $DOWNLOAD_SHA"

          echo "" >> $GITHUB_STEP_SUMMARY
          echo "## 🔐 SHA Compliance Dashboard" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY

          echo "| Action | Current SHA |" >> $GITHUB_STEP_SUMMARY
          echo "|---|---|" >> $GITHUB_STEP_SUMMARY
          echo "| actions/checkout | $CHECKOUT_SHA |" >> $GITHUB_STEP_SUMMARY
          echo "| actions/cache | $CACHE_SHA |" >> $GITHUB_STEP_SUMMARY
          echo "| actions/upload-artifact | $UPLOAD_SHA |" >> $GITHUB_STEP_SUMMARY
          echo "| actions/download-artifact | $DOWNLOAD_SHA |" >> $GITHUB_STEP_SUMMARY


# =========================================================
# 7. SECURITY GATE
# =========================================================
  security-gate:
    name: Security Gate

    needs:
      - trivy-scan
      - generate-reports
      - security-dashboard
      - sha-audit

    runs-on: ubuntu-latest

    steps:

      - name: Download Trivy JSON
        uses: actions/download-artifact@fa0a91b85d4f404e444e00e005971372dc801d16
        # v4

        with:
          name: trivy-json


      # =====================================================
      # FINAL SECURITY CHECK
      # =====================================================
      - name: Final Evaluation
        run: |
          CRITICAL=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' trivy.json)

          HIGH=$(jq '[.Results[].Vulnerabilities[]? | select(.Severity=="HIGH")] | length' trivy.json)

          echo "CRITICAL=$CRITICAL"
          echo "HIGH=$HIGH"

          if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
            echo "❌ SECURITY GATE FAILED"
            exit 1
          fi

          echo "✅ SECURITY GATE PASSED"


# =========================================================
# 8. DEPLOY
# =========================================================
  deploy:
    name: Deploy

    needs: security-gate

    runs-on: ubuntu-latest

    steps:

      - name: Deploy Application
        run: |
          echo "🚀 Deploying v1.0.${{ github.run_number }}"
          echo "Application LIVE"
```
</details>




**Note:**
> SARIF (Static Analysis Results Interchange Format) is a standardized format used by GitHub Security for displaying vulnerability and code scanning results.
> 
> Pinning GitHub Actions to commit SHAs ensures workflows always use verified and immutable action versions.
> 
> This implementation follows shift-left security practices by integrating vulnerability detection directly into the CI/CD pipeline.

- https://github.com/malathi-shetty/github-actions-capstone/actions/runs/26506903486
- https://github.com/malathi-shetty/github-actions-capstone/tree/pin-commit-sha/.github
- https://github.com/malathi-shetty/github-actions-capstone/blob/pin-commit-sha/.github/dependabot.yml

<img width="668" height="179" alt="Pin SHA" src="https://github.com/user-attachments/assets/3d1b870f-55c7-4344-b86e-e281a4a58846" />
<img width="1920" height="2897" alt="Pin SHA-2" src="https://github.com/user-attachments/assets/e4cdf2f5-85bd-4100-b047-97037575b478" />




---

# PENDING:

Learn About OIDC (Keyless Authentication)
Instead of storing cloud credentials as long-lived secrets, GitHub Actions can use OIDC to get short-lived tokens automatically. Research: "GitHub Actions OIDC" — it's how production pipelines authenticate to AWS, GCP, and Azure without storing any keys.

---

## Key Learnings

- Implemented DevSecOps practices directly into CI/CD
- Learned vulnerability management using Trivy
- Integrated SARIF with GitHub Security
- Applied least-privilege workflow permissions
- Implemented supply-chain protection using SHA pinning
- Built deployment blocking security gates
- Understood risks of outdated Docker base images

---

## Future Improvements

- Implement OIDC-based cloud authentication
- Add Kubernetes deployment scanning
- Integrate SAST tooling
- Add container signing with Cosign
- Add SBOM generation
- Add Dependabot auto-remediation
