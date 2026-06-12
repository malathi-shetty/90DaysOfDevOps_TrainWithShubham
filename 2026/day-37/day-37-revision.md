# Day 37 – Docker Revision

## Self-Assessment Checklist

| Topic | Status |
|---|---|
| Run a container from Docker Hub (interactive + detached) |  Can do |
| List, stop, remove containers and images | Can do |
| Explain image layers and how caching works | Shaky |
| Write a Dockerfile from scratch with FROM, RUN, COPY, WORKDIR, CMD | Can do |
| Explain CMD vs ENTRYPOINT | Can do |
| Build and tag a custom image | Can do |
| Create and use named volumes | Shaky |
| Use bind mounts | Shaky |
| Create custom networks and connect containers | Can do |
| Write a docker-compose.yml for a multi-container app | Can do |
| Use environment variables and `.env` files in Compose | Shaky |
| Write a multi-stage Dockerfile | Shaky |
| Push an image to Docker Hub | Can do |
| Use healthchecks and `depends_on` | Shaky |

---

# Quick-Fire Questions

## 1. Difference between an image and a container?

- Image = read-only blueprint/template
- Container = running instance of an image

---

## 2. What happens to data inside a container when you remove it?

Container data is deleted unless stored in:
- named volumes
- bind mounts

---

## 3. How do two containers on the same custom network communicate?

They communicate using:
- container names
- Docker DNS resolution

Example:
```bash
ping backend
```

## 4. What does docker compose down -v do differently?
`docker compose down` → removes containers/networks
`docker compose down -v` → also removes volumes

## 5. Why are multi-stage builds useful?

They:

reduce final image size
improve security
separate build dependencies from runtime

## 6. Difference between COPY and ADD?
COPY → copies local files/directories
ADD → can also extract archives and fetch URLs

COPY is preferred unless ADD features are needed.

## 7. What does -p 8080:80 mean?

Maps:

host port 8080 to container port 80

Access app via:

`localhost:8080`

## 8. How do you check Docker disk usage?
`docker system df`

## Weak Spots Revisited


## 1. Image Layers & Docker Caching

Docker images are built in layers.

Each instruction in a Dockerfile creates a new layer:
- `FROM`
- `RUN`
- `COPY`
- `CMD`

Docker reuses unchanged layers from cache to speed up builds.

Example:

```Dockerfile
FROM node:20

WORKDIR /app

COPY package.json .

RUN npm install

COPY . .

CMD ["npm", "start"]

```

### Why this order matters

* `npm install` is cached unless `package.json` changes
* Source code changes will not reinstall dependencies every time
* Faster image builds

### Rebuild without cache

```bash id="0npfbb"
docker build --no-cache -t myapp .
```

---

## 2. Named Volumes

Named volumes store persistent data managed by Docker.

Example:

```bash id="x2sv4x"
docker volume create myvolume
```

Mount volume into a container:

```bash id="ebn3s6"
docker run -v myvolume:/data nginx
```

### Benefits

* Data survives container deletion
* Docker-managed storage
* Useful for databases

### Inspect volume

```bash id="nqow1j"
docker volume inspect myvolume
```

---

## 3. Bind Mounts

Bind mounts connect a host directory to a container directory.

Example:

```bash id="s4m0kn"
docker run -v $(pwd):/app node:20
```

### Benefits

* Live code changes during development
* Easy local file access

### Difference from named volumes

| Named Volume          | Bind Mount             |
| --------------------- | ---------------------- |
| Docker-managed        | Host-managed           |
| Better for production | Better for development |
| Portable              | Depends on host path   |

---

## 4. Environment Variables & `.env` Files in Compose

Environment variables help configure applications.

### docker-compose.yml

```yaml
services:
  app:
    image: node:20
    environment:
      - NODE_ENV=production
      - PORT=3000
```

### Using `.env`

`.env`

```env
PORT=3000
DB_HOST=localhost
```

`docker-compose.yml`

```yaml
services:
  app:
    env_file:
      - .env
```

### Benefits

* Cleaner configuration
* Easier environment management
* Avoid hardcoding values

---

## 5. Multi-Stage Dockerfile

Multi-stage builds reduce final image size.

Example:

```Dockerfile
# Build stage
FROM node:20 AS builder

WORKDIR /app

COPY . .

RUN npm install
RUN npm run build

# Production stage
FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html
```

### Benefits

* Smaller production image
* Better security
* Faster deployments

---

## 6. Healthchecks & depends_on

Healthchecks verify whether a container is healthy.

Example:

```Dockerfile
HEALTHCHECK CMD curl --fail http://localhost:3000 || exit 1
```

### docker-compose.yml

```yaml
services:
  app:
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
```

### Benefits

* Ensures services start in correct order
* Prevents app startup before database is ready
* Improves reliability

---

## 7. CMD vs ENTRYPOINT

### CMD

Provides default arguments/command.

Example:

```Dockerfile
CMD ["npm", "start"]
```

### ENTRYPOINT

Defines fixed executable.

Example:

```Dockerfile
ENTRYPOINT ["python"]
```

### Combined Example

```Dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

Runs as:

```bash
python app.py
```
