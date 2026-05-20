# Day 35 – Multi-Stage Builds & Docker Hub

## Challenge Tasks

### Task 1: The Problem with Large Images
1. Write a simple Go, Java, or Node.js app (even a "Hello World" is fine)

**app.js**
```bash
const http = require("http");

const server = http.createServer((req, res) => {
  res.end("Hello World from Single Stage Docker!");
});

server.listen(3000, () => {
  console.log("Server running on port 3000");
});
```

**Run:**

`npm init -y`

This creates a basic package.json.

<img width="1137" height="551" alt="image" src="https://github.com/user-attachments/assets/60947b47-6396-4b94-ba04-bf60f5ee4d47" />


2. Create a Dockerfile that builds and runs it in a **single stage**

```bash
FROM node:18

WORKDIR /app

COPY package.json .
COPY app.js .

RUN npm install

EXPOSE 3000

CMD ["node", "app.js"]
```
<img width="835" height="262" alt="image" src="https://github.com/user-attachments/assets/55ed540e-528d-4349-82bc-514443e8fb45" />

3. Build the image and check its **size**

`docker build -t single-stage-app .`
`docker images`
   - Image Size is 395 MB

```bash
IMAGE                     ID             DISK USAGE   CONTENT SIZE   EXTRA
single-stage-app:latest   204896aa8962       1.57GB          395MB
```

<img width="1611" height="1248" alt="image" src="https://github.com/user-attachments/assets/714c449e-0a25-4a05-b22e-0bcfbcbf423f" />

<img width="725" height="42" alt="image" src="https://github.com/user-attachments/assets/def34fd5-c68f-4a49-9a6c-2f9a2323d8ca" />


**Observation:**
Single-stage image is large because:

- Full Node.js runtime included
- npm cache + dependencies included
- No separation between build and runtime
- No optimization


---

### Task 2: Multi-Stage Build
1. Rewrite the Dockerfile using **multi-stage build**:
   - Stage 1: Build the app (install dependencies, compile)
   - Stage 2: Copy only the built artifact into a minimal base image (`alpine`, `distroless`, or `scratch`)

<img width="1137" height="671" alt="image" src="https://github.com/user-attachments/assets/c5b3f65d-48c7-4da9-9969-acf509bb2f08" />


```bash
# -------------------------
# Stage 1: Build Stage
# -------------------------
FROM node:18 AS builder

WORKDIR /app

COPY package.json .
RUN npm install

COPY app.js .

# -------------------------
# Stage 2: Production Stage
# -------------------------
FROM node:18-alpine

WORKDIR /app

COPY --from=builder /app /app

EXPOSE 3000

CMD ["node", "app.js"]
```
   
2. Build the image and check its size again
3. Compare the two sizes

   - first image size is 638 MB
   - multi-stage image size is 255 MB

<img width="1132" height="112" alt="image" src="https://github.com/user-attachments/assets/0e52c04c-ceea-44c3-a933-28533d2b9425" />


Why is the multi-stage image so much smaller?

Multi-stage builds reduce image size because:

- Build tools are removed from final image
- Only required application files are copied
- Runtime image uses lightweight base (alpine)
- Separation of build and runtime environments

---

### Task 3: Push to Docker Hub
1. Create a free account on [Docker Hub](https://hub.docker.com) (if you don't have one)
2. Log in from your terminal

<img width="938" height="355" alt="image" src="https://github.com/user-attachments/assets/ef8ff0ae-21cc-4a44-bc5e-89d1b3dd1c6e" />


3. Tag your image properly: `yourusername/image-name:tag`

<img width="1141" height="162" alt="image" src="https://github.com/user-attachments/assets/f0dc05c7-e29c-4cd3-9db6-90eef3ff0911" />


4. Push it to Docker Hub

<img width="913" height="195" alt="image" src="https://github.com/user-attachments/assets/075b2651-a861-4421-a197-9ac5bd76d624" />
<img width="1206" height="770" alt="image" src="https://github.com/user-attachments/assets/818aee4b-ef8c-41fd-ba41-10b2b5f959a2" />


5. Pull it on a different machine (or after removing locally) to verify

<img width="1133" height="527" alt="image" src="https://github.com/user-attachments/assets/8cbf7e60-c57e-4713-9cd6-d63300eb22e2" />

<img width="2022" height="886" alt="image" src="https://github.com/user-attachments/assets/72b7cb5e-ab4a-4acc-ad2b-5f0884233e1a" />

Tags Concept
| Tag    | Meaning                       |
| ------ | ----------------------------- |
| 1.0    | Fixed version (stable)        |
| latest | Moving reference (can change) |

 Pull Behavior
- 1.0 → always same version (safe for production)
- latest → may change over time (not recommended for production)

---

### Task 4: Docker Hub Repository
1. Go to Docker Hub and check your pushed image
2. Add a **description** to the repository
3. Explore the **tags** tab — understand how versioning works
4. Pull a specific tag vs `latest` — what happens?

   - Specific tag (e.g., 1.0) = pulls that exact version of the image.
   - latest = pulls whatever image is currently marked latest, which can change


https://hub.docker.com/repository/docker/shettymalathi113/multi-stage-app

<img width="2112" height="1206" alt="image" src="https://github.com/user-attachments/assets/e455b7b5-141d-4631-a43a-8e4effdf13d6" />


---

### Task 5: Image Best Practices
Apply these to one of your images and rebuild:
1. Use a **minimal base image** (alpine vs ubuntu — compare sizes)
2. **Don't run as root** — add a non-root USER in your Dockerfile
3. Combine `RUN` commands to **reduce layers**
4. Use **specific tags** for base images (not `latest`)


 ```bash
 # Use specific lightweight base image (NOT latest)
FROM node:18-alpine

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only package first (better caching)
COPY package.json ./

# Combine RUN commands to reduce layers
RUN npm install && npm cache clean --force

# Copy app code
COPY app.js ./

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user (security best practice)
USER appuser

EXPOSE 3000

CMD ["node", "app.js"]
```

<img width="1576" height="813" alt="image" src="https://github.com/user-attachments/assets/fd09220b-f000-4bef-b570-5bb7203f53c5" />


---

**Improvements Applied**

- Minimal base image (alpine)
- Non-root user for security
- Combined RUN commands to reduce layers
- Cleaned npm cache
- Used pinned base image version

**Final Summary**
- Single-stage builds are simple but heavy
- Multi-stage builds reduce image size significantly
- Docker Hub enables versioned image distribution
- Best practices improve security + maintainability, not always size
- latest tag should not be used in production


- Multi-stage Docker builds separate build and runtime environments, producing smaller, secure, and production-ready images by copying only required artifacts into a minimal base image.
