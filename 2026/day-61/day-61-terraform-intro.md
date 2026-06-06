# Day 61 -- Introduction to Terraform and Your First AWS Infrastructure
---
## Challenge Tasks

### Task 1: Understand Infrastructure as Code
Before touching the terminal, research and write short notes on:


## 1. What is Infrastructure as Code (IaC)? Why does it matter in DevOps?

Infrastructure as Code (IaC) means writing code to define and manage infrastructure like servers, networks, databases, and storage instead of creating them manually in cloud dashboards.

In DevOps, it matters because it makes infrastructure repeatable, automated, and version-controlled. Teams can build the same environment anywhere just by running code, which reduces errors and improves collaboration between developers and operations.

---

## 2. What problems does IaC solve compared to manual AWS console setup?

When infrastructure is created manually in the AWS console, it leads to:

* Human errors (wrong settings, missed steps)
* No clear history of changes
* Hard to reproduce environments
* Difficult collaboration between team members
* Time-consuming setup for new environments

IaC solves these by making infrastructure:

* Reproducible using code
* Trackable through Git
* Automatable via CI/CD pipelines
* Consistent across environments (dev, staging, prod)
* Easier to destroy and recreate when needed

---

## 3. How is Terraform different from CloudFormation, Ansible, and Pulumi?

Terraform is focused on **provisioning infrastructure across multiple cloud providers**.

* **Terraform**

  * Multi-cloud (AWS, Azure, GCP, etc.)
  * Uses HCL (HashiCorp Configuration Language)
  * Strong ecosystem of providers

* **AWS CloudFormation**

  * Works only with AWS
  * Uses YAML/JSON
  * Deep integration with AWS services

* **Ansible**

  * Focused on configuration management (installing software, setting up servers)
  * Agentless and uses YAML
  * Not primarily for creating cloud infrastructure

* **Pulumi**

  * Uses real programming languages like Python, TypeScript, Go
  * More flexible and developer-friendly
  * Still less widely used than Terraform

---

## 4. What does “declarative” and “cloud-agnostic” mean in Terraform?

### Declarative

Terraform is declarative because you only describe **what you want**, not **how to do it**.

Example:
You say “I want an EC2 instance with t2.micro”.

Terraform decides:

* How to create it
* What order to create resources in
* What changes are needed

You don’t write step-by-step instructions.

---

### Cloud-agnostic

Terraform is cloud-agnostic because it works with many cloud providers, not just AWS.

You can use the same Terraform workflow to manage:

* AWS resources
* Azure resources
* Google Cloud resources
* Kubernetes clusters
* SaaS tools like GitHub or Cloudflare

So you are not locked into a single cloud provider.



---

### Task 2: Install Terraform and Configure AWS
1. Install Terraform:
```bash
# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Linux (amd64)
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Windows
choco install terraform
```

2. Verify:
```bash
terraform -version
```

3. Install and configure the AWS CLI:
```bash
aws configure
# Enter your Access Key ID, Secret Access Key, default region (e.g., ap-south-1), output format (json)
```

4. Verify AWS access:
```bash
aws sts get-caller-identity
```

You should see your AWS account ID and ARN.

<img width="1224" height="263" alt="image" src="https://github.com/user-attachments/assets/9023fd5c-6e23-4ed7-9e46-882a9291ad1e" />


---

### Task 3: Your First Terraform Config -- Create an S3 Bucket
Create a project directory and write your first Terraform config:

```bash
mkdir terraform-basics && cd terraform-basics
```

Create a file called `main.tf` with:
1. A `terraform` block with `required_providers` specifying the `aws` provider
2. A `provider "aws"` block with your region
3. A `resource "aws_s3_bucket"` that creates a bucket with a globally unique name

`main.tf`
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "terra_bucket" {
  bucket = "terraweek-malathi-2026-unique12345"
}
```

Run the Terraform lifecycle:
```bash
terraform init      # Download the AWS provider
terraform plan      # Preview what will be created
terraform apply     # Create the bucket (type 'yes' to confirm)
```

Go to the AWS S3 console and verify your bucket exists.

<img width="1853" height="858" alt="image" src="https://github.com/user-attachments/assets/acfd8366-68ef-4aa9-ba4a-80d7be390006" />


**Document:** What did `terraform init` download? What does the `.terraform/` directory contain?

##  What did `terraform init` download?

It downloaded:

* AWS provider plugin (`hashicorp/aws`)
* Required binaries to communicate with AWS API
* Dependency metadata for Terraform execution

Without this, Terraform cannot talk to AWS.

---

##  What does `.terraform/` contain?

Inside your project, `.terraform/` contains:

### 1. Provider binaries

* AWS provider executable files
* Used to create/update AWS resources

### 2. Plugin cache

* Stores downloaded providers
* Avoids re-downloading every run

### 3. Metadata files

* Internal Terraform configuration data

Example structure:

```text
.terraform/
└── providers/
    └── registry.terraform.io/
        └── hashicorp/
            └── aws/
```

---

## Also created:

### `.terraform.lock.hcl`

This file:
* Locks provider versions so every machine uses same AWS provider version.
* Ensures consistency across machines

---

##  Summary 
✔ Installed Terraform AWS provider
✔ Initialized a working Terraform project
✔ Defined infrastructure using code
✔ Created an S3 bucket in AWS using Terraform
✔ Understood state + provider download process

## Key Learning 
✔ Terraform = declarative infra tool
✔ Provider = bridge between Terraform and AWS
✔ init = downloads providers
✔ state = remembers what you created

---

### Task 4: Add an EC2 Instance
In the same `main.tf`, add:
1. A `resource "aws_instance"` using AMI `ami-0f5ee92e2d63afc18` (Amazon Linux 2 in ap-south-1 -- use the correct AMI for your region)
2. Set instance type to `t2.micro`
3. Add a tag: `Name = "TerraWeek-Day1"`

Run:
```bash
terraform plan      # You should see 1 resource to add (bucket already exists)
terraform apply
```

Go to the AWS EC2 console and verify your instance is running with the correct name tag.

<img width="1674" height="807" alt="image" src="https://github.com/user-attachments/assets/e8d1b28a-2571-4219-85ee-4526da6ec6c7" />


**Document:** How does Terraform know the S3 bucket already exists and only the EC2 instance needs to be created?

```bash
ubuntu@ip-172-31-36-28:~/90DaysOfDevOps_TrainWithShubham/2026/day-61/manifests$ aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-2.0.20260427.1-x86_64-gp2" \
  --query "Images[*].ImageId" \
  --output text
ami-003c5247665391546
```

##  Step 1: Update `main.tf`

Add this **below your S3 bucket resource**:

```hcl id="x8c2pm"
resource "aws_instance" "terra_ec2" {
  ami           = "ami-003c5247665391546"
  instance_type = "t2.micro"

  tags = {
    Name = "TerraWeek-Day1"
  }
}
```

---



##  How does Terraform know the S3 bucket already exists?

Terraform uses a file called:

```text id="s4v1xn"
terraform.tfstate
```

---

##  What is happening internally?

When you run:

```bash id="q7m2zp"
terraform plan
```

Terraform compares 3 things:

---

### 1. main.tf (your desired state)

You declared:

* S3 bucket
* EC2 instance

---

### 2. terraform.tfstate (Terraform memory)

It already contains:

* S3 bucket (from previous apply)

---

### 3. Real AWS infrastructure

It checks what actually exists in AWS.

---

##  Result of comparison

| Resource     | In code | In state | Action     |
| ------------ | ------- | -------- | ---------- |
| S3 bucket    | Yes     | Yes      | Do nothing |
| EC2 instance | Yes     | No       | Create     |

---


Terraform only creates what is missing.

👉 That’s why only EC2 is created.

---

#  Key Concept (VERY IMPORTANT)

Terraform is NOT blind.

It always does:

```text id="d9kq1v"
Desired State (code)
        ↓
Terraform State (memory)
        ↓
Actual AWS Resources
        ↓
Diff + Plan
```

---



> Terraform knows the S3 bucket already exists because it tracks all created resources in `terraform.tfstate` and compares it with your current configuration before making changes.



---

### Task 5: Understand the State File
Terraform tracks everything it creates in a state file. Time to inspect it.

1. Open `terraform.tfstate` in your editor -- read the JSON structure
2. Run these commands and document what each returns:
```bash
terraform show                          # Human-readable view of current state
terraform state list        # List all resources Terraform manages
terraform state show aws_s3_bucket.<name>   # Detailed view of a specific resource
terraform state show aws_instance.<name>
```

1. `terraform show`
- Displays the full current state in a human-readable format.
- It shows detailed information about all managed resources, including:
   - `EC2 instance (ID, state, IPs, tags, etc.)`
   - `S3 bucket (name, ARN, region, configuration)`

2. `terraform state list`
- Lists all resources tracked in the Terraform state.
   - `Output shows:`  
      `aws_instance.example`
      `aws_s3_bucket.bucket`
- This confirms Terraform is managing both resources.

3. `terraform state show aws_s3_bucket.bucket`
- Displays detailed state information for the S3 bucket only, such as:
   - `Bucket name and ARN`
   - `Region`
   - `Encryption settings`
   - `Versioning configuration`

4. `terraform state show aws_instance.instance`
- Displays detailed state information for the EC2 instance, including:
   - `Instance ID and state (running)`
   - `Instance type`
   - `Public & private IPs`
   - `Subnet and security groups`
   - `Tags (Name = TerraWeek-Day1)`

3. Answer these questions in your notes:
   - What information does the state file store about each resource?
      - The state file stores the resource configuration and current attributes, such as resource ID,ARNs,IP addresses,tags and dependencies mapping Terraform config to real infrastructure.

   - Why should you never manually edit the state file?
      - Manual edits can corrupt the state and cause mismatches between Terraform and actual infrastructure, leading to errors or unintended changes
   
   - Why should the state file not be committed to Git?
      - The state file contains sensitive data and committing it can cause security risks and team conflicts.
    

---

##  1. Open `terraform.tfstate`

When you open it:

```bash id="open1"
nano terraform.tfstate
```

A large **JSON file** containing Terraform’s internal memory of your infrastructure.

---

##  What you’ll notice inside

It contains:

* Resource details (S3, EC2, etc.)
* AWS resource IDs
* Region information
* Tags
* Instance metadata
* Internal Terraform mappings

Example structure:

```json id="state1"
{
  "resources": [
    {
      "type": "aws_s3_bucket",
      "name": "terra_bucket"
    },
    {
      "type": "aws_instance",
      "name": "terra_ec2"
    }
  ]
}
```



---

#  2. Terraform State Commands

Now run each command and understand output:

---

## 🔹 A) terraform show

```bash id="cmd_show"
terraform show
```

###  What it does:

Shows full **human-readable version of state**

### You will see:

* EC2 instance details
* S3 bucket details
* AMI ID
* Instance type
* Tags
* Region
* IDs (like instance-id, bucket ARN)

 Think of it as:

> “Readable snapshot of everything Terraform created”

---

## 🔹 B) terraform state list

```bash id="cmd_list"
terraform state list
```

###  Output example:

```text id="list1"
aws_s3_bucket.terra_bucket
aws_instance.terra_ec2
```

<img width="945" height="43" alt="image" src="https://github.com/user-attachments/assets/b4637611-fea9-4e28-a199-d3151d52956a" />


### What it does:

Lists all resources Terraform is currently managing.

 Think of it as:

> “Inventory of infrastructure under Terraform control”

---

## 🔹 C) S3 Bucket details

```bash id="cmd_s3"
terraform state show aws_s3_bucket.terra_bucket
```

###  Shows:

* Bucket name
* Region
* ARN
* Creation metadata

Example:

```text id="s3out"
id = terraweek-malathi-2026-unique12345
bucket = terraweek-malathi-2026-unique12345
region = ap-south-1
```

<img width="1041" height="617" alt="image" src="https://github.com/user-attachments/assets/a445e169-8c75-442f-8d44-15830e302479" />


---

## 🔹 D) EC2 Instance details

```bash id="cmd_ec2"
terraform state show aws_instance.terra_ec2
```

### Shows:

* Instance ID (i-xxxxxx)
* AMI ID
* Instance type (t3.micro)
* Public IP
* Subnet
* Tags
* Security group
* State

---



##  What information does the state file store?

The Terraform state file stores:

* Resource IDs (like EC2 instance ID, S3 bucket name)
* AWS metadata (ARN, region, availability zone)
* Configuration values (instance type, AMI ID, tags)
* Relationship between resources
* Current real-world status of infrastructure

It is Terraform’s **source of truth about deployed infrastructure**

---

##  Why should you never manually edit the state file?

Because:

* It is automatically managed by Terraform
* Manual edits can corrupt state
* It can break resource tracking
* Terraform may recreate or delete real infrastructure
* It leads to “drift” between AWS and Terraform

Even a small mistake can destroy production resources

---

##  Why should the state file not be committed to Git?

Because it may contain:

* Sensitive infrastructure data
* Instance IDs
* IP addresses
* ARNs
* Sometimes secrets (in some setups)

Also:

* State changes frequently
* Causes merge conflicts
* Not safe for collaboration

Instead, use remote backends like:

* AWS S3 + DynamoDB
* Terraform Cloud

---


> Terraform state is a local JSON file that acts as a memory system for Terraform. It tracks all resources created in AWS and helps Terraform compare desired state (code) with real infrastructure.

---

Without state:

👉 Terraform would NOT know what it already created
👉 It would recreate everything every time

With state:

👉 Terraform becomes intelligent and incremental



---

### Task 6: Modify, Plan, and Destroy
1. Change the EC2 instance tag from `"TerraWeek-Day1"` to `"TerraWeek-Modified"` in your `main.tf`
2. Run `terraform plan` and read the output carefully:
   - What do the `~`, `+`, and `-` symbols mean?
      
      `~` Resource will be `updated in-place`

      `+` Resource will be `created`
      
      `-` Resource will be `destroyed`
      
      

   - Is this an in-place update or a destroy-and-recreate?
      - Changing the EC2 tag results in a `~ (in-place update)`

3. Apply the change
4. Verify the tag changed in the AWS console

<img width="1649" height="527" alt="image" src="https://github.com/user-attachments/assets/3618e390-f9fd-4767-9012-1a3b752b36c5" />


5. Finally, destroy everything:
```bash
terraform destroy
```
6. Verify in the AWS console -- both the S3 bucket and EC2 instance should be gone

<img width="1628" height="849" alt="image" src="https://github.com/user-attachments/assets/ab5b2b60-3b6e-4d04-972a-c8e0e9f52d1d" />


---

## Documentation


##  1. Infrastructure as Code (IaC) – My Understanding

Infrastructure as Code (IaC) is a way of managing cloud infrastructure using code instead of manually creating resources through a web console. With IaC, we define servers, storage, and networks in configuration files, which makes infrastructure reproducible and consistent. It helps automate deployment and reduces human errors. In DevOps, IaC is important because it enables version control, faster deployments, and easy collaboration between teams.

---

## 📸 2. Terraform Apply Screenshots

###  S3 Bucket and EC2 creation using Terraform



* Terraform successfully created an S3 bucket
* Terraform also launched an EC2 instance using the defined configuration

---

## 📸 3. AWS Console Verification Screenshots 

###  S3 Bucket in AWS Console


###  EC2 Instance in AWS Console



* EC2 instance is running
* Correct tag is applied (`TerraWeek-Day1` or modified version)
* Resources match Terraform configuration

---

##  4. Terraform Commands Explanation

### 🔹 terraform init

Initializes the Terraform project by downloading required provider plugins (like AWS). It also creates the `.terraform/` directory and prepares the working environment.

---

### 🔹 terraform plan

Shows a preview of what Terraform will create, modify, or delete without making any actual changes. It helps review infrastructure changes safely before applying them.

---

### 🔹 terraform apply

Executes the changes defined in the configuration files and creates or updates real infrastructure in AWS after confirmation.

---

### 🔹 terraform destroy

Deletes all infrastructure resources that were created by Terraform and removes them from AWS.

---

### 🔹 terraform show

Displays the current state of infrastructure in a human-readable format based on the state file.

---

### 🔹 terraform state list

Lists all resources currently being managed by Terraform in the state file.

---

##  5. Terraform State File – What it contains and why it matters

The Terraform state file (`terraform.tfstate`) stores detailed information about all resources created by Terraform, including instance IDs, bucket names, AMI IDs, tags, and configuration details. It acts as Terraform’s memory to track what resources already exist in the cloud.

It is important because Terraform uses it to compare desired state (code) with actual infrastructure and decide what needs to be created, updated, or deleted. The state file should never be manually edited or pushed to Git because it may contain sensitive data and can break infrastructure tracking if corrupted.

---

