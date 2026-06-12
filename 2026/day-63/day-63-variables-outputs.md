# Day 63 -- Variables, Outputs, Data Sources and Expressions

## Challenge Tasks

### Task 1: Extract Variables
Take your Day 62 infrastructure config and refactor it:

1. Create a `variables.tf` file with input variables for:
   - `region` (string, default: your preferred region)
   - `vpc_cidr` (string, default: `"10.0.0.0/16"`)
   - `subnet_cidr` (string, default: `"10.0.1.0/24"`)
   - `instance_type` (string, default: `"t2.micro"`)
   - `project_name` (string, no default -- force the user to provide it)
   - `environment` (string, default: `"dev"`)
   - `allowed_ports` (list of numbers, default: `[22, 80, 443]`)
   - `extra_tags` (map of strings, default: `{}`)

     
`variables.tf`

```hcl
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "project_name" {
  description = "Project name"
  type        = string

  validation {
    condition     = length(var.project_name) > 0
    error_message = "Project name cannot be empty."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "allowed_ports" {
  description = "Ports allowed in Security Group"
  type        = list(number)
  default     = [22, 80, 443]
}

variable "extra_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
```

2. Replace every hardcoded value in `main.tf` with `var.<name>` references
`main.tf`
```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "main" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH, HTTP and HTTPS"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.allowed_ports


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

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-sg"
    Environment = var.environment
  })
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.main.id]
  associate_public_ip_address = true

  key_name = "tws"

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-server"
    Environment = var.environment
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "app_logs" {
  bucket = "${var.project_name}-${var.environment}-logs-bucket"

  depends_on = [aws_instance.main]
}

resource "aws_iam_role" "app_role" {
  name = "${var.project_name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "app_policy" {
  name = "${var.project_name}-app-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:ListBucket",
        "s3:GetObject"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_policy" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.app_policy.arn
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  depends_on = [aws_iam_role_policy_attachment.app_policy]
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  depends_on = [aws_security_group.main]
}

```

3. Run `terraform plan` -- it should prompt you for `project_name` since it has no default

<img width="1105" height="1275" alt="image" src="https://github.com/user-attachments/assets/915b04a3-5a65-4b94-bb8a-fb36eaf54b51" />

<img width="1036" height="1295" alt="image" src="https://github.com/user-attachments/assets/87aa6622-5427-461a-8fd3-9cb9b9b0b031" />


**Document:** What are the five variable types in Terraform? 

## What are the Five Variable Types in Terraform?

Terraform supports several variable types. The five most commonly used types are:

### 1. String

Used to store text values.

Example:

```hcl
variable "environment" {
  type    = string
  default = "dev"
}
```

Value:

```hcl
environment = "production"
```

---

### 2. Number

Used for integers and decimal values.

Example:

```hcl
variable "instance_count" {
  type    = number
  default = 2
}
```

Value:

```hcl
instance_count = 5
```

---

### 3. Bool

Used for true/false values.

Example:

```hcl
variable "enable_monitoring" {
  type    = bool
  default = true
}
```

Values:

```hcl
enable_monitoring = true
enable_monitoring = false
```

---

### 4. List

Used to store an ordered collection of values.

Example:

```hcl
variable "allowed_ports" {
  type    = list(number)
  default = [22, 80, 443]
}
```

Value:

```hcl
allowed_ports = [22, 80, 443, 8080]
```

---

### 5. Map

Used to store key-value pairs.

Example:

```hcl
variable "extra_tags" {
  type    = map(string)
  default = {}
}
```

Value:

```hcl
extra_tags = {
  Owner   = "Deepak"
  Team    = "DevOps"
  Purpose = "Learning"
}
```

---

### Summary

| Type                                                                                          | Purpose                    |
| --------------------------------------------------------------------------------------------- | -------------------------- |
| string                                                                                        | Stores text values         |
| number                                                                                        | Stores numeric values      |
| bool                                                                                          | Stores true/false values   |
| list                                                                                          | Stores ordered collections |
| map                                                                                           | Stores key-value pairs     |

These variable types make Terraform configurations flexible, reusable, and environment-aware. 

   

---

### Task 2: Variable Files and Precedence
1. Create `terraform.tfvars`:
```hcl
project_name = "terraweek"
environment  = "dev"
instance_type = "t2.micro"
```




2. Create `prod.tfvars`:
```hcl
project_name = "terraweek"
environment  = "prod"
instance_type = "t3.small"
vpc_cidr     = "10.1.0.0/16"
subnet_cidr  = "10.1.1.0/24"
```



3. Apply with the default file:
```bash
terraform plan                              # Uses terraform.tfvars automatically
```
<img width="792" height="1261" alt="image" src="https://github.com/user-attachments/assets/e0451e66-da8e-404a-ba79-751a8f1ae56b" />
<img width="656" height="695" alt="image" src="https://github.com/user-attachments/assets/82653b4e-d45b-4e2a-ac38-4e5e93b2583c" />

- terraform.tfvars is automatically loaded by default

4. Apply with the prod file:
```bash
terraform plan -var-file="prod.tfvars"      # Uses prod.tfvars
```
<img width="907" height="1267" alt="image" src="https://github.com/user-attachments/assets/1e15df9f-b907-4788-b0c1-1b437f59e9bc" />

<img width="797" height="1042" alt="image" src="https://github.com/user-attachments/assets/808ce4e1-60a8-47c2-be4f-2a6e48ef7509" />



5. Override with CLI:
```bash
terraform plan -var="instance_type=t2.nano"  # CLI overrides everything
```

<img width="1582" height="1331" alt="image" src="https://github.com/user-attachments/assets/37c8b4c7-a94a-4a3e-93af-dfe8b478cc86" />


6. Set an environment variable:
```bash
export TF_VAR_environment="staging"
terraform plan                              # env var overrides default but not tfvars
```

<img width="1546" height="1326" alt="image" src="https://github.com/user-attachments/assets/28ff89b0-38b0-4557-a4c8-7f3cd4f46568" />
<img width="1617" height="1327" alt="image" src="https://github.com/user-attachments/assets/1378892c-127c-4534-9f8b-3e5bd58e026f" />


- `export TF_VAR_environment="staging"` overrides only the `default` in `variables.tf`, but does not `override` `terraform.tfvars`.
- `terraform.tfvars` have `environment = dev`, Terraform uses `"dev"`

**Document:** Write the variable precedence order from lowest to highest priority.

## Terraform Variable Precedence

When the same variable is defined in multiple places, Terraform follows a precedence order.

Lowest priority → Highest priority:

1. Variable default values in `variables.tf`
2. Environment variables (`TF_VAR_*`)
3. `terraform.tfvars`
4. `*.auto.tfvars`
5. `-var-file`
6. `-var`

### Example

Default:

```hcl
variable "instance_type" {
  default = "t2.micro"
}
```

terraform.tfvars:

```hcl
instance_type = "t3.micro"
```

prod.tfvars:

```hcl
instance_type = "t3.small"
```

CLI:

```bash
terraform plan -var="instance_type=t2.nano"
```

Terraform chooses:

```text
t2.nano
```

because command-line variables have the highest priority.

### Summary Table

| Source                         | Priority |
| ------------------------------ | -------- |
| Variable Default               | Lowest   |
| TF_VAR_* Environment Variables | Higher   |
| terraform.tfvars               | Higher   |
| *.auto.tfvars                  | Higher   |
| -var-file                      | Higher   |
| -var                           | Highest  |

---

### Task 3: Add Outputs
Create an `outputs.tf` file with outputs for:

1. `vpc_id` -- the VPC ID
2. `subnet_id` -- the public subnet ID
3. `instance_id` -- the EC2 instance ID
4. `instance_public_ip` -- the public IP of the EC2 instance
5. `instance_public_dns` -- the public DNS name
6. `security_group_id` -- the security group ID

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = true

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "main" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH, HTTP and HTTPS"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.allowed_ports


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

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-sg"
    Environment = var.environment
  })
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.main.id]
  associate_public_ip_address = true

  key_name = "tws"

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-server"
    Environment = var.environment
  })

  lifecycle {
    create_before_destroy = true
  }
}


data "aws_caller_identity" "current" {}

resource "random_id" "bucket_suffix" {
  byte_length = 2
}

resource "aws_s3_bucket" "app_logs" {
  bucket = "${var.project_name}-${var.environment}-logs-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"

  depends_on = [aws_instance.main]
}

resource "aws_iam_role" "app_role" {
  name = "${var.project_name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "app_policy" {
  name = "${var.project_name}-app-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:ListBucket",
        "s3:GetObject"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_policy" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.app_policy.arn
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  depends_on = [aws_iam_role_policy_attachment.app_policy]
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  depends_on = [aws_security_group.main]
}
```

Apply your config and verify the outputs are printed at the end:
```bash
terraform apply

# After apply, you can also run:
terraform output                          # Show all outputs
terraform output instance_public_ip       # Show a specific output
terraform output -json                    # JSON format for scripting
```

<img width="923" height="597" alt="image" src="https://github.com/user-attachments/assets/fc728dfb-ccef-4a84-b5b0-ebbe7de4df08" />

<img width="931" height="771" alt="image" src="https://github.com/user-attachments/assets/7bd1f2e1-5d1c-46b5-a5fc-e2b21ee2d9a9" />



**Verify:** Does `terraform output instance_public_ip` return the correct IP?
- Yes

<img width="2232" height="786" alt="image" src="https://github.com/user-attachments/assets/88e483e4-a45d-4f68-ad68-4f2617b3b973" />

## Terraform Outputs

Terraform outputs expose useful information about created infrastructure resources.

Outputs created:

* vpc_id
* subnet_id
* instance_id
* instance_public_ip
* instance_public_dns
* security_group_id

Commands used:

```bash
terraform output
```

Displays all outputs.

```bash
terraform output instance_public_ip
```

Displays a specific output value.

```bash
terraform output -json
```

Displays outputs in JSON format for scripting and automation.

### Verification

Output:

```text
instance_public_ip = "100.21.17.7"
```

The output matched the EC2 instance public IP address, confirming that the output configuration was working correctly.






---

### Task 4: Use Data Sources
Stop hardcoding the AMI ID. Use a data source to fetch it dynamically.

1. Add a `data "aws_ami"` block that:
   - Filters for Amazon Linux 2 images
   - Filters for `hvm` virtualization and `gp2` root device
   - Uses `owners = ["amazon"]`
   - Sets `most_recent = true`

2. Replace the hardcoded AMI in your `aws_instance` with `data.aws_ami.amazon_linux.id`

3. Add a `data "aws_availability_zones"` block to fetch available AZs in your region

4. Use the first AZ in your subnet: `data.aws_availability_zones.available.names[0]`


```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_security_group" "main" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH, HTTP and HTTPS"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.allowed_ports


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

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-sg"
    Environment = var.environment
  })
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.main.id]
  associate_public_ip_address = true

  key_name = "tws"

  tags = merge(var.extra_tags, {
    Name        = "${var.project_name}-server"
    Environment = var.environment
  })

  lifecycle {
    create_before_destroy = true
  }
}


data "aws_caller_identity" "current" {}

resource "random_id" "bucket_suffix" {
  byte_length = 2
}

resource "aws_s3_bucket" "app_logs" {
  bucket = "${var.project_name}-${var.environment}-logs-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"

  depends_on = [aws_instance.main]
}

resource "aws_iam_role" "app_role" {
  name = "${var.project_name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "app_policy" {
  name = "${var.project_name}-app-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:ListBucket",
        "s3:GetObject"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_policy" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.app_policy.arn
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  depends_on = [aws_iam_role_policy_attachment.app_policy]
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  depends_on = [aws_security_group.main]
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

Apply and verify -- your config now works in any region without changing the AMI.

<img width="1243" height="1131" alt="image" src="https://github.com/user-attachments/assets/824a623c-8a97-46d6-8c87-1e229d836452" />
<img width="2257" height="1027" alt="image" src="https://github.com/user-attachments/assets/9ab0ac7f-4111-4750-a1eb-b2d348d8f999" />

<img width="2206" height="897" alt="image" src="https://github.com/user-attachments/assets/01c6aa85-b3e6-45cb-8a6a-05529467b3f5" />


**Document:** What is the difference between a `resource` and a `data` source?

## Difference Between a Resource and a Data Source

Terraform uses both resources and data sources, but they serve different purposes.

### Resource

A resource creates, updates, and manages infrastructure.

Example:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}
```

This creates a new VPC in AWS.

Examples from this project:

* aws_vpc
* aws_subnet
* aws_instance
* aws_security_group
* aws_s3_bucket

### Data Source

A data source reads information from existing infrastructure or AWS services.

Example:

```hcl
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
}
```

This does not create an AMI. It only retrieves information about an existing AMI.

Examples from this project:

* aws_ami
* aws_availability_zones
* aws_caller_identity

### Summary

| Resource                     | Data Source                    |
| ---------------------------- | ------------------------------ |
| Creates infrastructure       | Reads existing information     |
| Managed by Terraform         | Read-only                      |
| Can be created and destroyed | Cannot be created or destroyed |
| Example: aws_instance        | Example: aws_ami               |

In short, resources build infrastructure while data sources fetch information about existing infrastructure.



---

### Task 5: Use Locals for Dynamic Values
1. Add a `locals` block:
```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

2. Replace all Name tags with `local.name_prefix`:
   - VPC: `"${local.name_prefix}-vpc"`
   - Subnet: `"${local.name_prefix}-subnet"`
   - Instance: `"${local.name_prefix}-server"`

3. Merge common tags with resource-specific tags:
```hcl
tags = merge(local.common_tags, {
  Name = "${local.name_prefix}-server"
})
```

---

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${local.name_prefix}-subnet"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_security_group" "main" {
  name        = "${var.project_name}-sg"
  description = "Allow SSH, HTTP and HTTPS"
  vpc_id      = aws_vpc.main.id

  dynamic "ingress" {
    for_each = var.allowed_ports


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

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${local.name_prefix}-sg"
  })
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.main.id]
  associate_public_ip_address = true

  key_name = "tws"

  tags = merge(local.common_tags, var.extra_tags, {
    Name = "${local.name_prefix}-server"
  })

  lifecycle {
    create_before_destroy = true
  }
}


data "aws_caller_identity" "current" {}

resource "random_id" "bucket_suffix" {
  byte_length = 2
}

resource "aws_s3_bucket" "app_logs" {
  bucket = "${var.project_name}-${var.environment}-logs-${data.aws_caller_identity.current.account_id}-${random_id.bucket_suffix.hex}"

  depends_on = [aws_instance.main]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-logs"
  })
}

resource "aws_iam_role" "app_role" {
  name = "${local.name_prefix}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-role"
  })
}

resource "aws_iam_policy" "app_policy" {
  name = "${var.project_name}-app-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:ListBucket",
        "s3:GetObject"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "app_policy" {
  role       = aws_iam_role.app_role.name
  policy_arn = aws_iam_policy.app_policy.arn
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  depends_on = [aws_iam_role_policy_attachment.app_policy]
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  depends_on = [aws_security_group.main]
}

data "aws_availability_zones" "available" {
  state = "available"
}
```

```hcl
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "project_name" {
  description = "Project name"
  type        = string

  validation {
    condition     = trimspace(var.project_name) != ""
    error_message = "Project name cannot be empty."
  }
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "allowed_ports" {
  description = "Ports allowed in Security Group"
  type        = list(number)
  default     = [22, 80, 443]
}

variable "extra_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
```

Apply and check the tags in the AWS console -- every resource should have consistent tagging.

<img width="2226" height="906" alt="image" src="https://github.com/user-attachments/assets/72c92a96-491d-44f2-b227-dcd71713f450" />

<img width="2560" height="4351" alt="image" src="https://github.com/user-attachments/assets/6cd79b76-991d-4a08-a9df-3e7bafb44fb9" />

<img width="2388" height="825" alt="IAM" src="https://github.com/user-attachments/assets/45a9a477-ad1e-4897-a6d6-02c2b6b5e470" />

<img width="1587" height="822" alt="Internet gateways" src="https://github.com/user-attachments/assets/6826c5bc-f545-4d02-813e-ddb225a03045" />

<img width="1817" height="797" alt="Route tables" src="https://github.com/user-attachments/assets/dfd9581e-e311-4da9-99cc-a952d66bebf1" />

<img width="2543" height="817" alt="Security Groups" src="https://github.com/user-attachments/assets/c6c1076a-6b95-4cb3-8e66-dcc0eabac276" />

<img width="2518" height="798" alt="Subnets " src="https://github.com/user-attachments/assets/51d4285b-3527-4304-8fab-bba4c59aa257" />

<img width="2532" height="893" alt="VPCs" src="https://github.com/user-attachments/assets/a1309d24-0f3c-4ad2-8006-db5712128862" />


---

### Task 6: Built-in Functions and Conditional Expressions
Practice these in `terraform console`:
```bash
terraform console
```

1. **String functions:**
   - `upper("terraweek")` -> `"TERRAWEEK"`
   - `join("-", ["terra", "week", "2026"])` -> `"terra-week-2026"`
   - `format("arn:aws:s3:::%s", "my-bucket")`

2. **Collection functions:**
   - `length(["a", "b", "c"])` -> `3`
   - `lookup({dev = "t2.micro", prod = "t3.small"}, "dev")` -> `"t2.micro"`
   - `toset(["a", "b", "a"])` -> removes duplicates

3. **Networking function:**
   - `cidrsubnet("10.0.0.0/16", 8, 1)` -> `"10.0.1.0/24"`

<img width="888" height="862" alt="image" src="https://github.com/user-attachments/assets/5f9616d9-e664-40f1-a7cc-3f9c6dc72b9c" />


4. **Conditional expression** -- add this to your config:
```hcl
instance_type = var.environment == "prod" ? "t3.small" : "t2.micro"  
```
im taking t3.micro, t2.micro not available for me

instance_type = var.environment == "prod" ? "t3.small" : `"t3.micro"

<img width="1162" height="1206" alt="image" src="https://github.com/user-attachments/assets/75aabcde-82dd-4834-bf67-7f3979770c69" />


Apply with `environment = "prod"` and verify the instance type changes.

<img width="1261" height="1268" alt="image" src="https://github.com/user-attachments/assets/49f4d62a-7ef9-44e0-ad47-ab469ee2f29d" />


**Document:** Pick five functions you find most useful and explain what each does.

## Five Terraform Functions I Found Most Useful

### 1. upper()

Converts a string to uppercase.

Example:

```hcl
upper("terraweek")
```

Output:

```text
TERRAWEEK
```

Useful for standardizing names and tags.

---

### 2. join()

Combines elements of a list into a single string using a separator.

Example:

```hcl
join("-", ["terra", "week", "2026"])
```

Output:

```text
terra-week-2026
```

Useful for generating resource names.

---

### 3. length()

Returns the number of items in a collection.

Example:

```hcl
length(["a", "b", "c"])
```

Output:

```text
3
```

Useful for validation and conditional logic.

---

### 4. lookup()

Retrieves a value from a map.

Example:

```hcl
lookup({dev = "t2.micro", prod = "t3.small"}, "dev")
```

Output:

```text
t2.micro
```

Useful for selecting environment-specific configurations.

---

### 5. cidrsubnet()

Creates subnet CIDR ranges from a larger network.

Example:

```hcl
cidrsubnet("10.0.0.0/16", 8, 1)
```

Output:

```text
10.0.1.0/24
```

Useful for dynamically generating subnet ranges.


---

**Explanation of variable precedence with examples**

| Priority (High → Low) | Source                     | Example                                    |  Value       |
| --------------------- | -------------------------- | ------------------------------------------ | ------------ |
| 1 (Highest)           | Command-line (`-var`)      | `terraform plan -var="environment=qa"`     | `qa`         |
| 2                     | Command-line (`-var-file`) | `terraform plan -var-file="prod.tfvars"`   | `prod`       |
| 3                     | Auto-loaded tfvars         | `terraform.tfvars → environment = "stage"` | `stage`      |
| 4                     | Environment variable       | `TF_VAR_environment=uat`                   | `uat`        |
| 5 (Lowest)            | Default value              | `default = "dev"`                          | `dev`        |



**The difference between `variable`, `local`, `output`, and `data`**

   `variable:` Used to take input values from the user.

   `local:` Used to define internal reusable values or expressions.
   
   `data:` Used to fetch existing resources from the provider (read-only).
   
   `output:` Used to display or export values after execution.

---
