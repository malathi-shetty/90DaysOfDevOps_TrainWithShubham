# Docker Cheat Sheet (Structured Learning Version)

---

# PHASE 1 — Core Basics

Focus:

Core Runtime
- Images
- Containers
- Lifecycle
- run/start/exec
- ports
- logs
- monitoring
- cleanup

---

# Docker Core Concepts

| Concept       | Meaning                               |
| ------------- | ------------------------------------- |
| Image         | Read-only blueprint                   |
| Container     | Running instance of image             |
| Docker Engine | Core Docker daemon                    |
| Docker CLI    | Client command tool                   |
| Docker Daemon | Background service running containers |
| Registry      | Stores Docker images                  |
| Build Context | Files sent during `docker build`      |
| Orchestration | Managing multiple containers          |

---

# Docker Architecture Diagram

```text
Developer
    ↓
Docker CLI
    ↓
Docker Daemon (dockerd)
    ↓
---------------------------------
| Images | Containers | Networks |
| Volumes | Registries |
---------------------------------
    ↓
Linux Kernel Features
(namespaces + cgroups)
```

---

# Docker Lifecycle

```text
Dockerfile
    ↓
docker build
    ↓
IMAGE
    ↓
docker run
    ↓
CONTAINER
    ↓
start / stop / restart
    ↓
removed
```

---

# Image vs Container

| Type      | Meaning                      |
| --------- | ---------------------------- |
| Image     | Immutable read-only template |
| Container | Writable running instance    |

---

# Image Layer Concepts

| Concept         | Meaning                                     |
| --------------- | ------------------------------------------- |
| Image Layer     | Read-only filesystem layer                  |
| Container Layer | Ephemeral writable layer above image layers |

---

# Container States

| State   | Meaning                           |
| ------- | --------------------------------- |
| created | Container created but not started |
| running | Container actively running        |
| paused  | Processes temporarily frozen      |
| exited  | Container stopped                 |
| dead    | Container failed/unrecoverable    |

---

# Core Container Commands

```bash
# Run container interactively
docker run -it ubuntu bash

# may fail on slim/minimal images without bash

# Safer generic version
docker run -it ubuntu sh

# Run container in detached mode
docker run -d nginx

# List running containers
docker ps

# List all containers
docker ps -a

# Stop container
docker stop <container_id>

# Start stopped container
docker start <container_id>

# Restart container
docker restart <container>

# Create container only
docker create nginx

# Remove stopped container
docker rm <container_id>

# Remove running container
docker rm -f <container>

# Pause processes
docker pause <container>

# Resume paused processes
docker unpause <container>

# Rename container
docker rename old_name new_name

# Wait for container to stop
docker wait <container>
```

---

# docker run vs start vs exec vs attach

| Command | Difference                           |
| ------- | ------------------------------------ |
| run     | Create + start container             |
| start   | Start existing stopped container     |
| exec    | Run command inside running container |
| attach  | Attach terminal to main process      |

---

# docker run Internals

```text
docker run
    =
docker create
    +
docker start
```

---

# docker exec vs attach

| Command | Main Difference                     |
| ------- | ----------------------------------- |
| exec    | Starts NEW process inside container |
| attach  | Connects to EXISTING main process   |

---

# attach Important Note

```text
attach connects STDIN/STDOUT to main container process

CTRL+C may affect container process

attach may terminate container, if main process receives CTRL+C

attach connects directly to PID 1 main process streams
```

---

# Execute Commands Inside Container

```bash
# May fail on slim images
docker exec -it <container_id> bash

# Safer generic version
docker exec -it <container_id> sh
```

---

# Copy Files Between Host and Container

```bash
docker cp <container>:/path/file .

docker cp file.txt <container>:/path/
```

---

# Useful docker run Options

```bash
# Assign container name
docker run --name web nginx

# Run in background
docker run -d nginx

# Port mapping
docker run -p 8080:80 nginx

# Set environment variable
docker run -e ENV=prod nginx

# Auto-remove container
docker run --rm ubuntu

# Limit memory
docker run -m 512m nginx

# Limit CPU
docker run --cpus="1.5" nginx

# Restart policy
docker run --restart unless-stopped nginx

# Combined example
docker run -d --name web -p 8080:80 nginx
```

---

# Port Mapping

```text
HOST_PORT:CONTAINER_PORT
```

Example:

```bash
docker run -p 8080:80 nginx
```

Meaning:

```text
Host port 8080
        ↓
Container port 80
```

---

# EXPOSE vs -p

```text
EXPOSE != -p
```

| Feature | Meaning                     |
| ------- | --------------------------- |
| EXPOSE  | Metadata/documentation only |
| -p      | Publishes port to host      |

---

# Detached vs Interactive

| Option | Meaning                |
| ------ | ---------------------- |
| -d     | Run in background      |
| -it    | Interactive terminal   |
| --rm   | Auto-remove after exit |

---

# Logs + Monitoring

```bash
# View logs
docker logs <container>

# Follow live logs
docker logs -f <container>

# Show last 100 lines
docker logs --tail 100 <container>

# Show timestamps
docker logs -t <container>

# Show resource usage
docker stats

# Show running processes
docker top <container>

# Show mapped ports
docker port <container>

# Inspect filesystem changes
docker diff <container>

# Stream real-time events
docker events

```

---

# System / Engine Information

```bash
# Docker version
docker version

# Docker engine info
docker info

# Current context
docker context ls
```

---

# Cleanup Commands

```bash
# Remove stopped containers
docker container prune

# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune

# Remove unused networks
docker network prune

# Remove everything unused
docker system prune -a

# Remove everything unused including volumes
docker system prune -a --volumes

# Disk usage
docker system df

# Detailed disk usage
docker system df -v
```

`docker image prune -a`

**Unused = not referenced by ANY container
including stopped containers**

## docker image prune

| Command               | Meaning       |
| --------------------- | ------------- |
| docker image prune    | dangling only |
| docker image prune -a | all unused    |


---

# Dangerous Cleanup Commands

```bash
# Stop all running containers
docker stop $(docker ps -q)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images
docker rmi $(docker images -q)
```

WARNING:

```text
May remove ALL local containers/images
on host machine
```

---

# PHASE 2 — Dockerfile

Focus:

* layers
* caching
* COPY vs ADD
* CMD vs ENTRYPOINT
* HEALTHCHECK
* PID 1

---

# Dockerfile Example

```dockerfile
FROM node:20

WORKDIR /app

COPY . .

RUN npm install

EXPOSE 3000

ENV NODE_ENV=production

ARG APP_VERSION=1.0

LABEL maintainer="you@example.com"

USER node

VOLUME ["/data"]

HEALTHCHECK CMD curl --fail http://localhost:3000 || exit 1

CMD ["npm","start"]

ENTRYPOINT ["node"]
```

---

# Dockerfile Instructions

| Instruction | Purpose                            |
| ----------- | ---------------------------------- |
| FROM        | Base image                         |
| RUN         | Execute command during build       |
| COPY        | Copy files                         |
| ADD         | COPY + URL fetch + archive extract |
| WORKDIR     | Set working directory              |
| EXPOSE      | Metadata/documentation             |
| CMD         | Default startup command            |
| ENTRYPOINT  | Fixed executable                   |
| ENV         | Runtime environment variable       |
| ARG         | Build-time variable                |
| USER        | Run as non-root user               |
| LABEL       | Metadata                           |
| VOLUME      | Define mount point                 |
| HEALTHCHECK | Container health monitoring        |

---

# COPY vs ADD

| Instruction | Purpose                           |
| ----------- | --------------------------------- |
| COPY        | Preferred for normal copying      |
| ADD         | COPY + URL fetch + tar extraction |

```text
Prefer COPY unless ADD features are specifically needed

ADD app.tar.gz /app
```

---

# Layer Caching Best Practice

Bad:

```dockerfile
COPY . .
RUN npm install
```

Better:

```dockerfile
COPY package*.json ./
RUN npm install

COPY . .
```

Reason:

```text
Improves Docker layer caching
```

---

# Build Commands

```bash
# Build image
docker build -t myapp:v1 .

# Build without cache
docker build --no-cache -t myapp:v1 .
```

---

# Build Context

```text
docker build sends build context to BuildKit/classic builder backend

Which explains why .dockerignore matters
```

---

# .dockerignore

```text
node_modules
.git
.env
dist
target
*.log
```

---

# CMD vs ENTRYPOINT

| Instruction | Purpose                   |
| ----------- | ------------------------- |
| ENTRYPOINT  | Fixed executable          |
| CMD         | Default arguments/command |

Example:

```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

Runtime result:

```text
python app.py
```

---

# CMD Override Behavior

```dockerfile
CMD ["npm","start"]
```

Can override:

```bash
docker run image npm test
```

ENTRYPOINT is harder to override.

---

# Shell Form vs Exec Form

| Form                | Runs Through Shell |
| ------------------- | ------------------ |
| CMD npm start       | YES (`/bin/sh -c`) |
| CMD ["npm","start"] | NO                 |

```text
Exec form is preferred
because signal handling works properly
```

---

# PID 1 Understanding

```text
PID 1 inside container handles:

- signal forwarding
- zombie process handling
- graceful shutdowns
AND
- shell form CMD may prevent proper signal forwarding
```

Important connection:

```text
shell form vs exec form
directly affects signal handling
```

---

# docker stop Behavior

```text
docker stop

SIGTERM
   ↓
grace period
   ↓
SIGKILL
```

Note:

```text
Default grace period is usually 10 seconds on Linux
```

---

# HEALTHCHECK

Dockerfile:

```dockerfile
HEALTHCHECK CMD curl --fail http://localhost:3000 || exit 1
```

Production-safe example:

```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl --fail http://localhost:3000 || exit 1
```

---

# Runtime Healthcheck

```bash
docker run \
  --health-cmd="curl -f http://localhost || exit 1" \
  nginx
```

---

# Exit Codes

| Exit Code | Meaning |
| --------- | ------- |
| 0         | Success |
| non-zero  | Failure |

---

# Common Docker Exit Codes

| Code | Meaning                             |
| ---- | ----------------------------------- |
| 1    | General error                       |
| 125  | Docker daemon/container run failure |
| 126  | Command cannot execute              |
| 127  | Command not found                   |
| 137  | Container killed (often OOM)        |

---

# Inspect Exit Information

```bash
# Exit code
docker inspect <container> \
  --format='{{.State.ExitCode}}'

# OOM killed
docker inspect <container> \
  --format='{{.State.OOMKilled}}'
```

---

# Multi-Stage Builds

```dockerfile
# Build stage
FROM node:20 AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

RUN npm run build

# Production stage
FROM nginx:alpine

COPY --from=builder \
  /app/dist \
  /usr/share/nginx/html
```

Benefits:

* smaller production images
* reduced attack surface
* cleaner runtime image

---

# BuildKit / Modern Builds

```bash
# Enable BuildKit
DOCKER_BUILDKIT=1 docker build .

# Multi-platform builds
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t username/app:v1 \
  --push .

# List builders
docker buildx ls
```

---

# buildx Important Note

```text
buildx often uses BuildKit container drivers
instead of classic local daemon behavior
```

Usually also needs:

```bash
--push
```

or

```bash
--load
```
```text
Without --push or --load, image may not appear locally
```

---

# Registry Commands

```bash
# Login
docker login

# Logout
docker logout

# Login to private registry
docker login registry.example.com

# Pull from private registry
docker pull registry.example.com/myapp:v1

# Tag image
docker tag myapp:v1 username/myapp:v1

# Push image
docker push username/myapp:v1

# docker save
docker save <image> > image.tar

# docker load
docker load < image.tar

docker pull nginx

docker images

# docker search nginx
```
| Command   | Purpose                 |
| --------- | ----------------------- |
| save/load | Transfer images offline |



# docker history
```bash
docker history <image> # it helps inspect image layers.
```

# docker images --digests

Useful for:
- immutable image verification
- registry digests
- production deployments

---

# PHASE 3 — Storage

Focus:

* volumes
* bind mounts
* tmpfs
* persistence

---

# Storage Types

| Type         | Stored Where        | Typical Usage            |
| ------------ | ------------------- | ------------------------ |
| Named Volume | Docker-managed area | Databases                |
| Bind Mount   | Exact host path     | Development/code sync    |
| tmpfs        | Memory only         | Temporary sensitive data |

---

# Persistence Understanding

```text
Containers are ephemeral

Persistent data should be stored
outside container writable layer
```

---

# Volume Commands

```bash
# Create volume
docker volume create myvolume

# List volumes
docker volume ls

# Inspect volume
docker volume inspect myvolume

# Remove volume
docker volume rm myvolume

# Remove unused volumes
docker volume prune
```

---

# Mount Volumes

```bash
# Named volume
docker run -v myvolume:/data nginx

# Read-only volume
docker run -v myvolume:/data:ro nginx

# Bind mount current directory
docker run -v $(pwd):/app nginx

# Bind specific path
docker run -v /host/path:/container/path nginx
```

---

# VOLUME Instruction

```dockerfile
VOLUME ["/data"]
```

Meaning:

```text
Defines mount point inside container
```

---

# PHASE 4 — Networking

Focus:

* bridge
* DNS
* compose networking
* host/none/overlay/macvlan

---

# Network Drivers

| Driver  | Scope                           |
| ------- | ------------------------------- |
| bridge  | Single-host isolated networking |
| host    | Uses host network directly      |
| none    | No networking                   |
| overlay | Multi-host Swarm networking     |
| macvlan | Real MAC/IP for containers      |

---

# Network Commands

```bash
# Create network
docker network create mynetwork

# List networks
docker network ls

# Inspect network
docker network inspect mynetwork

# Connect container
docker network connect mynetwork <container>

# Disconnect container
docker network disconnect <network> <container>

# Remove network
docker network rm <network>

# Remove unused networks
docker network prune
```

---

# Run Using Network

```bash
# Custom network
docker run -d --network=mynetwork nginx

# Host network
docker run --network host nginx

# No networking
docker run --network none nginx
```

---

# Docker DNS

| Feature    | Meaning                            |
| ---------- | ---------------------------------- |
| Docker DNS | Containers communicate using names |

Example:

```text
web container
    ↓
connects to
    ↓
db container
using hostname "db"
```

---

# Compose Networking

```text
Compose automatically creates project-scoped bridge networks
```

---

# Important Networking Rule

```text
Containers communicate using
service names

NOT container_name best practice
```

Reason:

```text
Compose service names are stable
```

---

# Network Communication

| Mode               | Communication                   |
| ------------------ | ------------------------------- |
| Same network       | Containers communicate directly |
| Different networks | Blocked unless connected        |

---

# PHASE 5 — Docker Compose

Focus:

* lifecycle
* services
* depends_on
* healthchecks
* profiles
* env_file

---

# Compose Lifecycle

```text
docker compose up
        ↓
Creates networks
        ↓
Creates volumes
        ↓
Builds/Pulls images
        ↓
Starts containers
        ↓
Services communicate via Docker DNS
        ↓
docker compose down
        ↓
Stops/removes containers + networks
```

---

# Compose Purpose

Mainly used for:

* local development
* testing
* smaller deployments

```text
Compose CAN still be production-used
for smaller systems
```

---

# Compose Core Commands

```bash
# Start services
docker compose up

# Detached mode
docker compose up -d

# Build before start
docker compose up --build

# Force recreate
docker compose up --force-recreate

# Stop services
docker compose stop

# Start stopped services
docker compose start

# Restart services
docker compose restart

# Stop/remove containers/networks
docker compose down

# Remove volumes also
docker compose down -v

# Show services
docker compose ps

# Logs
docker compose logs

# Follow logs
docker compose logs -f

# Build services
docker compose build

# Pull latest images
docker compose pull

# Validate config
docker compose config

# Execute command
docker compose exec <service> sh

# One-off command
docker compose run --rm <service> <cmd>

# Processes running inside service containers
docker compose top

# Stop + remove orphan containers
docker compose down --remove-orphans

# Remove compose images also
docker compose down --rmi all

# Remove volumes + orphan containers
docker compose down --volumes --remove-orphans

```

`docker compose config`

Useful for debugging:
- variable expansion
- merges
- final generated config

`docker compose up --build`

- Docker may still use cache, unless --no-cache used

---

# Compose down Important Note

```text
docker compose down removes:

- compose containers
- compose-created networks

Does NOT remove named volumes
unless -v used
```

---

# Compose File Concepts

```yaml
depends_on:
restart:
healthcheck:
env_file:
networks:
volumes:
secrets:
configs:
profiles:
```

---

# Compose Keys

| Key         | Purpose             |
| ----------- | ------------------- |
| depends_on  | Start order only    |
| restart     | Restart policy      |
| healthcheck | Health monitoring   |
| env_file    | Load env variables  |
| networks    | Attach networks     |
| volumes     | Persistent storage  |
| secrets     | Sensitive values    |
| configs     | External configs    |
| profiles    | Conditional startup |

---

# depends_on Important Note

```text
depends_on does NOT guarantee
database readiness
```

Use healthchecks for readiness behavior.

---

# Restart Policies

| Policy         | Meaning                    |
| -------------- | -------------------------- |
| no             | Default behavior           |
| always         | Always restart             |
| on-failure     | Restart on failure         |
| unless-stopped | Restart except manual stop |

---

# PHASE 6 — Debugging

Focus:

* inspect
* logs
* events
* stats
* diff
* top
* exec

---

# Core Debugging Commands

```bash
# Container inspect
docker container inspect <container>

# Image inspect
docker image inspect <image>

# Network inspect
docker network inspect <network>

# Volume inspect
docker volume inspect <volume>

docker attach <container>
```

---

# Formatted Inspect

```bash
docker inspect --format

docker inspect -f \
'{{.NetworkSettings.IPAddress}}' \
<container>
```

Important:

```text
formatted inspect is heavily used
in real debugging
```

**Note:**
```text
docker inspect is a generic inspect command.

Examples:

docker inspect <container>
docker inspect <image>

More explicit forms also exist:

docker container inspect <container>
docker image inspect <image>
```

---

# Debugging Tools

```bash
# Logs
docker logs <container>

# Live logs
docker logs -f <container>

# Stats
docker stats

# Processes
docker top <container>

# Filesystem changes
docker diff <container>

# Real-time Docker events
docker events

# Execute shell
docker exec -it <container> sh
```

---

# PHASE 7 — Production + Best Practices

Focus:

* immutable containers
* stateless apps
* non-root users
* multi-stage builds
* pinned versions
* orchestration

---

# Security + Best Practices

| Best Practice          | Why                       |
| ---------------------- | ------------------------- |
| Use slim/alpine images | Smaller attack surface    |
| Use non-root USER      | Better security           |
| Use `.dockerignore`    | Faster builds             |
| Pin image versions     | Reproducible builds       |
| Multi-stage builds     | Smaller production images |
| Avoid latest tag       | Avoid unexpected updates  |

---

# Production Principles

| Rule                                           | Why                          |
| ---------------------------------------------- | ---------------------------- |
| Immutable containers                           | Rebuild instead of modifying |
| Stateless containers                           | Easier orchestration         |
| Persist data in volumes                        | Containers are ephemeral     |
| Usually one main service/process per container | Easier scaling/debugging     |

---

# One Process Per Container Note

```text
Usually one main service/process
per container
```

Because:

* nginx spawns workers
* Apache forks
* sidecars exist
* init systems exist

---

# Kubernetes vs Compose

| Tool           | Typical Usage               |
| -------------- | --------------------------- |
| Docker Compose | Local dev / smaller systems |
| Kubernetes     | Large-scale orchestration   |
| Docker Swarm   | Multi-node orchestration    |

---

# Final High-Level Mental Model

```text
Dockerfile
    ↓
Build Image
    ↓
Run Container
    ↓
Attach Storage + Network
    ↓
Monitor Logs/Health
    ↓
Scale/Orchestrate
```


```bash
docker events
docker compose images
docker compose rm # Remove stopped service containers
docker builder prune
docker manifest inspect
```
