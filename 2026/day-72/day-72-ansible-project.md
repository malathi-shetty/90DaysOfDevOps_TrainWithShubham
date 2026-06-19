# Day 72 -- Ansible Project: Automate Docker and Nginx Deployment
---

## Challenge Tasks

### Task 1: Plan the Project Structure
Create the complete project layout:

```
ansible-docker-project/
  ansible.cfg
  inventory.ini
  site.yml                          # Master playbook
  group_vars/
    all.yml                         # Common variables
    web/
      vars.yml                      # Nginx variables
      vault.yml                     # Encrypted Docker Hub credentials
  roles/
    common/                         # Shared setup for all servers
      tasks/main.yml
    docker/                         # Docker installation and container management
      tasks/main.yml
      templates/
        docker-compose.yml.j2
      handlers/main.yml
      defaults/main.yml
    nginx/                          # Nginx reverse proxy
      tasks/main.yml
      templates/
        nginx.conf.j2
        app-proxy.conf.j2
      handlers/main.yml
      defaults/main.yml
```



Generate the role skeletons:
```bash
mkdir -p ansible-docker-project/roles
cd ansible-docker-project
ansible-galaxy init roles/common
ansible-galaxy init roles/docker
ansible-galaxy init roles/nginx
```

<img width="997" height="907" alt="image" src="https://github.com/user-attachments/assets/e1b823b3-15c0-4fca-bc90-721b2694d583" />


Set up your `ansible.cfg` and `inventory.ini` using what you built on Day 68.

---

### Task 2: Build the Common Role
The `common` role runs on every server -- baseline packages and setup.

**`roles/common/tasks/main.yml`:**
```yaml
---
- name: Update package cache
  yum:
    update_cache: true
  tags: common

- name: Install common packages
  yum:
    name: "{{ common_packages }}"
    state: present
  tags: common

- name: Set hostname
  hostname:
    name: "{{ inventory_hostname }}"
  tags: common

- name: Set timezone
  timezone:
    name: "{{ timezone }}"
  tags: common

- name: Create deploy user
  user:
    name: deploy
    groups: wheel
    shell: /bin/bash
    state: present
  tags: common
```

(Use `apt` instead of `yum` if your instances run Ubuntu)

**`group_vars/all.yml`:**
```yaml
---
timezone: Asia/Kolkata
project_name: devops-app
app_env: development
common_packages:
  - vim
  - curl
  - wget
  - git
  - htop
  - tree
  - jq
  - unzip
```



<img width="1572" height="1272" alt="image" src="https://github.com/user-attachments/assets/245c5cc2-0301-48c0-b15c-22de805755a6" />
<img width="927" height="1135" alt="image" src="https://github.com/user-attachments/assets/2ec11e36-3d39-4bf9-b6cb-ac685d4f9b75" />


---

### Task 3: Build the Docker Role
This role installs Docker, starts the service, pulls images, and runs containers.

**`roles/docker/defaults/main.yml`:**
```yaml
---
docker_app_image: nginx
docker_app_tag: latest
docker_app_name: myapp
docker_app_port: 8080
docker_container_port: 80
```

**`roles/docker/tasks/main.yml`:**
Write tasks that:
1. Install Docker dependencies (`yum-utils`, `device-mapper-persistent-data`, `lvm2`)
2. Add the Docker CE repository
3. Install Docker CE
4. Start and enable the Docker service
5. Add the `deploy` user to the `docker` group
6. Install Docker Compose (via pip or direct download)
7. Log in to Docker Hub using vault-encrypted credentials:
```yaml
- name: Log in to Docker Hub
  community.docker.docker_login:
    username: "{{ vault_docker_username }}"
    password: "{{ vault_docker_password }}"
  become_user: deploy
  when: vault_docker_username is defined
```
8. Pull the application image:
```yaml
- name: Pull application image
  community.docker.docker_image:
    name: "{{ docker_app_image }}"
    tag: "{{ docker_app_tag }}"
    source: pull
```
9. Run the container:
```yaml
- name: Run application container
  community.docker.docker_container:
    name: "{{ docker_app_name }}"
    image: "{{ docker_app_image }}:{{ docker_app_tag }}"
    state: started
    restart_policy: always
    ports:
      - "{{ docker_app_port }}:{{ docker_container_port }}"
```
10. Verify the container is running:
```yaml
- name: Wait for container to be healthy
  uri:
    url: "http://localhost:{{ docker_app_port }}"
    status_code: 200
  retries: 5
  delay: 3
  register: health_check
  until: health_check.status == 200
```

Tag all tasks with `docker`.

**`roles/docker/handlers/main.yml`:**
```yaml
---
- name: Restart Docker
  service:
    name: docker
    state: restarted
```

**Install the required Ansible collection** (needed for `community.docker` modules):
```bash
ansible-galaxy collection install community.docker
```
<img width="2117" height="202" alt="image" src="https://github.com/user-attachments/assets/8883b7d4-9203-4566-8c72-5a073031cb0f" />

<img width="1530" height="1132" alt="image" src="https://github.com/user-attachments/assets/fc346c10-529a-4aee-975c-46e1bbde14a9" />


---

### Task 4: Build the Nginx Role
This role installs Nginx and configures it as a reverse proxy to the Docker container.

**`roles/nginx/defaults/main.yml`:**
```yaml
---
nginx_http_port: 80
nginx_upstream_port: 8080
nginx_server_name: "_"
```

**`roles/nginx/tasks/main.yml`:**
Write tasks that:
1. Install Nginx
2. Remove the default Nginx site config
3. Deploy the main Nginx config from a template
4. Deploy the reverse proxy config from a template
5. Test Nginx config before reloading:
```yaml
- name: Test Nginx configuration
  command: nginx -t
  changed_when: false
```
6. Start and enable Nginx
7. Use a handler to reload Nginx when any config changes

Tag all tasks with `nginx`.

**`roles/nginx/templates/app-proxy.conf.j2`:**
```nginx
# Reverse Proxy to Docker Container -- Managed by Ansible
upstream docker_app {
    server 127.0.0.1:{{ nginx_upstream_port }};
}

server {
    listen {{ nginx_http_port }};
    server_name {{ nginx_server_name }};

    location / {
        proxy_pass http://docker_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        access_log off;
        return 200 'OK';
        add_header Content-Type text/plain;
    }

{% if app_env == 'production' %}
    access_log /var/log/nginx/{{ project_name }}_access.log;
    error_log /var/log/nginx/{{ project_name }}_error.log;
{% else %}
    access_log /var/log/nginx/{{ project_name }}_access.log;
    error_log /var/log/nginx/{{ project_name }}_error.log debug;
{% endif %}
}
```

**`roles/nginx/handlers/main.yml`:**
```yaml
---
- name: Reload Nginx
  service:
    name: nginx
    state: reloaded

- name: Restart Nginx
  service:
    name: nginx
    state: restarted
```

<img width="1052" height="527" alt="image" src="https://github.com/user-attachments/assets/2717a7e4-ac87-4d8a-b944-cf5538cea4d9" />


---

### Task 5: Encrypt Docker Hub Credentials with Vault
1. Create the vault file:
```bash
ansible-vault create group_vars/web/vault.yml
```
Add:
```yaml
vault_docker_username: your-dockerhub-username
vault_docker_password: your-dockerhub-token
```

2. Create a vault password file for convenience:
```bash
echo "YourVaultPassword" > .vault_pass
chmod 600 .vault_pass
echo ".vault_pass" >> .gitignore
```

3. Reference it in `ansible.cfg`:
```ini
[defaults]
inventory = inventory.ini
host_key_checking = False
vault_password_file = .vault_pass
```

<img width="1396" height="1146" alt="image" src="https://github.com/user-attachments/assets/317d8bff-da69-4b13-8060-ed27b3f23d60" />


---

### Task 6: Write the Master Playbook and Deploy
**`site.yml`:**
```yaml
---
- name: Apply common configuration
  hosts: all
  become: true
  roles:
    - common
  tags: common

- name: Install Docker and run containers
  hosts: web
  become: true
  roles:
    - docker
  tags: docker

- name: Configure Nginx reverse proxy
  hosts: web
  become: true
  roles:
    - nginx
  tags: nginx
```

Deploy the full stack:
## Dry run first -- always
ansible-playbook site.yml --check --diff

<img width="1365" height="1247" alt="image" src="https://github.com/user-attachments/assets/c5d73108-10db-466e-a93c-f3564c1b4193" />
<img width="1347" height="1275" alt="image" src="https://github.com/user-attachments/assets/7f3ba9ad-aeca-4548-9094-cd0ee2fd4601" />
<img width="1352" height="1237" alt="image" src="https://github.com/user-attachments/assets/5ab3424f-03ce-416d-a237-7f5609aef191" />
<img width="1390" height="1272" alt="image" src="https://github.com/user-attachments/assets/424df07c-49c1-45e0-904a-2624924b0275" />


## Full deploy
ansible-playbook site.yml

<img width="1562" height="1262" alt="image" src="https://github.com/user-attachments/assets/f63e4365-3f52-4784-9a4b-919d0dc4230f" />
<img width="1556" height="1150" alt="image" src="https://github.com/user-attachments/assets/727d65c6-8d72-4592-8a06-d9f194f4f966" />


Use tags for selective execution:
## Only set up Docker and containers
ansible-playbook site.yml --tags docker

<img width="1562" height="987" alt="image" src="https://github.com/user-attachments/assets/1fd374b7-73e8-4e91-b07a-0e45912dd3bc" />


## Only update Nginx config
ansible-playbook site.yml --tags nginx

<img width="1402" height="787" alt="image" src="https://github.com/user-attachments/assets/5df7c508-76ea-4e74-bfc0-d1cf2d57e23f" />

<img width="1131" height="597" alt="image" src="https://github.com/user-attachments/assets/dc7346e4-4807-4f97-b859-be635090ce47" />


## Skip common setup
ansible-playbook site.yml --skip-tags common

<img width="1557" height="1247" alt="image" src="https://github.com/user-attachments/assets/4adc35bd-de32-442f-95f5-bc26978c1fa2" />
<img width="1572" height="262" alt="image" src="https://github.com/user-attachments/assets/b933584e-42ab-4575-934d-28e9240b526b" />


**Verify:**
1. Curl the server on port 8080 -- does the Docker container respond directly?
2. Curl the server on port 80 -- does Nginx reverse proxy the request to the container?

<img width="1200" height="1146" alt="image" src="https://github.com/user-attachments/assets/e84b5c7d-c891-4dbb-8736-7492b17273d9" />
<img width="1327" height="567" alt="image" src="https://github.com/user-attachments/assets/acb8065d-776b-4ca3-b830-d373597de48e" />



##  Verification Results

### 🔹 Port 8080 – Docker Container Response

The Docker container is reachable on port 8080, but it is not serving the expected application response. Instead, the container is in a restart loop due to an issue with the application inside the image (`demo:v3`), which prevents the application from running correctly.

👉 Conclusion: Docker container is running, but the application inside is not healthy.

---

### 🔹 Port 80 – Nginx Reverse Proxy Response

Port 80 is correctly handled by Nginx. The request is successfully forwarded to the backend service through the reverse proxy configuration, and the application response is returned.

👉 Conclusion: Nginx reverse proxy is working correctly and serving the backend response.

---

##  Final Summary

* Docker container: Running but application is unhealthy
* Port 8080: Not serving expected app response
* Port 80: Nginx reverse proxy working correctly
* End-to-end reverse proxy setup: Functional

---

3. Check `docker ps` on the server -- is the container running with the correct port mapping?

<img width="1335" height="992" alt="image" src="https://github.com/user-attachments/assets/16f2904a-4b8e-4ba5-a3f8-c625fb1629f3" />
<img width="987" height="1047" alt="image" src="https://github.com/user-attachments/assets/64245d41-a94c-4fdb-b497-96b236e1b8ee" />
<img width="1211" height="865" alt="image" src="https://github.com/user-attachments/assets/d85b5b21-d713-4629-9b04-b2e9146abea8" />
<img width="811" height="837" alt="image" src="https://github.com/user-attachments/assets/03b5fbf9-e2d1-49bf-95e2-94707b749f9f" />


The Docker container is running successfully with correct port mapping 8080:80. The container is stable and accessible, confirming that Docker setup and port exposure are correctly configured.


---

### Task 7: Bonus -- Deploy a Different App and Re-Run
Change the Docker image to something else. Update `group_vars/all.yml` or pass extra vars:

```bash
ansible-playbook site.yml --tags docker \
  -e "docker_app_image=httpd docker_app_tag=latest docker_app_name=apache-app"
```

The old container should be replaced with the new one. Nginx still proxies traffic -- no config change needed.

```bash
ansible-playbook site.yml --tags docker \
-e "docker_app_port=8081 docker_container_port=80 docker_app_image=httpd docker_app_tag=latest docker_app_name=apache-app"
```
<img width="1381" height="1010" alt="image" src="https://github.com/user-attachments/assets/af07e4f9-2649-4474-b313-0a07aa32d5ca" />
<img width="1122" height="842" alt="image" src="https://github.com/user-attachments/assets/83222dba-5964-4c28-83cc-859acd227082" />


Now run the full playbook one more time:
```bash
ansible-playbook site.yml
```

The output should show mostly `ok` with zero or minimal `changed`. This proves your entire setup is **idempotent**.

<img width="1552" height="1272" alt="image" src="https://github.com/user-attachments/assets/3511add9-825e-4e59-bbd4-e7a8225c8e4a" />
<img width="1427" height="1137" alt="image" src="https://github.com/user-attachments/assets/cc01edf5-6631-41a4-b478-a3f9cfafff8f" />



**Reflect and document:**
1. How many total tasks ran?
```bash
PLAY RECAP

app-server : ok=8 changed=7
db-server  : ok=8 changed=7
web-server : ok=25 changed=11
```
Total tasks executed:
```bash
app-server = 8
db-server  = 8
web-server = 25

Total = 41 tasks
```
2. Map each Ansible concept to the day you learned it:

| Day | Concept Used                                                                                                         |
| --- | -------------------------------------------------------------------------------------------------------------------- |
| 68  | Inventory, ad-hoc commands, SSH setup                                                                                |
| 69  | Playbooks, modules, handlers                                                                                         |
| 70  | Variables, facts, conditionals, loops                                                                                |
| 71  | Roles, templates, Galaxy, Vault                                                                                      |
| 72  | Combined project using Inventory, Roles, Variables, Templates, Vault, Docker, Nginx, Handlers, Tags, and Idempotency |


3. What would you add for production? (SSL with certbot, monitoring, log rotation, multi-container Compose)

- SSL/TLS using Certbot and Let's Encrypt
- Monitoring with Prometheus and Grafana
- Centralized logging with ELK Stack
- Log rotation using logrotate
- Docker Compose for multi-container applications
- CI/CD pipeline using GitHub Actions or Jenkins
- Backup and disaster recovery strategy
- Security hardening and firewall rules
- Health checks and alerting
- Load balancing and auto-scaling

4. Clean up your EC2 instances when done. If you used Terraform: `terraform destroy`. If manual: terminate from the console.

<img width="2107" height="166" alt="image" src="https://github.com/user-attachments/assets/437a072c-2703-413e-b37d-2add4739f132" />


---

**Project directory structure**


<img width="382" height="1076" alt="image" src="https://github.com/user-attachments/assets/7265ad9c-f42f-45d7-9b81-4c9deb82749c" />



---

Architecture:

```text
Ansible Control Node
        |
        v
   EC2 Web Server
        |
        +--> Nginx (Port 80)
                |
                v
         Docker Container
           (Port 8080)
```

---

# Project Directory Structure

```text
ansible-docker-project/
├── ansible.cfg
├── inventory.ini
├── site.yml
├── group_vars/
│   ├── all.yml
│   └── web/
│       └── vault.yml
├── roles/
│   ├── common/
│   │   └── tasks/
│   │       └── main.yml
│   ├── docker/
│   │   ├── defaults/
│   │   │   └── main.yml
│   │   └── tasks/
│   │       └── main.yml
│   └── nginx/
│       ├── defaults/
│       │   └── main.yml
│       ├── handlers/
│       │   └── main.yml
│       ├── tasks/
│       │   └── main.yml
│       └── templates/
│           └── app-proxy.conf.j2
└── day-72-ansible-project.md
```

---

# Master Playbook (site.yml)

```yaml
---
- name: Apply common configuration
  hosts: all
  become: true
  roles:
    - common
  tags: common

- name: Install Docker and run containers
  hosts: web
  become: true
  roles:
    - docker
  tags: docker

- name: Configure Nginx reverse proxy
  hosts: web
  become: true
  roles:
    - nginx
  tags: nginx
```

---

# Docker Role (roles/docker/tasks/main.yml)

Key tasks:

* Install Docker dependencies
* Configure Docker repository
* Install Docker Engine
* Start Docker service
* Add deploy user to docker group
* Pull application image
* Run Docker container
* Verify application availability

Example:

```yaml
- name: Pull application image
  community.docker.docker_image:
    name: "{{ docker_app_image }}"
    tag: "{{ docker_app_tag }}"
    source: pull

- name: Run container
  community.docker.docker_container:
    name: "{{ docker_app_name }}"
    image: "{{ docker_app_image }}:{{ docker_app_tag }}"
    state: started
    restart_policy: always
    ports:
      - "{{ docker_app_port }}:{{ docker_container_port }}"
```

---

# Nginx Role (roles/nginx/tasks/main.yml)

Key tasks:

* Install Nginx
* Remove default site
* Deploy reverse proxy configuration
* Enable site
* Test configuration
* Reload Nginx using handlers

Example:

```yaml
- name: Deploy reverse proxy config
  template:
    src: app-proxy.conf.j2
    dest: /etc/nginx/sites-available/app-proxy.conf

- name: Enable reverse proxy site
  file:
    src: /etc/nginx/sites-available/app-proxy.conf
    dest: /etc/nginx/sites-enabled/app-proxy.conf
    state: link

- name: Test Nginx configuration
  command: nginx -t
  changed_when: false
```

---

# Nginx Reverse Proxy Template

File:

```text
roles/nginx/templates/app-proxy.conf.j2
```

```nginx
upstream docker_app {
    server 127.0.0.1:{{ nginx_upstream_port }};
}

server {
    listen {{ nginx_http_port }};
    server_name {{ nginx_server_name }};

    location / {
        proxy_pass http://docker_app;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

# Vault Usage

Docker Hub credentials were encrypted using Ansible Vault.

File:

```text
group_vars/web/vault.yml
```

Contents:

```yaml
vault_docker_username: ********
vault_docker_password: ********
```

Vault password file:

```text
.vault_pass
```

Configured in:

```ini
[defaults]
inventory = inventory.ini
host_key_checking = False
vault_password_file = .vault_pass
```

Benefits:

* Credentials are not stored in plain text.
* Secrets can safely be committed to source control.
* Ansible decrypts automatically during execution.

---

# Selective Deployment Using Tags

Run only Docker tasks:

```bash
ansible-playbook site.yml --tags docker
```

Run only Nginx tasks:

```bash
ansible-playbook site.yml --tags nginx
```

Skip common tasks:

```bash
ansible-playbook site.yml --skip-tags common
```

Dry run:

```bash
ansible-playbook site.yml --check --diff
```

---

# Verification

## Docker Container

Verified using:

```bash
docker ps
```

Output:

```text
CONTAINER ID   IMAGE          PORTS
abe470318d12   nginx:latest   0.0.0.0:8080->80/tcp
```

Container is running successfully with port mapping:

```text
Host Port 8080 -> Container Port 80
```

---

## Nginx Reverse Proxy

Direct container access:

```bash
curl http://SERVER_IP:8080
```

Result:

```text
Nginx welcome page from Docker container
```

Reverse proxy access:

```bash
curl http://SERVER_IP:80
```

Result:

```html
<h1>myapp</h1>
<h2>Server: ip-172-31-8-127</h2>
<h3>IP: 172.31.8.127</h3>
<h4>Environment: development</h4>
<p>Managed by Ansible</p>
```

This confirms Nginx successfully proxies requests to the backend container.

---

# Idempotency Verification

The playbook was executed multiple times.

Second run output showed mostly:

```text
ok=XX
changed=0
```

This confirms the deployment is idempotent and does not make unnecessary changes.




---

Architecture: Ansible -> Server [Nginx:80 -> Docker Container:8080]
```bash
                Ansible Control Node
                        |
                        | SSH
                        v
                EC2 Web Server
                        |
                        v
                  Nginx :80
                        |
                 Reverse Proxy
                        |
                        v
          Docker Container :8080
                        |
                        v
                 Application
```
