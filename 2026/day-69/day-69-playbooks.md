# Day 69 -- Ansible Playbooks and Modules

---

## Challenge Tasks

### Task 1: Your First Playbook
Create `install-nginx.yml`:

```yaml
---
- name: Install and start Nginx on web servers
  hosts: web
  become: true

  tasks:
    - name: Install Nginx
      yum:
        name: nginx
        state: present

    - name: Start and enable Nginx
      service:
        name: nginx
        state: started
        enabled: true

    - name: Create a custom index page
      copy:
        content: "<h1>Deployed by Ansible - TerraWeek Server</h1>"
        dest: /usr/share/nginx/html/index.html
```

(Use `apt` instead of `yum` if your instances run Ubuntu)

Run it:
```bash
ansible-playbook install-nginx.yml
```

Read the output carefully -- every task shows `changed`, `ok`, or `failed`.

<img width="1180" height="477" alt="image" src="https://github.com/user-attachments/assets/c066f323-cd77-4ddf-92f3-a50c16c4a6bf" />


Now run it **again**. Notice that tasks show `ok` instead of `changed`. This is **idempotency** -- Ansible only makes changes when needed.

<img width="1357" height="412" alt="image" src="https://github.com/user-attachments/assets/30ed96b3-a31f-40a6-a17f-064f0e5cd0ac" />


**Verify:** Curl the web server's public IP. Do you see your custom page?
<img width="1182" height="60" alt="image" src="https://github.com/user-attachments/assets/7cb1eed4-9574-4b2e-a743-9fd0a8ecd8b8" />

<img width="737" height="202" alt="image" src="https://github.com/user-attachments/assets/077f5a6d-6827-4bfe-8ebb-3885cc85b24e" />


---

### Task 2: Understand the Playbook Structure
Open your playbook and annotate each part in your notes:

```yaml
---                                    # YAML document start
- name: Play name                      # PLAY -- targets a group of hosts
  hosts: web                           # Which inventory group to run on
  become: true                         # Run tasks as root (sudo)

  tasks:                               # List of TASKS in this play
    - name: Task name                  # TASK -- one unit of work
      module_name:                     # MODULE -- what Ansible does
        key: value                     # Module arguments
```

Answer:

## Playbook Structure Annotation

Using your `install-nginx.yml`:

```yaml
---
# YAML document start

- name: Install and start Nginx on web servers
  # PLAY
  # A play targets a group of hosts and defines what tasks run on them

  hosts: web
  # Inventory group to execute against

  become: true
  # Run tasks with sudo/root privileges

  tasks:
    # List of tasks

    - name: Install Nginx
      # TASK
      # One unit of work

      yum:
        # MODULE
        # The action Ansible performs

        name: nginx
        state: present
        # Module arguments

    - name: Start and enable Nginx
      service:
        name: nginx
        state: started
        enabled: true

    - name: Create a custom index page
      copy:
        content: "<h1>Deployed by Ansible - TerraWeek Server</h1>"
        dest: /usr/share/nginx/html/index.html
```

---



### 1. What is the difference between a play and a task?

| Play                                               | Task                                |
| -------------------------------------------------- | ----------------------------------- |
| A collection of tasks executed on a group of hosts | A single action performed on a host |
| Defines target hosts and execution settings        | Uses a module to perform work       |
| Contains one or more tasks                         | Smallest unit of work in Ansible    |

Example:

```yaml
- name: Install and start Nginx on web servers
  hosts: web
```

This is a **play**.

```yaml
- name: Install Nginx
  yum:
    name: nginx
    state: present
```

This is a **task**.

**Simple way to remember:**

* Play = "What servers?"
* Task = "What action?"

---

### 2. Can you have multiple plays in one playbook?

**Yes.**

A playbook can contain multiple plays, each targeting different host groups.

Example:

```yaml
---
- name: Configure web servers
  hosts: web

  tasks:
    - name: Install Nginx
      yum:
        name: nginx
        state: present

- name: Configure database servers
  hosts: db

  tasks:
    - name: Install MySQL
      yum:
        name: mysql
        state: present
```

Here:

* First play runs only on `web`
* Second play runs only on `db`

---

### 3. What does `become: true` do at the play level vs task level?

#### Play Level

```yaml
- name: Configure web servers
  hosts: web
  become: true
```

Every task inside the play runs with sudo privileges.

Equivalent to:

```bash
sudo <command>
```

for every task.

---

#### Task Level

```yaml
- name: Install Nginx
  become: true
  yum:
    name: nginx
    state: present
```

Only this task runs with sudo privileges.

Other tasks run as the normal user.

Use task-level `become` when only a few tasks need root access.

---

### 4. What happens if a task fails? Do remaining tasks still run?

**By default: No.**

Example:

```yaml
tasks:
  - name: Install Nginx
    yum:
      name: nginx
      state: present

  - name: Run invalid command
    command: invalid_command

  - name: Create file
    file:
      path: /tmp/test
      state: touch
```

Execution:

```text
Install Nginx      -> OK
Run invalid command -> FAILED
Create file         -> NOT RUN
```

Ansible stops running remaining tasks on that host.

However:

* Other hosts continue processing.
* You can override behavior using `ignore_errors: true`.

Example:

```yaml
- name: Run command
  command: invalid_command
  ignore_errors: true
```

Then Ansible continues to the next task.

---

## Key Takeaways

* **Play** = targets hosts and contains tasks.
* **Task** = one action performed using a module.
* A playbook can contain **multiple plays**.
* `become: true` provides sudo/root privileges.
* If a task fails, subsequent tasks on that host stop unless error handling is used.


---

### Task 3: Learn the Essential Modules
Practice each of these modules by writing a playbook called `essential-modules.yml` with multiple tasks:

1. **`yum`/`apt`** -- Install and remove packages:
```yaml
- name: Install multiple packages
  yum:
    name:
      - git
      - curl
      - wget
      - tree
    state: present
```

2. **`service`** -- Manage services:
```yaml
- name: Ensure Nginx is running
  service:
    name: nginx
    state: started
    enabled: true
```

3. **`copy`** -- Copy files from control node to managed nodes:
```yaml
- name: Copy config file
  copy:
    src: files/app.conf
    dest: /etc/app.conf
    owner: root
    group: root
    mode: '0644'
```

4. **`file`** -- Create directories and manage permissions:
```yaml
- name: Create application directory
  file:
    path: /opt/myapp
    state: directory
    owner: ec2-user
    mode: '0755'
```

5. **`command`** -- Run a command (no shell features):
```yaml
- name: Check disk space
  command: df -h
  register: disk_output

- name: Print disk space
  debug:
    var: disk_output.stdout_lines
```

6. **`shell`** -- Run a command with shell features (pipes, redirects):
```yaml
- name: Count running processes
  shell: ps aux | wc -l
  register: process_count

- name: Show process count
  debug:
    msg: "Total processes: {{ process_count.stdout }}"
```

7. **`lineinfile`** -- Add or modify a single line in a file:
```yaml
- name: Set timezone in environment
  lineinfile:
    path: /etc/environment
    line: 'TZ=Asia/Kolkata'
    create: true
```

Create a `files/` directory with a sample `app.conf` file for the copy task. Run the playbook against all servers.

<img width="1122" height="2362" alt="image" src="https://github.com/user-attachments/assets/d29ffddf-cb60-4576-b807-b04f8e315afc" />

<img width="1252" height="597" alt="image" src="https://github.com/user-attachments/assets/257ab065-8d96-4c49-9ad3-8daea4a133c0" />


**Document:** What is the difference between `command` and `shell`? When should you use each?

| command                        | shell                                     |
| ------------------------------ | ----------------------------------------- |
| Executes commands directly     | Executes commands through a shell         |
| More secure                    | Less secure                               |
| Faster                         | Slightly slower                           |
| No pipes, redirects, wildcards | Supports pipes, redirects, wildcards      |
| Preferred when possible        | Use only when shell features are required |

### command Example

```yaml id="zjlwmc"
- name: Check disk space
  command: df -h
```

Works because it is a simple command.

---

### shell Example

```yaml id="otvyyv"
- name: Count running processes
  shell: ps aux | wc -l
```

Requires a pipe (`|`), so it must use `shell`.

---

## Rule of Thumb

Use **`command` by default**.

Use **`shell` only when you need shell-specific features** such as:

* Pipes (`|`)
* Redirection (`>`, `>>`)
* Wildcards (`*`)
* Environment variable expansion (`$HOME`)



---

### Task 4: Handlers -- Restart Services Only When Needed
Handlers are tasks that run only when triggered by a `notify`. This avoids unnecessary service restarts.

Create `nginx-config.yml`:
```yaml
---
- name: Configure Nginx with a custom config
  hosts: web
  become: true

  tasks:
    - name: Install Nginx
      yum:
        name: nginx
        state: present

    - name: Deploy Nginx config
      copy:
        src: files/nginx.conf
        dest: /etc/nginx/nginx.conf
        owner: root
        mode: '0644'
      notify: Restart Nginx

    - name: Deploy custom index page
      copy:
        content: "<h1>Managed by Ansible</h1><p>Server: {{ inventory_hostname }}</p>"
        dest: /usr/share/nginx/html/index.html

    - name: Ensure Nginx is running
      service:
        name: nginx
        state: started
        enabled: true

  handlers:
    - name: Restart Nginx
      service:
        name: nginx
        state: restarted
```

Create `files/nginx.conf` with a basic Nginx config.

Run the playbook:
- First run: handler triggers because the config file is new
- Second run: handler does NOT trigger because nothing changed

**Verify:** Run it twice and compare the output. Does the handler run both times?
No. The handler runs only on the first run.

<img width="1272" height="1022" alt="image" src="https://github.com/user-attachments/assets/a53c5d76-5ea5-40e1-9c5d-9179cd442f82" />

<img width="550" height="297" alt="image" src="https://github.com/user-attachments/assets/19083c9b-e929-42ec-944b-298713186fba" />

### Handler Verification

I ran `nginx-config.yml` twice.

#### First Run
- `Deploy Nginx config` showed `changed`
- The handler `Restart Nginx` was triggered and executed

#### Second Run
- All tasks showed `ok`
- No changes were detected
- The handler did not run

This demonstrates Ansible's idempotent behavior. Handlers execute only when a task reports a change and sends a notification.

---

### Task 5: Dry Run, Diff, and Verbosity
Before running playbooks on production, always preview changes first.

1. **Dry run (check mode)** -- shows what would change without changing anything:
```bash
ansible-playbook install-nginx.yml --check
```

<img width="1141" height="472" alt="image" src="https://github.com/user-attachments/assets/55244402-f089-4be6-a8fc-0902193fee59" />


2. **Diff mode** -- shows the actual file differences:
```bash
ansible-playbook nginx-config.yml --check --diff
```

<img width="1189" height="881" alt="image" src="https://github.com/user-attachments/assets/582135ff-e2a3-45ad-9686-0e453133bfcd" />


3. **Verbosity** -- increase output detail for debugging:
```bash
ansible-playbook install-nginx.yml -v       # verbose
ansible-playbook install-nginx.yml -vv      # more verbose
ansible-playbook install-nginx.yml -vvv     # connection debugging
```

<img width="2491" height="1266" alt="image" src="https://github.com/user-attachments/assets/4fbaf2d7-9871-406b-9806-77fb0811450a" />
<img width="2487" height="1680" alt="image" src="https://github.com/user-attachments/assets/940bda2b-58f7-4362-9712-92a9efe91d10" />
<img width="2497" height="2163" alt="image" src="https://github.com/user-attachments/assets/3dbf78bc-80bd-4505-bb77-f01d0bd5f997" />



4. **Limit to specific hosts:**
```bash
ansible-playbook install-nginx.yml --limit web-server
```
<img width="2481" height="666" alt="image" src="https://github.com/user-attachments/assets/507cc68d-bafa-4e56-bbc9-a19c19c328bb" />



5. **List what would be affected without running:**
```bash
ansible-playbook install-nginx.yml --list-hosts
ansible-playbook install-nginx.yml --list-tasks
```
<img width="1291" height="826" alt="image" src="https://github.com/user-attachments/assets/e1b289de-1e2e-4314-b573-3fd0c839560d" />



**Document:** Why is `--check --diff` the most important flag combination for production use?

### Why `--check --diff` is Important for Production

`--check` performs a dry run and shows what changes Ansible would make without actually modifying the servers.

`--diff` displays the exact file-level differences between the current state and the desired state.

Using both flags together allows administrators to:

* Preview infrastructure changes safely
* Detect mistakes before deployment
* Review configuration file modifications
* Reduce production outages caused by incorrect changes
* Validate playbooks before applying them

Because no changes are applied while still showing the expected results, `--check --diff` is one of the safest ways to test Ansible playbooks in production environments.


<img width="822" height="788" alt="image" src="https://github.com/user-attachments/assets/67f1d5b5-9464-46d2-8d14-22c00bfb06c5" />


---

### Task 6: Multiple Plays in One Playbook
Write `multi-play.yml` with separate plays for each server group:

```yaml
---
- name: Configure web servers
  hosts: web
  become: true
  tasks:
    - name: Install Nginx
      yum:
        name: nginx
        state: present
    - name: Start Nginx
      service:
        name: nginx
        state: started
        enabled: true

- name: Configure app servers
  hosts: app
  become: true
  tasks:
    - name: Install Node.js dependencies
      yum:
        name:
          - gcc
          - make
        state: present
    - name: Create app directory
      file:
        path: /opt/app
        state: directory
        mode: '0755'

- name: Configure database servers
  hosts: db
  become: true
  tasks:
    - name: Install MySQL client
      yum:
        name: mysql
        state: present
    - name: Create data directory
      file:
        path: /var/lib/appdata
        state: directory
        mode: '0700'
```

Run it:
```bash
ansible-playbook multi-play.yml
```

Watch the output -- each play targets a different group, and tasks run only on the relevant hosts.

<img width="1337" height="872" alt="image" src="https://github.com/user-attachments/assets/8ec6b4ef-8bbe-49d2-86db-c21d137c17fc" />


**Verify:** Is Nginx only installed on web servers? Is MySQL only on db servers?

  - Yes, `Nginx` is Installed on `web server` & `Mysql` is on `db server`

<img width="1312" height="902" alt="image" src="https://github.com/user-attachments/assets/8b9cf1ee-611a-4dd9-a45a-91deabff85f1" />

### Verification of Multiple Plays

The `multi-play.yml` playbook contained three separate plays targeting the `web`, `app`, and `db` inventory groups.

Verification showed:

* Nginx service running on the web server.
* GCC and Make packages installed on the app server.
* MariaDB client installed on the database server.
* `/opt/app` directory created only on the app server.
* `/var/lib/appdata` directory created only on the database server.

Nginx was also present on the app and database servers because it had been installed earlier during Task 1 when the playbook was executed against `hosts: all`. However, the Task 6 play itself correctly targeted only the hosts defined in each play.


---

## Documentation




## Task 1: First Playbook with Annotations


```
---
# YAML document start

- name: Install and start Nginx on web servers
  # PLAY
  # A play targets a group of hosts and defines what tasks run on them

  hosts: web
  # Inventory group to execute against

  become: true
  # Run tasks with sudo/root privileges

  tasks:
    # List of tasks

    - name: Install Nginx
      # TASK
      # One unit of work

      yum:
        # MODULE
        # The action Ansible performs

        name: nginx
        state: present
        # Module arguments

    - name: Start and enable Nginx
      service:
        name: nginx
        state: started
        enabled: true

    - name: Create a custom index page
      copy:
        content: "<h1>Deployed by Ansible - TerraWeek Server</h1>"
        dest: /usr/share/nginx/html/index.html
```

### Playbook Structure

* **Play**: A collection of tasks that runs on a specified group of hosts.
* **Task**: A single unit of work executed by Ansible.
* **Module**: The action Ansible performs (yum, service, copy, etc.).
* **become: true**: Runs tasks with elevated (root/sudo) privileges.

### Answers

**1. Difference between a play and a task?**

* A play defines *which hosts* Ansible targets.
* A task defines *what action* Ansible performs.

**2. Can you have multiple plays in one playbook?**

Yes. A single playbook can contain multiple plays targeting different host groups.

**3. What does become: true do at play level vs task level?**

* Play level: applies to all tasks in the play.
* Task level: applies only to that specific task.

**4. What happens if a task fails?**

By default, Ansible stops executing remaining tasks for that host and marks it as failed.



---

## Task 3: Essential Modules

### 1. yum Module

Installs, updates, or removes packages.

```yaml
- name: Install packages
  yum:
    name:
      - git
      - wget
      - tree
    state: present
```

### 2. service Module

Manages services.

```yaml
- name: Ensure Nginx is running
  service:
    name: nginx
    state: started
    enabled: true
```

### 3. copy Module

Copies files from the Ansible control node to managed nodes.

```yaml
- name: Copy config file
  copy:
    src: files/app.conf
    dest: /etc/app.conf
```

### 4. file Module

Creates files/directories and manages permissions.

```yaml
- name: Create application directory
  file:
    path: /opt/myapp
    state: directory
```

### 5. command Module

Executes commands without shell features.

```yaml
- name: Check disk space
  command: df -h
```

### 6. shell Module

Executes commands using a shell.

```yaml
- name: Count running processes
  shell: ps aux | wc -l
```

### 7. lineinfile Module

Adds or modifies a specific line in a file.

```yaml
- name: Set timezone
  lineinfile:
    path: /etc/environment
    line: 'TZ=Asia/Kolkata'
```

### command vs shell

| command                 | shell                                     |
| ----------------------- | ----------------------------------------- |
| Safer                   | Less secure                               |
| No pipes or redirects   | Supports pipes and redirects              |
| Preferred when possible | Use only when shell features are required |

Examples:

```yaml
command: df -h
```

```yaml
shell: ps aux | wc -l
```

---

## Task 4: Handlers

### What is a Handler?

A handler is a task that runs only when notified by another task.

### Example

```yaml
- name: Deploy Nginx config
  copy:
    src: files/nginx.conf
    dest: /etc/nginx/nginx.conf
  notify: Restart Nginx
```

```yaml
handlers:
  - name: Restart Nginx
    service:
      name: nginx
      state: restarted
```

### First Run

Output:

```text
TASK [Deploy Nginx config]
changed

RUNNING HANDLER [Restart Nginx]
changed
```

The handler runs because the configuration file changed.

### Second Run

Output:

```text
TASK [Deploy Nginx config]
ok
```

No handler execution occurs because no changes were detected.

### Result

Handlers prevent unnecessary service restarts and only execute when needed.

```
```

---

## Task 5: Dry Run, Diff, and Verbosity

### --check

Performs a dry run and shows what changes would occur without actually making them.

```bash
ansible-playbook nginx-config.yml --check
```

### --diff

Shows file-level differences before changes are applied.

```bash
ansible-playbook nginx-config.yml --check --diff
```

### -v

Provides additional execution details.

```bash
ansible-playbook nginx-config.yml -v
```

### -vv

Provides more detailed module output.

```bash
ansible-playbook nginx-config.yml -vv
```

### -vvv

Displays SSH connection and debugging information.

```bash
ansible-playbook nginx-config.yml -vvv
```

### Why is --check --diff important?

Using both flags together allows administrators to:

* Preview changes safely.
* Review configuration differences before deployment.
* Detect mistakes before affecting production systems.
* Reduce downtime and deployment risks.

This is one of the safest ways to validate Ansible playbooks before execution.



