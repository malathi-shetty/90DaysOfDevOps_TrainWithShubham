# Day 29 – Introduction to Docker

## Task 1

### What is Docker?

Docker is a platform that allows developers to build, package, and run applications inside containers.
A container is an instance of an image that is ready to execute code with all its necessary libraries, configurations, and files.

A Docker image is a blueprint, and a container is a running instance of that image.

---

### Why do we need Docker?

- Build locally, deploy to the cloud, and run anywhere  
- Eliminates "it works on my machine" problems  
- More efficient than virtual machines (shares host OS kernel)  
- Ensures consistent environments for teams  
- Avoids dependency and version mismatch issues  
- Lightweight and fast

---

### What is a Container and Why Do We Need Them?

A container is a lightweight, portable unit that packages:

- Application code
- Dependencies
- Runtime
- Configuration

Key benefit:
“It works the same everywhere”

#### Why containers?

- Eliminates “it works on my machine” problems
- Ensures consistency across environments (dev, test, prod)
- Faster startup compared to traditional systems
- Lightweight and efficient (shares host OS kernel)


### Containers vs Virtual Machines

| Feature | Virtual Machines (VMs) | Containers |
|----------|------------------------|------------|
| **Virtualization Level** | Hardware-level virtualization | OS-level virtualization |
| **Architecture** | Includes full guest OS + hypervisor | Shares host OS kernel |
| **Size** | Large (GBs) | Small (MBs) |
| **Startup Time** | Slow (minutes) | Fast (seconds) |
| **Performance** | Slower due to OS overhead | Faster, lightweight |
| **Isolation** | Strong (separate OS per VM) | Process-level isolation |
| **Resource Usage** | High CPU, RAM, Storage usage | Efficient resource usage |
| **Portability** | Less portable | Highly portable |
| **Management** | Complex (manage full OS) | Simple (manage app + dependencies) |
| **Best For** | Legacy apps, multiple OS environments | Microservices, CI/CD, cloud-native apps |



### Docker architecture

Docker follows a client-server architecture.

---

### Docker Client

### What it is
The Docker client is the command-line interface (CLI) used to interact with Docker. It acts as the command center.

### How it works
You type commands in the Docker client, and it sends those requests to the Docker daemon, which performs the actual work.

### Example Commands
- `docker build`
- `docker run`
- `docker pull`
- `docker push`

---

### Docker Daemon (dockerd)

### What it is
The Docker daemon (`dockerd`) is the background service that manages Docker objects such as images, containers, networks, and volumes.

### How it works
The daemon:
- Listens for Docker API requests from the Docker client
- Builds images
- Runs and manages containers
- Handles networking and storage
- Handles API requests

---

### Docker Images
- Read-only templates
- Used to create containers
- Example: nginx, ubuntu

---

### Docker Containers
- Running instances of images
- Isolated environments where apps run

---

### Docker Hub

### What it is

- Docker Hub is a cloud-based public registry (like an app store) for Docker images.

### How it works
It works like an app store for container images. 

You can:
- **Pull** images created by others
- **Push** your own images

### Usage
When you need an image to create a container, you can pull it from Docker Hub.

---

### Docker Registry

### What it is
A Docker registry is a system that stores and distributes Docker images. Docker Hub is the most popular public registry,but you can also create private registries.

### How it works
Registries:
- Store Docker images
- Allow users to pull images
- Allow users to push images

Private registries are commonly used by companies to securely store internal application images.

---

**Architecture Flow (Simple Explanation)**

1. You run:
`docker run nginx`
2. Client → sends request to daemon
3. Daemon:
 - Checks for image locally
 - If not found → pulls from Docker Hub
4. Container is created and started

---

### Task 2: Install Docker
1. Install Docker on your machine (https://docs.docker.com/engine/install/ubuntu/)

    ```bash
    # Add Docker's official GPG key:
    sudo apt update
    sudo apt install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
    Types: deb
    URIs: https://download.docker.com/linux/ubuntu
    Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
    Components: stable
    Signed-By: /etc/apt/keyrings/docker.asc
    EOF

    sudo apt update
    sudo systemctl status docker
    sudo systemctl start docker

    sudo usermod -aG docker $USER
    newgrp docker
    ```

2. Verify the installation

   <img width="668" height="152" alt="image" src="https://github.com/user-attachments/assets/d80ceda0-5ba7-48c2-a077-b5c3270cf476" />


3. Run the `hello-world` container: **docker run hello-world**

    <img width="1132" height="606" alt="image" src="https://github.com/user-attachments/assets/750102df-ce5f-4f39-b405-936d337857ee" />


4. **Output explain** :
- Image not found locally
- Pulled from Docker Hub
- Container created and executed
- Printed “Hello from Docker!”
- Container stopped

---

### Task 3: Run Real Containers
1. Run an **Nginx** container and access it in your browser: **docker run -d -p 80:80 nginx**  **<host_port>:<container_port>**

   <img width="2081" height="1096" alt="image" src="https://github.com/user-attachments/assets/493cccc5-a4ae-4fbd-b715-7d7670726416" />


2. Run an **Ubuntu** container in interactive mode: **docker run -it ubuntu**

   <img width="956" height="1206" alt="image" src="https://github.com/user-attachments/assets/7943c117-0015-4d49-8aa6-930beeb24ddb" />

3. List all running containers: **docker ps**

   <img width="1242" height="132" alt="image" src="https://github.com/user-attachments/assets/c9850646-3719-4cab-a6d9-35c45e5253b2" />


4. List all containers (including stopped ones): **docker ps -a**

    <img width="1577" height="157" alt="image" src="https://github.com/user-attachments/assets/4072814c-2964-41c7-9f65-e1bd32ff8d29" />



5. Stop and remove a container: **docker stop <container-id>** && **docker rm <container-id>**

   <img width="1246" height="242" alt="image" src="https://github.com/user-attachments/assets/b7ef89f8-50fe-4fd9-9c96-e1f7cab9d6ba" />


---

### Task 4: Explore
1. Run a container in **detached mode** : **detach mode** **run containers in background mode**

   <img width="618" height="173" alt="image" src="https://github.com/user-attachments/assets/468f9dda-69ab-4671-9271-53c7df7d10fa" />


2. Give a container a custom **name** : **docker run -d --name my-web nginx**

    <img width="1067" height="472" alt="image" src="https://github.com/user-attachments/assets/57ab4b8a-8784-4016-b6de-5560ec2fcbcc" />


3. Map a **port** from the container to your host: **docker run -d --name web-app -p 3000:80 nginx**  **<host_port>:<container_port>**

   <img width="2137" height="852" alt="image" src="https://github.com/user-attachments/assets/32301f3f-4f2e-442a-8464-4e4b328cf17c" />


4. Check **logs** of a running container: **docker logs <container-id>**  **docker logs web-app**

   <img width="1661" height="571" alt="image" src="https://github.com/user-attachments/assets/3a129952-9c33-4d8c-b819-b53a23bc70c5" />



5. Run a command **inside** a running container : **docker exec -it <container-id>**

    <img width="1411" height="951" alt="image" src="https://github.com/user-attachments/assets/3b394cf2-f485-44a2-8907-6a5108049caf" />



---

## Why This Matters for DevOps

- Docker is the foundation of modern deployment. 
- Every CI/CD pipeline, Kubernetes cluster,and microservice - architecture starts with containers. 
- Today you took the first step
