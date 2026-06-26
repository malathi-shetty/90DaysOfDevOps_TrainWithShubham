# Day 77 -- Observability Project: Full Stack with Docker Compose

---

## Challenge Tasks

### Task 1: Clone and Launch the Reference Stack
Clone the reference repository that contains the complete observability setup:

```bash
git clone https://github.com/LondheShubham153/observability-for-devops.git
cd observability-for-devops
```

Examine the project structure:
```bash
tree -I 'node_modules|build|staticfiles|__pycache__'
```

```
observability-for-devops/
  docker-compose.yml                    # 8 services orchestrated together
  prometheus.yml                        # Prometheus scrape configuration
  alert-rules.yml                       # (you will add this)
  grafana/
    provisioning/
      datasources/datasources.yml       # Auto-provisioned: Prometheus + Loki
      dashboards/dashboards.yml         # Dashboard provisioning config
  loki/
    loki-config.yml                     # Loki storage and schema config
  promtail/
    promtail-config.yml                 # Docker log collection config
  otel-collector/
    otel-collector-config.yml           # OTLP receivers, processors, exporters
  notes-app/                            # Sample Django + React application
```

<img width="912" height="1142" alt="image" src="https://github.com/user-attachments/assets/49506ad4-9f50-40c6-9dd6-e5ff50d4abee" />



Launch the entire stack:
```bash
docker compose up -d
```

<img width="1127" height="222" alt="image" src="https://github.com/user-attachments/assets/8ec1fc63-60e1-48cc-b59f-2c9eaf4f5584" />


Wait for all containers to start:
```bash
docker compose ps
```

<img width="2121" height="222" alt="image" src="https://github.com/user-attachments/assets/d2888e30-88bc-45f5-bbe9-3d00ea6d6af7" />


All 8 services should show as running:

| Service | Port | Check |
|---------|------|-------|
| Prometheus | 9090 | `http://localhost:9090` |
| Node Exporter | 9100 | `curl http://localhost:9100/metrics \| head -5` |
| cAdvisor | 8080 | `http://localhost:8080` |
| Grafana | 3000 | `http://localhost:3000` (admin/admin) |
| Loki | 3100 | `curl http://localhost:3100/ready` |
| Promtail | 9080 | Internal only |
| OTEL Collector | 4317/4318 | `docker logs otel-collector` |
| Notes App | 8000 | `http://localhost:8000` |

---

### Task 2: Validate the Metrics Pipeline
Confirm Prometheus is scraping all targets:

1. Open `http://localhost:9090/targets`
2. Verify all 4 scrape jobs are UP:
   - `prometheus` (self-monitoring)
   - `node-exporter` (host metrics)
   - `docker` / `cadvisor` (container metrics)
   - `otel-collector` (OTLP metrics)


<img width="1920" height="968" alt="Prometheus" src="https://github.com/user-attachments/assets/fe7d2cf3-49e4-4835-9627-dfc70a741781" />



Run these validation queries:

### All targets are healthy
up

<img width="1920" height="912" alt="image" src="https://github.com/user-attachments/assets/a480df63-52bf-4649-968b-373955f7f717" />


### Host CPU usage
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

<img width="1920" height="912" alt="image" src="https://github.com/user-attachments/assets/5db92715-0896-4968-8d53-e6603ecf0052" />


### Memory usage
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

<img width="1920" height="912" alt="image" src="https://github.com/user-attachments/assets/baf99ef4-99dc-4adb-8ec3-0018d9ee66df" />


------

# NOTE: For below replace name with id since cadvisor label got changed now:

### Container CPU per container
rate(container_cpu_usage_seconds_total{id!=""}[5m]) * 100

<img width="1920" height="2174" alt="image" src="https://github.com/user-attachments/assets/4f31670a-c3fb-4a06-a3ed-d463e6fb66d8" />


### Top 3 memory-hungry containers
topk(3, container_memory_usage_bytes{id!=""})

<img width="1917" height="562" alt="image" src="https://github.com/user-attachments/assets/c5885c9e-b5f2-4e01-a546-c97bf6fc15f6" />



---

Compare the `prometheus.yml` from the reference repo with the one you built over days 73-76. Note the scrape jobs and intervals.

- Both the reference repo and my configuration are the same:

- `Global settings:`
| Setting             | Reference Repo | Your Setup | Result |
| ------------------- | -------------- | ---------- | ------ |
| scrape_interval     | 15s            | 15s        | ✔ Same |
| evaluation_interval | 15s            | 15s        | ✔ Same |

- `Scrape jobs:`

| Job                 | Target              | Status |
| ------------------- | ------------------- | ------ |
| `prometheus`        | localhost:9090      | ✔ Same |
| `node-exporter`     | node-exporter:9100  | ✔ Same |
| `docker` (cAdvisor) | cadvisor:8080       | ✔ Same |
| `otel-collector`    | otel-collector:8889 | ✔ Same |

> Both the reference repository and my Prometheus configuration are identical in structure. The global scrape_interval and evaluation_interval are set to 15s in both setups. Additionally, both configurations define the same scrape jobs: prometheus (self-monitoring), node-exporter (host metrics), docker/cAdvisor (container metrics), and otel-collector (tracing metrics endpoint). This confirms that my implementation from Days 73–76 has successfully converged with the reference observability architecture, ensuring full metric coverage and consistent scrape behavior across all services.

---

### Task 3: Validate the Logs Pipeline
Generate traffic so there are logs to see:

```bash
for i in $(seq 1 50); do
  curl -s http://localhost:8000 > /dev/null
  curl -s http://localhost:8000/api/ > /dev/null
done
```

Open Grafana (`http://localhost:3000`) and go to Explore:

1. Select Loki as the datasource
2. Run these LogQL queries:


# All container logs
{job="docker"}

<img width="1920" height="1658" alt="image" src="https://github.com/user-attachments/assets/de08a70e-352f-4edf-b815-5817cc2c60bf" />


# Only notes-app logs
{job="docker"} |= "notes-app"

<img width="1920" height="1735" alt="image" src="https://github.com/user-attachments/assets/ae1b83eb-3163-4262-999f-7ecfced48219" />


# Errors across all containers
{job="docker"} |= "error"

<img width="1920" height="1735" alt="image" src="https://github.com/user-attachments/assets/238aec62-a856-43b3-9c39-7a3672399d10" />


# HTTP request logs from the app
{container_name="notes-app"} |= "GET"

{job="docker"} |= "GET"

<img width="1920" height="1735" alt="image" src="https://github.com/user-attachments/assets/0799d814-ecdd-4df6-b481-540b457c44b4" />

{job="docker"} |= "/api"

<img width="1920" height="1735" alt="image" src="https://github.com/user-attachments/assets/ad8b7c76-ed18-448b-b013-c862a989d33a" />


# Rate of log lines per container
sum by (container_name) (rate({job="docker"}[5m]))

<img width="1920" height="1250" alt="image" src="https://github.com/user-attachments/assets/ea8187e9-9375-4170-aa7f-b548305b8417" />


```

Check Promtail's targets to see which log files it is watching:
```bash
curl -s http://localhost:9080/targets | head -30
```
<img width="1840" height="687" alt="image" src="https://github.com/user-attachments/assets/bdbc9170-51fe-4bdf-a827-e920195b5e1b" />


- Compare `promtail/promtail-config.yml` from the reference repo with yours from Day 75.
Replaced `static_configs` with `docker_sd_configs` to collect container-specific labels.

| Area               | Reference repo                           | Your Day 75 config                                                      |
| ------------------ | ---------------------------------------- | ----------------------------------------------------------------------- |
| Log discovery      | `docker_sd_configs`                      | `static_configs (__path__)` (earlier) + later partial Docker SD attempt |
| Container labeling | Uses Docker metadata (`__meta_docker_*`) | Partial / inconsistent relabeling                                       |
| Log parsing        | `pipeline_stages: docker`                | Same                                                                    |
| Positions file     | `/tmp/positions.yaml`                    | `/var/log/promtail/positions.yaml` (caused errors)                      |
| Stability          | Clean + stateless                        | File permission + missing path issues                                   |


---

### Task 4: Validate the Traces Pipeline
Send OTLP traces to the collector:

```bash
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": { "stringValue": "notes-app" }
        }]
      },
      "scopeSpans": [{
        "spans": [{
          "traceId": "aaaabbbbccccdddd1111222233334444",
          "spanId": "1111222233334444",
          "name": "GET /api/notes",
          "kind": 2,
          "startTimeUnixNano": "1700000000000000000",
          "endTimeUnixNano": "1700000000150000000",
          "attributes": [{
            "key": "http.method",
            "value": { "stringValue": "GET" }
          },
          {
            "key": "http.route",
            "value": { "stringValue": "/api/notes" }
          },
          {
            "key": "http.status_code",
            "value": { "intValue": "200" }
          }],
          "status": { "code": 1 }
        },
        {
          "traceId": "aaaabbbbccccdddd1111222233334444",
          "spanId": "5555666677778888",
          "parentSpanId": "1111222233334444",
          "name": "SELECT notes FROM database",
          "kind": 3,
          "startTimeUnixNano": "1700000000020000000",
          "endTimeUnixNano": "1700000000120000000",
          "attributes": [{
            "key": "db.system",
            "value": { "stringValue": "sqlite" }
          },
          {
            "key": "db.statement",
            "value": { "stringValue": "SELECT * FROM notes" }
          }]
        }]
      }]
    }]
  }'
```

This simulates a two-span trace: an HTTP request that calls a database query.

Check the debug output:
```bash
docker logs otel-collector 2>&1 | grep -A 20 "GET /api/notes"
```

You should see both spans with their attributes, the parent-child relationship, and timing data.

<img width="1442" height="485" alt="image" src="https://github.com/user-attachments/assets/c269773d-b66c-4745-9cc7-8d1bf7052346" />


Compare `otel-collector/otel-collector-config.yml` from the reference repo with yours from Day 76.

| Feature | Reference Repo           | My Day 76           |
| ------- | ------------------------ | ------------------- |
| Metrics | Prometheus + enrichments | Prometheus exporter |
| Logs    | Structured / backend     | Debug output        |
| Traces  | Tempo/Jaeger storage     | Console logs only   |


---

### Task 5: Build a Unified "Production Overview" Dashboard
Create a single Grafana dashboard that gives a complete picture of your system.

Go to Dashboards > New Dashboard. Add these panels:

**Row 1 -- System Health (Node Exporter + Prometheus):**

| Panel | Type | Query |
|-------|------|-------|
| CPU Usage | Gauge | `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` |
| Memory Usage | Gauge | `(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100` |
| Disk Usage | Gauge | `(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100` |
| Targets Up | Stat | `sum(up)` / `count(up)` |

**Row 2 -- Container Metrics (cAdvisor):**

| Panel | Type | Query |
|-------|------|-------|
| Container CPU | Time series | `rate(container_cpu_usage_seconds_total{name!=""}[5m]) * 100` (legend: `{{name}}`) |
| Container Memory | Bar chart | `container_memory_usage_bytes{name!=""} / 1024 / 1024` (legend: `{{name}}`) |
| Container Count | Stat | `count(container_last_seen{name!=""})` |

**Row 3 -- Application Logs (Loki):**

| Panel | Type | Query (Loki datasource) |
|-------|------|-------|
| App Logs | Logs | `{container_name="notes-app"}` |
| Error Rate | Time series | `sum(rate({job="docker"} |= "error" [5m]))` |
| Log Volume | Time series | `sum by (container_name) (rate({job="docker"}[5m]))` |

**Row 4 -- Service Overview:**

| Panel | Type | Query |
|-------|------|-------|
| Prometheus Scrape Duration | Time series | `prometheus_target_interval_length_seconds{quantile="0.99"}` |
| OTEL Metrics Received | Stat | `otelcol_receiver_accepted_metric_points` (if available) | up{job="otel-collector"}

Save the dashboard as "Production Overview -- Observability Stack".

Set the dashboard time range to "Last 30 minutes" and enable auto-refresh (every 10s).

<img width="2560" height="2908" alt="image" src="https://github.com/user-attachments/assets/67f35af0-34fa-42e7-b69c-1b6004f54548" />


---

### Task 6: Compare Your Stack with the Reference and Document
Now compare what you built over days 73-76 with the reference repository.

| Component | Your Version | Reference Repo | Differences |
|-----------|-------------|----------------|-------------|
| `prometheus.yml` | Day 73-74 | Root directory | Compare scrape jobs |
| `loki-config.yml` | Day 75 | `loki/` directory | Compare storage config |
| `promtail-config.yml` | Day 75 | `promtail/` directory | Compare scrape configs |
| `otel-collector-config.yml` | Day 76 | `otel-collector/` directory | Compare pipelines |
| `datasources.yml` | Day 74 | `grafana/provisioning/` | Compare provisioned sources |
| `docker-compose.yml` | Days 73-76 | Root directory | Compare all 8 services |

**Reflect and document:**

1. Map each observability concept to the day you learned it:

| Day | What You Built |
|-----|---------------|
| 73 | Prometheus, PromQL, metrics fundamentals |
| 74 | Node Exporter, cAdvisor, Grafana dashboards |
| 75 | Loki, Promtail, LogQL, log-metric correlation |
| 76 | OTEL Collector, traces, alerting rules |
| 77 | Full stack integration, unified dashboard |

2. What would you add for production?
   - Alertmanager for routing alerts to Slack/PagerDuty
   - Grafana Tempo for trace storage (replacing debug exporter)
   - HTTPS/TLS for all endpoints
   - Authentication on Grafana and Prometheus
   - Log retention policies and storage limits
   - High availability (multiple Prometheus/Loki replicas)

3. How does this stack compare to managed solutions like Datadog, New Relic, or AWS CloudWatch?


      | My Stack           | Managed Solutions     |
      | ------------------ | --------------------- |
      | Complex setup      | Easy setup            |
      | Cheaper at scale   | Expensive at scale    |
      | Full control       | Limited control       |
      | Self-managed       | Fully managed         |
      | Flexible           | All-in-one            |


# Day 77 – Observability Stack Comparison and Reflection

## Configuration Comparison

| Component                   | My Version                                                                                                   | Reference Repository                                             | Differences                                                                                                              |
| --------------------------- | ------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `prometheus.yml`            | Added scrape jobs for Prometheus, Node Exporter, cAdvisor and OTEL Collector                                 | Similar                                                          | No significant differences. Scrape jobs matched the reference.                                                           |
| `loki-config.yml`           | Same local filesystem storage configuration                                                                  | Similar                                                          | No functional differences.                                                                                               |
| `promtail-config.yml`       | Used `docker_sd_configs` for Docker service discovery                                                        | Used file-based scraping (`static_configs` with Docker log path) | Switched to Docker service discovery, which automatically discovers containers and adds metadata like `container_name`.  |
| `otel-collector-config.yml` | `debug` exporter with `verbosity: detailed`                                                                  | `debug` exporter with `verbosity: basic`                         | Changed verbosity to `detailed` so spans, attributes and parent-child relationships are visible during trace validation. |
| `datasources.yml`           | Provisioned Prometheus and Loki datasources                                                                  | Similar                                                          | No significant differences.                                                                                              |
| `docker-compose.yml`        | Included Prometheus, Grafana, Node Exporter, cAdvisor, Loki, Promtail, OpenTelemetry Collector and Notes App | Same services                                                    | Minor differences in configuration while troubleshooting Promtail and Docker service discovery.                          |

## Observability Concepts Learned

| Day | What I Built                                                               |
| --- | -------------------------------------------------------------------------- |
| 73  | Prometheus, PromQL and metrics fundamentals                                |
| 74  | Node Exporter, cAdvisor and Grafana dashboards                             |
| 75  | Loki, Promtail, LogQL and log collection                                   |
| 76  | OpenTelemetry Collector, OTLP pipelines, traces and alerting basics        |
| 77  | Integrated metrics, logs and traces into a unified observability dashboard |

## What I Would Add for Production

* Alertmanager for routing alerts to Slack, Microsoft Teams or PagerDuty.
* Grafana Tempo for persistent trace storage instead of the Debug exporter.
* TLS/HTTPS for Prometheus, Grafana, Loki and OTEL Collector.
* Authentication and role-based access control for Grafana and Prometheus.
* Log retention policies and storage limits for Loki.
* High Availability deployment with multiple Prometheus and Loki instances.
* Long-term metric storage using Thanos or Cortex.
* Backup strategy for Grafana dashboards and Prometheus data.

## Comparison with Managed Observability Platforms

| Open Source Stack                           | Managed Platforms (Datadog, New Relic, AWS CloudWatch) |
| ------------------------------------------- | ------------------------------------------------------ |
| Free and self-hosted                        | Commercial SaaS                                        |
| Full control over infrastructure and data   | Managed infrastructure with minimal maintenance        |
| Requires manual setup, scaling and upgrades | Automatic scaling, upgrades and maintenance            |
| Highly customizable                         | Rich built-in integrations and advanced analytics      |
| Lower cost for long-running deployments     | Easier to operate but incurs subscription costs        |

## Summary

Over Days 73–77, I built a complete observability stack using Prometheus, Grafana, Node Exporter, cAdvisor, Loki, Promtail and the OpenTelemetry Collector. I successfully collected infrastructure metrics, container metrics, application logs and distributed traces, and visualized them in Grafana through a unified "Production Overview" dashboard. This project demonstrated the three pillars of observability—metrics, logs and traces—and how they work together to monitor and troubleshoot applications.


**Clean up when done:**
```bash
docker compose down -v
```

The `-v` flag removes named volumes (Prometheus data, Grafana data, Loki data). Only use this if you are done exploring.

<img width="1111" height="310" alt="image" src="https://github.com/user-attachments/assets/bc0977c6-6be4-4b06-b9c0-ed27ebb22d82" />


---


# Documentation

## Architecture Diagram

```text
                                +--------------------+
                                |    Notes App       |
                                | (Flask Container)  |
                                +---------+----------+
                                          |
             +----------------------------+----------------------------+
             |                            |                            |
         Metrics                      Logs                        Traces
             |                            |                            |
             |                            |                            |
             v                            v                            v
+-----------------------+       +----------------+        +-----------------------+
|    OTEL Collector     |       |   Promtail     |        |   OTEL Collector      |
|  Receives OTLP        |       | Reads Docker   |        | Receives OTLP Traces  |
|  Metrics              |       | Container Logs |        |                       |
+-----------+-----------+       +--------+-------+        +-----------+-----------+
            |                            |                            |
            |                            |                            |
            v                            v                            v
     Prometheus Exporter             Loki                     Debug Exporter
            |                            |                            |
            +-------------+--------------+                            |
                          |                                           |
                          |                                           |
                          v                                           |
                     Prometheus                                        |
                          |                                           |
                          +-------------------+-----------------------+
                                              |
                                              |
                                              v
                                         Grafana
                           Dashboards (Metrics + Logs)
```

---

# Components Used

| Service                 | Purpose                     |
| ----------------------- | --------------------------- |
| Prometheus              | Metrics collection          |
| Node Exporter           | Host metrics                |
| cAdvisor                | Docker container metrics    |
| Grafana                 | Visualization               |
| Loki                    | Log storage                 |
| Promtail                | Log collection              |
| OpenTelemetry Collector | Metrics/Logs/Trace pipeline |
| Notes App               | Demo application            |

---

# Configuration Comparison

| File                      | My Configuration                                                   | Reference Repository  | Difference                                                    |
| ------------------------- | ------------------------------------------------------------------ | --------------------- | ------------------------------------------------------------- |
| docker-compose.yml        | 8 services with monitoring network                                 | Same                  | Minor volume/path differences                                 |
| prometheus.yml            | Prometheus + Node Exporter + cAdvisor + OTEL Collector scrape jobs | Same                  | No major differences                                          |
| loki-config.yml           | Local filesystem storage                                           | Same                  | None                                                          |
| promtail-config.yml       | Docker Service Discovery (`docker_sd_configs`)                     | Static file discovery | Switched to Docker SD for automatic container discovery       |
| otel-collector-config.yml | Metrics → Prometheus, Traces → Debug, Logs → Debug                 | Same                  | Changed `debug` exporter verbosity from `basic` to `detailed` |
| datasources.yml           | Prometheus and Loki provisioned automatically                      | Same                  | None                                                          |

---

# Production Readiness Improvements

If this stack were deployed in production, I would add:

* Alertmanager for alert routing (Slack, Email, PagerDuty)
* Grafana Tempo for distributed trace storage
* Persistent object storage for Loki
* HTTPS/TLS for all services
* Authentication and RBAC
* Long-term Prometheus storage (Thanos/Mimir)
* Log retention policies
* High Availability for Prometheus, Loki and Grafana
* Backup strategy for Grafana dashboards
* Centralized secret management
* Kubernetes deployment with Helm

---

# Key Learnings (Days 73–77)

| Day    | Topic                    | Outcome                                                              |
| ------ | ------------------------ | -------------------------------------------------------------------- |
| Day 73 | Prometheus               | Learned metrics collection and PromQL                                |
| Day 74 | Node Exporter & cAdvisor | Monitored host and container resources                               |
| Day 75 | Loki & Promtail          | Centralized Docker logs using LogQL                                  |
| Day 76 | OpenTelemetry            | Collected OTLP metrics, logs and traces                              |
| Day 77 | Complete Stack           | Integrated metrics, logs and traces into a unified Grafana dashboard |

---

# What I Built

* Docker-based observability stack
* Prometheus metrics collection
* Host monitoring using Node Exporter
* Container monitoring using cAdvisor
* Log aggregation with Loki
* Docker log collection using Promtail
* OTLP metrics/traces ingestion using OpenTelemetry Collector
* Grafana dashboards for metrics and logs
* Production Overview dashboard combining system, container and application monitoring

---

# Production Overview Dashboard

The dashboard includes four sections:

### System Health

* CPU Usage
* Memory Usage
* Disk Usage
* Prometheus Targets Up

### Container Metrics

* Container CPU Usage
* Container Memory Usage
* Running Containers

### Application Logs

* Live Notes App logs
* Error log count
* Log volume by container

### Service Overview

* Prometheus scrape duration
* OpenTelemetry metrics (when available)

---

# Observability Flow

```text
Application
   │
   ├── Metrics ─────────────► OTEL Collector ─► Prometheus ─► Grafana
   │
   ├── Logs ────────────────► Promtail ───────► Loki ───────► Grafana
   │
   └── Traces ──────────────► OTEL Collector ─► Debug Exporter
```

---

# Technologies Used

* Docker Compose
* Prometheus
* Grafana
* Loki
* Promtail
* OpenTelemetry Collector
* Node Exporter
* cAdvisor
* Flask

---

# Configuration Files Included

```
docker-compose.yml
prometheus.yml
loki/loki-config.yml
promtail/promtail-config.yml
otel-collector/otel-collector-config.yml
grafana/provisioning/datasources/datasources.yml
```

