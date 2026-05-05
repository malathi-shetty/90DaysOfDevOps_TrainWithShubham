# Day 31 – Dockerfile: Build Your Own Images

## Challenge Tasks

### Task 1: Your First Dockerfile
1. Create a folder called `my-first-image`

<img width="568" height="72" alt="image" src="https://github.com/user-attachments/assets/10407035-a9d1-4582-a27c-7c4933756932" />


2. Inside it, create a `Dockerfile` that:
   - Uses `ubuntu` as the base image
   - Installs `curl`
   - Sets a default command to print `"Hello from my custom image!"`

<img width="742" height="155" alt="image" src="https://github.com/user-attachments/assets/79cf24f2-2604-4b5f-b1ca-540681f09bd6" />

   
3. Build the image and tag it `my-ubuntu:v1`

<img width="990" height="619" alt="image" src="https://github.com/user-attachments/assets/8aa7f698-dcfd-47ff-aabd-9148c9cfee95" />


4. Run a container from your image

<img width="1007" height="198" alt="image" src="https://github.com/user-attachments/assets/1e08bf16-0822-4e07-bfdc-b4715b01629a" />


**Verify:** The message prints on `docker run`

  [my-first-image Dockerfile](day-31/scripts/my-first-image/Dockerfile)

   

---

### Task 2: Dockerfile Instructions
```bash
FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl

WORKDIR /app

COPY . .

EXPOSE 8080

CMD ["bash"]
```

### Explanation
FROM: Base image (Ubuntu)
RUN: Installs curl during build
WORKDIR: Sets working directory inside container
COPY: Copies files from host → container
EXPOSE: Documents port (not actually publishing it)
CMD: Default command when container starts

<img width="1002" height="1086" alt="image" src="https://github.com/user-attachments/assets/4c6da89d-3df1-4bda-ab2d-0a5763c74bc2" />

 [Dockerfile Instructions](day-31/scripts/dockerfile-demo)


---

### Task 3: CMD vs ENTRYPOINT
1. Create an image with `CMD ["echo", "hello"]` — run it, then run it with a custom command. What happens?

<img width="1007" height="497" alt="image" src="https://github.com/user-attachments/assets/9f85d1ed-19bb-4b36-a0ac-81d1b477b29f" />


* **Run without arguments:**
  The container runs the default command `echo hello` and outputs:

  ```
  hello
  ```

* **Run with a custom command:**
  When you run the container with a custom command (e.g., `echo "custom command"`), the custom command **completely overrides** the `CMD`, so the output is:

  ```
  custom command
  ```


 [CMD_Dockerfile](day-31/scripts/cmd-demo/Dockerfile)


2. Create an image with `ENTRYPOINT ["echo"]` — run it, then run it with additional arguments. What happens?

<img width="1003" height="458" alt="image" src="https://github.com/user-attachments/assets/5077789e-3608-4fcc-8ff1-fb730af0bb6e" />


* **Run without arguments:**
  It executes echo with no arguments, resulting in a blank output line.

* **Run with additional arguments:**
  When you pass arguments (e.g., `hello-world`), they are **appended** to the `ENTRYPOINT`, so it runs `echo hello-world` and outputs:

  ```
  hello-world
  ```


 [ENTRYPOINT_Dockerfile](day-31/scripts/entrypoint-demo/Dockerfile)
 

3. When would you use CMD vs ENTRYPOINT?

- Use `CMD` when you want to provide a default command that can be changed easily when you run the container.

- Use `ENTRYPOINT` when you want to set a fixed command that always runs.

<img width="1008" height="528" alt="image" src="https://github.com/user-attachments/assets/7dd2d60c-42d6-40d9-bee6-1df91832ecb0" />


[CMD_ENTRYPOINT_Dockerfile](day-31/scripts/CMD_ENTRYPOINT/Dockerfile)


| Feature  | CMD                 | ENTRYPOINT         |
| -------- | ------------------- | ------------------ |
| Purpose  | Default command     | Fixed executable   |
| Override | Easily overridden   | Harder to override |
| Use Case | Flexible containers | CLI-style tools    |

- Use CMD for default behavior
- Use ENTRYPOINT when container acts like a tool

---

### Task 4: Build a Simple Web App Image
1. Create a small static HTML file (`index.html`) with any content

<img width="537" height="242" alt="image" src="https://github.com/user-attachments/assets/cc7427de-2237-4d3c-b7bf-9e8abfd10207" />


2. Write a Dockerfile that:
   - Uses `nginx:alpine` as base
   - Copies your `index.html` to the Nginx web directory

<img width="545" height="90" alt="image" src="https://github.com/user-attachments/assets/6787643d-f07f-4aad-baf1-ce20c84f12c0" />


3. Build and tag it `my-website:v1`

<img width="868" height="702" alt="image" src="https://github.com/user-attachments/assets/8b0a29c4-d447-4e21-ad43-bfe210f25843" />


4. Run it with port mapping and access it in your browser

<img width="1161" height="1002" alt="image" src="https://github.com/user-attachments/assets/4373b58f-08c6-43a6-a32f-ec9e6f033ada" />


[CMD_ENTRYPOINT_Dockerfile](day-31/scripts/CMD_ENTRYPOINT/Dockerfile)

---

### Task 5: .dockerignore
1. Create a `.dockerignore` file in one of your project folders
2. Add entries for: `node_modules`, `.git`, `*.md`, `.env`

<img width="988" height="602" alt="image" src="https://github.com/user-attachments/assets/8af3a8e2-87b0-4012-8e81-2ade3b413efe" />



3. Build the image — verify that ignored files are not included

<img width="1041" height="858" alt="image" src="https://github.com/user-attachments/assets/9562bbd8-ad6c-4e13-8f95-3c34138fa18d" />


[dockerignore](day-31/scripts/dockerignore-demo)


## .dockerignore
```bash
node_modules
.git
*.md
.env
```
Why?

Prevents unnecessary files (test.md, .env, .git, or node_modules listed) from being copied into the image → smaller & faster builds.

---

### Task 6: Build Optimization
1. Build an image, then change one line and rebuild — notice how Docker uses **cache**

```bash
echo "version 1" > app.txt
```

Create a docker file: 

```bash
FROM ubuntu:latest
COPY . .
RUN apt-get update && apt-get install -y curl
WORKDIR /app
CMD ["cat", "app.txt"]
```

`docker build -t opt-demo:v1 .`

Observation: The image is built successfully and all layers are created.

Change one line and rebuild: change in app.py

Now update file:
```bash
echo "version 2" > app.txt
```
`docker build -t opt-demo:v2 .`

Observation:
- Even though only the application code changed
- Docker re-ran apt-get install curl when cache was invalidated.
- Any change in files used by a layer invalidates that layer and all subsequent layers.

<img width="1226" height="2015" alt="image" src="https://github.com/user-attachments/assets/1ada6cc8-0089-455d-a37d-571d75844fc8" />


2. Reorder your Dockerfile so that frequently changing lines come **last**

```bash
FROM ubuntu:latest
RUN apt-get update && apt-get install -y curl
WORKDIR /app
COPY . .
CMD ["cat", "app.txt"]
```



[docker-opt](day-31/scripts/docker-opt)

Observation:
Docker reused cached layers for: Base image,Working directory,Dependency installation

3. Why does layer order matter for build speed?

- Docker caches each step as a layer
- If a layer changes → all layers after it rebuild
- Place frequently changing code LAST
- Place dependencies FIRST

Result: Faster builds 

---

Key Takeaways
- Dockerfiles define reproducible environments
- Layer caching is critical for performance
- CMD vs ENTRYPOINT controls container behavior
- .dockerignore improves efficiency
- You can ship real apps using custom images

---

 Pro Tip (important)

If something doesn’t work:
- Use `docker images`
- Use `docker ps -a`
- Use `docker logs <container_id>`
