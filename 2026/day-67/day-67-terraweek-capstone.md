# Day 67 -- TerraWeek Capstone: Multi-Environment Infrastructure with Workspaces and Modules

## Challenge Tasks

### Task 1: Learn Terraform Workspaces
Before building the project, understand workspaces:

```bash
mkdir terraweek-capstone && cd terraweek-capstone
terraform init

# See current workspace
terraform workspace show                    # default

# Create new workspaces
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod



# List all workspaces
terraform workspace list



# Switch between them
terraform workspace select dev
terraform workspace select staging
terraform workspace select prod
```

<img width="1147" height="1130" alt="image" src="https://github.com/user-attachments/assets/b43aac7f-59e8-4f79-a4bd-fe40c25f6419" />

---

## 1. What does `terraform.workspace` return inside a config?

`terraform.workspace` is a built-in Terraform variable that returns the name of the currently selected workspace.

Example:

```hcl
locals {
  env = terraform.workspace
}
```

If you run:

```bash
terraform workspace select dev
```

then:

```hcl
terraform.workspace
```

returns:

```text
dev
```

If you switch to:

```bash
terraform workspace select prod
```

it returns:

```text
prod
```

### Common usage

```hcl
resource "aws_instance" "server" {
  instance_type = terraform.workspace == "prod" ? "t3.small" : "t2.micro"

  tags = {
    Environment = terraform.workspace
  }
}
```

This allows a single codebase to behave differently depending on the workspace.

---

## 2. Where does each workspace store its state file?

Terraform keeps a separate state file for each workspace.

### Default workspace

Uses:

```text
terraform.tfstate
```

### Additional workspaces

Stored under:

```text
terraform.tfstate.d/
├── dev/
│   └── terraform.tfstate
├── staging/
│   └── terraform.tfstate
└── prod/
    └── terraform.tfstate
```

So:

| Workspace | State File                                      |
| --------- | ----------------------------------------------- |
| default   | `terraform.tfstate`                             |
| dev       | `terraform.tfstate.d/dev/terraform.tfstate`     |
| staging   | `terraform.tfstate.d/staging/terraform.tfstate` |
| prod      | `terraform.tfstate.d/prod/terraform.tfstate`    |

### With an S3 backend

Terraform automatically separates state by workspace.

Example:

```text
s3://terraform-state-bucket/env:/dev/terraform.tfstate
s3://terraform-state-bucket/env:/staging/terraform.tfstate
s3://terraform-state-bucket/env:/prod/terraform.tfstate
```

Each workspace still gets its own isolated state.

---

## 3. How is this different from using separate directories per environment?

### Workspaces Approach

Single codebase:

```text
terraform-project/
├── main.tf
├── variables.tf
└── workspaces
    ├── dev
    ├── staging
    └── prod
```

Advantages:

* One source of truth
* Less duplicated code
* Easier maintenance
* Simple environment switching

Example:

```bash
terraform workspace select dev
```

No code changes required.

---

### Separate Directories Approach

```text
terraform-project/
├── dev/
│   └── main.tf
├── staging/
│   └── main.tf
└── prod/
    └── main.tf
```

Advantages:

* Stronger isolation
* Environment-specific customization
* Easier access control

Disadvantages:

* Code duplication
* More maintenance
* Harder to keep environments consistent

---

## Summary

| Feature     | Workspaces             | Separate Directories          |
| ----------- | ---------------------- | ----------------------------- |
| Codebase    | Single                 | Multiple                      |
| State Files | Separate per workspace | Separate per directory        |
| Maintenance | Easier                 | More effort                   |
| Duplication | Minimal                | Higher                        |
| Isolation   | Logical                | Physical                      |
| Best For    | Similar environments   | Highly different environments |

### Key Takeaway

* `terraform.workspace` returns the active workspace name.
* Each workspace has its own independent state file.
* Workspaces let you manage **dev, staging, and prod from one codebase**, while separate directories use multiple copies of Terraform configurations.




---

### Task 2: Set Up the Project Structure
Create this layout:

```
terraweek-capstone/
  main.tf                   # Root module -- calls child modules
  variables.tf              # Root variables
  outputs.tf                # Root outputs
  providers.tf              # AWS provider and backend
  locals.tf                 # Local values using workspace
  dev.tfvars                # Dev environment values
  staging.tfvars            # Staging environment values
  prod.tfvars               # Prod environment values
  .gitignore                # Ignore state, .terraform, tfvars with secrets
  modules/
    vpc/
      main.tf
      variables.tf
      outputs.tf
    security-group/
      main.tf
      variables.tf
      outputs.tf
    ec2-instance/
      main.tf
      variables.tf
      outputs.tf
```

Create the `.gitignore`:
```
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
.terraform.lock.hcl
```

<img width="887" height="641" alt="image" src="https://github.com/user-attachments/assets/4e59f3bc-3c9b-4ca0-b18b-55d7f3d90032" />


**Document:** Why is this file structure considered best practice?
> This structure follows Terraform best practices by separating providers, variables, outputs, locals, and resource definitions into dedicated files. 
> Reusable infrastructure components are encapsulated into modules, making the code easier to maintain, test, and scale. 
> Workspaces provide environment isolation while allowing all environments to share the same codebase, reducing duplication and improving consistency across dev, staging, and prod.


---

### Task 3: Build the Custom Modules
Create three focused modules:

**Module 1: `modules/vpc/`**
- Input: `cidr`, `public_subnet_cidr`, `environment`, `project_name`
- Resources: VPC, public subnet, internet gateway, route table, route table association
- Output: `vpc_id`, `subnet_id`
- All resources tagged with environment and project name

**Module 2: `modules/security-group/`**
- Input: `vpc_id`, `ingress_ports`, `environment`, `project_name`
- Resources: Security group with dynamic ingress rules, allow all egress
- Output: `sg_id`

**Module 3: `modules/ec2-instance/`**
- Input: `ami_id`, `instance_type`, `subnet_id`, `security_group_ids`, `environment`, `project_name`
- Resources: EC2 instance with tags
- Output: `instance_id`, `public_ip`

Write and validate each module:
```bash
terraform validate
```

<img width="1096" height="182" alt="image" src="https://github.com/user-attachments/assets/1f7c7ff7-91cd-40c1-974d-e8e0d0bcb8dc" />




---

### Task 4: Wire It All Together with Workspace-Aware Config
In the root module, use `terraform.workspace` to drive environment-specific behavior.

**`locals.tf`:**
```hcl
locals {
  environment = terraform.workspace
  name_prefix = "${var.project_name}-${local.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Workspace   = terraform.workspace
  }
}
```

**`variables.tf`:**
```hcl
variable "project_name" {
  type    = string
  default = "terraweek"
}

variable "vpc_cidr" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ingress_ports" {
  type    = list(number)
  default = [22, 80]
}
```

**`main.tf`** -- call all three modules, passing workspace-aware names and variables.

**Environment-specific tfvars:**

`dev.tfvars`:
```hcl
vpc_cidr      = "10.0.0.0/16"
subnet_cidr   = "10.0.1.0/24"
instance_type = "t3.micro"  # Im taking here `t3.micro`,`t2.micro` is not available in my AWS account
```

`staging.tfvars`:
```hcl
vpc_cidr      = "10.1.0.0/16"
subnet_cidr   = "10.1.1.0/24"
instance_type = "t3.small" 
ingress_ports = [22, 80, 443]
```

`prod.tfvars`:
```hcl
vpc_cidr      = "10.2.0.0/16"
subnet_cidr   = "10.2.1.0/24"
instance_type = "c7i-flex.large"  # Im taking here c7i-flex.large
ingress_ports = [80, 443]
```

Notice: dev allows SSH, prod does not. Different CIDRs prevent overlap. Instance types scale up per environment.

---

### Task 5: Deploy All Three Environments
Deploy each environment using its workspace and tfvars file:

**Dev:**
```bash
terraform workspace select dev
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

<img width="1392" height="612" alt="image" src="https://github.com/user-attachments/assets/2f925bfa-1819-42bc-8dc3-e40d5be30d70" />
<img width="772" height="311" alt="image" src="https://github.com/user-attachments/assets/40894fc1-a125-4f07-b783-edcfeb46f003" />
<img width="1217" height="1254" alt="terraform plan -var-file-dev tfvars" src="https://github.com/user-attachments/assets/caa73c54-5d5d-4e77-9915-adafcc8be127" />


**Staging:**
```bash
terraform workspace select staging
terraform plan -var-file="staging.tfvars"
terraform apply -var-file="staging.tfvars"
```
<img width="1237" height="96" alt="image" src="https://github.com/user-attachments/assets/91a4a556-66a1-4332-8b2a-44a5082567d6" />
<img width="1220" height="1182" alt="image" src="https://github.com/user-attachments/assets/9a14d838-e427-45d0-8d1f-a4fed2c5d220" />
<img width="1362" height="1255" alt="image" src="https://github.com/user-attachments/assets/2f84bf56-34b7-4f6a-9b69-41efc1add9b2" />


**Prod:**
```bash
terraform workspace select prod
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```
<img width="1187" height="121" alt="image" src="https://github.com/user-attachments/assets/981c6290-2e14-4a38-ab85-8756e0067be8" />
<img width="1177" height="1160" alt="image" src="https://github.com/user-attachments/assets/ffda83b7-348c-455d-95e2-869c1166178d" />
<img width="1197" height="1258" alt="image" src="https://github.com/user-attachments/assets/9ebbaa7a-a6c6-480a-8fe0-63ba81713648" />


After all three are deployed, verify:
```bash
# Check each workspace's resources
terraform workspace select dev && terraform output
terraform workspace select staging && terraform output
terraform workspace select prod && terraform output
```

<img width="1170" height="540" alt="image" src="https://github.com/user-attachments/assets/ad18e513-9731-4c86-b624-253e4f69e0b3" />


Go to the AWS console and verify:
- Three separate VPCs with different CIDR ranges
- Three EC2 instances with different instance types
- Different Name tags per environment: `terraweek-dev-server`, `terraweek-staging-server`, `terraweek-prod-server`

EC2:
<img width="2241" height="357" alt="image" src="https://github.com/user-attachments/assets/f4cde965-622b-44ea-ae67-96218bc9f925" />


VPC:
<img width="2212" height="457" alt="image" src="https://github.com/user-attachments/assets/4e0538c1-5af4-4d00-b88e-44df8bac8924" />


Subnet:
<img width="2235" height="332" alt="image" src="https://github.com/user-attachments/assets/2182c6f6-fa83-4121-accf-98bfeca96cd1" />


Security:
<img width="2197" height="1015" alt="image" src="https://github.com/user-attachments/assets/8a358b96-ffb1-4ed3-a871-e15974cac3af" />
<img width="2207" height="1031" alt="image" src="https://github.com/user-attachments/assets/cdc6d545-5fce-4ab4-bd1a-d29d8e5fe5d0" />
<img width="2206" height="1022" alt="image" src="https://github.com/user-attachments/assets/5dcbc3e9-dd21-4e5c-bb29-7f37408980ec" />


**Verify:** Are all three environments completely isolated from each other?

<img width="1157" height="91" alt="image" src="https://github.com/user-attachments/assets/15ef4001-362e-4a3f-b85e-29606c321bc3" />

# Are All Three Environments Completely Isolated?

**Yes.**

Each environment has:

- Separate Terraform state

```text
dev state
staging state
prod state
```

- Separate VPC

```text
10.0.0.0/16
10.1.0.0/16
10.2.0.0/16
```

- Separate subnet

- Separate route table

- Separate internet gateway

- Separate security group

- Separate EC2 instance

- Separate resource names

```text
terraweek-dev-*
terraweek-staging-*
terraweek-prod-*
```

- Separate outputs

---

# Expected Verification Summary for Documentation

You can include:

| Resource      | Dev         | Staging     | Prod        |
| ------------- | ----------- | ----------- | ----------- |
| Workspace     | dev         | staging     | prod        |
| VPC CIDR      | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Subnet CIDR   | 10.0.1.0/24 | 10.1.1.0/24 | 10.2.1.0/24 |
| Instance Type | t2.micro    | t2.small    | t3.small    |
| Open Ports    | 22,80       | 22,80,443   | 80,443      |
| State File    | Separate    | Separate    | Separate    |

**Result:** One Terraform codebase successfully manages three independent AWS environments using workspaces and custom modules.




---

### Task 6: Terraform best practices guide:
 
1. **File Structure** — Separate files for each concern: `providers.tf`, `variables.tf`, `outputs.tf`, `locals.tf`, `main.tf`
2. **State Management** — Remote S3 backend with `encrypt = true`, `use_lockfile = true`. Each workspace gets its own state file at `env:/<workspace>/terraweek-capstone/terraform.tfstate`
3. **Variables** — Never hardcode values. Used `dev/staging/prod.tfvars` per environment.
4. **Modules** — One concern per module. Three focused modules: `vpc/` (networking), `security-group/` (access control), `ec2-instance/` (compute). Each module has `main.tf`, `variables.tf`, `outputs.tf`
5. **Workspaces** — Three workspaces for full environment isolation. `terraform.workspace` drives environment name through `locals.tf`. One codebase, three environments
6. **Security** — `.gitignore` excludes `*.tfvars`, `*.tfstate`, `.terraform/`. State encrypted at rest with `encrypt = true`. No credentials hardcoded anywhere
7. **Commands** — Always `terraform validate` → `terraform plan` → `terraform apply`. Never skip plan. Use `terraform fmt` before committing
8. **Tagging** — Every resource tagged with `Environment`, `Project`, `ManagedBy = "Terraform"`.
9. **Naming** — Consistent pattern: `<environment>-<project>-<resource>` e.g. `dev-terraweek-VPC`, `terraweek-prod-Server`
10. **Cleanup** — always `terraform destroy` non-production environments when not in use

---

## 1. File Structure (Separation of Concerns)

Terraform configurations should always be split into logical files:

* `providers.tf` → provider configuration (AWS, backend, version constraints)
* `variables.tf` → all input variables
* `locals.tf` → computed values and reusable expressions
* `main.tf` → core infrastructure resources and module calls
* `outputs.tf` → exported values after deployment

### Why this matters

* Improves readability
* Makes debugging easier
* Enables team collaboration
* Scales cleanly for large infrastructure

---

## 2. State Management

State is the source of truth in Terraform.

### Best practices:

* Always use a **remote backend (S3, Terraform Cloud, etc.)**
* Enable **state locking (DynamoDB for AWS)**
* Enable **versioning for rollback safety**
* Encrypt state at rest (S3 SSE or KMS)

### Why this matters

* Prevents state corruption
* Enables team collaboration
* Avoids concurrent modification issues

---

## 3. Variables

Never hardcode values inside Terraform resources.

### Best practices:

* Use `variables.tf` for all inputs
* Use `tfvars` files for environments (dev/staging/prod)
* Use `validation` blocks for safety

Example:

```hcl
variable "instance_type" {
  type = string

  validation {
    condition     = contains(["t2.micro", "t2.small", "t3.small"], var.instance_type)
    error_message = "Invalid instance type"
  }
}
```

---

## 4. Modules

Modules are the foundation of reusable infrastructure.

### Best practices:

* One module = one responsibility (VPC, EC2, SG)
* Always define **inputs and outputs explicitly**
* Avoid hardcoding values inside modules
* Use version-pinned registry modules when applicable

### Why this matters

* Reusability across projects
* Easier testing
* Cleaner architecture

---

## 5. Workspaces

Workspaces enable multiple environments from a single codebase.

### Best practices:

* Use workspaces for environment separation (dev/staging/prod)
* Reference `terraform.workspace` in configurations
* Keep state isolated per workspace

### Important note:

Workspaces isolate **state**, not network design.

---

## 6. Security

Security must be built into Terraform workflows.

### Best practices:

* Add `.gitignore` for:

  * `.terraform/`
  * `*.tfstate`
  * `*.tfvars`
* Never commit secrets or credentials
* Encrypt backend state (S3 SSE / KMS)
* Restrict IAM permissions for Terraform execution

---

## 7. Commands Workflow

Always follow a safe execution order:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

### Why this matters

* Prevents syntax errors
* Ensures configuration validity
* Avoids unintended infrastructure changes

---

## 8. Tagging Strategy

Every resource must be tagged consistently.

### Standard tags:

* Project
* Environment
* ManagedBy
* Owner (optional)
* CostCenter (recommended in enterprise setups)

### Example:

```hcl
tags = {
  Project     = "terraweek"
  Environment = "dev"
  ManagedBy   = "Terraform"
}
```

---

## 9. Naming Conventions

Use a consistent naming pattern:

```
<project>-<environment>-<resource>
```

### Examples:

* terraweek-dev-vpc
* terraweek-prod-server
* terraweek-staging-sg

### Why this matters

* Easy identification in cloud console
* Prevents naming collisions
* Improves operational clarity

---

## 10. Cleanup Strategy

Always destroy non-production resources when not in use.

### Best practices:

* Use `terraform destroy` for dev/staging
* Avoid leaving test infrastructure running
* Automate teardown for temporary environments

### Why this matters

* Reduces cloud costs
* Prevents resource sprawl
* Keeps environment clean and controlled

---

#  Final Summary

Terraform best practices focus on:

* Clean architecture (files + modules)
* Safe state management
* Environment isolation using workspaces
* Security-first design
* Repeatable and automated workflows




---

### Task 7: Destroy All Environments
Clean up all three environments in reverse order:

```bash
terraform workspace select prod
terraform destroy -var-file="prod.tfvars"

terraform workspace select staging
terraform destroy -var-file="staging.tfvars"

terraform workspace select dev
terraform destroy -var-file="dev.tfvars"
```
<img width="942" height="552" alt="image" src="https://github.com/user-attachments/assets/ac9cc0ad-7487-464b-bead-9dcdbfc89c0a" />


Verify in the AWS console -- all VPCs, instances, security groups, and gateways should be gone.

<img width="2217" height="271" alt="image" src="https://github.com/user-attachments/assets/b88d0f3d-9f42-4dda-a98f-8ef412630133" />
<img width="2230" height="457" alt="image" src="https://github.com/user-attachments/assets/998ced15-c579-4abe-a159-0c3ce3525e1e" />


Delete the workspaces:
```bash
terraform workspace select default
terraform workspace delete dev
terraform workspace delete staging
terraform workspace delete prod
```

<img width="1167" height="182" alt="image" src="https://github.com/user-attachments/assets/3edd4292-67da-4742-8ad3-625be82b16fd" />


**Verify:** Is your AWS account completely clean?
- Yes — AWS account is completely clean
  
---


## Documentation

---


#  Complete Project Structure

```text
terraweek-capstone/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── locals.tf
├── dev.tfvars
├── staging.tfvars
├── prod.tfvars
├── .gitignore
└── modules/
    ├── vpc/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── security-group/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ec2-instance/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

#  Root Configuration

---

## providers.tf

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

---

## variables.tf

```hcl
variable "project_name" {
  type    = string
  default = "terraweek"
}

variable "vpc_cidr" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ingress_ports" {
  type = list(number)
}
```

---

## locals.tf (Workspace Awareness)

```hcl
locals {
  environment = terraform.workspace

  name_prefix = "${var.project_name}-${local.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = local.environment
    ManagedBy   = "Terraform"
    Workspace   = terraform.workspace
  }
}
```

---

## main.tf (WORKSPACE-AWARE MODULE CALLS)

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*"]
  }
}

module "vpc" {
  source             = "./modules/vpc"
  cidr               = var.vpc_cidr
  public_subnet_cidr = var.subnet_cidr
  environment        = local.environment
  project_name       = var.project_name
}

module "security_group" {
  source        = "./modules/security-group"
  vpc_id        = module.vpc.vpc_id
  ingress_ports = var.ingress_ports
  environment   = local.environment
  project_name  = var.project_name
}

module "ec2" {
  source             = "./modules/ec2-instance"
  ami_id             = data.aws_ami.amazon_linux.id
  instance_type      = var.instance_type
  subnet_id          = module.vpc.subnet_id
  security_group_ids = [module.security_group.sg_id]
  environment        = local.environment
  project_name       = var.project_name
}
```

---

## outputs.tf

```hcl
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "subnet_id" {
  value = module.vpc.subnet_id
}

output "security_group_id" {
  value = module.security_group.sg_id
}

output "instance_id" {
  value = module.ec2.instance_id
}

output "public_ip" {
  value = module.ec2.public_ip
}
```

---

#  MODULES

---

#  VPC Module

## modules/vpc/main.tf

```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-subnet"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

## modules/vpc/variables.tf

```hcl
variable "cidr" {}
variable "public_subnet_cidr" {}
variable "environment" {}
variable "project_name" {}
```

## modules/vpc/outputs.tf

```hcl
output "vpc_id" {
  value = aws_vpc.this.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}
```

---

#  Security Group Module

## modules/security-group/main.tf

```hcl
resource "aws_security_group" "this" {
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_ports

    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

## variables + outputs

```hcl
variable "vpc_id" {}
variable "ingress_ports" {}
variable "environment" {}
variable "project_name" {}

output "sg_id" {
  value = aws_security_group.this.id
}
```

---

#  EC2 Module

## modules/ec2-instance/main.tf

```hcl
resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-server"
    Environment = var.environment
    Project     = var.project_name
  }
}
```

## variables + outputs

```hcl
variable "ami_id" {}
variable "instance_type" {}
variable "subnet_id" {}
variable "security_group_ids" {}
variable "environment" {}
variable "project_name" {}

output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  value = aws_instance.this.public_ip
}
```

---

#  ENV FILES (IMPORTANT DIFFERENCE)

---

## dev.tfvars

```hcl
vpc_cidr      = "10.0.0.0/16"
subnet_cidr   = "10.0.1.0/24"
instance_type = "t2.micro"
ingress_ports = [22, 80]
```

---

## staging.tfvars

```hcl
vpc_cidr      = "10.1.0.0/16"
subnet_cidr   = "10.1.1.0/24"
instance_type = "t2.small"
ingress_ports = [22, 80, 443]
```

---

## prod.tfvars

```hcl
vpc_cidr      = "10.2.0.0/16"
subnet_cidr   = "10.2.1.0/24"
instance_type = "t3.small"
ingress_ports = [80, 443]
```

---

#  REQUIRED LINKEDIN PROOF

Attach:

## 1. Terraform workspace list

```bash
terraform workspace list
```

## 2. AWS VPC screen (3 VPCs)

## 3. EC2 instances (3 environments)

## 4. terraform output per workspace

```bash
terraform workspace select dev
terraform output
```

(staging + prod same)

---

# 📘 BEST PRACTICES (FINAL)

* Modular infrastructure design
* Workspace-based environment isolation
* Never hardcode values
* Use tfvars per environment
* Separate files for clarity
* Tag everything
* Use dynamic security rules
* Always run fmt → validate → plan → apply
* Destroy non-prod environments after use

---

#  TERRAWEEK LEARNING MAP

| Day | Concepts                                 |
| --- | ---------------------------------------- |
| 61  | IaC basics, HCL, init/plan/apply/destroy |
| 62  | Providers, resources, lifecycle          |
| 63  | Variables, outputs, locals, functions    |
| 64  | Remote backend, locking, drift           |
| 65  | Modules, reuse, versioning               |
| 66  | EKS real-world infra                     |
| 67  | Workspaces + multi-env architecture      |

---

#  FINAL RESULT

You built:

✔ One Terraform codebase
✔ Three isolated environments
✔ Modular AWS infrastructure
✔ Workspace-based deployments
✔ Production-style architecture

