# Day 71 -- Roles, Galaxy, Templates and Vault

---

## Challenge Tasks

### Task 1: Jinja2 Templates
Templates let you generate config files dynamically using variables and facts.

1. Create `templates/nginx-vhost.conf.j2`:
```jinja2
# Managed by Ansible -- do not edit manually
server {
    listen {{ http_port | default(80) }};
    server_name {{ ansible_hostname }};

    root /var/www/{{ app_name }};
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    access_log /var/log/nginx/{{ app_name }}_access.log;
    error_log /var/log/nginx/{{ app_name }}_error.log;
}
```

2. Create a playbook `template-demo.yml`:
```yaml
---
- name: Deploy Nginx with template
  hosts: web
  become: true
  vars:
    app_name: terraweek-app
    http_port: 80

  tasks:
    - name: Install Nginx
      apt:
        name: nginx
        state: present

    - name: Create web root
      file:
        path: "/var/www/{{ app_name }}"
        state: directory
        mode: '0755'

    - name: Deploy vhost config from template
      template:
        src: templates/nginx-vhost.conf.j2
        dest: "/etc/nginx/conf.d/{{ app_name }}.conf"
        owner: root
        mode: '0644'
      notify: Restart Nginx

    - name: Deploy index page
      copy:
        content: "<h1>{{ app_name }}</h1><p>Host: {{ ansible_hostname }} | IP: {{ ansible_default_ipv4.address }}</p>"
        dest: "/var/www/{{ app_name }}/index.html"

  handlers:
    - name: Restart Nginx
      service:
        name: nginx
        state: restarted
```

Run it with `--diff` to see the rendered template:
```bash
ansible-playbook template-demo.yml --diff
```

<img width="1037" height="1080" alt="image" src="https://github.com/user-attachments/assets/49995cf6-d3db-4201-b2d2-36a6ee8b2d14" />


**Verify:** SSH into the web server and read the generated config. Are the variables replaced with actual values?


<img width="1186" height="755" alt="image" src="https://github.com/user-attachments/assets/5251a0fb-f5a5-4e81-a4bb-a79233cb55ca" />

**Answer: YES**

Template:

```jinja2
listen {{ http_port }};
server_name {{ ansible_hostname }};
root /var/www/{{ app_name }};
```

Rendered output:

```nginx
listen 80;
server_name ip-172-31-43-135;
root /var/www/terraweek-app;
```

And the index page:

```html
<h1>terraweek-app</h1>
<p>Host: ip-172-31-43-135 | IP: 172.31.43.135</p>
```

This proves:

| Variable                             | Rendered Value     |
| ------------------------------------ | ------------------ |
| `{{ http_port }}`                    | `80`               |
| `{{ app_name }}`                     | `terraweek-app`    |
| `{{ ansible_hostname }}`             | `ip-172-31-43-135` |
| `{{ ansible_default_ipv4.address }}` | `172.31.43.135`    |

---

Created a Jinja2 template (nginx-vhost.conf.j2) and deployed it using the Ansible template module.

Verified that variables and Ansible facts were rendered dynamically:

- http_port → 80
- app_name → terraweek-app
- ansible_hostname → ip-172-31-43-135
- ansible_default_ipv4.address → 172.31.43.135

Generated file:

/etc/nginx/conf.d/terraweek-app.conf

Generated web page:

/var/www/terraweek-app/index.html

---

### Task 2: Understand the Role Structure
An Ansible role has a fixed directory structure. Each directory has a specific purpose:

```
roles/
  webserver/
    tasks/
      main.yml         # The main task list
    handlers/
      main.yml         # Handlers (restart services, etc.)
    templates/
      nginx.conf.j2    # Jinja2 templates
    files/
      index.html       # Static files to copy
    vars/
      main.yml         # Role variables (high priority)
    defaults/
      main.yml         # Default variables (low priority, easily overridden)
    meta/
      main.yml         # Role metadata and dependencies
```

Every directory contains a `main.yml` that Ansible loads automatically. You only create the directories you need.

Generate a skeleton with:
```bash
ansible-galaxy init roles/webserver
```

<img width="860" height="507" alt="image" src="https://github.com/user-attachments/assets/d610666b-067f-4f03-bc02-270365e8df87" />


Explore the generated directory. Read the README.md that Galaxy creates.

It serves as documentation for:

What the role does
Variables
Dependencies
Example usage

In real projects, every reusable role should have a proper README.

### Understanding Each Directory
| Directory    | Purpose                                           |
| ------------ | ------------------------------------------------- |
| `tasks/`     | Main automation steps                             |
| `handlers/`  | Triggered actions (restart nginx, reload service) |
| `templates/` | Jinja2 templates (`.j2`)                          |
| `files/`     | Static files copied as-is                         |
| `defaults/`  | User-overridable variables                        |
| `vars/`      | Internal/high-priority variables                  |
| `meta/`      | Metadata, dependencies, Galaxy info               |
| `tests/`     | Role testing                                      |
| `README.md`  | Documentation                                     |


<img width="1990" height="906" alt="image" src="https://github.com/user-attachments/assets/ee9006d7-4dc1-4e2f-8106-292cbeb2efbd" />

**Document:** What is the difference between `vars/main.yml` and `defaults/main.yml`?

## vars/main.yml vs defaults/main.yml

### defaults/main.yml
- Lowest variable precedence
- Intended for user-customizable values
- Easily overridden by inventory, playbooks, or extra vars

Example:
http_port: 80

### vars/main.yml
- Higher variable precedence
- Used for internal role variables
- Not intended to be overridden frequently

Example:
nginx_service_name: nginx

Rule of thumb:
- Use defaults/ for configurable settings
- Use vars/ for constants and internal values

---

### Task 3: Build a Custom Webserver Role
Build a complete `webserver` role from scratch:

**`roles/webserver/defaults/main.yml`:**
```yaml
---
http_port: 80
app_name: myapp
max_connections: 512
```

**`roles/webserver/tasks/main.yml`:**
```yaml
---
- name: Install Nginx
  yum:
    name: nginx
    state: present

- name: Deploy Nginx config
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    mode: '0644'
  notify: Restart Nginx

- name: Deploy vhost config
  template:
    src: vhost.conf.j2
    dest: "/etc/nginx/conf.d/{{ app_name }}.conf"
    owner: root
    mode: '0644'
  notify: Restart Nginx

- name: Create web root
  file:
    path: "/var/www/{{ app_name }}"
    state: directory
    mode: '0755'

- name: Deploy index page
  template:
    src: index.html.j2
    dest: "/var/www/{{ app_name }}/index.html"
    mode: '0644'

- name: Start and enable Nginx
  service:
    name: nginx
    state: started
    enabled: true
```

**`roles/webserver/handlers/main.yml`:**
```yaml
---
- name: Restart Nginx
  service:
    name: nginx
    state: restarted
```

**`roles/webserver/templates/index.html.j2`:**
```html
<h1>{{ app_name }}</h1>
<p>Server: {{ ansible_hostname }}</p>
<p>IP: {{ ansible_default_ipv4.address }}</p>
<p>Environment: {{ app_env | default('development') }}</p>
<p>Managed by Ansible</p>
```

Create the `vhost.conf.j2` and `nginx.conf.j2` templates yourself based on what you learned in Task 1.

**`roles/webserver/templates/vhsot.confg.j2`:**
```yaml
# Managed by Ansible -- do not edit manually

server {
    # Listen on configured HTTP port
    listen {{ http_port | default(80) }} default_server;

    # Server name: IP as default, _ as wildcard
    server_name {{ ansible_default_ipv4.address }} _;

    # Web root directory
    root /var/www/{{ app_name }};
    index index.html;

    # Request handling
    location / {
        # Try requested URI, then directory, else return 404
        try_files $uri $uri/ =404;
    }

    # App-specific logs
    access_log /var/log/nginx/{{ app_name }}_access.log;
    error_log /var/log/nginx/{{ app_name }}_error.log;
}
```

**`roles/webserver/templates/nginx.conf.j2`:**
```yaml
# Event settings
events {
    # Maximum simultaneous connections per worker
    worker_connections {{ max_connections | default(512) }};
}

# HTTP block for general settings
http {
    # Load MIME types
    include /etc/nginx/mime.types;

    # Default content type
    default_type application/octet-stream;

    # Enable efficient file sending
    sendfile on;

    # Keep connections alive for 65 seconds
    keepalive_timeout 65;

    # Global access and error logs
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Include all virtual hosts
    include /etc/nginx/conf.d/*.conf;
}
```

<img width="895" height="507" alt="image" src="https://github.com/user-attachments/assets/b804ad0a-207e-4e5e-beaa-6734b6aaf965" />


Now call the role from a playbook `site.yml`:
```yaml
---
- name: Configure web servers
  hosts: web
  become: true
  roles:
    - role: webserver
      vars:
        app_name: terraweek
        http_port: 80
```

Run it:
```bash
ansible-playbook site.yml
```

<img width="1112" height="677" alt="image" src="https://github.com/user-attachments/assets/940c6842-e068-482f-aad4-d0d459dba2eb" />


**Verify:** Curl the web server. Does the custom page load?

<img width="985" height="570" alt="image" src="https://github.com/user-attachments/assets/d689020f-962c-4c83-b0c6-46d6e1069238" />


---

### Task 4: Ansible Galaxy -- Use Community Roles
Ansible Galaxy is a marketplace of pre-built roles.

1. **Search for roles:**
```bash
ansible-galaxy search nginx --platforms EL
ansible-galaxy search mysql
```

<img width="1532" height="1277" alt="image" src="https://github.com/user-attachments/assets/cefa978a-6767-4cb2-bb37-b787b8b8cbb9" />
<img width="1616" height="1271" alt="image" src="https://github.com/user-attachments/assets/88b161ba-b49e-4b9e-a92a-8000ea71747a" />


2. **Install a role from Galaxy:**
```bash
ansible-galaxy install geerlingguy.docker
```

3. **Check where it was installed:**
```bash
ansible-galaxy list
```

<img width="1062" height="245" alt="image" src="https://github.com/user-attachments/assets/f006a114-1f0a-400d-a356-fb9e66f9e8d8" />


- The geerlingguy.docker role was installed locally in the roles/ folder i.e.`ansible-practice/roles/geerlingguy.docker/`

4. **Use the installed role** -- create `docker-setup.yml`:
```yaml
---
- name: Install Docker using Galaxy role
  hosts: app-server
  become: true

  vars:
    docker_packages:
      - docker

    docker_packages_state: present

    docker_service_manage: true

    docker_users:
      - ec2-user

    docker_install_compose_plugin: false

  roles:
    - geerlingguy.docker
```

Run it -- Docker gets installed with a single role call.

<img width="716" height="1217" alt="image" src="https://github.com/user-attachments/assets/9e240516-67af-4226-aabb-e809f4eb29b4" />


5. **Use a requirements file** for managing multiple roles. Create `requirements.yml`:
```yaml
---
roles:
  - name: geerlingguy.docker
    version: "7.4.1"
  - name: geerlingguy.ntp
```

Install all at once:
```bash
ansible-galaxy install -r requirements.yml
```


<img width="1062" height="1271" alt="image" src="https://github.com/user-attachments/assets/50460bea-af57-4206-9445-23fe92bee142" />



**Document:** Why use a `requirements.yml` instead of installing roles manually?

### Why use `requirements.yml` instead of installing roles manually?

A `requirements.yml` file helps manage Ansible Galaxy roles in a consistent and repeatable way.

Benefits include:

1. **Version Control**

   * Specific role versions can be pinned.
   * Ensures all team members use the same tested version.
   * Prevents unexpected issues caused by role updates.

2. **Automation**

   * Multiple roles can be installed with a single command:

     ```bash
     ansible-galaxy install -r requirements.yml
     ```
   * Eliminates the need to install each role individually.

3. **Reproducibility**

   * Makes it easy to recreate the same environment on different machines or CI/CD pipelines.
   * New team members can quickly install all required dependencies.

4. **Centralized Dependency Management**

   * All required roles are listed in one file.
   * Easier to maintain and review project dependencies.

5. **Infrastructure as Code Best Practice**

   * Role dependencies become part of the project's source code.
   * The complete setup can be tracked in Git along with playbooks and inventories.

Example:

```yaml
---
roles:
  - name: geerlingguy.docker
    version: "7.4.1"
  - name: geerlingguy.ntp
```

This allows Ansible to install the exact role versions needed for the project, ensuring consistent and reliable deployments.

> requirements.yml provides automated, version-controlled, and reproducible management of Ansible Galaxy roles, making deployments consistent across different environments and team members.

---

### Task 5: Ansible Vault -- Encrypt Secrets
Never put passwords, API keys, or tokens in plain text. Ansible Vault encrypts sensitive data.

1. **Create an encrypted file:**
```bash
ansible-vault create group_vars/db/vault.yml
```




It will ask for a vault password, then open an editor. Add:
```yaml
vault_db_password: SuperSecretP@ssw0rd
vault_db_root_password: R00tP@ssw0rd123
vault_api_key: sk-abc123xyz789
```
Save and exit. Open the file with `cat` -- it is fully encrypted.

<img width="961" height="131" alt="image" src="https://github.com/user-attachments/assets/f12918f9-30cf-49a4-9eac-df581bd90ef4" />

2. **Edit an encrypted file:**
```bash
ansible-vault edit group_vars/db/vault.yml
```

3. **View without editing:**
```bash
ansible-vault view group_vars/db/vault.yml
```

<img width="1097" height="157" alt="image" src="https://github.com/user-attachments/assets/80eef23c-0e38-4854-bac9-790582b9c009" />


4. **Encrypt an existing file:**
```bash
ansible-vault encrypt group_vars/db/secrets.yml
```

<img width="1131" height="485" alt="image" src="https://github.com/user-attachments/assets/4acba831-3a0c-4d25-9c25-8a1684acb3aa" />


5. **Use vault variables in a playbook** -- create `db-setup.yml`:
```yaml
---
- name: Configure database
  hosts: db
  become: true

  tasks:
    - name: Show DB password (never do this in production)
      debug:
        msg: "DB password is set: {{ vault_db_password | length > 0 }}"
```

Run with the vault password:
```bash
ansible-playbook db-setup.yml --ask-vault-pass
```

<img width="1351" height="347" alt="image" src="https://github.com/user-attachments/assets/3358b906-4b76-4a68-b24e-a830f86c488d" />


6. **Use a password file** (better for CI/CD):
```bash
echo "YourVaultPassword" > .vault_pass
chmod 600 .vault_pass
echo ".vault_pass" >> .gitignore

ansible-playbook db-setup.yml --vault-password-file .vault_pass
```

<img width="1257" height="357" alt="image" src="https://github.com/user-attachments/assets/631e0aff-7de7-4409-80e8-667311762620" />



Or set it in `ansible.cfg`:
```ini
[defaults]
vault_password_file = .vault_pass
```

**Document:** Why is `--vault-password-file` better than `--ask-vault-pass` for automated pipelines?

# Why is `--vault-password-file` Better than `--ask-vault-pass` for Automated Pipelines?

## Introduction

Ansible Vault is used to securely store sensitive information such as passwords, API keys, and database credentials in encrypted files. To decrypt these files during playbook execution, Ansible needs access to the vault password.

Two common methods are:

1. `--ask-vault-pass`
2. `--vault-password-file`

While both methods work, `--vault-password-file` is generally preferred for automated environments such as CI/CD pipelines.

---

## Using `--ask-vault-pass`

Example:

```bash
ansible-playbook site.yml --ask-vault-pass
```

When executed, Ansible prompts the user:

```text
Vault password:
```

### Advantages

* Simple to use.
* No password file required.
* Suitable for learning and manual execution.

### Limitations

* Requires human interaction.
* Cannot run unattended.
* Not suitable for automation tools such as Jenkins, GitHub Actions, GitLab CI, or Azure DevOps.

---

## Using `--vault-password-file`

Example:

```bash
ansible-playbook site.yml --vault-password-file .vault_pass
```

Contents of `.vault_pass`:

```text
vault
```

Ansible automatically reads the password from the file and decrypts the vault without prompting the user.

### Advantages

* Fully automated execution.
* Works in CI/CD pipelines.
* Enables scheduled and unattended deployments.
* Eliminates manual password entry.

---

## Why Automated Pipelines Need It

A CI/CD system executes jobs without human involvement.

For example:

```text
Developer pushes code
        ↓
GitHub Actions starts
        ↓
Ansible playbook runs
        ↓
Infrastructure is deployed
```

If the playbook uses:

```bash
ansible-playbook site.yml --ask-vault-pass
```

the pipeline will stop and wait forever for someone to type a password.

With:

```bash
ansible-playbook site.yml --vault-password-file .vault_pass
```

the job continues automatically.

---

## Security Considerations

Storing the vault password in a plain text file can be risky if not handled correctly.

Recommended practices:

### Restrict Permissions

```bash
chmod 600 .vault_pass
```

Only the owner can read the file.

### Do Not Commit Password Files

Add the file to `.gitignore`:

```text
.vault_pass
```

The encrypted vault file can be committed to Git, but the password file should never be stored in the repository.

### Use Secret Managers

In production environments, the password is often retrieved from:

* AWS Secrets Manager
* HashiCorp Vault
* Azure Key Vault
* GitHub Actions Secrets
* GitLab CI Variables

Instead of storing the password directly on disk.

---

## Comparison

| Feature             | `--ask-vault-pass` | `--vault-password-file` |
| ------------------- | ------------------ | ----------------------- |
| Manual execution    | Yes                | Yes                     |
| Requires user input | Yes                | No                      |
| Suitable for CI/CD  | No                 | Yes                     |
| Fully automated     | No                 | Yes                     |
| Easy for beginners  | Yes                | Yes                     |
| Production-friendly | Limited            | Yes                     |

---

## Conclusion

`--ask-vault-pass` is useful for learning, testing, and occasional manual execution because it prompts the user to enter the vault password interactively.

`--vault-password-file` is preferred for automated pipelines because it allows Ansible to decrypt vaults without human intervention. When combined with proper file permissions, secret management tools, and CI/CD secrets, it enables secure and fully automated infrastructure deployments.


---

### Task 6: Combine Roles, Templates, and Vault
Write a complete `site.yml` that uses everything you learned today:

```yaml
---
- name: Configure web servers
  hosts: web
  become: true
  roles:
    - role: webserver
      vars:
        app_name: terraweek
        http_port: 80

- name: Configure app servers with Docker
  hosts: app
  become: true
  roles:
    - geerlingguy.docker

- name: Configure database servers
  hosts: db
  become: true
  tasks:
    - name: Create DB config with secrets
      template:
        src: templates/db-config.j2
        dest: /etc/db-config.env
        owner: root
        mode: '0600'
```

Create `templates/db-config.j2`:
```jinja2
# Database Configuration -- Managed by Ansible
DB_HOST={{ ansible_default_ipv4.address }}
DB_PORT={{ db_port | default(3306) }}
DB_PASSWORD={{ vault_db_password }}
DB_ROOT_PASSWORD={{ vault_db_root_password }}
```

Run:
```bash
ansible-playbook site.yml
```



**Verify:** SSH into the db server and check `/etc/db-config.env`. Are the secrets rendered correctly? Is the file permission `600`?

- Yes

<img width="1172" height="527" alt="image" src="https://github.com/user-attachments/assets/a34b013e-4ded-4833-b807-2c055d052d69" />



---



#  Ansible Project Documentation

---

# 1. Webserver Role Directory Structure

A typical Ansible role follows a standard structure:

```
roles/
└── webserver/
    ├── tasks/
    │   └── main.yml
    ├── handlers/
    │   └── main.yml
    ├── templates/
    │   ├── index.html.j2
    │   └── nginx.conf.j2
    ├── files/
    ├── vars/
    │   └── main.yml
    ├── defaults/
    │   └── main.yml
    ├── meta/
    │   └── main.yml
    └── README.md
```

### Key idea:

* `tasks/` → what to run
* `templates/` → Jinja2 dynamic configs
* `handlers/` → restart services
* `vars/defaults` → variables

---

# 2. Jinja2 Templates & Rendered Output

## Example template: `templates/index.html.j2`

```html
<html>
  <head><title>Welcome</title></head>
  <body>
    <h1>Hello from {{ ansible_hostname }}</h1>
    <p>Managed by Ansible Webserver Role</p>
  </body>
</html>
```

---

## Rendered output (on target server)

After running playbook:

```html
<html>
  <head><title>Welcome</title></head>
  <body>
    <h1>Hello from ip-172-31-45-221</h1>
    <p>Managed by Ansible Webserver Role</p>
  </body>
</html>
```

---

# 3. Screenshot of Role Execution (Above atached)

When successful:

```
TASK [webserver : Install nginx] ***************
changed: [app-server]

TASK [webserver : Copy template] **************
changed: [app-server]

TASK [webserver : Start nginx] ***************
ok: [app-server]

PLAY RECAP ************************************
app-server : ok=3 changed=2 failed=0
```

---

# 4. Installing & Using a Galaxy Role

## Install role from Galaxy

```bash
ansible-galaxy install geerlingguy.docker
```

or using requirements file:

### requirements.yml

```yaml
- src: geerlingguy.docker
```

Install:

```bash
ansible-galaxy install -r requirements.yml
```

---

## Use in playbook

```yaml
- hosts: app
  become: true

  roles:
    - geerlingguy.docker
```

---

# 5. Ansible Vault Workflow

## Create encrypted file

```bash
ansible-vault create group_vars/db/vault.yml
```

---

## Edit encrypted file

```bash
ansible-vault edit group_vars/db/vault.yml
```

---

## View encrypted file

```bash
ansible-vault view group_vars/db/vault.yml
```

---

## Encrypt existing file

```bash
ansible-vault encrypt group_vars/db/secrets.yml
```

---

## Decrypt file

```bash
ansible-vault decrypt group_vars/db/secrets.yml
```

---

## Re-key (change password)

```bash
ansible-vault rekey group_vars/db/secrets.yml
```

---

# 6. Screenshot of Encrypted Vault File (Attached Above )

After encryption:

```bash
cat group_vars/db/secrets.yml
```

Output:

```
$ANSIBLE_VAULT;1.1;AES256
6139393739....
7a6b4f....
```

---

# 7. Vault Password File Workflow (CI/CD Best Practice)

## Create password file

```bash
echo "MyVaultPassword" > .vault_pass
chmod 600 .vault_pass
```

## Use in playbook

```bash
ansible-playbook db-setup.yml --vault-password-file .vault_pass
```

## Or in ansible.cfg

```ini
[defaults]
vault_password_file = .vault_pass
```

---

# Why password file is better than --ask-vault-pass

| Method                | Use Case        | Issue                   |
| --------------------- | --------------- | ----------------------- |
| --ask-vault-pass      | Manual runs     | Not automation-friendly |
| --vault-password-file | CI/CD pipelines | Fully automated         |
| ansible.cfg           | Team standard   | No repeated typing      |

---

# 8. Roles vs Playbooks vs Ad-hoc Commands

## 🔹 Ad-hoc commands

Used for quick tasks

```bash
ansible all -m ping
ansible all -m yum -a "name=nginx state=present"
```

✔ Fast
❌ Not reusable

---

## 🔹 Playbooks

Used for automation workflows

```yaml
- hosts: web
  tasks:
    - name: install nginx
      yum:
        name: nginx
        state: present
```

✔ Reusable
✔ Structured

---

## 🔹 Roles (Best Practice)

Used for production-grade automation

✔ Modular
✔ Reusable across projects
✔ Organized structure
✔ Supports scaling

---

# Final Summary

* Roles → Production automation structure
* Playbooks → Task orchestration
* Ad-hoc → Quick debugging commands
* Vault → Secure secrets management
* Galaxy → Reusable community roles


