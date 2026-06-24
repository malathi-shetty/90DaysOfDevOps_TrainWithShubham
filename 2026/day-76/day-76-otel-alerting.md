# Day 76 -- OpenTelemetry and Alerting
---

## Challenge Tasks

### Task 1: Understand OpenTelemetry
Research and write notes on:

Perfect. Let's do **Task 1 only** and create notes that you can directly put into `day-76-otel-alerting.md`.

# Task 1: Understand OpenTelemetry

## 1. What is OpenTelemetry (OTEL)?

OpenTelemetry (OTEL) is an open-source, vendor-neutral observability framework used to generate, collect, process, and export telemetry data from applications and infrastructure.

Telemetry data consists of three main signals:

* **Metrics** → Numerical measurements over time (CPU usage, request count, memory usage)
* **Logs** → Timestamped records of events
* **Traces** → Request flow across services

OpenTelemetry itself is **not a storage backend**. It collects telemetry data and sends it to monitoring systems such as:

* Prometheus (metrics)
* Loki (logs)
* Jaeger (traces)
* Grafana Tempo (traces)
* Datadog
* New Relic

### Why OpenTelemetry?

Before OTEL, every monitoring vendor had its own SDK and agent. Applications had to be instrumented differently depending on the backend.

OpenTelemetry provides a single standard for instrumentation and telemetry collection, allowing organizations to switch backends without changing application code.

### Data Flow

```text
Application
    |
    v
OpenTelemetry SDK
    |
    v
OpenTelemetry Collector
    |
    v
Prometheus / Loki / Jaeger / Tempo / Datadog
```

---

## 2. What is the OpenTelemetry Collector?

The OpenTelemetry Collector is a standalone service that receives, processes, and exports telemetry data.

Instead of applications sending telemetry directly to multiple monitoring systems, they send data to the collector, which acts as a central pipeline.

### Benefits

* Centralized telemetry processing
* Vendor-independent architecture
* Reduced application complexity
* Supports filtering, batching, and sampling

### Collector Pipeline Components

#### Receivers

Receivers accept telemetry from external sources.

Examples:

* OTLP
* Prometheus
* Jaeger
* Zipkin

```text
Application
    |
    v
Receiver
```

---

#### Processors

Processors modify telemetry before exporting it.

Common processors:

* Batch
* Filter
* Sampling
* Resource enrichment

Example:

```text
Incoming telemetry
       |
       v
Batch Processor
       |
       v
Grouped telemetry
```

Batching improves performance by sending data in groups rather than one item at a time.

---

#### Exporters

Exporters send processed telemetry to a destination backend.

Examples:

* Prometheus
* Debug Console
* Jaeger
* Grafana Tempo
* Datadog

```text
Processed Data
      |
      v
Exporter
      |
      v
Backend
```

---

### Collector Architecture

```text
           RECEIVERS
                |
                v
           PROCESSORS
                |
                v
            EXPORTERS
                |
                v
           OBSERVABILITY
             BACKENDS
```

---

## 3. What is OTLP?

OTLP stands for **OpenTelemetry Protocol**.

It is the standard protocol used by OpenTelemetry components to exchange telemetry data.

OTLP supports:

| Protocol | Port |
| -------- | ---- |
| gRPC     | 4317 |
| HTTP     | 4318 |

### Why OTLP?

OTLP provides a common format for:

* Metrics
* Logs
* Traces

This allows applications and collectors to communicate using a consistent protocol regardless of programming language or backend.

### Example Flow

```text
Application
    |
    | OTLP
    v
OTEL Collector
    |
    v
Prometheus / Jaeger / Tempo
```

---

## 4. What are Distributed Traces?

A distributed trace follows a single request as it travels through multiple services in a system.

Instead of seeing only isolated logs or metrics, tracing shows the complete request journey.

### Example

A user opens a web application:

```text
User Request
     |
     v
API Gateway
     |
     v
Auth Service
     |
     v
Database
```

The entire journey forms a **trace**.

---

### What is a Span?

A span represents a single operation within a trace.

Examples:

* API request
* Authentication check
* Database query

A trace consists of multiple spans connected together.

```text
Trace
 |
 +-- Span 1 (API Gateway)
 |
 +-- Span 2 (Auth Service)
 |
 +-- Span 3 (Database Query)
```

---

### Span Components

Each span contains:

| Field               | Description                                |
| ------------------- | ------------------------------------------ |
| Trace ID            | Unique identifier for the entire request   |
| Span ID             | Unique identifier for a specific operation |
| Parent Span ID      | Links spans together                       |
| Start Time          | When operation started                     |
| End Time / Duration | How long operation took                    |
| Attributes          | Metadata about the operation               |

Example attributes:

```text
http.method = GET
http.status_code = 200
user.id = 123
db.system = mysql
```

---

### Example Distributed Trace

```text
Trace ID: abc123

Span 1
├─ API Gateway
├─ Duration: 20ms
│
└── Span 2
     ├─ Auth Service
     ├─ Duration: 10ms
     │
     └── Span 3
          ├─ Database Query
          └─ Duration: 50ms
```

Using traces, engineers can quickly identify where latency or failures occur within a request path.

---

### Key Takeaways

* OpenTelemetry is a vendor-neutral observability framework.
* OTEL collects **metrics, logs, and traces**.
* The OTEL Collector uses **Receivers → Processors → Exporters** pipelines.
* OTLP is the standard OpenTelemetry communication protocol.
* Distributed traces track a request across multiple services.
* A trace is composed of multiple spans connected through parent-child relationships.



---

### Task 2: Add the OpenTelemetry Collector
Create the collector configuration:

```bash
mkdir -p otel-collector
```

Create `otel-collector/otel-collector-config.yml`:
```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  debug:
    verbosity: detailed

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
    logs:
      receivers: [otlp]
      processors: [batch]
      exporters: [debug]
```

**What this config does:**
- **Receivers:** Accepts OTLP data via gRPC (4317) and HTTP (4318)
- **Processors:** Batches data before exporting (reduces overhead)
- **Exporters:**
  - Metrics go to a Prometheus-compatible endpoint on port 8889 (Prometheus scrapes this)
  - Traces and logs go to debug output (console) -- in production you would send these to Jaeger or Tempo

Add the collector to your `docker-compose.yml`:
```yaml
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    container_name: otel-collector
    ports:
      - "4317:4317"   # OTLP gRPC
      - "4318:4318"   # OTLP HTTP
      - "8889:8889"   # Prometheus exporter
    volumes:
      - ./otel-collector/otel-collector-config.yml:/etc/otelcol-contrib/config.yaml
    restart: unless-stopped
```

Add the OTEL Collector as a Prometheus scrape target in `prometheus.yml`:
```yaml
  - job_name: "otel-collector"
    static_configs:
      - targets: ["otel-collector:8889"]
```

Restart everything:
```bash
docker compose up -d
```

Verify the collector is running:
```bash
docker logs otel-collector 2>&1 | tail -5
```

<img width="2481" height="462" alt="image" src="https://github.com/user-attachments/assets/dde9136f-2c94-4936-941e-066ad129967f" />


Check Prometheus Targets -- you should now see `otel-collector` as UP.

<img width="2560" height="1272" alt="image" src="https://github.com/user-attachments/assets/f193445a-1563-4b66-b4e8-6572077726a6" />


---

### Task 3: Send Test Traces to the Collector
Send a sample OTLP trace using curl:

```bash
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": { "stringValue": "my-test-service" }
        }]
      },
      "scopeSpans": [{
        "spans": [{
          "traceId": "5b8efff798038103d269b633813fc60c",
          "spanId": "eee19b7ec3c1b174",
          "name": "test-span",
          "kind": 1,
          "startTimeUnixNano": "1544712660000000000",
          "endTimeUnixNano": "1544712661000000000",
          "attributes": [{
            "key": "http.method",
            "value": { "stringValue": "GET" }
          },
          {
            "key": "http.status_code",
            "value": { "intValue": "200" }
          }]
        }]
      }]
    }]
  }'
```

<img width="1370" height="642" alt="sample OTLP trace using curl" src="https://github.com/user-attachments/assets/c576dcc0-29ed-4722-83a1-52ebd1d3cdeb" />


Check the collector debug output to see the trace:
```bash
docker logs otel-collector 2>&1 | grep -A 10 "test-span"
```
<img width="2277" height="1107" alt="image" src="https://github.com/user-attachments/assets/91e3b010-6d0e-403f-b484-d64c36a65e8d" />


You should see the span details printed to the console. In a production setup, you would send these to a trace backend like Jaeger or Grafana Tempo for storage and visualization.

**Send OTLP metrics too:**
```bash
curl -X POST http://localhost:4318/v1/metrics \
  -H "Content-Type: application/json" \
  -d '{
    "resourceMetrics": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": { "stringValue": "my-test-service" }
        }]
      },
      "scopeMetrics": [{
        "metrics": [{
          "name": "test_requests_total",
          "sum": {
            "dataPoints": [{
              "asInt": "42",
              "startTimeUnixNano": "1544712660000000000",
              "timeUnixNano": "1544712661000000000"
            }],
            "aggregationTemporality": 2,
            "isMonotonic": true
          }
        }]
      }]
    }]
  }'
```

<img width="2262" height="952" alt="image" src="https://github.com/user-attachments/assets/57b6cd31-3f0f-4178-aba1-77fb3e536682" />


Now query it in Prometheus:
```promql
test_requests_total
```

<img width="1171" height="187" alt="image" src="https://github.com/user-attachments/assets/ec936106-8552-458e-9a86-132b842a5465" />
<img width="2560" height="1272" alt="image" src="https://github.com/user-attachments/assets/87079b9c-1faf-42e2-b233-5758f2a41555" />

<img width="2560" height="1272" alt="image" src="https://github.com/user-attachments/assets/05266b05-4085-45ae-829b-7919f8bba4e6" />


The metric traveled: your curl command -> OTEL Collector (OTLP receiver) -> Prometheus exporter -> Prometheus scraped it. This is how OTEL bridges different telemetry formats.

---

### Task 4: Set Up Prometheus Alerting Rules
Alerts notify you when something is wrong. Prometheus evaluates alerting rules and fires alerts when conditions are met.

Create an alerting rules file `alert-rules.yml`:
```yaml
groups:
  - name: system-alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "CPU usage has been above 80% for more than 2 minutes. Current value: {{ $value }}%"

      - alert: HighMemoryUsage
        expr: (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 > 85
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Memory usage is above 85%. Current value: {{ $value }}%"

      - alert: ContainerDown
        expr: absent(container_last_seen{name="notes-app"})
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Container is down"
          description: "The notes-app container has not been seen for over 1 minute"

      - alert: TargetDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Scrape target is down"
          description: "{{ $labels.job }} target {{ $labels.instance }} is unreachable"

      - alert: HighDiskUsage
        expr: (1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Disk space running low"
          description: "Root filesystem usage is above 90%. Current value: {{ $value }}%"
```

**What each alert does:**
- `expr` -- the PromQL condition that triggers the alert
- `for` -- how long the condition must be true before firing (avoids flapping)
- `labels` -- metadata for routing (severity: warning vs critical)
- `annotations` -- human-readable description

Update `prometheus.yml` to load the rules:
```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/alert-rules.yml

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node-exporter"
    static_configs:
      - targets: ["node-exporter:9100"]

  - job_name: "cadvisor"
    static_configs:
      - targets: ["cadvisor:8080"]

  - job_name: "otel-collector"
    static_configs:
      - targets: ["otel-collector:8889"]
```

Mount the rules file in `docker-compose.yml` under the Prometheus service:
```yaml
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./alert-rules.yml:/etc/prometheus/alert-rules.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
    restart: unless-stopped
```

Restart Prometheus:
```bash
docker compose up -d prometheus
```

<img width="2557" height="1282" alt="image" src="https://github.com/user-attachments/assets/f73af938-7cf8-4def-b0ad-08625a13069d" />


Check the rules in the Prometheus UI: go to Status > Rules. You should see all five alert rules listed.

<img width="2560" height="2077" alt="image" src="https://github.com/user-attachments/assets/a65feea7-bbaf-4af1-81e7-dcb9f3b1dc21" />
<img width="2556" height="717" alt="image" src="https://github.com/user-attachments/assets/83fe15fb-766e-4094-bdaa-bd60ea50f445" />


Go to Alerts -- they should be in `inactive` state (green). If any condition is true, the alert moves to `pending`, then `firing` after the `for` duration.

<img width="2560" height="2077" alt="image" src="https://github.com/user-attachments/assets/2d470f06-929d-473b-85f5-160ac6bae1e2" />
<img width="2557" height="720" alt="image" src="https://github.com/user-attachments/assets/90d4fd06-d2ee-4e40-a2ad-ea2f1c5dc085" />


**Test it:** Stop the notes-app container and watch the `TargetDown` alert fire:
```bash
docker compose stop notes-app
```
<img width="1122" height="685" alt="stop notes-app-1" src="https://github.com/user-attachments/assets/3d1deb10-2247-4b78-a446-29a5f377a0ff" />

<img width="2557" height="672" alt="image" src="https://github.com/user-attachments/assets/948b46de-6536-45c5-93e8-11e20795b606" />
<img width="2560" height="1762" alt="image" src="https://github.com/user-attachments/assets/120071d8-b91d-4f1d-b173-8906e0cf5bfe" />


Wait 1-2 minutes, then check Alerts in the Prometheus UI. Start it back up when done:
```bash
docker compose start notes-app
```
<img width="1125" height="71" alt="image" src="https://github.com/user-attachments/assets/3c6f89e3-e607-490f-8535-5a4278aa48e3" />
<img width="2552" height="672" alt="image" src="https://github.com/user-attachments/assets/023e83ad-75d0-4560-bebf-dac54a8521b4" />


---

### Task 5: Set Up Grafana Alerts
Grafana can also evaluate alerts and send notifications to Slack, email, PagerDuty, and more.

1. **Create a contact point:**
   - Go to Alerting > Contact points > Add contact point
   - Name: "DevOps Team"
   - Integration: Choose email (or Slack webhook if you have one)
   - For email: just enter your email address
   - Save
  
  <img width="2557" height="1127" alt="image" src="https://github.com/user-attachments/assets/a7e7293d-a4c3-4629-bd2e-b9d7a3fe278c" />


2. **Create an alert rule in Grafana:**
   - Go to Alerting > Alert rules > New alert rule
   - Name: "High Container Memory"
   - Query: `container_memory_usage_bytes{name="notes-app"} / 1024 / 1024`
   - Condition: IS ABOVE 100 (fire if container uses more than 100MB)
   - Evaluation: every 1m, for 2m
   - Add label: severity = warning
   - Link to the "DevOps Team" contact point
   - Save

<img width="1920" height="3465" alt="New-alert-rule-Alert-rules-Alerting-Grafana" src="https://github.com/user-attachments/assets/eb8c9535-38ca-41b4-ae4c-db9f07331baa" />


3. **Create a notification policy:**
   - Go to Alerting > Notification policies
   - Set the default contact point to "DevOps Team"
   - Add a nested policy: match label `severity=critical` -> route to a different contact point (or the same one with different settings)
  
  <img width="1920" height="912" alt="image" src="https://github.com/user-attachments/assets/94606d54-16bc-4c1d-8bd7-19295b8f6ee5" />


4. **View alert state:**
   - Go to Alerting > Alert rules
   - You should see your rule in Normal, Pending, or Firing state

<img width="2560" height="1601" alt="image" src="https://github.com/user-attachments/assets/27e10ee6-984d-44c4-aa70-4bb489c19cb6" />



**Document:** What is the difference between Prometheus alerts and Grafana alerts? When would you use each?

| Feature             | Prometheus Alerts         | Grafana Alerts         |
| ------------------- | ------------------------- | ---------------------- |
| Configuration       | YAML files                | UI-based               |
| Evaluation engine   | Prometheus                | Grafana                |
| Notification system | Alertmanager              | Contact points         |
| Best for            | Infrastructure monitoring | Dashboard-based alerts |
| Complexity          | Medium                    | Easy                   |
| Scalability         | High                      | Medium                 |

---

### Task 6: Review the Full Stack Architecture
Your observability stack now covers all three pillars. Map out what you have built:

```
                    METRICS PIPELINE
[Node Exporter] -----> [Prometheus] -----> [Grafana Dashboards]
[cAdvisor] ----------> [Prometheus] -----> [Grafana Dashboards]
[OTEL Collector:8889]> [Prometheus] -----> [Grafana Dashboards]
                                    -----> [Alert Rules -> Notifications]

                    LOGS PIPELINE
[Docker Containers] -> [Promtail] -> [Loki] -> [Grafana Explore/Dashboards]

                    TRACES PIPELINE
[curl/App OTLP] -----> [OTEL Collector] -> [Debug Output / Future: Jaeger/Tempo]
```

**Services running:**

| Service | Port | Purpose |
|---------|------|---------|
| Prometheus | 9090 | Metrics storage and querying |
| Node Exporter | 9100 | Host system metrics |
| cAdvisor | 8080 | Container metrics |
| Grafana | 3000 | Visualization and alerting |
| Loki | 3100 | Log storage |
| Promtail | 9080 | Log collection agent |
| OTEL Collector | 4317/4318/8889 | Telemetry collection |
| Notes App | 8000 | Sample application |

Verify all services are running:
```bash
docker compose ps
```

All 8 containers should be healthy and running.

<img width="2456" height="235" alt="image" src="https://github.com/user-attachments/assets/da75e860-ca5d-401a-97ae-330a37e22446" />


---

# Documentation

#  1. OpenTelemetry Architecture (Core Concept)

OpenTelemetry Collector works using 3 building blocks:

---

## 🔹 Receivers (INPUT)

👉 “How data enters the collector”

Examples:

* OTLP (gRPC / HTTP)
* Prometheus scrape
* Jaeger / Zipkin (optional)

👉 In your setup:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:
```

✔ Accepts metrics/traces/logs from apps

---

## 🔹 Processors (MIDDLE LAYER)

👉 “How data is transformed before sending”

Examples:

* batch (groups data)
* memory limiter
* filtering
* attributes enrichment

👉 In your setup:

```yaml
processors:
  batch:
```

✔ Reduces load + improves performance

---

## 🔹 Exporters (OUTPUT)

👉 “Where data goes”

Examples:

* Prometheus
* Loki
* Jaeger / Tempo
* Debug logs

👉 In your setup:

```yaml
exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  debug:
```

✔ Sends processed telemetry to storage systems

---

##  Full Flow

```text
App → Receiver → Processor → Exporter → Backend
```

---

#  2. Your OTEL Collector Config 

Here is your config with meaning:

---

##  Receivers

```yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:
```

✔ Accepts telemetry from:

* Notes App (future instrumentation)
* curl / test clients

---

##  Processors

```yaml
processors:
  batch:
```

✔ Groups telemetry → improves performance
✔ Prevents overload

---

##  Exporters

```yaml
exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  debug:
```

✔ Prometheus scrapes metrics from:

```
otel-collector:8889/metrics
```

✔ Debug exporter prints logs in container logs

---

##  Pipelines

### Metrics pipeline

```yaml
metrics:
  receivers: [otlp]
  processors: [batch]
  exporters: [prometheus, debug]
```

✔ Converts OTLP → Prometheus format

---

### Traces pipeline

```yaml
traces:
  receivers: [otlp]
  processors: [batch]
  exporters: [debug]
```

✔ Currently debug only (no Jaeger/Tempo yet)

---

### Logs pipeline

```yaml
logs:
  receivers: [otlp]
  processors: [batch]
  exporters: [debug]
```

✔ Logs not stored yet → only debug output

---

#  3. Your Alert Rules (Explained Properly)

Prometheus evaluates all rules using PromQL.

---

##  High CPU Usage

```yaml
expr: (100 - avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
```

✔ Checks CPU usage > 80%
✔ Trigger delay: 2 minutes

---

##  High Memory Usage

```yaml
expr: (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 > 85
```

✔ Checks RAM usage > 85%

---

##  Notes App Down

```yaml
expr: up{job="notes-app"} == 0
```

✔ If Prometheus cannot scrape app
✔ Means service is DOWN or unreachable

---

##  Target Down (generic)

```yaml
expr: up == 0
```

✔ Any scrape target is down

---

##  High Disk Usage

```yaml
expr: (1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 > 90
```

✔ Disk usage > 90%

---

#  4. Final Architecture (Your System)

This matches your diagram exactly:

---

##  METRICS PIPELINE

```text
Node Exporter ─────► Prometheus ─────► Grafana
cAdvisor      ─────► Prometheus ─────► Dashboards
OTEL Collector─────► Prometheus ─────► Alerts + Grafana
```

✔ Includes alerting layer

---

##  LOGS PIPELINE

```text
Docker Logs ─────► Promtail ─────► Loki ─────► Grafana Explore
```

✔ Centralized log system working

---

##  TRACES PIPELINE

```text
App / curl ─────► OTEL Collector ─────► Debug Exporter
                                 └────► (Future: Tempo / Jaeger)
```

✔ Tracing foundation ready

---

#  5. Important Reality Check (Why your system now works)

Your system is now correct because:

✔ All containers are running
✔ Prometheus scraping works
✔ Node Exporter working
✔ cAdvisor working
✔ OTEL exporter exposed on 8889
✔ Alerts firing correctly
✔ Grafana connected

---

#  Final Summary 
You built a complete **3-pillar observability stack**:

```text
Metrics + Logs + Traces = Full Observability Platform
```

---
```text
                        ┌──────────────────────────────┐
                        │        TRACES PIPELINE       │
                        └──────────────────────────────┘

     curl / App (OTLP)
              │
              ▼
   ┌──────────────────────┐
   │  OTEL Collector      │
   │  (4317 / 4318 / 8889)│
   └──────────────────────┘
        │            │
        │            ▼
        │     ┌───────────────┐
        │     │ Debug Exporter │
        │     └───────────────┘
        │
        ▼
┌──────────────────────┐
│ Tempo / Jaeger       │  (future backend)
└──────────────────────┘


────────────────────────────────────────────────────────


                        ┌──────────────────────────────┐
                        │        LOGS PIPELINE         │
                        └──────────────────────────────┘

┌──────────────────────┐
│ Docker Containers    │
└─────────┬────────────┘
          ▼
┌──────────────────────┐
│      Promtail        │
└─────────┬────────────┘
          ▼
┌──────────────────────┐
│        Loki          │
└─────────┬────────────┘
          ▼
┌──────────────────────────────┐
│ Grafana (Explore / Dashboards)│
└──────────────────────────────┘


────────────────────────────────────────────────────────


                        ┌──────────────────────────────┐
                        │       METRICS PIPELINE       │
                        └──────────────────────────────┘

┌──────────────────────┐     ┌──────────────────────┐
│ Node Exporter        │     │ cAdvisor             │
└─────────┬────────────┘     └─────────┬────────────┘
          │                            │
          └────────────┬──────────────┘
                       ▼
            ┌──────────────────────┐
            │     Prometheus       │
            │  (Scrape + Rules)    │
            └─────────┬────────────┘
                      │
        ┌─────────────┴─────────────┐
        ▼                           ▼
┌──────────────────┐     ┌──────────────────────┐
│ Grafana          │     │ Alert Rules Engine   │
│ Dashboards       │     │ (Prometheus Alerts)  │
└──────────────────┘     └─────────┬────────────┘
                                    ▼
                         ┌──────────────────────┐
                         │ Notifications        │
                         │ (Email / Slack etc.) │
                         └──────────────────────┘


────────────────────────────────────────────────────────


                    ┌──────────────────────────────┐
                    │        YOUR SERVICES         │
                    └──────────────────────────────┘

┌──────────────┐   ┌──────────────┐
│ Notes App    │   │ OTEL Export  │
│ (8000)       │──▶│ Metrics/Logs │
└──────────────┘   └──────────────┘


────────────────────────────────────────────────────────
                 OBSERVABILITY VISUALIZATION LAYER
────────────────────────────────────────────────────────

                ┌────────────────────────┐
                │        GRAFANA         │
                │ Dashboards + Alerts    │
                └────────────────────────┘

```
