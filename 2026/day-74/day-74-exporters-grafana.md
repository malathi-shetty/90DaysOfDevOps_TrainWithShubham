<img width="1647" height="165" alt="image" src="https://github.com/user-attachments/assets/6fb4dc20-3060-494d-932f-e9e0f8ed3362" /># Day 74 -- Node Exporter, cAdvisor, and Grafana Dashboards

---

## Challenge Tasks

### Task 1: Add Node Exporter for Host Metrics
Node Exporter exposes Linux system metrics (CPU, memory, disk, filesystem, network) in Prometheus format.

Update your `docker-compose.yml` from Day 73 -- add the Node Exporter service:
```yaml
  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--path.rootfs=/rootfs'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    restart: unless-stopped
```

**Why these volume mounts?**
- `/proc` -- kernel and process information (CPU stats, memory info)
- `/sys` -- hardware and driver details
- `/` -- filesystem usage (disk space)

All mounted read-only (`ro`) -- Node Exporter only reads, never modifies.

Add it as a scrape target in `prometheus.yml`:
```yaml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node-exporter"
    static_configs:
      - targets: ["node-exporter:9100"]
```

Restart the stack:
```bash
docker compose up -d
```


Verify Node Exporter is healthy:
```bash
curl -s http://localhost:9100/metrics | grep -q node_exporter_build_info && echo OK
```

<img width="1607" height="52" alt="image" src="https://github.com/user-attachments/assets/31e2872b-3025-4e8c-99ac-a62d88a62fb7" />


Check Prometheus Targets page -- `node-exporter` should show as `UP`.

<img width="1916" height="927" alt="image" src="https://github.com/user-attachments/assets/ffefea03-1988-40f8-a9f7-52c49873af1b" />
<img width="1920" height="2320" alt="image" src="https://github.com/user-attachments/assets/4868bcac-63c2-47a9-9933-ce3e83a3f32e" />


Run these queries in Prometheus to see host metrics:

# CPU: percentage of time spent idle (per core)
node_cpu_seconds_total{mode="idle"}

<img width="1920" height="1356" alt="image" src="https://github.com/user-attachments/assets/60865730-7727-446b-8ba6-e8ca5f2ec5ae" />


# Memory: total vs available
node_memory_MemTotal_bytes
node_memory_MemAvailable_bytes

<img width="1920" height="1297" alt="image" src="https://github.com/user-attachments/assets/5e330e60-5191-4dfb-acbe-b13a82cadca4" />


# Memory usage percentage
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

`Out of 100% RAM: ~10% is in use` 

<img width="1920" height="1252" alt="image" src="https://github.com/user-attachments/assets/badab2d9-eeec-4c6b-bf6a-a979f9c06f01" />


# Disk: filesystem usage percentage
(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100

`root filesystem (/) is using approximately 5.60% disk space`

<img width="1920" height="2044" alt="image" src="https://github.com/user-attachments/assets/187a1e46-c8dd-463c-b520-767f046b4578" />


# Network: bytes received per second
rate(node_network_receive_bytes_total[5m])

`Network receive rate on eth0 is approximately 48 bytes per second`

<img width="1920" height="1287" alt="image" src="https://github.com/user-attachments/assets/a780c466-27e8-4512-8267-99b256a201db" />


---

### Task 2: Add cAdvisor for Container Metrics
cAdvisor (Container Advisor) monitors resource usage and performance of running Docker containers.

Add it to your `docker-compose.yml`:
```yaml
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    restart: unless-stopped
```

**Why these volume mounts?**
- Docker socket (`docker.sock`) -- lets cAdvisor discover and query running containers
- `/sys` -- kernel-level container stats (cgroups)
- `/var/lib/docker/` -- container filesystem information

Add cAdvisor as a Prometheus scrape target:
```yaml
  - job_name: "cadvisor"
    static_configs:
      - targets: ["cadvisor:8080"]
```

Restart and verify:
```bash
docker compose up -d
```

Open `http://localhost:8081` to see the cAdvisor web UI. Click on Docker Containers to see per-container stats.

<img width="1969" height="6207" alt="cAdvisor" src="https://github.com/user-attachments/assets/027be3fd-d186-4f30-a3a5-b533c0e75d53" />


Run these queries in Prometheus:

# CPU usage per container (in seconds)
rate(container_cpu_usage_seconds_total{id!="/", id=~".*docker.*"}[5m])

<img width="1920" height="2285" alt="image" src="https://github.com/user-attachments/assets/df21ff14-d1d1-4bf0-990c-4051d77dc2e6" />


# Memory usage per container
container_memory_usage_bytes{id!="/", id=~".*docker.*"}

<img width="1920" height="2767" alt="image" src="https://github.com/user-attachments/assets/26256ca4-dc92-4546-8ed1-ac029f6ba489" />


# Network received bytes per container
rate(container_network_receive_bytes_total{name!=""}[5m]) 

<img width="1920" height="2443" alt="image" src="https://github.com/user-attachments/assets/f524ebb9-c55c-4a82-9cde-786f58ed2698" />



# Which container is using the most memory?
topk(3, container_memory_usage_bytes{id!="/", id=~".*docker.*"})

<img width="1920" height="1676" alt="image" src="https://github.com/user-attachments/assets/306ab024-0911-4381-8f88-8eebd938bf25" />



The {name!=""} filter was not working because the `name` label is not present in the metric. Instead, {id!="/"} is used to remove aggregated/system-level entries and show container-level data.

**Document:** What is the difference between Node Exporter and cAdvisor? When would you use each?

| Feature  | Node Exporter         | cAdvisor              |
| -------- | --------------------- | --------------------- |
| Level    | Host (machine)        | Container             |
| Scope    | Entire system         | Individual containers |
| Metrics  | node_*                | container_*           |
| Focus    | Infrastructure health | Application workload  |
| Use case | Server monitoring     | Docker monitoring     |

#  When to use what?

### Use Node Exporter when:

* You care about **server health**
* CPU/RAM/disk issues on machine level
* You manage VMs or cloud instances

---

### Use cAdvisor when:

* You run **Docker containers or microservices**
* You want to know **which app is slow or heavy**
* You debug container crashes or memory leaks

---

#  In real DevOps stacks

You usually use BOTH:

✔ Node Exporter → infrastructure layer
✔ cAdvisor → application/container layer
✔ Prometheus → metrics storage
✔ Grafana → visualization



### Task 3: Set Up Grafana
Grafana is the visualization layer. It connects to Prometheus (and later Loki) and lets you build dashboards, set alerts, and share views with your team.

Add Grafana to your `docker-compose.yml`:
```yaml
  grafana:
    image: grafana/grafana-enterprise:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    restart: unless-stopped
```

Add the volume at the bottom of your compose file:
```yaml
volumes:
  prometheus_data:
  grafana_data:
```

Restart:
```bash
docker compose up -d
```

Open `http://localhost:3000`. Log in with `admin` / `admin123`.

**Add Prometheus as a datasource:**
1. Go to Connections > Data Sources > Add data source
2. Select Prometheus
3. Set URL to `http://prometheus:9090` (use the container name, not localhost -- they are on the same Docker network)
4. Click Save & Test -- you should see "Successfully queried the Prometheus API"


<img width="1912" height="795" alt="image" src="https://github.com/user-attachments/assets/066df68e-8626-49e7-9d1e-20614f048aa5" />
<img width="1920" height="3284" alt="image" src="https://github.com/user-attachments/assets/5f1aa348-1f6c-46b7-ba3d-2df028b1bc1d" />
<img width="1911" height="962" alt="image" src="https://github.com/user-attachments/assets/25970999-1e90-4d97-8c2d-1a07fbc34a40" />


---

### Task 4: Build Your First Dashboard
Create a dashboard that shows the health of your system at a glance.

1. Go to Dashboards > New Dashboard > Add Visualization
2. Select Prometheus as the datasource

**Panel 1 -- CPU Usage (Gauge):**
```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```
- Visualization: Gauge
- Title: "CPU Usage %"
- Set thresholds: green < 60, yellow < 80, red >= 80


**Panel 2 -- Memory Usage (Gauge):**
```promql
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100
```
- Visualization: Gauge
- Title: "Memory Usage %"

**Panel 3 -- Container CPU Usage (Time Series):**
```promql
rate(container_cpu_usage_seconds_total{id!="/", id=~".*docker.*"}[5m])
```
- Visualization: Time series
- Title: "Container CPU Usage"
- Legend: `{{name}}`

**Panel 4 -- Container Memory Usage (Bar Chart):**
```promql
container_memory_usage_bytes{id!="/", id=~".*docker.*"}
```
- Visualization: Bar chart
- Title: "Container Memory (MB)"
- Legend: `{{name}}`

**Panel 5 -- Disk Usage (Stat):**
```promql
(1 - node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100
```
- Visualization: Stat
- Title: "Disk Usage %"

Save the dashboard as "DevOps Observability Overview".

<img width="2560" height="1296" alt="image" src="https://github.com/user-attachments/assets/9d82ff33-bdc8-4a7d-a214-aa45843fbcac" />



---

### Task 5: Auto-Provision Datasources with YAML
In production, you do not click through the UI to add datasources. You provision them with configuration files so the setup is repeatable.

Create the provisioning directory structure:
```bash
mkdir -p grafana/provisioning/datasources
mkdir -p grafana/provisioning/dashboards
```

<img width="960" height="157" alt="image" src="https://github.com/user-attachments/assets/b1e14470-7900-4420-b8bd-f82a68eced8d" />


Create `grafana/provisioning/datasources/datasources.yml`:
```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

Update the Grafana service in `docker-compose.yml` to mount the provisioning directory:
```yaml
  grafana:
    image: grafana/grafana-enterprise:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    restart: unless-stopped
```

Restart Grafana:
```bash
docker compose up -d grafana
```

Check Connections > Data Sources -- Prometheus should already be there without any manual setup.
<img width="1841" height="971" alt="image" src="https://github.com/user-attachments/assets/5c6c057d-1272-4d2d-9c09-fa727a231a51" />

<img width="2557" height="757" alt="image" src="https://github.com/user-attachments/assets/6d9800ea-347f-47dc-87e6-527df747cfde" />


**Document:** Why is provisioning datasources via YAML better than configuring them manually through the UI?

## Why is datasource provisioning via YAML better than configuring them manually?

Provisioning datasources through YAML makes Grafana configuration reproducible, version-controlled, and automated.

### Benefits

1. **Consistency**

   * Every environment (development, staging, production) uses the same datasource configuration.
   * Eliminates human errors during manual setup.

2. **Infrastructure as Code**

   * Datasource configurations are stored as files in the repository.
   * Changes can be reviewed, tracked, and audited through Git.

3. **Automation**

   * New Grafana instances automatically load required datasources during startup.
   * No manual UI configuration is required.

4. **Faster Disaster Recovery**

   * If Grafana is recreated or moved to another server, datasources are restored automatically.

5. **Team Collaboration**

   * All team members use the same datasource definitions.
   * Configuration becomes part of the application deployment process.

In production environments, provisioning via YAML is preferred because it ensures repeatable and reliable Grafana deployments.


---

### Task 6: Import a Community Dashboard
The Grafana community maintains thousands of pre-built dashboards. Import one for Node Exporter:

1. Go to Dashboards > New > Import
2. Enter dashboard ID: **1860** (Node Exporter Full)
3. Select your Prometheus datasource
4. Click Import

Explore the imported dashboard. It has dozens of panels covering CPU, memory, disk, network, and more -- all built on the same Node Exporter metrics you queried manually.


<img width="1920" height="1828" alt="image" src="https://github.com/user-attachments/assets/b0b0cfea-864c-4b2a-8adb-6f54694dcc1b" />


**Try another one:** Import dashboard ID **193** (Docker monitoring via cAdvisor). Select Prometheus as the datasource and explore container-level stats.

**Your full `docker-compose.yml` should now have these services:**
- `prometheus`
- `node-exporter`
- `cadvisor`
- `grafana`
- `notes-app` (from Day 73)

<img width="1920" height="962" alt="image" src="https://github.com/user-attachments/assets/664a05ef-dd40-48c6-843f-41cd531b0fc2" />


Verify all are running:
```bash
docker compose ps
```

<img width="1647" height="165" alt="image" src="https://github.com/user-attachments/assets/055e8527-145a-4834-9268-b6cf5bb5bdf6" />


---



# Documentation:

#  docker-compose.yml

```yaml
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - "--path.procfs=/host/proc"
      - "--path.sysfs=/host/sys"
      - "--path.rootfs=/rootfs"
      - "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
    restart: unless-stopped

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    ports:
      - "8081:8080"
    privileged: true
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
    restart: unless-stopped

  grafana:
    image: grafana/grafana-enterprise:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    restart: unless-stopped

  notes-app:
    build:
      context: ../metrics-enabled-app
    container_name: notes-app
    ports:
      - "8000:8000"
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
```

---

#  prometheus.yml

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["prometheus:9090"]

  - job_name: "node-exporter"
    static_configs:
      - targets: ["node-exporter:9100"]

  - job_name: "cadvisor"
    static_configs:
      - targets: ["cadvisor:8080"]

  - job_name: "notes-app"
    static_configs:
      - targets: ["notes-app:8000"]
```

---

#  Node Exporter vs cAdvisor

##  Node Exporter (Host Metrics)

* Monitors entire Linux system
* CPU, memory, disk, filesystem, network
* Metrics prefix: `node_*`

### When to use:

* Server health monitoring
* VM/EC2 monitoring
* Infrastructure-level alerts

---

##  cAdvisor (Container Metrics)

* Monitors Docker containers
* CPU, memory, network per container
* Metrics prefix: `container_*`

### When to use:

* Microservices monitoring
* Container resource debugging
* Kubernetes-style observability

---

##  Key Difference

| Feature | Node Exporter  | cAdvisor    |
| ------- | -------------- | ----------- |
| Scope   | Host system    | Containers  |
| Level   | Infrastructure | Application |
| Metrics | node_*         | container_* |

---

#  PromQL Queries

## CPU Usage

```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

---

## Memory Usage

```promql
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100
```

---

## Disk Usage

```promql
(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100
```

---

## Container CPU Usage

```promql
rate(container_cpu_usage_seconds_total[5m]) * 100
```

---

## Container Memory Usage

```promql
container_memory_usage_bytes / 1024 / 1024
```

---

#  Prometheus Targets (Screenshot Required)



All targets should be:

* prometheus → UP
* node-exporter → UP
* cadvisor → UP
* notes-app → UP

---

#  Grafana Dashboard (Custom)

Dashboard name:

```
DevOps Observability Overview
```

Panels included:

* CPU Usage %
* Memory Usage %
* Disk Usage %
* Container CPU Usage
* Container Memory Usage



---

#  Imported Dashboard (ID 1860)

* Node Exporter Full Dashboard
* Shows full host metrics:

  * CPU
  * Memory
  * Disk
  * Network



---

#  Datasource Provisioning (YAML)

Grafana datasource is automatically configured using:

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
```

## Why this is important:

* Enables Infrastructure as Code (IaC)
* No manual UI setup required
* Ensures repeatability across environments
* Prevents configuration drift



