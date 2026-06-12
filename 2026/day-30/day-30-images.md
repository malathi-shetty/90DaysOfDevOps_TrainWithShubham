# Day 30 – Docker Images & Container Lifecycle

## Challenge Tasks

### Task 1: Docker Images
1. Pull the `nginx`, `ubuntu`, and `alpine` images from Docker Hub

<img width="802" height="427" alt="image" src="https://github.com/user-attachments/assets/28625d15-3616-42f5-9947-32651a584925" />


2. List all images on your machine

   <img width="670" height="191" alt="image" src="https://github.com/user-attachments/assets/3e86211b-da5b-46bf-a19e-107c7bb90b9e" />



    | Image         | Disk Usage | Content Size |
    | ------------- | ---------- | ------------ |
    | alpine:latest | 13.1MB     | 3.95MB       |
    | nginx:latest  | 240MB      | 65.8MB       |
    | ubuntu:latest | 119MB      | 31.7MB       |

    **Local Size(Disk usage) is actual image size**

    **Transfer Size(Content Size) is amount of data used when pulling the image over a network**



3. Compare `ubuntu` vs `alpine`

<img width="870" height="238" alt="image" src="https://github.com/user-attachments/assets/431a49af-ebe1-420c-af6b-d99343158379" />


  - Ubuntu is a full Linux distribution with many built-in tools.
   - Alpine is a minimal distribution designed for containers.
   - Alpine is smaller because it uses musl libc and BusyBox instead of full GNU utilities.


4. Inspect an image — what information can you see?

  <img width="1038" height="1111" alt="image" src="https://github.com/user-attachments/assets/277b5b20-6676-4a7a-bb6c-9bb6971e80a9" />

<img width="965" height="698" alt="image" src="https://github.com/user-attachments/assets/5218d34a-c12a-44d7-8877-d0e013326fc4" />

<img width="897" height="681" alt="image" src="https://github.com/user-attachments/assets/a8977ee2-6044-47f1-876e-ce9448b425d1" />


    - Image ID: sha256:6e234791...
    - Image: nginx:latest
    - Exposed Port: 80/tcp (HTTP)
    - Repository: docker.io/library/nginx
    - Environment variable
    - NGINX Version: 1.29.8
    - ENTRYPOINT
    - CMD
    - Lables,maintainer
    - Filesystem | Uses layered filesystem | 7 layers


5. Remove an image you no longer need

  <img width="821" height="336" alt="image" src="https://github.com/user-attachments/assets/a758d388-8cbf-4c76-94a1-acb0c4d97d44" />


---

### Task 2: Image Layers
1. Run `docker image history nginx` — what do you see?

  <img width="1037" height="410" alt="image" src="https://github.com/user-attachments/assets/259f57cb-eb78-47d6-8f73-d7479789620d" />



### Observations:
- Each line represents a layer created by a Dockerfile instruction.


2. Each line is a **layer**. Note how some layers show sizes and some show 0B

- Layers with size (MB/KB) are created by filesystem changes (RUN, COPY, ADD).
- Layers with 0B are metadata-only (ENV, CMD, LABEL, ENTRYPOINT, EXPOSE).

3. What are layers and why does Docker use them?

Docker layers are read-only filesystem snapshots created for each instruction in an image build process.
Docker uses layers:
- Faster builds using caching
- Efficient storage (shared layers)
- Faster image downloads
- Reusability across multiple images
---

### Task 3: Container Lifecycle
Practice the full lifecycle on one container:
1. **Create** a container (without starting it)
<img width="879" height="165" alt="image" src="https://github.com/user-attachments/assets/afd641b1-5b7a-4e58-8964-ba463b96fdc5" />

2. **Start** the container
<img width="987" height="109" alt="image" src="https://github.com/user-attachments/assets/81efa8ee-4e70-491c-99a4-6d7da72dec6f" />

3. **Pause** it and check status
<img width="1057" height="114" alt="image" src="https://github.com/user-attachments/assets/9f00d31d-9734-4bfa-bafb-b5aad5133e96" />

4. **Unpause** it
<img width="937" height="107" alt="image" src="https://github.com/user-attachments/assets/7c1f1d9a-39d5-4387-a831-fbb1a19d5e8e" />

5. **Stop** it
<img width="1073" height="123" alt="image" src="https://github.com/user-attachments/assets/0d96b229-88ce-47bc-8266-83e73cefc3b7" />

6. **Restart** it
<img width="1025" height="123" alt="image" src="https://github.com/user-attachments/assets/eee0387c-8da9-4714-96e1-d06bcd6356fb" />

7. **Kill** it
<img width="1055" height="141" alt="image" src="https://github.com/user-attachments/assets/21ac3d01-6d11-4f17-b67c-03590c5eddf1" />

8. **Remove** it
Check `docker ps -a` after each step — observe the state changes.

<img width="744" height="92" alt="image" src="https://github.com/user-attachments/assets/25daa84f-26f0-4453-9116-ab4feda18957" />


<img width="1072" height="1013" alt="image" src="https://github.com/user-attachments/assets/ba006cd8-6886-4a6b-b8d1-cd1cba618066" />

### Observation:
Used `docker ps -a` after each step to observe state changes:
- Created → Running → Paused → Running → Exited → Running → Exited → Removed

---

### Task 4: Working with Running Containers
1. Run an Nginx container in detached mode
<img width="1212" height="145" alt="image" src="https://github.com/user-attachments/assets/a8ce042a-19e2-4c8a-8f1c-8dd9dc1b5d8c" />

2. View its **logs**
<img width="920" height="322" alt="image" src="https://github.com/user-attachments/assets/a355a8f0-7cd4-4bb6-b597-958fd0b677c9" />

3. View **real-time logs** (follow mode)

    <img width="911" height="346" alt="image" src="https://github.com/user-attachments/assets/e76d6f43-0478-4387-a7be-9c7ca3442ee0" />



4. **Exec** into the container and look around the filesystem

<img width="861" height="812" alt="image" src="https://github.com/user-attachments/assets/ffc80645-5bc5-48cb-a196-57d1f0e0a527" />



5. Run a single command inside the container without entering it


   <img width="710" height="747" alt="image" src="https://github.com/user-attachments/assets/aa790301-c515-4bb5-adaa-92b4958bb231" />




6. **Inspect** the container — find its IP address, port mappings, and mounts

  <img width="1081" height="1371" alt="image" src="https://github.com/user-attachments/assets/32e6f514-1bfc-43ed-a1b1-a812df45eba7" />

  <img width="2090" height="638" alt="image" src="https://github.com/user-attachments/assets/a10262a3-bc33-4e78-bf9c-73eff6a6e925" />

### Observed:
- IP address from NetworkSettings
- Port mapping (8080 → 80)
- Mounts and container configuration

---

### Task 5: Cleanup

1. Stop all running containers in one command
<img width="702" height="168" alt="image" src="https://github.com/user-attachments/assets/8242b23b-c660-4742-a065-2d00e4da5d20" />

2. Remove all stopped containers in one command
<img width="673" height="162" alt="image" src="https://github.com/user-attachments/assets/900dc2bf-0caa-499f-ab3e-7018207afcff" />

3. Remove unused images

<img width="800" height="297" alt="image" src="https://github.com/user-attachments/assets/d459506f-bc30-4212-96ab-10c9b5071ee4" />


4. Check how much disk space Docker is using

<img width="586" height="170" alt="image" src="https://github.com/user-attachments/assets/55ecc767-87c3-4274-ba3d-85846fea5784" />


### Observation:
- All unused resources were removed
- Disk usage reduced significantly

## Learnings

- Docker images are built using layered architecture
- Containers are runtime instances of images
- Layers improve performance through caching and reuse
- Container lifecycle management is essential for operations
- Cleanup is important to maintain system efficiency
