# Day 36 – Docker Project: Dockerize a Full Application
---
```bash
Folder Structure:

2026/day-36/
│
├── app/
│   ├── app.py
│   ├── requirements.txt
│   ├── templates/
│   │   └── index.html
│   └── static/
│
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .env
├── README.md
└── day-36-docker-project.md
```
## Challenge Tasks

### Task 1: App
- A **Python Flask** app with a database

### App Code
`app/app.py`

```bash
from flask import Flask, render_template, request, redirect
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)

DB_USER = os.getenv("POSTGRES_USER")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD")
DB_NAME = os.getenv("POSTGRES_DB")
DB_HOST = os.getenv("DB_HOST")

app.config["SQLALCHEMY_DATABASE_URI"] = (
    f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:5432/{DB_NAME}"
)

app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)

class Task(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    content = db.Column(db.String(200), nullable=False)

with app.app_context():
    db.create_all()

@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        task_content = request.form["content"]

        if task_content:
            new_task = Task(content=task_content)
            db.session.add(new_task)
            db.session.commit()

        return redirect("/")

    tasks = Task.query.all()
    return render_template("index.html", tasks=tasks)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

---

`app/requirements.txt`

```bash
Flask==3.0.3
Flask-SQLAlchemy==3.1.1
psycopg2-binary==2.9.9
```
---

`app/templates/index.html`

```bash
<!DOCTYPE html>
<html>
<head>
    <title>Task Tracker</title>
</head>
<body>
    <h1>Task Tracker</h1>

    <form method="POST">
        <input type="text" name="content" placeholder="Enter task">
        <button type="submit">Add</button>
    </form>

    <ul>
        {% for task in tasks %}
            <li>{{ task.content }}</li>
        {% endfor %}
    </ul>
</body>
</html>
```

The application allows users to:

- Add tasks
- Store tasks in a PostgreSQL database
- Display saved tasks on the webpage

---

### Task 2: Write the Dockerfile
1. Create a Dockerfile for your application
2. Use a **multi-stage build** if applicable
3. Use a **non-root user**
4. Keep the image **small** — use alpine or slim base images
5. Add a `.dockerignore` file

Build and test it locally.

The application was containerized using a multi-stage Docker build to reduce image size and improve efficiency.

- Dockerfile Features
- Multi-stage build
- Lightweight python:3.12-slim image
- Non-root user for security
- Optimized dependency installation
- Small final image size

#### Dockerfile
```bash
# -------- Base Stage --------
FROM python:3.12-slim AS base

# Prevent Python from writing pyc files
ENV PYTHONDONTWRITEBYTECODE=1

# Ensure logs appear instantly
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Install dependencies required for psycopg2
RUN apt-get update && apt-get install -y gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY app/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# -------- Final Stage --------
FROM python:3.12-slim

WORKDIR /app

# Create non-root user
RUN useradd -m appuser

# Copy installed packages from base image
COPY --from=base /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=base /usr/local/bin /usr/local/bin

# Copy app source
COPY app/ .

# Change ownership
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

EXPOSE 5000

CMD ["python", "app.py"]
```
---

`.dockerignore`

```bash
__pycache__
*.pyc
*.pyo
*.pyd
.env
.git
.gitignore
venv
```
<img width="1047" height="193" alt="image" src="https://github.com/user-attachments/assets/3c4e5ff7-079e-4c3a-b2b5-c27b3eb7268b" />


---

### Task 3: Add Docker Compose
Write a `docker-compose.yml` that includes:
1. Your **app** service (built from Dockerfile)
2. A **database** service (Postgres, MySQL, MongoDB — whatever your app needs)
3. **Volumes** for database persistence
4. A **custom network**
5. **Environment variables** for configuration (use `.env` file)
6. **Healthchecks** on the database

Run `docker compose up` and verify everything works together.

<img width="1047" height="752" alt="image" src="https://github.com/user-attachments/assets/3dc64945-4796-4053-88e2-110265d48645" />


Docker Compose was used to manage both the Flask application and PostgreSQL database.

- Features Implemented
- Multi-container setup
- PostgreSQL database service
- Persistent Docker volumes
- Custom Docker network
- Environment variable management
- Database healthchecks

`docker-compose.yml`
```bash

services:
  web:
    build: .
    container_name: flask_app
    ports:
      - "5000:5000"
    env_file:
      - .env
    depends_on:
      db:
        condition: service_healthy
    networks:
      - app_network

  db:
    image: postgres:16-alpine
    container_name: postgres_db
    restart: always

    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: taskdb

    volumes:
      - postgres_data:/var/lib/postgresql/data

    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

    networks:
      - app_network

volumes:
  postgres_data:

networks:
  app_network:
    driver: bridge
```

---

`Environment Variables`

```bash
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=taskdb
DB_HOST=db
```
---



---

### Build & Run the Application

**Build Containers**
`docker compose build`

**Start Containers**
`docker compose up`

Open in Browser:

`http://localhost:5000`

<img width="2043" height="942" alt="image" src="https://github.com/user-attachments/assets/fa26b72c-dc04-42bc-a9cf-0a9987809f19" />

<img width="1600" height="380" alt="image" src="https://github.com/user-attachments/assets/eade9dee-c0ba-42da-a042-a4390765b42d" />

<img width="712" height="173" alt="image" src="https://github.com/user-attachments/assets/144d44d9-eb76-4459-8b7f-8ecea6609976" />

<img width="858" height="531" alt="image" src="https://github.com/user-attachments/assets/d181e113-62ee-4aa6-93ff-74e51545eca8" />


---

### Task 4: Ship It
1. Tag your app image
2. Push it to Docker Hub
3. Share the Docker Hub link
4. Write a `README.md` in your project with:
   - What the app does
   - How to run it with Docker Compose
   - Any environment variables needed

```bash

docker login

docker tag app-web shettymalathi113/task-tracker:latest

docker push shettymalathi113/task-tracker:latest

```

---

### Task 5: Test the Whole Flow
1. Remove all local images and containers
2. Pull from Docker Hub and run using only your compose file
3. Does it work fresh? If not — fix it until it does


**The application worked successfully in a fresh environment.**

<img width="710" height="530" alt="image" src="https://github.com/user-attachments/assets/f2960c1a-b342-4e95-9082-a98fe694ab05" />

<img width="2542" height="1143" alt="image" src="https://github.com/user-attachments/assets/953d411c-f220-40e9-96c4-07dc206c0919" />


---

## Documentation
Create `day-36-docker-project.md` with:
####   What app you chose and why

I chose to build a Flask Task Tracker application with PostgreSQL as the backend database.

This project was selected because it demonstrates several important real-world Docker concepts:

- Running a multi-container application using Docker Compose
- Connecting an application container with a database container
- Managing persistent database storage using Docker volumes
- Using environment variables for configuration
- Implementing Docker healthchecks
- Creating optimized Docker images using multi-stage builds
- Running containers securely with a non-root user

The Task Tracker application allows users to:

- Add tasks
- Store tasks in a PostgreSQL database
- Display tasks dynamically on a web interface

This project provided practical experience in building and deploying a complete containerized application workflow similar to production environments.

#### Your Dockerfile (with comments explaining each line)

```base

# -------- Base Stage --------

# Use lightweight Python image
FROM python:3.12-slim AS base

# Prevent Python from creating .pyc files
ENV PYTHONDONTWRITEBYTECODE=1

# Enable real-time log output
ENV PYTHONUNBUFFERED=1

# Set working directory inside container
WORKDIR /app

# Install system dependencies required for PostgreSQL driver
RUN apt-get update && apt-get install -y gcc libpq-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements file first for better Docker layer caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# -------- Final Stage --------

# Use another lightweight Python image for final container
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Create a non-root user for security
RUN useradd -m appuser

# Copy installed Python packages from base stage
COPY --from=base /usr/local/lib/python3.12 /usr/local/lib/python3.12

# Copy installed binaries from base stage
COPY --from=base /usr/local/bin /usr/local/bin

# Copy application source code into container
COPY . .

# Change ownership of app files to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose Flask application port
EXPOSE 5000

# Start Flask application
CMD ["python", "app.py"]

```


#### Challenges you faced and how you solved them

**1. Docker Build Context Issue**

Initially, the Docker build failed because the COPY paths in the Dockerfile did not match the actual project structure.

**Solution**

Updated:
```bash
COPY app/requirements.txt .
COPY app/ .
```
to:
```bash
COPY requirements.txt .
COPY . .
```

**2. Missing `.env` File**

Docker Compose failed because the `.env` file was not created.

**Solution**

Created the `.env` file with database configuration values.

**3. Docker Compose File Location**

`docker compose logs -f` initially failed because the command was executed outside the compose file directory.

**Solution**

Ran the command from the correct directory containing `docker-compose.yml`.


#### Final image size

- Final Image size is  55.3MB

The image size was optimized using:

- Multi-stage builds
- Slim base image
- .dockerignore
- Minimal dependencies

#### Docker Hub link
**Doceker Hub Link** : https://hub.docker.com/repository/docker/shettymalathi113/task-tracker/general

---
