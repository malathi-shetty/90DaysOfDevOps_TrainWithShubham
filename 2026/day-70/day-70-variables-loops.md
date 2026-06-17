# Day 70 -- Variables, Facts, Conditionals and Loops

---

## Challenge Tasks

### Task 1: Variables in Playbooks
Create `variables-demo.yml`:

```yaml
---
- name: Variable demo
  hosts: all
  become: true

  vars:
    app_name: terraweek-app
    app_port: 8080
    app_dir: "/opt/{{ app_name }}"
    packages:
      - git
      - curl
      - wget

  tasks:
    - name: Print app details
      debug:
        msg: "Deploying {{ app_name }} on port {{ app_port }} to {{ app_dir }}"

    - name: Create application directory
      file:
        path: "{{ app_dir }}"
        state: directory
        mode: '0755'

    - name: Install required packages
      yum:
        name: "{{ packages }}"
        state: present
```

Run it and verify the variables resolve correctly.

<img width="1954" height="980" alt="image" src="https://github.com/user-attachments/assets/19d5106a-f20c-4218-925c-ea0908fe88a3" />

<img width="1247" height="607" alt="image" src="https://github.com/user-attachments/assets/c47b1c11-5353-4963-ba68-d8a5037ed7c1" />


Now, override a variable from the command line:
```bash
ansible-playbook variables-demo.yml -e "app_name=my-custom-app app_port=9090"
```

**Verify:** Does the CLI variable override the playbook variable?


<img width="1422" height="1211" alt="image" src="https://github.com/user-attachments/assets/9445f8eb-0e80-49bc-8847-a8663d3e0fd2" />

**Yes, the CLI variable overrides the playbook variable.**

### Evidence from  run

Playbook variables:

```yaml
vars:
  app_name: terraweek-app
  app_port: 8080
```

Command executed:

```bash
ansible-playbook variables-demo.yml \
-e "app_name=my-custom-app app_port=9090"
```

Output:

```text
"msg": "Deploying my-custom-app on port 9090 to /opt/my-custom-app"
```

This shows that:

| Variable   | Playbook Value     | CLI Value                          | Final Value Used   |
| ---------- | ------------------ | ---------------------------------- | ------------------ |
| `app_name` | terraweek-app      | my-custom-app                      | my-custom-app      |
| `app_port` | 8080               | 9090                               | 9090               |
| `app_dir`  | /opt/terraweek-app | Derived from overridden `app_name` | /opt/my-custom-app |

Additional verification:

```bash
ls -ld /opt/my-custom-app
```

Output:

```text
drwxr-xr-x. 2 root root ... /opt/my-custom-app
```

and

```bash
ls -ld /opt/terraweek-app
```

Output:

```text
drwxr-xr-x. 2 root root ... /opt/terraweek-app
```

This confirms the playbook created a new directory using the overridden value.

### Conclusion

**Yes. Variables passed through `-e` (extra vars) take precedence over variables defined in the playbook, so the CLI values override the playbook values.** 


---

### Task 2: group_vars and host_vars
Variables should not live inside playbooks. Move them to dedicated files.

Create this structure:
```
ansible-practice/
  inventory.ini
  ansible.cfg
  group_vars/
    all.yml
    web.yml
    db.yml
  host_vars/
    web-server.yml
  playbooks/
    site.yml
```

**`group_vars/all.yml`** -- applies to every host:
```yaml
---
ntp_server: pool.ntp.org
app_env: development
common_packages:
  - vim
  - htop
  - tree
```

**`group_vars/web.yml`** -- applies only to the web group:
```yaml
---
http_port: 80
max_connections: 1000
web_packages:
  - nginx
```

**`group_vars/db.yml`** -- applies only to the db group:
```yaml
---
db_port: 3306
db_packages:
  - mysql-server
```

**`host_vars/web-server.yml`** -- applies only to this specific host:
```yaml
---
max_connections: 2000
custom_message: "This is the primary web server"
```

Write a playbook `site.yml` that uses these variables:
```yaml
---
- name: Apply common config
  hosts: all
  become: true
  tasks:
    - name: Install common packages
      yum:
        name: "{{ common_packages }}"
        state: present
    - name: Show environment
      debug:
        msg: "Environment: {{ app_env }}"

- name: Configure web servers
  hosts: web
  become: true
  tasks:
    - name: Show web config
      debug:
        msg: "HTTP port: {{ http_port }}, Max connections: {{ max_connections }}"
    - name: Show host-specific message
      debug:
        msg: "{{ custom_message }}"
```

Run it and observe which variables apply to which hosts.

<img width="1076" height="982" alt="image" src="https://github.com/user-attachments/assets/9da1b4bd-0fd6-4469-bd02-c7627fa74402" />


- `Observations:`
  - `app_env` applied to all hosts
  - `http_port` only web group
  - `db_port` only db group
  - `custom_message` only web-server
  - `max_connections` came from group_vars

**Document:** What is the variable precedence? (hint: host_vars > group_vars > playbook vars, and -e overrides everything)



`ansible-playbook playbooks/site.yml -e "app_env=production"`
<img width="1277" height="992" alt="image" src="https://github.com/user-attachments/assets/3c0f4305-6392-4b5d-bbe8-689672f68306" />


### Variable Precedence Verification

`group_vars/web.yml` contained:

```yaml
max_connections: 1000
```

`host_vars/web-server.yml` contained:

```yaml
max_connections: 2000
```

Observed output:

```text
HTTP port: 80, Max connections: 2000
```

Since `2000` was used instead of `1000`, the value from `host_vars` overrode the value from `group_vars`.

---

### Extra Variables (-e)

Executed:

```bash
ansible-playbook playbooks/site.yml -e "app_env=production"
```

Observed output:

```text
Environment: production
```

even though `group_vars/all.yml` contained:

```yaml
app_env: development
```

This confirms that extra variables passed with `-e` override variables defined in inventory, group_vars, host_vars, and playbooks.

---

### Variable Precedence Order

Highest precedence:

```text
Extra Variables (-e)
        ↓
host_vars
        ↓
group_vars
        ↓
Playbook Variables
```

Example from this task:

```text
app_env:
group_vars/all.yml      = development
CLI (-e)               = production
Final value used       = production
```

```text
max_connections:
group_vars/web.yml      = 1000
host_vars/web-server.yml = 2000
Final value used       = 2000
```

### Conclusion

* `group_vars/all.yml` applies to all hosts.
* `group_vars/<group>.yml` applies only to that inventory group.
* `host_vars/<host>.yml` applies only to the specified host.
* `host_vars` override `group_vars`.
* Extra variables (`-e`) have the highest precedence and override all other variable definitions.




---

### Task 3: Ansible Facts -- Gathering System Information
Ansible automatically collects "facts" about each managed node -- OS, IP, memory, CPU, disks, and hundreds more.

1. **See all facts for a host:**
```bash
ansible web-server -m setup
```
<img width="1262" height="1067" alt="image" src="https://github.com/user-attachments/assets/445a093f-bfbb-451a-8a9f-4bc1b6430232" />

<img width="1747" height="1247" alt="setup-1" src="https://github.com/user-attachments/assets/31d3ccc4-09ea-4d19-a187-4b622039f82f" />
<img width="1352" height="487" alt="image" src="https://github.com/user-attachments/assets/8fa8006d-5b05-485f-86a4-c4667b36b05f" />


2. **Filter specific facts:**
```bash
ansible web-server -m setup -a "filter=ansible_os_family"
ansible web-server -m setup -a "filter=ansible_distribution*"
ansible web-server -m setup -a "filter=ansible_memtotal_mb"
ansible web-server -m setup -a "filter=ansible_default_ipv4"
```

<img width="1297" height="1002" alt="image" src="https://github.com/user-attachments/assets/bb8fb56b-8e5a-4dc1-8434-adcc91922d18" />
<img width="1292" height="1267" alt="image" src="https://github.com/user-attachments/assets/65d3865c-d8e9-4a20-9338-dab89d1d8ce2" />


3. **Use facts in a playbook** -- create `facts-demo.yml`:
```yaml
---
- name: Facts demo
  hosts: all
  tasks:
    - name: Show OS info
      debug:
        msg: >
          Hostname: {{ ansible_hostname }},
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }},
          RAM: {{ ansible_memtotal_mb }}MB,
          IP: {{ ansible_default_ipv4.address }}

    - name: Show all network interfaces
      debug:
        var: ansible_interfaces
```

Run it and observe the facts printed for each host.

<img width="1088" height="992" alt="image" src="https://github.com/user-attachments/assets/5fdb4265-bf32-4c0a-9a56-681da856d86b" />


**Document:** Name five facts you would use in real playbooks and why.

| Fact                           | Why it is useful                                |
| ------------------------------ | ----------------------------------------------- |
| `ansible_os_family`            | Choose apt or yum/dnf depending on OS family    |
| `ansible_distribution`         | Handle distro-specific configurations           |
| `ansible_default_ipv4.address` | Configure services with the server's IP         |
| `ansible_memtotal_mb`          | Tune applications based on available RAM        |
| `ansible_processor_vcpus`      | Set worker/thread counts based on CPU resources |


---

### Task 4: Conditionals with when
Tasks should not always run on every host. Use `when` to control execution.

Create `conditional-demo.yml`:

```yaml
---
- name: Conditional tasks demo
  hosts: all
  become: true

  tasks:
    - name: Install Nginx (only on web servers)
      yum:
        name: nginx
        state: present
      when: "'web' in group_names"

    - name: Install MySQL (only on db servers)
      yum:
        name: mysql-server
        state: present
      when: "'db' in group_names"

    - name: Show warning on low memory hosts
      debug:
        msg: "WARNING: This host has less than 1GB RAM"
      when: ansible_memtotal_mb < 1024

    - name: Run only on Amazon Linux
      debug:
        msg: "This is an Amazon Linux machine"
      when: ansible_distribution == "Amazon"

    - name: Run only on Ubuntu
      debug:
        msg: "This is an Ubuntu machine"
      when: ansible_distribution == "Ubuntu"

    - name: Run only in production
      debug:
        msg: "Production settings applied"
      when: app_env == "production"

    - name: Multiple conditions (AND)
      debug:
        msg: "Web server with enough memory"
      when:
        - "'web' in group_names"
        - ansible_memtotal_mb >= 512

    - name: OR condition
      debug:
        msg: "Either web or app server"
      when: "'web' in group_names or 'app' in group_names"
```

Run it and observe which tasks are skipped on which hosts.

- `Observation`

    - `Nginx installation` – skipped on db-server and app-server; runs on web-server.
    - `MariaDB installation` – skipped on web-server and app-server; runs on db-server.
    - `Low memory warning` – runs on all hosts.
    - `Amazon Linux check` – runs on all hosts.
    - `Ubuntu check` – skipped on all hosts.
    - `Production check` – skipped on all hosts.
    - `Multiple conditions (AND)` – runs only on web-server.
    - `OR condition` – runs on web-server and app-server; skipped on db-server.


<img width="1195" height="1872" alt="image" src="https://github.com/user-attachments/assets/138ed817-540f-43da-8f8b-c72d48819e2b" />


**Verify:** Are tasks correctly skipping on hosts that don't match the condition?

Yes. The playbook output confirms that tasks were correctly skipped on hosts that did not meet the specified `when` conditions.

For example:

* The **Install Nginx** task ran only on `web-server` and was skipped on `app-server` and `db-server`.
* The **Install git/tree** and **Database server detected** tasks ran only on `db-server` and were skipped on the other hosts.
* The **Run only on Ubuntu** task was skipped on all hosts because all servers are running Amazon Linux 2023.
* The **Multiple conditions (AND)** task ran only on `web-server` because it satisfied both conditions.
* The **OR condition** task ran on `web-server` and `app-server` and was skipped on `db-server`.

Since the final recap shows:

```text
web-server : failed=0
app-server : failed=0
db-server  : failed=0
```

and the output contains the expected `skipping` messages, the conditional logic is working correctly.



> **Verification:** Yes, tasks were correctly skipped on hosts that did not satisfy the `when` conditions. Web-specific tasks executed only on the web server, database-specific tasks executed only on the database server, Ubuntu-specific tasks were skipped because all hosts were Amazon Linux 2023, and the AND/OR conditional tasks behaved as expected. All hosts completed successfully with `failed=0`, confirming that the conditional execution worked correctly.




  
---

### Task 5: Loops
Create `loops-demo.yml`:

```yaml
---
- name: Loops demo
  hosts: all
  become: true

  vars:
    users:
      - name: deploy
        groups: wheel
      - name: monitor
        groups: wheel
      - name: appuser
        groups: users

    directories:
      - /opt/app/logs
      - /opt/app/config
      - /opt/app/data
      - /opt/app/tmp

  tasks:
    - name: Create multiple users
      user:
        name: "{{ item.name }}"
        groups: "{{ item.groups }}"
        state: present
      loop: "{{ users }}"

    - name: Create multiple directories
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      loop: "{{ directories }}"

    - name: Install multiple packages
      yum:
        name: "{{ item }}"
        state: present
      loop:
        - git
        - curl
        - unzip
        - jq

    - name: Print each user created
      debug:
        msg: "Created user {{ item.name }} in group {{ item.groups }}"
      loop: "{{ users }}"
```

Run it and observe the loop output -- each iteration is shown separately.

<img width="1077" height="1857" alt="image" src="https://github.com/user-attachments/assets/65153693-53bc-4f4b-9d83-f3fbbbd8edc3" />



**Document:** What is the difference between `loop` and the older `with_items`?

> `loop` is the modern and recommended way to iterate over items in Ansible. It provides a consistent syntax for looping and works well with newer Ansible features. `with_items` is the older looping mechanism that is still supported for backward compatibility but is considered legacy syntax. In most new playbooks, `loop` should be preferred because it is simpler, more readable, and aligns with Ansible's current best practices.

### Example

Old syntax:

```yaml
- name: Install packages
  yum:
    name: "{{ item }}"
    state: present
  with_items:
    - git
    - curl
    - jq
```

Modern syntax:

```yaml
- name: Install packages
  yum:
    name: "{{ item }}"
    state: present
  loop:
    - git
    - curl
    - jq
```

The result is the same, but `loop` is the recommended approach.


<img width="1150" height="815" alt="image" src="https://github.com/user-attachments/assets/f555d864-a8a0-4f26-958b-d25b94225902" />

    
---

### Task 6: Register, Debug, and Combine Everything
Build a real-world playbook `server-report.yml` that combines variables, facts, conditionals, and register:

```yaml
---
- name: Server Health Report
  hosts: all

  tasks:
    - name: Check disk space
      command: df -h /
      register: disk_result

    - name: Check memory
      command: free -m
      register: memory_result

    - name: Check running services
      shell: systemctl list-units --type=service --state=running | head -20
      register: services_result

    - name: Generate report
      debug:
        msg:
          - "========== {{ inventory_hostname }} =========="
          - "OS: {{ ansible_distribution }} {{ ansible_distribution_version }}"
          - "IP: {{ ansible_default_ipv4.address }}"
          - "RAM: {{ ansible_memtotal_mb }}MB"
          - "Disk: {{ disk_result.stdout_lines[1] }}"
          - "Running services (first 20): {{ services_result.stdout_lines | length }}"

    - name: Flag if disk is critically low
      debug:
        msg: "ALERT: Check disk space on {{ inventory_hostname }}"
      when: "'9[0-9]%' in disk_result.stdout or '100%' in disk_result.stdout"

    - name: Save report to file
      copy:
        content: |
          Server: {{ inventory_hostname }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          IP: {{ ansible_default_ipv4.address }}
          RAM: {{ ansible_memtotal_mb }}MB
          Disk: {{ disk_result.stdout }}
          Checked at: {{ ansible_date_time.iso8601 }}
        dest: "/tmp/server-report-{{ inventory_hostname }}.txt"
      become: true
```

Run it and verify the report file is created on each server.

<img width="1332" height="1548" alt="image" src="https://github.com/user-attachments/assets/e921f684-3e8b-41be-aa28-72e6ac981014" />


**Verify:** SSH into a server and read `/tmp/server-report-*.txt`. Does it contain accurate information?
- Yes

<img width="1272" height="1545" alt="image" src="https://github.com/user-attachments/assets/02cd20ef-538d-4e24-8ec9-0996969bc28e" />


---

# Day 70 – Ansible Variables, Facts, Conditionals, Loops, and Registers

## 1. Your group_vars/ and host_vars/ directory structure:

### group_vars/ and host_vars/ Directory Structure

Project structure:

```text
 ansible
    ├── ansible.cfg
    ├── conditional-demo.yml
    ├── facts-demo.yml
    ├── group_vars
    │   ├── all.yml
    │   ├── db.yml
    │   └── web.yml
    ├── host_vars
    │   └── web-server.yml
    ├── inventory.ini
    ├── loops-demo.yml
    ├── playbooks
    │   └── site.yml
    ├── server-report.yml
    └── variables-demo.yml
```

<img width="782" height="467" alt="image" src="https://github.com/user-attachments/assets/3995bb57-679b-458a-9b52-63d65d799edc" />


### Purpose

* **group_vars/** contains variables shared by all hosts in a group.
* **host_vars/** contains variables specific to an individual host.
* This structure keeps playbooks clean and allows environment-specific customization.

---

## 2. How variable precedence works with examples from your test

Ansible follows a precedence order when the same variable is defined in multiple places.

### Example

Suppose the variable `app_port` is defined as:

**group_vars/all.yml**

```yaml
app_port: 8080
```

**group_vars/web.yml**

```yaml
app_port: 8081
```

**host_vars/web-server.yml**

```yaml
app_port: 9090
```

When the playbook runs on `web-server`, the value used is:

```yaml
app_port: 9090
```

because **host variables override group variables**.

### Precedence Demonstrated

```text
host_vars > group_vars > playbook vars > inventory defaults
```

This allows host-specific customization while still maintaining common group-level settings.

---

## 3. Five Useful Ansible Facts  and where you would use them

### 1. ansible_distribution

Example:

```yaml
{{ ansible_distribution }}
```

Use case:

* Detect operating system (Amazon Linux, Ubuntu, CentOS, etc.)
* Install OS-specific packages

Example:

```yaml
when: ansible_distribution == "Amazon"
```

---

### 2. ansible_distribution_version

Example:

```yaml
{{ ansible_distribution_version }}
```

Use case:

* Handle version-specific configurations
* Support different package repositories

---

### 3. ansible_default_ipv4.address

Example:

```yaml
{{ ansible_default_ipv4.address }}
```

Use case:

* Configure load balancers
* Generate application configuration files
* Register hosts in monitoring systems

---

### 4. ansible_memtotal_mb

Example:

```yaml
{{ ansible_memtotal_mb }}
```

Use case:

* Validate system requirements
* Tune memory-related application settings

Example:

```yaml
when: ansible_memtotal_mb < 1024
```

---

### 5. ansible_hostname

Example:

```yaml
{{ ansible_hostname }}
```

Use case:

* Logging
* Inventory reporting
* Dynamic configuration generation

---

## 4. Conditional playbook with screenshot showing skipped vs executed tasks

Playbook: `conditional-demo.yml`

### Verified Conditions

#### Nginx Installation

```yaml
when: "'web' in group_names"
```

Result:

* Executed on `web-server`
* Skipped on `app-server`
* Skipped on `db-server`

#### Database Tasks

```yaml
when: "'db' in group_names"
```

Result:

* Executed on `db-server`
* Skipped on other hosts

#### Amazon Linux Check

```yaml
when: ansible_distribution == "Amazon"
```

Result:

* Executed on all three servers

#### Ubuntu Check

```yaml
when: ansible_distribution == "Ubuntu"
```

Result:

* Skipped on all servers

#### AND Condition

```yaml
when:
  - "'web' in group_names"
  - ansible_memtotal_mb >= 512
```

Result:

* Executed only on `web-server`

#### OR Condition

```yaml
when: "'web' in group_names or 'app' in group_names"
```

Result:

* Executed on `web-server`
* Executed on `app-server`
* Skipped on `db-server`



---

## 5. Loop playbook with screenshot showing multiple iterations

Playbook: `loops-demo.yml`

### Users Created

```yaml
loop: "{{ users }}"
```

Users:

* deploy
* monitor
* appuser

### Directories Created

```yaml
loop: "{{ directories }}"
```

Directories:

* /opt/app/logs
* /opt/app/config
* /opt/app/data
* /opt/app/tmp

### Packages Installed

```yaml
loop:
  - git
  - curl-minimal
  - unzip
  - jq
```

### Difference Between loop and with_items

#### Old Syntax

```yaml
with_items:
  - git
  - curl
  - jq
```

#### Modern Syntax

```yaml
loop:
  - git
  - curl
  - jq
```

`loop` is the recommended modern syntax because it is more consistent, easier to read, and integrates better with newer Ansible features.


---

## 6. Server Health Report Output

Playbook: `server-report.yml`

### Generated Reports

Files created:

```text
/tmp/server-report-web-server.txt
/tmp/server-report-app-server.txt
/tmp/server-report-db-server.txt
```

### Sample Report

```text
Server: web-server
OS: Amazon 2023
IP: 172.31.43.32
RAM: 911MB
Disk: Filesystem      Size  Used Avail Use% Mounted on
/dev/nvme0n1p1  8.0G  1.8G  6.2G  23% /
Checked at: 2026-06-17T10:32:15Z
```

### Verification

The report values were compared against:

```bash
ansible all -m setup -a "filter=ansible_distribution*"
ansible all -m setup -a "filter=ansible_default_ipv4"
ansible all -m setup -a "filter=ansible_memtotal_mb"
ansible all -m shell -a "df -h /"
```

All values matched successfully.

### Result

The playbook successfully demonstrated:

* Facts
* Variables
* Conditionals
* Loops
* Register variables
* Debug output
* Dynamic report generation

All report files contained accurate server information.

