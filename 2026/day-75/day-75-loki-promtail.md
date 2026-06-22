# Day 75 -- Log Management with Loki and Promtail

---

## Challenge Tasks

### Task 1: Understand the Logging Pipeline
Before writing any config, understand how the pieces fit together:

```
[Docker Containers]
       |
       | (write JSON logs to /var/lib/docker/containers/)
       v
  [Promtail]
       |
       | (reads log files, adds labels, pushes to Loki)
       v
    [Loki]
       |
       | (stores logs, indexes by labels)
       v
   [Grafana]
       |
       | (queries Loki with LogQL, displays logs)
       v
   [You]
```

Key differences from the ELK stack:
- Loki does **not** index the full text of logs -- it only indexes labels (like container name, job, filename)
- This makes Loki much cheaper to run and simpler to operate
- Think of it as "Prometheus, but for logs" -- same label-based approach

**Document:** Why does Loki only index labels instead of full text? What is the trade-off?

Loki was designed to be lightweight and cost-efficient.

Traditional logging systems such as Elasticsearch create indexes for every log message.

Example log:

```text
User 123 failed payment due to timeout
```

Elasticsearch indexes:

```text
User
123
failed
payment
due
to
timeout
```

This creates a huge amount of index data and requires significant:

* CPU
* Memory
* Storage

Loki takes a different approach.

It only indexes metadata (labels):

```text
container_name=notes-app
job=docker
environment=prod
```

The actual log message is stored in compressed chunks and searched only when needed.

---

## Trade-Off of Loki's Design

| Advantage                              | Disadvantage                               |
| -------------------------------------- | ------------------------------------------ |
| Lower storage cost                     | Slower full-text searches                  |
| Less RAM usage                         | Less powerful search capabilities          |
| Faster log ingestion                   | Cannot search as flexibly as Elasticsearch |
| Easier to operate                      | Complex analytics are harder               |
| Works naturally with Prometheus labels | Depends heavily on good label design       |

### Example

Suppose you have 100 million log lines.

**Elasticsearch**

* Indexes every word
* Very fast searches
* Large storage footprint
* Higher infrastructure cost

**Loki**

* Indexes only labels
* Smaller storage footprint
* Lower infrastructure cost
* Searches may take longer because log content is scanned when queried

---

### Task 2: Add Loki to the Stack
Create the Loki configuration file.

```bash
mkdir -p loki
```

Create `loki/loki-config.yml`:
```yaml
auth_enabled: false

server:
  http_listen_port: 3100

common:
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory
  replication_factor: 1
  path_prefix: /loki

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

storage_config:
  filesystem:
    directory: /loki/chunks
```

**What this config does:**
- `auth_enabled: false` -- single-tenant mode, no authentication needed
- `store: tsdb` -- uses Loki's time-series database for indexing
- `object_store: filesystem` -- stores log chunks on local disk
- `replication_factor: 1` -- single instance, no replication (fine for learning)

Add Loki to your `docker-compose.yml`:
```yaml
  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    volumes:
      - ./loki/loki-config.yml:/etc/loki/loki-config.yml
      - loki_data:/loki
    command: -config.file=/etc/loki/loki-config.yml
    restart: unless-stopped
```

Add `loki_data` to your volumes section:
```yaml
volumes:
  prometheus_data:
  grafana_data:
  loki_data:
```

Start Loki:
```bash
docker compose up -d loki
```

Verify Loki is running:
```bash
curl http://localhost:3100/ready
```

You should see `ready`.

<img width="1767" height="222" alt="image" src="https://github.com/user-attachments/assets/3e7a6688-ef45-452c-ace2-9916ca548c5b" />
<img width="521" height="187" alt="image" src="https://github.com/user-attachments/assets/9e38e728-6969-4272-96ad-d908152e6aaa" />


---

### Task 3: Add Promtail to Collect Container Logs
Promtail is the log collection agent. It reads Docker container log files from the host and pushes them to Loki.

```bash
mkdir -p promtail
```

Create `promtail/promtail-config.yml`:
```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: docker
    static_configs:
      - targets:
          - localhost
        labels:
          job: docker
          __path__: /var/lib/docker/containers/*/*-json.log
    pipeline_stages:
      - docker: {}
```

**What this config does:**
- `positions` -- tracks which log lines have already been shipped (like a bookmark)
- `clients` -- where to send logs (Loki endpoint)
- `__path__` -- the glob pattern to find Docker JSON log files on the host
- `pipeline_stages: docker: {}` -- parses the Docker JSON log format and extracts timestamp, stream (stdout/stderr), and the log message

Add Promtail to your `docker-compose.yml`:
```yaml
  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    volumes:
      - ./promtail/promtail-config.yml:/etc/promtail/promtail-config.yml
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - /var/run/docker.sock:/var/run/docker.sock
    command: -config.file=/etc/promtail/promtail-config.yml
    restart: unless-stopped
```

**Why these volume mounts?**
- `/var/lib/docker/containers` -- where Docker stores container log files (read-only)
- `/var/run/docker.sock` -- lets Promtail discover container metadata (names, labels)

Restart the stack:
```bash
docker compose up -d
```

Generate some logs by hitting the notes app:
```bash
for i in $(seq 1 20); do curl -s http://localhost:8000 > /dev/null; done
```

<img width="1920" height="2328" alt="image" src="https://github.com/user-attachments/assets/a3fa1c6a-a346-4d62-9886-7522c3fbfaa5" />
<img width="1917" height="820" alt="image" src="https://github.com/user-attachments/assets/8844b127-bd58-4bc2-83b3-efa623e1a5ac" />

<img width="1920" height="1970" alt="image" src="https://github.com/user-attachments/assets/f91f10ac-ffe0-4555-bbc4-69c1f4b5de78" />



---

### Task 4: Add Loki as a Grafana Datasource
You can add it manually through the UI or auto-provision it with YAML.

**Option A -- Provision via YAML (recommended):**

Update `grafana/provisioning/datasources/datasources.yml`:
```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false

  - name: Loki
    type: loki
    access: proxy
    url: http://loki:3100
    editable: false
```

Restart Grafana to pick up the new datasource:
```bash
docker compose restart grafana
```

**Option B -- Manual UI setup:**
1. Go to Connections > Data Sources > Add data source
2. Select Loki
3. URL: `http://loki:3100`
4. Save & Test

Either way, you should now have two datasources in Grafana: Prometheus and Loki.

<img width="1917" height="820" alt="loki-data-source" src="https://github.com/user-attachments/assets/bce5d867-61c7-4924-a19b-010606a096f3" />


---

### Task 5: Query Logs with LogQL
LogQL is Loki's query language -- similar to PromQL but for logs.

Go to Grafana > Explore (compass icon). Select Loki as the datasource.

1. **Stream selector** -- filter logs by labels:
```logql
{job="docker"}
```
This shows all Docker container logs.

<img width="1920" height="1658" alt="image" src="https://github.com/user-attachments/assets/39bb5cf1-5092-4e1a-a94e-5f02723f1ff6" />


2. **Filter by container name:**
```logql
{container_name="prometheus"}
```

<img width="1920" height="1668" alt="image" src="https://github.com/user-attachments/assets/06b2a3e5-7d65-40b3-8d8c-90d1150aa070" />


3. **Keyword search** -- filter log lines by content:
```logql
{job="docker"} |= "error"
```
`|=` means "line contains". This finds all log lines with the word "error".

<img width="1920" height="1578" alt="image" src="https://github.com/user-attachments/assets/6caaad52-66e8-4738-beb3-38327a0185fe" />


4. **Negative filter:**
```logql
{job="docker"} != "health"
```
Excludes lines containing "health" (useful to filter out health check noise).

<img width="1920" height="1735" alt="image" src="https://github.com/user-attachments/assets/e825d63e-c65b-4c01-a974-2ba602dbbf47" />


5. **Regex filter:**
```logql
{job="docker"} |~ "status=[45]\\d{2}"
```
Finds lines with HTTP 4xx or 5xx status codes.

<img width="1920" height="1735" alt="image" src="https://github.com/user-attachments/assets/cf0b5591-7f2b-49e8-92f6-fb6dffed504c" />


6. **Log metric queries** -- count log lines over time:
```logql
count_over_time({job="docker"}[5m])
```

<img width="1920" height="1173" alt="image" src="https://github.com/user-attachments/assets/1591e3f7-83e1-429d-80e8-45575d518f70" />


7. **Rate of logs per second:**
```logql
rate({job="docker"}[5m])
```

<img width="1920" height="1173" alt="image" src="https://github.com/user-attachments/assets/88298cc3-86ba-4a8e-ae32-5af7af12761f" />


8. **Top containers by log volume:**
```logql
topk(5, sum by (container_name) (rate({job="docker"}[5m])))
```

<img width="1920" height="1325" alt="image" src="https://github.com/user-attachments/assets/4a91e97a-cac2-4c96-9a54-85c633620bd9" />


**Exercise:** Write a LogQL query that finds all error logs from the notes-app container in the last 1 hour. Then write another query that counts how many error lines per minute.

- `{compose_project="observability-stack"} |~ "(?i)error|404|exception"`
<img width="1920" height="1735" alt="image" src="https://github.com/user-attachments/assets/9e947ef9-328f-4ba5-b968-c544eabcf6d3" />


- `count_over_time(
  {compose_project="observability-stack"} |~ "(?i)error|404|exception" [1m]
)`

or

`count_over_time({compose_project="observability-stack"} |~ "(?i)error|404|exception"[1m])`


<img width="1917" height="905" alt="image" src="https://github.com/user-attachments/assets/88151a87-7c5b-4f9c-b7ae-9f55cc85a92e" />





---

### Task 6: Correlate Metrics and Logs in Grafana
The real power of observability is correlation -- seeing metrics and logs together.

1. **Add a logs panel to your dashboard:**
   - Open the dashboard you built on Day 74
   - Add a new panel
   - Select Loki as the datasource
   - Query: `{job="docker"}`
   - Visualization: Logs
   - Title: "Container Logs"

<img width="1920" height="1340" alt="image" src="https://github.com/user-attachments/assets/1ee1bbf2-2786-456c-87e6-0011f82c64aa" />


2. **Use the Explore split view:**
   - Go to Explore
   - Click the split button (two panels side by side)
   - Left panel: Prometheus -- `rate(container_cpu_usage_seconds_total{name="notes-app"}[5m])`
   - Right panel: Loki -- `{container_name="notes-app"}`
   - Now you can see CPU spikes and the corresponding log output at the same time

<img width="2560" height="1972" alt="image" src="https://github.com/user-attachments/assets/898d3f57-6bf7-453d-8900-e517e46e86b8" />


3. **Time sync:** Click on a spike in the metrics graph and both panels will zoom to that time range. This is how you debug in production -- you see a metric anomaly and immediately check the logs from that exact moment.

<img width="2560" height="1948" alt="image" src="https://github.com/user-attachments/assets/fb67eb5d-7352-4944-8ed1-96c2064d20c9" />


**Document:** How does having metrics and logs in the same tool (Grafana) help during incident response compared to checking separate systems?

When metrics + logs are in the same tool:

- You don’t switch tabs between Prometheus & ELK
- One click on spike → logs auto-filter to same time
- You instantly see cause (logs) + effect (metrics) together
- Incident response becomes minutes instead of hours


---

# Documentation:



## 1. Architecture Diagram

```
[ Docker Containers ]
        ↓
[ Promtail (log collector) ]
        ↓
[ Loki (log storage + query engine) ]
        ↓
[ Grafana (visualization + correlation with Prometheus) ]
```

###  Flow Explanation:

* **Docker Containers**

  * Applications generating logs (Flask, Node, etc.)

* **Promtail**

  * Reads container logs from Docker
  * Adds metadata (container name, project)
  * Sends logs to Loki

* **Loki**

  * Stores logs efficiently (like Prometheus but for logs)
  * Supports LogQL queries

* **Grafana**

  * Combines:

    * Prometheus metrics 
    * Loki logs 
  * Enables time-based correlation (incident debugging)

---

# 2. Loki Configuration (`loki-config.yml`)

```yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1

schema_config:
  configs:
    - from: 2023-01-01
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h

storage_config:
  filesystem:
    directory: /loki/chunks

limits_config:
  allow_structured_metadata: true
```

###  Explanation:

* Runs Loki in **single-node mode**
* Uses filesystem storage (good for learning)
* TSDB schema for efficient querying
* No auth (dev environment)

---

# 3. Promtail Configuration (`promtail-config.yml`)

```yaml
server:
  http_listen_port: 9080

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: docker

    docker_sd_configs:
      - host: unix:///var/run/docker.sock
        refresh_interval: 5s

    relabel_configs:
      - source_labels: ['__meta_docker_container_name']
        target_label: container_name

      - source_labels: ['__meta_docker_container_label_com_docker_compose_project']
        target_label: compose_project

      - source_labels: ['__meta_docker_container_label_com_docker_compose_project']
        regex: observability-stack
        action: keep

      # IMPORTANT: enables actual log scraping
      - source_labels: ['__meta_docker_container_log_path']
        target_label: __path__

    pipeline_stages:
      - docker: {}
```

###  Explanation:

* Discovers Docker containers automatically
* Filters only `observability-stack`
* Extracts logs from Docker log files
* Sends structured logs to Loki

---

# 4. Docker Compose (`docker-compose.yml`)

```yaml
version: "3.8"

services:

  loki:
    image: grafana/loki:2.9.0
    ports:
      - "3100:3100"
    command: -config.file=/etc/loki/config.yml
    volumes:
      - ./loki-config.yml:/etc/loki/config.yml

  promtail:
    image: grafana/promtail:2.9.0
    volumes:
      - ./promtail-config.yml:/etc/promtail/config.yml
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    command: -config.file=/etc/promtail/config.yml
    depends_on:
      - loki

  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    depends_on:
      - prometheus
      - loki
```

###  Explanation:

* **Loki** → stores logs
* **Promtail** → collects logs from Docker
* **Prometheus** → metrics system
* **Grafana** → visualization + correlation layer

---

# 5. LogQL Queries You Ran

###  All container logs

```logql
{container_name=~".*"}
```

✔ Returns logs from all containers

---

###  Filter by compose project

```logql
{compose_project="observability-stack"}
```

✔ Shows only your project logs

---

###  Specific container logs

```logql
{container_name="notes-app"}
```

✔ Logs only from app container

---

###  Error filtering (if added later)

```logql
{container_name=~".+"} |= "error"
```

✔ Shows only error logs

---

# 6. What you should expect in Grafana Logs panel

After fix:

* You will see:

  * HTTP requests (200 / 404)
  * Container startup logs
  * Errors (if any)

Example:

```
GET /does-not-exist 404
GET / 200
POST /login 200
```

---

# 7. Time Sync (Core Concept)

### In Grafana:

When you:

* Click a spike in CPU graph 
* Logs panel automatically filters same timestamp 

### This works because:

* Both use **same time range**
* Loki stores logs with timestamps
* Prometheus stores metrics with timestamps
* Grafana aligns them visually

---

# 8. Why Metrics + Logs Together is Powerful

| Feature             | Separate Systems | Grafana Unified View |
| ------------------- | ---------------- | -------------------- |
| Debug speed         | Slow             | Fast                 |
| Context switching   | High             | None                 |
| Root cause analysis | Hard             | Easy                 |
| Time correlation    | Manual           | Automatic            |
| Incident response   | 30–60 min        | 5–10 min             |

---

# 9. Loki vs ELK Stack

| Feature        | Loki                                           | ELK Stack (Elasticsearch + Logstash + Kibana)   |
| -------------- | ---------------------------------------------- | ----------------------------------------------- |
| Architecture   | Lightweight indexing                           | Heavy indexing                                  |
| Storage        | Label-based                                    | Full-text indexed                               |
| Performance    | Faster for DevOps                              | Powerful for deep search                        |
| Cost           | Low                                            | High                                            |
| Complexity     | Simple                                         | Complex                                         |
| Query language | LogQL                                          | Lucene / DSL                                    |
| Best use case  | Kubernetes / Docker logs + metrics correlation | Enterprise log analytics, security, deep search |



