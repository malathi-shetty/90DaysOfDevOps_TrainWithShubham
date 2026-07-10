Yes! This task is essentially **documentation**, so let's make it look like something a DevOps engineer would write. You can use **your own screenshots from previous days**, which makes the submission much stronger.

Here's a complete version you can use and customize.

# Task 1: The End-to-End DevOps Pipeline

## Overview

During this 90-day journey, I learned that DevOps is not about individual tools but about how they work together to automate software delivery. A single code change passes through multiple stages before reaching production. Below is the complete lifecycle of a feature in the AI-BankApp project.

---

## 1. Development on Linux

The journey starts on a Linux machine, where the developer writes or modifies the application code. Linux provides the development environment, while shell scripts automate repetitive tasks such as running tests, formatting code, or starting the application. Git is used to track changes and maintain version control.

**Tools Used:** Linux, Bash, Git

---

* Linux terminal showing the project directory (`pwd`, `ls`)
* Git status or commit (`git status`, `git commit`)
* Running a shell script (`./scripts/test.sh`)

<img width="793" height="816" alt="image" src="https://github.com/user-attachments/assets/dd7eeae2-709e-44ac-96d4-ffaab6f82edd" />
<img width="567" height="322" alt="image" src="https://github.com/user-attachments/assets/62cfddb4-2544-41de-89ef-392ed35a44f7" />
<img width="882" height="1042" alt="image" src="https://github.com/user-attachments/assets/8f4336a7-00c9-424a-ac9a-059422ec0250" />
<img width="675" height="277" alt="image" src="https://github.com/user-attachments/assets/3b50d0d3-fd62-48c7-845a-b6a1a942160f" />


---

## 2. Push Code to GitHub

After testing the changes locally, the developer commits the code and pushes it to the GitHub repository. This push automatically triggers the GitHub Actions workflow configured for the project.

**Tools Used:** Git, GitHub, GitHub Actions

---

* GitHub repository showing a recent commit
* GitHub Actions workflow starting after a push

<img width="901" height="405" alt="image" src="https://github.com/user-attachments/assets/06f10229-d933-4159-bd52-95a85e995ba6" />
<img width="1184" height="405" alt="image" src="https://github.com/user-attachments/assets/5b375125-19d6-47a8-9d95-ffd3fba2face" />
<img width="1920" height="1182" alt="image" src="https://github.com/user-attachments/assets/0ad8e16a-adda-4720-a9a4-626f20ccec16" />
<img width="1920" height="2841" alt="image" src="https://github.com/user-attachments/assets/560635d5-6e8b-4e86-8a90-bbd5971deea2" />
<img width="1920" height="2570" alt="image" src="https://github.com/user-attachments/assets/f04582ce-b9ff-4698-8b7e-8ccc2eee22f9" />


---

## 3. Build and Push Docker Image

The GitHub Actions workflow builds a Docker image using the application's Dockerfile. Once the build succeeds, the image is tagged with the new version and pushed to Docker Hub, making it available for deployment.

**Tools Used:** Docker, Docker Hub, GitHub Actions

---

* Successful Docker image build logs
* Docker Hub repository with the latest image tag

<img width="1600" height="380" alt="image" src="https://github.com/user-attachments/assets/f0a9063b-5ad9-4f9c-817e-df8f4334bac2" />
<img width="1576" height="813" alt="image" src="https://github.com/user-attachments/assets/b694283b-e731-4aaf-90b4-81f594e4ef86" />

<img width="2542" height="1143" alt="image" src="https://github.com/user-attachments/assets/6c483a12-c32d-4001-96b6-d2d6f6987ec2" />


---

## 4. Update Kubernetes Configuration

After publishing the Docker image, the deployment configuration is updated with the new image tag. This change is committed back to the Git repository so that Git always represents the desired state of the application.

**Tools Used:** Git, Kubernetes Manifests

---

* Git commit showing the updated image tag
* `deployment.yaml` or Helm values file containing the new image version


<img width="1905" height="1037" alt="image" src="https://github.com/user-attachments/assets/e511fffd-4ccb-4e4c-80dd-58c382d564f3" />
<img width="1681" height="1024" alt="image" src="https://github.com/user-attachments/assets/c8a9ee30-c8e4-4671-8e69-56ce44aa10c0" />


---

## 5. ArgoCD Deploys to Amazon EKS

ArgoCD continuously monitors the Git repository. When it detects the updated deployment configuration, it synchronizes the changes with the Amazon EKS cluster and performs the deployment automatically.

**Tools Used:** ArgoCD, Amazon EKS

---

* ArgoCD Application dashboard showing **Synced** and **Healthy**
* EKS workload after deployment

<img width="2247" height="502" alt="image" src="https://github.com/user-attachments/assets/f45a13da-4aa6-4fa1-b4dd-cd3f50631cc2" />
<img width="1207" height="552" alt="image" src="https://github.com/user-attachments/assets/820f7ebf-2473-4ca9-99dc-0e0af9260d7b" />

<img width="2557" height="1337" alt="image" src="https://github.com/user-attachments/assets/e6574fdc-5ae2-47c1-ba75-bd39edac79b1" />
<img width="2557" height="1382" alt="image" src="https://github.com/user-attachments/assets/7346787f-0771-4d18-b9c5-9632dabd7eec" />


---

## 6. Infrastructure Managed by Terraform and Ansible

The Amazon EKS cluster and supporting AWS resources are provisioned using Terraform. Ansible is then used to configure systems and ensure they remain in the desired state. This provides a repeatable and automated infrastructure setup.

**Tools Used:** Terraform, Ansible

---

* `terraform apply` output
* Ansible playbook execution (`PLAY RECAP`)

<img width="1170" height="540" alt="image" src="https://github.com/user-attachments/assets/3dcf1001-84e4-4831-b4f8-3e273696dbdd" />
<img width="1217" height="1254" alt="image" src="https://github.com/user-attachments/assets/42fcb201-e123-4400-9192-4a6eff95052c" />
<img width="1247" height="607" alt="image" src="https://github.com/user-attachments/assets/b3e301ab-b69a-425a-8214-b8e0baeffd6c" />
<img width="1337" height="872" alt="image" src="https://github.com/user-attachments/assets/01fd8890-4a02-40a8-87c7-8e6425b10fb9" />


---

## 7. Helm Manages the Deployment

Helm packages the Kubernetes resources into reusable charts. Different environments such as development, staging, and production use different values files, allowing the same application to be deployed with environment-specific configurations.

**Tools Used:** Helm

**Suggested Screenshot:**

* Helm chart directory structure
* `helm install` or `helm upgrade` output
* `values-dev.yaml` or `values-prod.yaml`

<img width="1201" height="1106" alt="image" src="https://github.com/user-attachments/assets/3ed3ae04-0431-422c-bb17-7366373e6f3b" />
<img width="1087" height="992" alt="image" src="https://github.com/user-attachments/assets/b518a86c-eb46-40b2-a9b5-bd462dccbce1" />


---

## 8. Observability with Prometheus, Grafana, and Loki

Once the application is running, observability tools monitor its health and performance. Prometheus collects metrics, Grafana visualizes dashboards, and Loki stores application logs. Together, they help identify performance issues and troubleshoot problems.

**Tools Used:** Prometheus, Grafana, Loki

**Suggested Screenshot:**

* Grafana dashboard
* Prometheus targets or metrics page
* Loki log query results


<img width="2560" height="2077" alt="image" src="https://github.com/user-attachments/assets/75ce20a6-abe9-43a1-ae4d-d8629bb6cea2" />
<img width="1920" height="1252" alt="image" src="https://github.com/user-attachments/assets/287597a6-3c9a-4c5f-9b01-4de7258a94cc" />
<img width="2560" height="1296" alt="image" src="https://github.com/user-attachments/assets/0914f2ee-811e-4965-812f-461319632c01" />
  <img width="1920" height="1658" alt="image" src="https://github.com/user-attachments/assets/f3cf576f-6e2a-4df9-9480-4c5817d4f2a3" />


---

## 9. AI Agent Troubleshooting

If an issue occurs, an AI-powered DevOps agent analyzes Kubernetes resources, application logs, metrics, and recent Git changes. Based on this analysis, it identifies the root cause and suggests or creates a fix.

**Tools Used:** AI Agent, Kubernetes, Prometheus, Loki

**Suggested Screenshot:**

* AI agent output (if available)
* Terminal showing troubleshooting commands (`kubectl logs`, `kubectl describe pod`)
* KubeHealer or MCP demonstration (if completed)

  <img width="2007" height="1191" alt="image" src="https://github.com/user-attachments/assets/54ac2848-2236-43c6-9d07-8fe2ea58b4af" />
<img width="1455" height="606" alt="image" src="https://github.com/user-attachments/assets/3a02639a-b7a6-481a-9f86-26f29c84ef23" />
<img width="1260" height="580" alt="image" src="https://github.com/user-attachments/assets/a571766f-d15c-421d-bf14-023b5c50fbe0" />


---

## 10. Continuous Improvement

The proposed fix is reviewed and committed to Git. GitHub Actions builds a new Docker image, ArgoCD deploys the updated version to Amazon EKS, and monitoring continues. This creates a continuous feedback loop where every change is automatically tested, deployed, monitored, and improved.

---

## End-to-End Workflow

```text
Developer (Linux)
        │
        ▼
Git Commit & Push
        │
        ▼
GitHub Actions (CI)
        │
        ▼
Docker Build & Push
        │
        ▼
Update Kubernetes Configuration
        │
        ▼
ArgoCD (GitOps)
        │
        ▼
Amazon EKS
        │
        ▼
Helm Deployment
        │
        ▼
Prometheus + Grafana + Loki
        │
        ▼
AI Agent Analysis
        │
        ▼
Git Fix → Continuous Deployment
```

## Conclusion

This journey taught me that every DevOps tool has a specific purpose, but the real power comes from integrating them into a single automated workflow. From writing code on Linux to deploying applications on Amazon EKS with GitOps and monitoring them with observability tools, each stage builds on the previous one to create a reliable, scalable, and production-ready software delivery pipeline.


---



## Task 2: AI-BankApp – Bringing Everything Together

The AI-BankApp served as my capstone project during the final phase of the 90 Days of DevOps challenge. Instead of learning each tool in isolation, I applied them to a single real-world application and built a complete production-ready deployment pipeline.

### Day 78 – MySQL Deployment with Helm

I deployed the MySQL database as a Helm chart, making the database installation reusable, configurable, and easier to manage across different environments.

<img width="1312" height="95" alt="image" src="https://github.com/user-attachments/assets/67083c23-ff65-49ec-94f7-2d0cad12c3c9" />


---

### Day 79 – Converting Kubernetes Manifests to Helm

I converted the application's raw Kubernetes manifests into a reusable Helm chart. This improved maintainability and simplified deployments by replacing multiple YAML files with parameterized templates.

<img width="1135" height="307" alt="image" src="https://github.com/user-attachments/assets/c8c575c9-a3de-498b-a176-ee7c68caaeff" />


---

### Day 80 – Multi-Environment Configuration

I created separate values files for development, staging, and production environments. I also integrated Helm with the CI/CD pipeline, making deployments environment-specific and more automated.

<img width="1325" height="841" alt="image" src="https://github.com/user-attachments/assets/2ed42986-5b7a-4a0a-91f1-4b36645e2a79" />


---

### Day 81 – Provisioning Amazon EKS with Terraform

I used Terraform to provision the AWS infrastructure, including the Amazon EKS cluster and its supporting resources. This demonstrated Infrastructure as Code (IaC) by creating cloud resources in a repeatable and version-controlled way.

<img width="1255" height="502" alt="image" src="https://github.com/user-attachments/assets/de5ca989-2fc3-4936-a3fa-c96e5272b185" />


---

### Day 82 – Configuring Production Features

I configured production-ready Kubernetes features such as the Gateway API, persistent storage using Amazon EBS, and session persistence to improve application reliability and availability.

<img width="1570" height="181" alt="image" src="https://github.com/user-attachments/assets/9b25b590-c3b8-409e-aaa1-f1fa4c9c1aee" />


---

### Day 83 – Production Deployment with Monitoring

I successfully deployed the AI-BankApp to Amazon EKS and verified that it was running correctly. I also integrated monitoring tools to observe the application's health and performance.

<img width="2547" height="1321" alt="image" src="https://github.com/user-attachments/assets/9cfc1b58-5635-414d-a226-1ca0153f1815" />
<img width="1920" height="1668" alt="image" src="https://github.com/user-attachments/assets/1fe7f46e-1d4c-4d76-bcb1-df1c7e504f20" />


---

### Day 84 – GitOps Deployment with ArgoCD

I deployed the application using ArgoCD by connecting the Git repository to the Kubernetes cluster. ArgoCD continuously synchronized the desired state stored in Git with the running application.

<img width="2550" height="1191" alt="image" src="https://github.com/user-attachments/assets/d5beef88-7c83-445c-b3cf-14c705362c25" />


---

### Day 85 – Advanced GitOps Configuration

I enhanced the GitOps setup by implementing Sync Waves, the App of Apps pattern, and Role-Based Access Control (RBAC). These improvements enabled better deployment ordering, scalability, and secure access management.

<img width="2321" height="946" alt="image" src="https://github.com/user-attachments/assets/9c0316f4-0ed5-41ff-9dbd-49886ce8f037" />


---

### Day 86 – End-to-End GitOps Automation

I completed the CI/CD pipeline by integrating GitHub Actions with ArgoCD. Every code change automatically triggered the build process, published a new Docker image, updated the deployment configuration, and synchronized the application to the Amazon EKS cluster through GitOps.

<img width="1536" height="1024" alt="image" src="https://github.com/user-attachments/assets/14d01c35-0220-4252-9227-0fbdb0f75613" />


---

## What I Learned

The AI-BankApp brought together everything I learned during the final 13 days of the challenge. It demonstrated how Infrastructure as Code, Kubernetes, Helm, GitHub Actions, ArgoCD, observability, and automation work together to deliver applications reliably.

Rather than practicing individual tools separately, I built a complete DevOps workflow that takes an application from source code to a production-ready deployment on Amazon EKS using GitOps principles.

---

### Task 3: Skills Inventory
Rate yourself on each skill. Be honest -- this is for you, not anyone else.

| Skill | Days | Confidence (1-5) |
|-------|------|------------------|
| Linux command line | 1-13 | 3 |
| Shell scripting | 16-21 | 3|
| Git & GitHub | 22-28 | 3 |
| Docker | 29-37 | 3|
| CI/CD (GitHub Actions) | 38-49 | 3|
| Kubernetes | 50-58 |3 |
| Terraform | 59-67 | 3|
| Ansible | 68-72 |3 |
| Observability (Prometheus, Grafana, Loki) | 73-77 |3 |
| Helm | 78-80 |3 |
| Amazon EKS | 81-83 | 3|
| ArgoCD / GitOps | 84-86 |3 |
| Agentic AI for DevOps | 87-89 |3 |

---

# Task 4: What Comes Next

Completing the 90 Days of DevOps challenge is not the end of my learning journey - it's the beginning. This challenge gave me a strong foundation in Linux, Git, Docker, Kubernetes, Terraform, Helm, GitHub Actions, ArgoCD, and cloud-native DevOps practices. My next goal is to deepen these skills by building more real-world projects and gaining production-level experience.

## Areas I Want to Explore

### Advanced Kubernetes

I want to learn more about multi-cluster Kubernetes, cluster federation, fleet management, and service mesh technologies like Istio and Linkerd to better understand large-scale deployments.

### Infrastructure as Code

I plan to expand my Terraform knowledge by learning modules in greater depth, Terragrunt, custom providers, remote state management, and drift detection.

### Secrets and Security

Managing sensitive information securely is an important DevOps skill. I want to explore HashiCorp Vault, AWS Secrets Manager, and the External Secrets Operator to improve application security.

### Observability and Reliability

I want to strengthen my monitoring skills by learning advanced Prometheus queries, creating better Grafana dashboards, and experimenting with distributed tracing and alerting strategies.

### Database Operations

I plan to learn database backups, migrations, disaster recovery, and blue-green deployment strategies to better support production applications.

### Chaos Engineering and FinOps

Understanding how systems behave during failures and optimizing cloud costs are important production skills. I plan to explore Litmus Chaos, Chaos Monkey, and FinOps best practices.

## Certifications I Plan to Pursue

To validate my skills and continue learning, I would like to work toward the following certifications:

* AWS Certified Solutions Architect – Associate
* Certified Kubernetes Administrator (CKA)
* Certified Kubernetes Application Developer (CKAD)
* HashiCorp Terraform Associate
* GitHub Actions Certification

## My Next Portfolio Project

My next goal is to build a complete production-ready DevOps project from scratch using everything I learned during this challenge.

The project will include:

* Developing a web application
* Containerizing it with Docker
* Packaging it using Helm
* Provisioning Amazon EKS with Terraform
* Deploying through ArgoCD using GitOps
* Building a CI/CD pipeline with GitHub Actions
* Monitoring with Prometheus and Grafana
* Exploring AI-powered troubleshooting for Kubernetes

I will publish the complete source code on GitHub, document the architecture, write a technical blog explaining the implementation, and share my learning journey on LinkedIn.

## Final Thoughts

The 90 Days of DevOps challenge has given me the confidence to continue learning beyond the fundamentals. While there is still a lot to explore, I now understand how modern DevOps tools fit together to build reliable, automated, and scalable software delivery pipelines. My focus going forward is to gain more hands-on experience, contribute to open-source projects, and continue learning by building.


---

# 🎓 Day 90 Graduation – My DevOps Journey

## Introduction

Ninety days ago, I started this challenge with basic Linux commands and very little knowledge of the DevOps ecosystem. Throughout this journey, I learned not only individual tools but also how they work together to build, deploy, monitor, and maintain modern applications.

This challenge taught me that DevOps is more than automation - it's about creating reliable, repeatable, and scalable software delivery pipelines.

---

# 90-Day Timeline

## Weeks 1–2: Linux Fundamentals (Days 1–13)

* Linux commands and navigation
* File system management
* Permissions and ownership
* Process management
* Package management
* LVM and storage

**Key takeaway:** Linux is the foundation of every DevOps environment.

---

## Week 3: Networking & Shell Scripting (Days 14–21)

* Networking basics
* DNS, IP addressing, ports
* Bash scripting
* Functions and automation

**Key takeaway:** Automating repetitive tasks saves time and reduces errors.

---

## Week 4: Git & GitHub (Days 22–28)

* Version control
* Branching and merging
* GitHub collaboration
* GitHub CLI

**Key takeaway:** Every change should be tracked and version controlled.

---

## Week 5–6: Docker (Days 29–37)

* Docker images
* Containers
* Dockerfiles
* Volumes
* Networking
* Docker Compose

**Key takeaway:** Containers provide consistent environments across development and production.

---

## Week 7: GitHub Actions CI/CD (Days 38–49)

* Workflow automation
* YAML configuration
* Secrets management
* Automated testing and deployment

**Key takeaway:** CI/CD enables faster and more reliable software delivery.

---

## Week 8: Kubernetes (Days 50–58)

* Pods
* Deployments
* Services
* ConfigMaps
* RBAC

**Key takeaway:** Kubernetes simplifies application orchestration and scaling.

---

## Week 9: Terraform (Days 59–67)

* Infrastructure as Code
* Providers
* State management
* Modules
* Workspaces

**Key takeaway:** Infrastructure should be reproducible and version controlled.

---

## Week 10: Ansible (Days 68–72)

* Inventory
* Playbooks
* Roles
* Templates
* Vault

**Key takeaway:** Configuration management keeps systems consistent.

---

## Week 11: Observability (Days 73–77)

* Prometheus
* Grafana
* Loki
* OpenTelemetry

**Key takeaway:** Monitoring and logging are essential for understanding application health.

---

## Week 12: Helm & Amazon EKS (Days 78–83)

* Helm charts
* Environment-specific values
* Amazon EKS
* Persistent storage
* Gateway API

**Key takeaway:** Production deployments become easier through reusable packaging and managed Kubernetes.

---

## Week 13: GitOps & Agentic AI (Days 84–89)

* ArgoCD
* GitOps workflows
* Sync strategies
* AI-powered troubleshooting
* Kubernetes automation

**Key takeaway:** GitOps and AI improve deployment consistency and operational efficiency.

---

# My Top 5 Aha Moments

1. **Everything is connected.** Linux, Docker, Kubernetes, Terraform, Helm, and GitOps are parts of one complete delivery pipeline.

2. **Infrastructure can be treated like code.** Terraform completely changed how I think about creating cloud infrastructure.

3. **Containers solve consistency problems.** Docker ensures applications behave the same across environments.

4. **GitOps simplifies deployments.** Using Git as the source of truth makes deployments predictable and auditable.

5. **Observability is essential.** Metrics, logs, and dashboards provide the visibility needed to maintain reliable systems.

---

# The Hardest Part

One of the most challenging parts of this journey was understanding Kubernetes concepts and integrating multiple tools together during the final project.

Whenever I got stuck, I revisited the documentation, broke problems into smaller steps, practiced the commands again, and learned by fixing my own mistakes. Every challenge helped me build confidence.

---

# Skills Inventory

| Skill                       | Confidence |
| --------------------------- | :--------: |
| Linux Command Line          |    3   |
| Shell Scripting             |     3    |
| Git & GitHub                |    3   |
| Docker                      |    3   |
| GitHub Actions              |     3    |
| Kubernetes                  |    3    |
| Terraform                   |    3    |
| Ansible                     |     3    |
| Prometheus / Grafana / Loki |     3    |
| Helm                        |     3    |
| Amazon EKS                  |    3    |
| ArgoCD / GitOps             |     3    |
| Agentic AI for DevOps       |     3    |

---

# Screenshot Gallery (Added above in Task 1 & Task 2)

Include screenshots from your journey:

* Linux terminal
* GitHub Actions workflow
* Docker image build
* Terraform provisioning
* Kubernetes pods
* Helm deployment
* ArgoCD dashboard
* Grafana monitoring dashboard
* AI-BankApp running on Amazon EKS

---

# What's Next

My learning journey continues with:

* Multi-cluster Kubernetes
* Service Mesh (Istio, Linkerd)
* Advanced Terraform
* Secrets Management
* Chaos Engineering
* FinOps
* AWS and Kubernetes certifications

I also plan to build a complete production-ready project from scratch using everything I learned throughout this challenge.

---

# Advice for Someone Starting Day 1

# Advice for Someone Starting Day 1

If you're starting this challenge today, my biggest advice is simple: **don't give up.**

Don't worry if everything feels overwhelming in the beginning. DevOps introduces many new tools and concepts, and it's completely normal to feel confused at first.

There will be days when nothing works. You'll run into unexpected errors, spend hours debugging, and sometimes feel like you're not making any progress. You might even feel like quitting. I had moments where I stepped away for a day or two, took a break, and then came back with a fresh mindset. That's okay - what matters is that you come back and keep going.

Focus on learning **one concept at a time**. You don't have to master everything in a single day. Practice consistently, and don't be afraid to make mistakes. Every mistake is an opportunity to learn something new.

One of the best ways to learn DevOps is by **building, breaking, and fixing systems**. The troubleshooting process teaches you far more than simply following tutorials.

You also don't need to memorize every command. Professional engineers use documentation, search for solutions, and increasingly use AI tools to help them solve problems. What's important is understanding the concepts and knowing how the different tools fit together.

Remember that **every expert was once a beginner**. Stay consistent, keep experimenting, ask for help when you're stuck, and enjoy the learning process.

When you look back after 90 days, you'll realize just how much you've grown. The person who starts on Day 1 is very different from the person who completes Day 90.

Keep learning, keep building, and most importantly, believe in yourself. The journey is absolutely worth it. 


---

# Final Reflection

Completing the 90 Days of DevOps challenge has been an incredible learning experience. Beyond mastering individual tools, I learned how modern software moves from a developer's laptop to a production Kubernetes cluster through automation, Infrastructure as Code, GitOps, observability, and continuous improvement.

This is not the end of my DevOps journey - it's the foundation for everything I build next.

**Happy Learning!**

---

## Task 6: Share Your Achievement
You spent 90 days showing up. That matters.



