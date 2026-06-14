# Day 68 -- Introduction to Ansible and Inventory Setup
---

## Challenge Tasks

### Task 1: Understand Ansible
Research and write short notes on:


## 1. What is Configuration Management? Why do we need it?

Configuration Management is the process of defining, maintaining, and enforcing the desired state of servers and infrastructure.

Instead of manually logging into each server to:

* Install software
* Configure services
* Create users
* Update settings

we define these configurations as code and apply them automatically.

### Why do we need it?

* **Consistency:** Ensures all servers are configured the same way.
* **Automation:** Eliminates repetitive manual tasks.
* **Scalability:** Manage hundreds or thousands of servers efficiently.
* **Reduced Human Error:** Avoid mistakes caused by manual configuration.
* **Version Control:** Infrastructure changes can be tracked in Git.
* **Faster Recovery:** Rebuild servers quickly using automation.

### Example

Without configuration management:

```bash
ssh server1
sudo yum install nginx

ssh server2
sudo yum install nginx

ssh server3
sudo yum install nginx
```

With Ansible:

```bash
ansible web -m yum -a "name=nginx state=present" --become
```

One command manages multiple servers.

---

## 2. How is Ansible different from Chef, Puppet, and Salt?

| Feature                | Ansible | Puppet         | Chef           | SaltStack    |
| ---------------------- | ------- | -------------- | -------------- | ------------ |
| Agent Required         | No      | Yes            | Yes            | Usually Yes  |
| Communication          | SSH     | Agent ↔ Server | Agent ↔ Server | Agent or SSH |
| Learning Curve         | Easy    | Medium         | Steep          | Medium       |
| Configuration Language | YAML    | Puppet DSL     | Ruby DSL       | YAML/Python  |
| Setup Complexity       | Low     | Medium         | High           | Medium       |
| Push/Pull Model        | Push    | Pull           | Pull           | Hybrid       |

### Key Differences

#### Ansible

* Agentless
* Uses SSH
* Simple YAML syntax
* Easy to learn and deploy

#### Puppet

* Requires Puppet Agent on each node
* Uses a custom DSL
* Suitable for large enterprise environments

#### Chef

* Uses Ruby-based recipes
* More flexible but harder to learn
* Requires Chef Client on nodes

#### SaltStack

* Fast execution
* Supports agent-based and agentless modes
* Often used for real-time infrastructure management

### Why Ansible is Popular

* No agent installation
* Easy setup
* Human-readable YAML
* Strong cloud and DevOps ecosystem support

---

## 3. What does "Agentless" mean? How does Ansible connect to managed nodes?

### Agentless

Agentless means that Ansible does **not require any software agent to be installed on the target servers**.

Many configuration management tools require:

* A central server
* An agent running continuously on every managed node

Ansible avoids this requirement.

### How Ansible Connects

Ansible uses:

* SSH (Linux/Unix)
* WinRM (Windows)

For Linux servers:

```text
Control Node
      |
      | SSH
      v
Managed Node
```

When a task is executed:

1. Ansible connects via SSH.
2. Copies a small module to the target.
3. Executes the module.
4. Returns the result.
5. Removes temporary files.

### Benefits of Agentless Architecture

* Simpler setup
* Lower resource usage
* Easier maintenance
* Fewer security concerns

---

## 4. Ansible Architecture

### High-Level Architecture

```text
                 +------------------+
                 |   Control Node   |
                 |    (Ansible)     |
                 +------------------+
                           |
                           | SSH
                           |
       -----------------------------------------
       |                   |                   |
       v                   v                   v

+--------------+   +--------------+   +--------------+
| Web Server   |   | App Server   |   | DB Server    |
| Managed Node |   | Managed Node |   | Managed Node |
+--------------+   +--------------+   +--------------+

         Inventory defines these hosts
```

---

### Control Node

The machine where Ansible is installed and executed.

Examples:

* Your laptop
* A jump server
* A dedicated management EC2 instance

Responsibilities:

* Stores inventory
* Stores playbooks
* Executes Ansible commands
* Connects to managed nodes via SSH

---

### Managed Nodes

The servers that Ansible manages.

Examples:

* EC2 instances
* Virtual Machines
* Physical servers

Characteristics:

* Do not require Ansible installation
* Must allow SSH access
* Execute tasks sent by the control node

---

### Inventory

An inventory is a file that contains information about managed hosts.

Example:

```ini
[web]
web-server ansible_host=10.0.1.10

[app]
app-server ansible_host=10.0.1.11

[db]
db-server ansible_host=10.0.1.12
```

Purpose:

* Organize servers into groups
* Define connection variables
* Specify target hosts for automation

---

### Modules

Modules are reusable units of work executed by Ansible.

Examples:

| Module  | Purpose                               |
| ------- | ------------------------------------- |
| ping    | Test connectivity                     |
| yum     | Install packages on RHEL/Amazon Linux |
| apt     | Install packages on Ubuntu            |
| copy    | Copy files                            |
| service | Start/stop services                   |
| user    | Manage users                          |

Example:

```bash
ansible web -m yum -a "name=git state=present" --become
```

Here, `yum` is the module.

---

### Playbooks

Playbooks are YAML files that define automation tasks.

Example:

```yaml
---
- name: Install Git
  hosts: web

  tasks:
    - name: Install Git package
      yum:
        name: git
        state: present
```

Purpose:

* Automate repeatable tasks
* Maintain desired state
* Enable Infrastructure as Code (IaC)

---

### Task 1 Summary

* Configuration Management automates server configuration and maintains consistency.
* Ansible differs from Chef, Puppet, and Salt because it is agentless and uses SSH.
* Agentless means no software is installed on managed nodes.
* Core Ansible components:

  * **Control Node** → Runs Ansible
  * **Managed Nodes** → Target servers
  * **Inventory** → Host definitions
  * **Modules** → Individual tasks
  * **Playbooks** → YAML automation files



---

### Task 2: Set Up Your Lab Environment
You need 2-3 EC2 instances to practice on. Choose one approach:

**Option A: Use Terraform (recommended -- you just learned this)**
Use your TerraWeek skills to provision 3 EC2 instances with:
- Amazon Linux 2 or Ubuntu 22.04
- `t2.micro` instance type `iam taking t3.micro because on my account t2.micro N/A`
- A security group allowing SSH (port 22)
- A key pair for SSH access

**Option B: Launch manually from AWS Console**
Create 3 instances with the same specs above.

Label them mentally:
- **Instance 1:** web server
- **Instance 2:** app server
- **Instance 3:** db server

Verify you can SSH into each one from your control node:
```bash
ssh -i ~/your-key.pem ec2-user@<public-ip-1>
ssh -i ~/your-key.pem ec2-user@<public-ip-2>
ssh -i ~/your-key.pem ec2-user@<public-ip-3>
```

<img width="1097" height="847" alt="image" src="https://github.com/user-attachments/assets/e71b3eeb-1b0b-408a-92a1-c82307fe954e" />
<img width="1097" height="592" alt="image" src="https://github.com/user-attachments/assets/ee991f6b-f70f-43da-9705-daa0e4f22077" />
<img width="1726" height="352" alt="image" src="https://github.com/user-attachments/assets/9f8bdaa9-8b20-4e35-9ead-1ecb44560afd" />

<img width="1102" height="221" alt="image" src="https://github.com/user-attachments/assets/db98fb5c-8e29-4215-bffa-176156ce2003" />

<img width="1437" height="1267" alt="image" src="https://github.com/user-attachments/assets/faf2d516-528c-43e1-ac83-8aac0df48a4d" />



---

### Task 3: Install Ansible
Install Ansible on your **control node** (your laptop or one dedicated EC2 instance):

```bash
# macOS
brew install ansible

# Ubuntu/Debian
sudo apt update
sudo apt install ansible -y

# Amazon Linux / RHEL
sudo yum install ansible -y
# or
pip3 install ansible

# Verify
ansible --version
```

Confirm the output shows the Ansible version, config file path, and Python version.

<img width="1075" height="227" alt="image" src="https://github.com/user-attachments/assets/4383ad9a-1e1e-4198-98e5-c24508b7ec4a" />


**Document:** On which machine did you install Ansible? Why is it only needed on the control node?

### On which machine did you install Ansible?

I installed Ansible on my control node (`malathi@Deepak` Ubuntu/WSL machine).

### Why is Ansible only needed on the control node?

Ansible follows an **agentless architecture**. The control node runs Ansible and connects to managed nodes using SSH. It temporarily transfers modules, executes tasks, and retrieves results. 
Because Ansible uses SSH, no Ansible software or agent needs to be installed on the managed EC2 instances.


### Why only on the Control Node?

Ansible is agentless. It communicates with managed nodes over SSH, executes modules remotely, and returns results. Therefore, Ansible only needs to be installed on the control node and not on the target EC2 instances.




---

### Task 4: Create Your Inventory File
The inventory tells Ansible which servers to manage. Create a project directory and your first inventory:

```bash
mkdir ansible-practice && cd ansible-practice
```

Create a file called `inventory.ini`:
```ini
[web]
web-server ansible_host=<PUBLIC_IP_1>

[app]
app-server ansible_host=<PUBLIC_IP_2>

[db]
db-server ansible_host=<PUBLIC_IP_3>

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/your-key.pem
```

<img width="2066" height="1262" alt="image" src="https://github.com/user-attachments/assets/04ba8875-3569-4d2e-9482-330d9b789ad8" />


Verify Ansible can reach all hosts:
```bash
ansible all -i inventory.ini -m ping
```

You should see green `SUCCESS` with `"ping": "pong"` for each host.

<img width="1221" height="682" alt="image" src="https://github.com/user-attachments/assets/c2b638ea-60e5-4c88-b6fc-648fcf0a635d" />


**Troubleshoot:** If ping fails:
- Check the SSH key path and permissions (`chmod 400 your-key.pem`)
- Check the security group allows SSH from your IP
- Check the `ansible_user` matches your AMI (ec2-user for Amazon Linux, ubuntu for Ubuntu)

---

### Task 5: Run Ad-Hoc Commands
Ad-hoc commands let you run quick one-off tasks without writing a playbook.

1. **Check uptime on all servers:**
```bash
ansible all -i inventory.ini -m command -a "uptime"
```

<img width="1612" height="441" alt="image" src="https://github.com/user-attachments/assets/a9c383ba-37b3-4d12-80d2-1e451ba3d3b5" />


2. **Check free memory on web servers only:**
```bash
ansible web -i inventory.ini -m command -a "free -h"
```

<img width="1616" height="155" alt="image" src="https://github.com/user-attachments/assets/dbd26159-34dd-4109-96d8-c728be4b2969" />


3. **Check disk space on all servers:**
```bash
ansible all -i inventory.ini -m command -a "df -h"
```

<img width="1621" height="812" alt="image" src="https://github.com/user-attachments/assets/62e5f2f6-ce5e-49e8-92d9-cb0894c8156b" />


4. **Install a package on the web group:**
```bash
ansible web -i inventory.ini -m yum -a "name=git state=present" --become
```
(Use `apt` instead of `yum` if running Ubuntu)

<img width="1607" height="465" alt="image" src="https://github.com/user-attachments/assets/8a4f9a50-3a6f-4a19-8331-733db916edda" />
<img width="1621" height="112" alt="image" src="https://github.com/user-attachments/assets/3040bde3-fa66-4fdf-8682-1b6720b93f08" />


5. **Copy a file to all servers:**
```bash
echo "Hello from Ansible" > hello.txt
ansible all -i inventory.ini -m copy -a "src=hello.txt dest=/tmp/hello.txt"
```

<img width="1627" height="926" alt="image" src="https://github.com/user-attachments/assets/5d59e463-b862-45f7-8702-3cda43984386" />
<img width="1622" height="446" alt="image" src="https://github.com/user-attachments/assets/bae3d88f-2ea2-46be-b690-3a82351dde59" />


6. **Verify the file was copied:**
```bash
ansible all -i inventory.ini -m command -a "cat /tmp/hello.txt"
```

<img width="1645" height="287" alt="image" src="https://github.com/user-attachments/assets/af014431-31fa-471e-af73-69a452e5db15" />


**Document:** What does `--become` do? When do you need it?

`--become` enables privilege escalation (similar to `sudo`) so Ansible can execute tasks as the root user.

### When do you need it?

You need `--become` for operations that require administrative privileges, such as:

* Installing packages
* Managing services (start/stop/restart)
* Creating users and groups
* Modifying system files under `/etc`
* Changing firewall settings

Example:

```bash
ansible web -i inventory.ini -m dnf -a "name=git state=present" --become
```

Without `--become`, the `ec2-user` account would not have permission to install packages.


---

### Task 6: Explore Inventory Groups and Patterns
1. **Create a group of groups** -- add this to your `inventory.ini`:
```ini
[application:children]
web
app

[all_servers:children]
application
db
```

2. Run commands against different groups:
```bash
ansible application -i inventory.ini -m ping     # web + app servers
ansible db -i inventory.ini -m ping               # only db server
ansible all_servers -i inventory.ini -m ping      # everything
```

<img width="1177" height="226" alt="image" src="https://github.com/user-attachments/assets/a7812ec4-ca68-4e03-8917-d46adbba354e" />
<img width="1445" height="702" alt="image" src="https://github.com/user-attachments/assets/e9ed39ba-ccdc-4169-9917-e813e25d3a22" />
<img width="1342" height="686" alt="image" src="https://github.com/user-attachments/assets/621c33dd-b02c-49e3-a6fd-ebe84da5cdad" />


3. **Use patterns:**
```bash
ansible 'web:app' -i inventory.ini -m ping        # OR: web or app
ansible 'all:!db' -i inventory.ini -m ping        # NOT: all except db
```

<img width="1386" height="927" alt="image" src="https://github.com/user-attachments/assets/6b64699e-97c5-4680-ace8-7dedde40c610" />


4. **Create an `ansible.cfg`** to avoid typing `-i inventory.ini` every time:
```ini
[defaults]
inventory = inventory.ini
host_key_checking = False
remote_user = ec2-user
private_key_file = ~/your-key.pem
```

Now you can simply run:
```bash
ansible all -m ping
```

**Verify:** Does `ansible all -m ping` work without specifying the inventory file?

- Yes

<img width="1622" height="846" alt="image" src="https://github.com/user-attachments/assets/8dd63cf2-6ee1-4161-9256-071a768311a6" />


# Documentation Answers

### What is a Group of Groups?

A group of groups allows multiple inventory groups to be combined into a larger logical group using the `:children` keyword.

Example:

```ini
[application:children]
web
app
```

This creates an `application` group containing both the `web` and `app` groups.

---

### What are Inventory Patterns?

Patterns allow selecting hosts dynamically.

Examples:

| Pattern    | Meaning                     |
| ---------- | --------------------------- |
| `web:app`  | web OR app                  |
| `all:!db`  | all except db               |
| `web:&app` | intersection of web and app |
| `all`      | every host                  |


---


## Ansible Architecture 

Ansible is an agentless configuration management tool used to automate server configuration, software installation, user management, and application deployment. Unlike other configuration management tools, Ansible does not require any software agent to be installed on the target servers. It communicates with managed nodes using SSH.

### Architecture Components

* **Control Node**: The machine where Ansible is installed and executed. In my lab, my Ubuntu WSL machine (`malathi@Deepak`) acted as the control node.
* **Managed Nodes**: The EC2 instances that Ansible manages and configures.
* **Inventory**: A file that contains the list of managed nodes grouped by purpose.
* **Modules**: Small units of work executed by Ansible, such as installing packages, copying files, or checking system information.
* **Playbooks**: YAML files that define automation tasks and desired system states.

### Low-Level Architecture Diagram

```text
+------------------------------------------------+
|                  CONTROL NODE                  |
|         Ubuntu WSL (Ansible Installed)         |
+------------------------------------------------+
|                                                |
|  inventory.ini                                 |
|  playbooks.yml                                 |
|  ansible.cfg                                   |
|  Ansible Modules                               |
|                                                |
+-------------------+----------------------------+
                    |
                    | SSH (Port 22)
                    |
    -------------------------------------------------
    |                       |                       |
    |                       |                       |
+-----------+         +-----------+         +-----------+
| WEB NODE  |         | APP NODE  |         |  DB NODE  |
| EC2       |         | EC2       |         | EC2       |
| Amazon    |         | Amazon    |         | Amazon    |
| Linux 2023|         | Linux 2023|         | Linux 2023|
+-----------+         +-----------+         +-----------+

   Managed Node       Managed Node        Managed Node
```

---

## Lab Setup

I used **Terraform** to provision the infrastructure on AWS.

### EC2 Configuration

| Server Role | OS                | Instance Type |
| ----------- | ----------------- | ------------- |
| Web Server  | Amazon Linux 2023 | t2.micro      |
| App Server  | Amazon Linux 2023 | t2.micro      |
| DB Server   | Amazon Linux 2023 | t2.micro      |

### Additional Resources

* Security Group allowing SSH (Port 22)
* AWS Key Pair: `ansible-lab`
* Public IPs assigned to all instances
* Control Node: Ubuntu WSL machine

### SSH Verification

Verified SSH connectivity to all EC2 instances using:

```bash
ssh -i ~/.ssh/ansible-lab.pem ec2-user@<public-ip>
```

---

## Inventory File

```ini
[web]
web-server ansible_host=<WEB_SERVER_IP>

[app]
app-server ansible_host=<APP_SERVER_IP>

[db]
db-server ansible_host=<DB_SERVER_IP>

[all:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=/home/malathi/.ssh/ansible-lab.pem

[application:children]
web
app

[all_servers:children]
application
db
```

---

## Ansible Connectivity Test

Command:

```bash
ansible all -m ping
```

Output:

```text
app-server | SUCCESS => {
    "ping": "pong"
}

db-server | SUCCESS => {
    "ping": "pong"
}

web-server | SUCCESS => {
    "ping": "pong"
}
```

All managed nodes successfully responded with `"pong"`.

> Screenshot: Attach the screenshot of your terminal showing the successful ping results.

---

## Ad-Hoc Commands Executed

### 1. Check Server Uptime

```bash
ansible all -m command -a "uptime"
```

Output:

```text
web-server | CHANGED | rc=0 >>
up 1 hour

app-server | CHANGED | rc=0 >>
up 1 hour

db-server | CHANGED | rc=0 >>
up 1 hour
```

---

### 2. Check Memory Usage

```bash
ansible web -m command -a "free -h"
```

Output:

```text
web-server | CHANGED | rc=0 >>
              total        used        free
Mem:          ...
```

---

### 3. Check Disk Space

```bash
ansible all -m command -a "df -h"
```

Output:

```text
web-server | CHANGED | rc=0 >>
Filesystem      Size  Used Avail Use%
...

app-server | CHANGED | rc=0 >>
...

db-server | CHANGED | rc=0 >>
...
```

---

### 4. Install Git Package

```bash
ansible web -m dnf -a "name=git state=present" --become
```

Verification:

```bash
ansible web -m command -a "git --version"
```

Output:

```text
web-server | CHANGED | rc=0 >>
git version 2.x.x
```

---

### 5. Copy File to All Servers

Create file:

```bash
echo "Hello from Ansible" > hello.txt
```

Copy:

```bash
ansible all -m copy -a "src=hello.txt dest=/tmp/hello.txt"
```

Verify:

```bash
ansible all -m command -a "cat /tmp/hello.txt"
```

Output:

```text
web-server | CHANGED | rc=0 >>
Hello from Ansible

app-server | CHANGED | rc=0 >>
Hello from Ansible

db-server | CHANGED | rc=0 >>
Hello from Ansible
```

---

## What Does `--become` Do?

`--become` enables privilege escalation and allows Ansible to execute tasks as the root user (similar to `sudo`).

It is required for operations such as:

* Installing packages
* Managing services
* Creating system users
* Modifying files under `/etc`
* Updating system configurations

Example:

```bash
ansible web -m dnf -a "name=git state=present" --become
```

Without `--become`, the `ec2-user` account would not have sufficient permissions to install packages.

---

## Difference Between `command` and `shell` Modules

| command Module                        | shell Module                          |                   |    |
| ------------------------------------- | ------------------------------------- | ----------------- | -- |
| Executes commands directly            | Executes commands through a shell     |                   |    |
| More secure                           | Less secure                           |                   |    |
| Does not support pipes (`             | `)                                    | Supports pipes (` | `) |
| Does not support redirects (`>`, `<`) | Supports redirects                    |                   |    |
| Does not support shell variables      | Supports shell variables              |                   |    |
| Recommended for simple commands       | Used when shell features are required |                   |    |

### Example: command

```bash
ansible all -m command -a "uptime"
```

### Example: shell

```bash
ansible all -m shell -a "df -h | grep nvme"
```

Use `command` whenever possible and use `shell` only when shell-specific features are needed.

---

## Conclusion

In this lab, I installed Ansible on my control node, provisioned three EC2 instances using Terraform, created an inventory with host groups, verified connectivity using the ping module, executed ad-hoc commands, explored inventory patterns, and configured `ansible.cfg` for easier command execution. This provided a practical introduction to Ansible's agentless architecture and remote automation capabilities.
