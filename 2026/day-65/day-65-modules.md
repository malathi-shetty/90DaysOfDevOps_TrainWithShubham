# Day 65 -- Terraform Modules: Build Reusable Infrastructure

## Challenge Tasks

### Task 1: Understand Module Structure
A Terraform module is just a directory with `.tf` files. Create this structure:

```
terraform-modules/
  main.tf                    # Root module -- calls child modules
  variables.tf               # Root variables
  outputs.tf                 # Root outputs
  providers.tf               # Provider config
  modules/
    ec2-instance/
      main.tf                # EC2 resource definition
      variables.tf           # Module inputs
      outputs.tf             # Module outputs
    security-group/
      main.tf                # Security group resource definition
      variables.tf           # Module inputs
      outputs.tf             # Module outputs
```

Create all the directories and empty files. This is the standard layout every Terraform project follows.

<img width="918" height="386" alt="image" src="https://github.com/user-attachments/assets/4f86bbd4-6e2e-4536-9319-00bafb6d3ff9" />



**Document:** What is the difference between a "root module" and a "child module"?

### Root Module

The directory where you run Terraform commands:

```bash
terraform init
terraform plan
terraform apply
```

In our project:

```text
terraform-modules/
```

is the **root module**.

Responsibilities:

* Provider configuration
* Calling child modules
* Managing overall infrastructure
* Defining root outputs

Example:

```hcl
module "web_server" {
  source = "./modules/ec2-instance"
}
```

---

### Child Module

A reusable Terraform component that is called by another module.

Examples:

```text
modules/ec2-instance
modules/security-group
```

Responsibilities:

* Create specific resources
* Accept inputs through variables
* Return outputs
* Be reusable across projects






---

### Task 2: Build a Custom EC2 Module
Create `modules/ec2-instance/`:

1. **`variables.tf`** -- define inputs:
   - `ami_id` (string)
   - `instance_type` (string, default: `"t2.micro"`)
   - `subnet_id` (string)
   - `security_group_ids` (list of strings)
   - `instance_name` (string)
   - `tags` (map of strings, default: `{}`)

```hcl
variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "instance_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
```  

2. **`main.tf`** -- define the resource:
   - `aws_instance` using all the variables
   - Merge the Name tag with additional tags

```hcl
resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids

  tags = merge(
    var.tags,
    {
      Name = var.instance_name
    }
  )
}
```

3. **`outputs.tf`** -- expose:
   - `instance_id`
   - `public_ip`
   - `private_ip`
  
```hcl
output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  value = aws_instance.this.public_ip
}

output "private_ip" {
  value = aws_instance.this.private_ip
}
```     

Do NOT apply yet -- just write the module.

---

### Task 3: Build a Custom Security Group Module
Create `modules/security-group/`:

1. **`variables.tf`** -- define inputs:
   - `vpc_id` (string)
   - `sg_name` (string)
   - `ingress_ports` (list of numbers, default: `[22, 80]`)
   - `tags` (map of strings, default: `{}`)

2. **`main.tf`** -- define the resource:
   - `aws_security_group` in the given VPC
   - Use `dynamic "ingress"` block to create rules from the `ingress_ports` list
   - Allow all egress

3. **`outputs.tf`** -- expose:
   - `sg_id`

This is your first time using a `dynamic` block -- it loops over a list to generate repeated nested blocks.

---

### Task 4: Call Your Modules from Root
In the root `main.tf`, wire everything together:

1. Create a VPC and subnet directly (or reuse your Day 62 config)
2. Call the security group module:
```hcl
module "web_sg" {
  source        = "./modules/security-group"
  vpc_id        = aws_vpc.main.id
  sg_name       = "terraweek-web-sg"
  ingress_ports = [22, 80, 443]
  tags          = local.common_tags
}
```

3. Call the EC2 module -- deploy **two instances** with different names using the same module:
```hcl
module "web_server" {
  source             = "./modules/ec2-instance"
  ami_id             = data.aws_ami.amazon_linux.id
  instance_type      = "t2.micro"
  subnet_id          = aws_subnet.public.id
  security_group_ids = [module.web_sg.sg_id]
  instance_name      = "terraweek-web"
  tags               = local.common_tags
}

module "api_server" {
  source             = "./modules/ec2-instance"
  ami_id             = data.aws_ami.amazon_linux.id
  instance_type      = "t2.micro"
  subnet_id          = aws_subnet.public.id
  security_group_ids = [module.web_sg.sg_id]
  instance_name      = "terraweek-api"
  tags               = local.common_tags
}
```

4. Add root outputs that reference module outputs:
```hcl
output "web_server_ip" {
  value = module.web_server.public_ip
}

output "api_server_ip" {
  value = module.api_server.public_ip
}
```

5. Apply:
```bash
terraform init    # Downloads/links the local modules
terraform plan    # Should show all resources from both module calls
terraform apply
```

<img width="989" height="422" alt="image" src="https://github.com/user-attachments/assets/5454d050-910a-4140-aaf4-933ea2fe531f" />
<img width="969" height="787" alt="image" src="https://github.com/user-attachments/assets/978c85c8-63ed-442e-9f72-c2ea9b2fe899" />
<img width="1164" height="908" alt="image" src="https://github.com/user-attachments/assets/01f62d6b-9013-4be2-8a37-38ac8b354002" />



**Verify:** Two EC2 instances running, same security group, different names. Check the AWS console.


<img width="2560" height="2617" alt="image" src="https://github.com/user-attachments/assets/1a4f19b3-c9b4-4a25-9394-8f12af002962" />

<img width="2560" height="3928" alt="Instances-EC2-web-vpc-subnet" src="https://github.com/user-attachments/assets/a977b43c-8b47-4a8f-bd16-73efd47f4fcf" />

<img width="2560" height="2610" alt="image" src="https://github.com/user-attachments/assets/ed81fab1-ee07-4533-8294-17bd02e027bc" />
<img width="2560" height="2107" alt="Instances-EC2-api-vpc-subnet" src="https://github.com/user-attachments/assets/ea171ecc-d0e8-4e18-a81a-46e9677f37c3" />



---

### Task 5: Use a Public Registry Module
Instead of building your own VPC from scratch, use the official module from the Terraform Registry.

1. Replace your hand-written VPC resources with:
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "terraweek-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = false
  enable_dns_hostnames = true

  tags = local.common_tags
}
```

2. Update your EC2 and SG module calls to reference `module.vpc.vpc_id` and `module.vpc.public_subnets[0]`

3. Run:
```bash
terraform init     # Downloads the registry module
terraform plan
terraform apply
```

<img width="836" height="576" alt="image" src="https://github.com/user-attachments/assets/96591d59-d325-416f-b027-9c0fadc1f23d" />
<img width="1102" height="1265" alt="image" src="https://github.com/user-attachments/assets/0faf7fb3-8f21-469c-adf0-5230036ba0ff" />

<img width="2560" height="1378" alt="image" src="https://github.com/user-attachments/assets/ef24ae37-7145-4ef0-af51-fa0cdd93abb3" />

<img width="2242" height="642" alt="image" src="https://github.com/user-attachments/assets/af418f15-8365-4bfa-adae-1f485f36897f" />
<img width="2232" height="675" alt="image" src="https://github.com/user-attachments/assets/b789a57f-6bd6-4813-9a9e-e12882b572cb" />

<img width="2232" height="787" alt="image" src="https://github.com/user-attachments/assets/a7743036-b754-4747-8b93-417cf115ce98" />
<img width="2222" height="762" alt="image" src="https://github.com/user-attachments/assets/d6de9c3f-1a04-4684-a17f-2a65ae572f62" />
<img width="2212" height="1015" alt="image" src="https://github.com/user-attachments/assets/bb9d9624-2ac5-4e71-85a3-d09b1a034492" />

<img width="2242" height="787" alt="image" src="https://github.com/user-attachments/assets/a992bd09-ae51-4892-b8ab-39e37b74eaf3" />
<img width="2232" height="722" alt="image" src="https://github.com/user-attachments/assets/f15575f5-3696-4141-aff3-a079d0ba3296" />
<img width="2212" height="992" alt="image" src="https://github.com/user-attachments/assets/1f2ecb56-8c08-4956-88e9-a37ca2c35d3b" />


<img width="2232" height="632" alt="image" src="https://github.com/user-attachments/assets/f12c6c93-4045-44e5-9196-6baf485c3661" />

<img width="2257" height="707" alt="image" src="https://github.com/user-attachments/assets/217dfa06-bf08-48f4-b086-63ad803af749" />
<img width="2242" height="777" alt="image" src="https://github.com/user-attachments/assets/2c125a88-5461-4666-b2cc-acb1d726aca5" />
<img width="2227" height="682" alt="image" src="https://github.com/user-attachments/assets/ccd327ca-6d66-4c83-9391-92db3b00a7a2" />


4. Compare: how many resources did the VPC module create vs your hand-written VPC from Day 62?

### Hand-written VPC (Day 62)
| Resource                | Count           |
| ----------------------- | --------------- |
| VPC                     | 1               |
| Subnet                  | 1               |
| Internet Gateway        | 1               |
| Route Table             | 1               |
| Route Table Association | 1               |
| Security Group          | 1               |
| **Total**               | **6 Resources** |

### VPC Module (Terraform Registry)
| Resource                            | Count            |
| ----------------------------------- | ---------------- |
| `aws_vpc.this`                      | 1                |
| `aws_default_network_acl.this`      | 1                |
| `aws_default_route_table.default`   | 1                |
| `aws_default_security_group.this`   | 1                |
| `aws_internet_gateway.this`         | 1                |
| Public Subnets                      | 2                |
| Private Subnets                     | 2                |
| Public Route Tables                 | 1                |
| Private Route Tables                | 2                |
| `aws_route.public_internet_gateway` | 1                |
| Public Route Table Associations     | 2                |
| Private Route Table Associations    | 2                |
| **Total**                           | **17 Resources** |

>The Terraform Registry VPC module created approximately 17 networking resources automatically, compared to only 6 resources in my hand-written VPC setup.
>Using the module significantly reduced the amount of code I had to write while providing a production-style VPC architecture with multiple public/private subnets,
>route tables, route associations, and default networking components.

>The registry module automatically created public/private subnets, route tables, route associations, Internet Gateway, and default networking resources that I would otherwise have had to create manually.

### Document: Where does Terraform download registry modules to?

Terraform downloads registry modules into:

```text
.terraform/modules/
```

Verified during initialization:

```text
Downloading registry.terraform.io/terraform-aws-modules/vpc/aws 5.21.0 for vpc...
- vpc in .terraform/modules/vpc
```

You can inspect downloaded modules using:

```bash
tree .terraform/modules/vpc
```

or

```bash
ls -R .terraform/modules
```


<img width="645" height="1287" alt="image" src="https://github.com/user-attachments/assets/360533b7-68f8-4967-bf23-dd812bfdc6da" />

<img width="1692" height="1127" alt="image" src="https://github.com/user-attachments/assets/1eb21802-c880-4d96-877f-c9d0f088cc31" />

<img width="712" height="1192" alt="image" src="https://github.com/user-attachments/assets/3f9ee47d-810b-4f57-ad37-5e5868d38593" />


---

### Task 6: Module Versioning and Best Practices
1. Pin your registry module version explicitly:
   - `version = "5.1.0"` -- exact version
   - `version = "~> 5.0"` -- any 5.x version
   - `version = ">= 5.0, < 6.0"` -- range

2. Run `terraform init -upgrade` to check for newer versions

<img width="1057" height="601" alt="image" src="https://github.com/user-attachments/assets/0de73d7e-b216-4df9-b031-77057ad9ab5c" />


3. Check the state to see how modules appear:
```bash
terraform state list
```
Notice the `module.vpc.`, `module.web_server.`, `module.web_sg.` prefixes.

<img width="1017" height="487" alt="image" src="https://github.com/user-attachments/assets/d9d15bc9-d04d-43eb-bf5c-99ec706d77b3" />



4. Destroy everything:
```bash
terraform destroy
```




## Module Best Practices

1. **Always pin versions for registry modules** to avoid unexpected changes when newer versions are released.

2. **Keep modules focused on a single responsibility**. For example, create separate modules for EC2 instances, security groups, and VPCs instead of putting everything into one module.

3. **Use variables instead of hardcoded values** so modules can be reused across different environments and projects.

4. **Always define outputs** for important values such as IDs, IP addresses, and ARNs so other modules can reference them.

5. **Document and organize modules properly** by using `main.tf`, `variables.tf`, `outputs.tf`, and a `README.md` that explains inputs, outputs, and usage.


### Additional Lessons Learned

* Use clear and meaningful names for resources and variables.
* Use `locals` to avoid repeating common values such as tags.
* Avoid assumptions about the environment; do not hardcode regions, account IDs, or resource names.
* Validate inputs where appropriate to catch errors early.
* Keep modules small and easy to test, maintain, and reuse.
* Run `terraform validate` and `terraform plan` before applying changes.

***

# Documentation

## Objective

Learn how to create reusable Terraform modules, consume them from a root module, and use a public module from the Terraform Registry.

---

# Custom Module Structure

```text
terraform-modules/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── modules
│   ├── ec2-instance
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── security-group
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── .terraform
```

### Root Module vs Child Module

* **Root Module**: The main Terraform configuration executed by Terraform commands (`init`, `plan`, `apply`).
* **Child Module**: A reusable Terraform module called by another module using the `module` block.

---

# Custom EC2 Module

## modules/ec2-instance/variables.tf

```hcl
variable "ami_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "instance_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
```

## modules/ec2-instance/main.tf

```hcl
resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids

  tags = merge(
    var.tags,
    {
      Name = var.instance_name
    }
  )
}
```

## modules/ec2-instance/outputs.tf

```hcl
output "instance_id" {
  value = aws_instance.this.id
}

output "public_ip" {
  value = aws_instance.this.public_ip
}

output "private_ip" {
  value = aws_instance.this.private_ip
}
```

---

# Root main.tf

## Terraform Registry VPC Module

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "terraweek-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway   = false
  enable_dns_hostnames = true

  tags = local.common_tags
}
```

## Security Group Module

```hcl
module "web_sg" {
  source        = "./modules/security-group"
  vpc_id        = module.vpc.vpc_id
  sg_name       = "terraweek-web-sg"
  ingress_ports = [22, 80, 443]
  tags          = local.common_tags
}
```

## EC2 Module Called Twice

```hcl
module "web_server" {
  source             = "./modules/ec2-instance"
  ami_id             = data.aws_ami.amazon_linux.id
  instance_type      = "t3.micro"
  subnet_id          = module.vpc.public_subnets[0]
  security_group_ids = [module.web_sg.sg_id]
  instance_name      = "terraweek-web"
  tags               = local.common_tags
}

module "api_server" {
  source             = "./modules/ec2-instance"
  ami_id             = data.aws_ami.amazon_linux.id
  instance_type      = "t3.micro"
  subnet_id          = module.vpc.public_subnets[0]
  security_group_ids = [module.web_sg.sg_id]
  instance_name      = "terraweek-api"
  tags               = local.common_tags
}
```

---

# EC2 Verification

Screenshot: Two EC2 instances created from the same custom module.

* terraweek-web
* terraweek-api

(Both instances use the same EC2 module with different input values.)

> Insert AWS Console screenshot here.

---

# Hand-Written VPC vs Registry VPC Module

| Aspect           | Hand-written VPC | Registry VPC Module |
| ---------------- | ---------------- | ------------------- |
| Total Resources  | 6                | 17                  |
| Lines of Code    | ~50              | ~20                 |
| Production Ready | No               | Yes                 |
| Maintained By    | Developer        | Community           |
| Reusable         | Limited          | High                |

### Hand-Written VPC Resources

| Resource                | Count |
| ----------------------- | ----- |
| VPC                     | 1     |
| Subnet                  | 1     |
| Internet Gateway        | 1     |
| Route Table             | 1     |
| Route Table Association | 1     |
| Security Group          | 1     |
| Total                   | 6     |






## Terraform State and Module Prefixes

Command:

```bash
terraform state list
```

Output:

```text
data.aws_ami.amazon_linux
module.api_server.aws_instance.this
module.vpc.aws_default_network_acl.this[0]
module.vpc.aws_default_route_table.default[0]
module.vpc.aws_default_security_group.this[0]
module.vpc.aws_internet_gateway.this[0]
module.vpc.aws_route.public_internet_gateway[0]
module.vpc.aws_route_table.private[0]
module.vpc.aws_route_table.private[1]
module.vpc.aws_route_table.public[0]
module.vpc.aws_route_table_association.private[0]
module.vpc.aws_route_table_association.private[1]
module.vpc.aws_route_table_association.public[0]
module.vpc.aws_route_table_association.public[1]
module.vpc.aws_subnet.private[0]
module.vpc.aws_subnet.private[1]
module.vpc.aws_subnet.public[0]
module.vpc.aws_subnet.public[1]
module.vpc.aws_vpc.this[0]
module.web_server.aws_instance.this
module.web_sg.aws_security_group.this
```

### Observation

Terraform prefixes resources with the module name:

* `module.vpc.*` → Resources created by the Terraform Registry VPC module.
* `module.web_server.*` → Resources created by the custom EC2 module for the web server.
* `module.api_server.*` → Resources created by the custom EC2 module for the API server.
* `module.web_sg.*` → Resources created by the custom Security Group module.

This makes it easy to identify which module owns and manages each resource in the Terraform state.

### Resource VPC Module Resources Count from  Actual State

Your state shows: 

| Resource Type                  | Count  |
| ------------------------------ | ------ |
| VPC                            | 1      |
| Default Network ACL            | 1      |
| Default Route Table            | 1      |
| Default Security Group         | 1      |
| Internet Gateway               | 1      |
| Public Subnets                 | 2      |
| Private Subnets                | 2      |
| Public Route Table             | 1      |
| Private Route Tables           | 2      |
| Routes                         | 1      |
| Public Route Associations      | 2      |
| Private Route Associations     | 2      |
| **Total VPC Module Resources** | **17** |



### Module Download Location

Terraform downloads registry modules into:

```text
.terraform/modules/
```

Verified using:

```bash
terraform init -upgrade
```

Output:

```text
Downloading registry.terraform.io/terraform-aws-modules/vpc/aws 5.21.0 for vpc...
- vpc in .terraform/modules/vpc
```

---

# Five Module Best Practices

1. Always pin versions for registry modules to avoid unexpected changes.
2. Keep modules focused on a single responsibility.
3. Use variables instead of hardcoded values to improve reusability.
4. Always define outputs so other modules can consume resource attributes.
5. Maintain proper documentation using a README.md file and organized Terraform files (`main.tf`, `variables.tf`, `outputs.tf`).

---

# Key Learnings

* Modules help eliminate code duplication.
* Child modules can be reused multiple times with different inputs.
* Dynamic blocks simplify repeated nested configurations.
* Terraform Registry provides production-ready modules maintained by the community.
* Module outputs enable communication between modules.
* Version pinning ensures stable and predictable deployments.

```
```
