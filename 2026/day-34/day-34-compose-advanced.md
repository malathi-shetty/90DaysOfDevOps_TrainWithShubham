# Day 34 – Docker Compose: Real-World Multi-Container Apps

## Challenge Tasks

### Task 1: Build Your Own App Stack
Create a `docker-compose.yml` for a 3-service stack:
- A **web app** (use Python Flask, Node.js, or any language you know)
- A **database** (Postgres or MySQL)
- A **cache** (Redis)

```bash
services:

  web:
    build: ./app

    ports:
      - "3000:3000"

    environment:
      DB_HOST: db
      DB_NAME: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres
      REDIS_HOST: redis

  db:
    image: postgres:15

    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres

  redis:
    image: redis:7
```
Dockerfile:
```bash
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "app.py"]
```

requirements.txt

```bash
flask
psycopg2-binary
redis
```

app.py
```bash
from flask import Flask
import psycopg2
import redis
import os

app = Flask(__name__)

@app.route("/")
def home():

    db_status = "Not Connected"
    redis_status = "Not Connected"

    # PostgreSQL connection
    try:
        conn = psycopg2.connect(
            host=os.getenv("DB_HOST"),
            database=os.getenv("DB_NAME"),
            user=os.getenv("DB_USER"),
            password=os.getenv("DB_PASSWORD")
        )

        db_status = "PostgreSQL Connected"

        conn.close()

    except Exception as e:
        db_status = str(e)

    # Redis connection
    try:
        r = redis.Redis(
            host=os.getenv("REDIS_HOST"),
            port=6379
        )

        r.set("message", "Redis Connected")

        redis_status = r.get("message").decode()

    except Exception as e:
        redis_status = str(e)

    return {
        "message": "Hello from Flask Docker App",
        "database": db_status,
        "redis": redis_status
    }

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3000)
```
<img width="842" height="1090" alt="image" src="https://github.com/user-attachments/assets/720cbe3a-715f-4d28-8c9e-e7b992988ef9" />

<img width="691" height="287" alt="image" src="https://github.com/user-attachments/assets/938b0307-13fa-43b6-bf00-b2f52040cae6" />

<img width="653" height="566" alt="image" src="https://github.com/user-attachments/assets/cb56053e-ab4f-431d-b802-e46de8265b6d" />

<img width="1593" height="652" alt="image" src="https://github.com/user-attachments/assets/d7835fa9-007a-41ae-ae07-a639533a1ed5" />


---

### Task 2: depends_on & Healthchecks
1. Add `depends_on` to your compose file so the app starts **after** the database
2. Add a **healthcheck** on the database service
3. Use `depends_on` with `condition: service_healthy` so the app waits for the database to be truly ready, not just started


    **Test:** Bring everything down and up — does the app wait for the DB?

    - Yes

<img width="1407" height="775" alt="image" src="https://github.com/user-attachments/assets/1ffd34ec-eb80-4c6b-a231-415696da249a" />

<img width="951" height="572" alt="image" src="https://github.com/user-attachments/assets/8911fd2d-e16f-403e-86f9-efa23ec07059" />


<img width="1593" height="1316" alt="image" src="https://github.com/user-attachments/assets/c720bc80-3dcf-4d5f-bd8b-be5dd71a8dea" />

<img width="701" height="837" alt="image" src="https://github.com/user-attachments/assets/fda0c566-227f-4b78-ad98-c8a3f97e38b5" />

<img width="1601" height="1319" alt="image" src="https://github.com/user-attachments/assets/30611dcc-9a96-475f-a6d6-b0490a9fa44e" />


- Postgres container starts first.
- Healthcheck waits until DB is ready.
- App container starts only after DB is healthy.

```bash
services:

  web:
    build: ./app

    ports:
      - "3000:3000"

    environment:
      DB_HOST: db
      DB_NAME: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres
      REDIS_HOST: redis

    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:15

    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres

    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7
```
| Feature         | Purpose                  |
| --------------- | ------------------------ |
| depends_on      | Controls startup order   |
| healthcheck     | Checks service readiness |
| service_healthy | Waits until DB is usable |

---

### Task 3: Restart Policies
1. Add `restart: always` to your database service

```bash
services:

  web:
    build: ./app

    ports:
      - "3000:3000"

    environment:
      DB_HOST: db
      DB_NAME: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres
      REDIS_HOST: redis

    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:15
    restart: always

    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres

    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7
```

Run:

`docker inspect web_db_cache-db-1 | grep -A 5 RestartPolicy`

You should see:
```bash
"RestartPolicy": {
    "Name": "always",
```

2. Manually kill the database container — does it come back?
    - Yes, the container restarted automatically.





3. Try `restart: on-failure` — how is it different?
    - Container did not restart automatically.
  
  ```bash
Replace:
restart: always

with:

restart: on-failure

Save file.
```

  <img width="2522" height="1333" alt="image" src="https://github.com/user-attachments/assets/10f739fd-ec34-4349-952e-221035dbaa05" />

<img width="2550" height="1262" alt="image" src="https://github.com/user-attachments/assets/255b567b-7d65-4b76-b499-a13229c7dc95" />


4. When would you use each restart policy?

### restart: always
- Added `restart: always` to PostgreSQL service
- Docker attempts to keep the service running continuously
- Commonly used for:
  - Databases
  - APIs
  - Backend production services

### restart: on-failure
- Changed policy to `restart: on-failure`
- Container restarts only when the application exits with a failure/non-zero exit code
- Manual stops typically do not trigger restart
- Useful for jobs or processes that should retry only on crashes

### Difference
- `always` → restart regardless of stop reason
- `on-failure` → restart only when application exits with failure

| Restart Policy | Behavior                                    |
| -------------- | ------------------------------------------- |
| `always`       | tries to keep service running               |
| `on-failure`   | only restarts when app itself crashes/fails |


### Learning
- Restart policies help improve service availability in Docker Compose environments.
---

### Task 4: Custom Dockerfiles in Compose
1. Instead of using a pre-built image for your app, use `build:` in your compose file to build from a Dockerfile
2. Make a code change in your app

`vi app.py`
```bash
return "Hello from Flask App!"

Change it to:

return "Docker Compose Rebuild Successful!"
```

3. Rebuild and restart with one command

`docker compose up -d --build`


<img width="1938" height="1252" alt="image" src="https://github.com/user-attachments/assets/d71883d2-0215-40f9-960b-6680945e249e" />



- Used `build: ./app` to build custom Flask application image
- Modified application code in `app.py`
- Modified Flask Message: 
`return "Hello from Flask App!"`
Changed it to:
`return "Docker Compose Rebuild Successful!"`
- Rebuilt and restarted containers using:

`docker compose up -d --build` --> This is how teams deploy updates in many Docker environments

### Learning
- Docker Compose can automatically rebuild images from Dockerfiles
- Code changes require image rebuild to reflect inside containers
- `--build` simplifies rebuild + restart workflow

---

### Task 5: Named Networks & Volumes
1. Define **explicit networks** in your compose file instead of relying on the default

```bash
networks:
  - app-network

and:

networks:
  app-network:
```


2. Define **named volumes** for database data

```bash
volumes:
  - postgres-data:/var/lib/postgresql/data

and:

volumes:
  postgres-data:
```


3. Add **labels** to your services for better organization

```bash
labels:
  app: "flask-app"
  environment: "dev"
```

---

```bash
services:

  web:
    build: ./app

    ports:
      - "3000:3000"

    environment:
      DB_HOST: db
      DB_NAME: postgres
      DB_USER: postgres
      DB_PASSWORD: postgres
      REDIS_HOST: redis

    depends_on:
      db:
        condition: service_healthy

    networks:
      - app-network

    labels:
      app: "flask-app"
      environment: "dev"

  db:
    image: postgres:15

    restart: on-failure

    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: postgres

    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

    volumes:
      - postgres-data:/var/lib/postgresql/data

    networks:
      - app-network

    labels:
      app: "postgres-db"
      environment: "dev"

  redis:
    image: redis:7

    networks:
      - app-network

    labels:
      app: "redis-cache"
      environment: "dev"

networks:
  app-network:

volumes:
  postgres-data:
```

### Networks
- Created explicit network:
  - `app-network`
- Connected web, db, and redis services using custom network

### Volumes
- Added named volume:
  - `postgres-data`
- PostgreSQL data persists even after container removal

### Labels
Added labels for better organization:
- app name
- environment type

### Verification
- Verified network using:
  docker network inspect
- Verified labels using:
  docker inspect
- Verified volume using:
  docker volume ls

### Learning
- Networks improve container communication and isolation
- Volumes provide persistent storage
- Labels help organize and manage services
  
### Important Real-World DevOps Concepts
- Feature	Why It Matters
- Networks	secure service communication
- Volumes	persistent production data
- Labels	observability & automation

<img width="1317" height="902" alt="image" src="https://github.com/user-attachments/assets/23a53c84-45a0-4f5b-afb0-a7d150bdf076" />

<img width="835" height="530" alt="image" src="https://github.com/user-attachments/assets/2e5e1245-c9d5-4052-8e2c-c95c0fa72fd2" />

<img width="1070" height="250" alt="image" src="https://github.com/user-attachments/assets/4a97282f-0e6a-45a9-886f-f42d0d9f561e" />

<img width="1162" height="565" alt="image" src="https://github.com/user-attachments/assets/3456d5a8-deb8-4f88-99fa-d665409aaa65" />


---

### Task 6: Scaling
1. Try scaling your web app to 3 replicas using `docker compose up --scale`
2. What happens? What breaks?
- Scaling the web service to 3 replicas failed because all containers tried to bind to host port 3000.
- Docker allows only one container to use a specific host port at a time.
3. Why doesn't simple scaling work with port mapping?
The first container started successfully, while the others failed with:
"Bind for 0.0.0.0:3000 failed: port is already allocated"

Simple scaling with direct port mapping does not work in production.


<img width="1487" height="628" alt="image" src="https://github.com/user-attachments/assets/2d00669e-e427-474b-9a9e-6eab11e4c670" />





### Real-world scaling is usually handled using:
- Load balancers
- Reverse proxies (Nginx/Traefik)
- Docker Swarm
- Kubernetes

### Learning
- Scaling creates multiple replicas of the same service
- Direct host port mapping prevents multiple replicas from using the same port
- Real-world container scaling uses load balancers or orchestration tools
---
