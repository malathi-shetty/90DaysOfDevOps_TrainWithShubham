# Day 79 -- Creating a Custom Helm Chart for AI-BankApp

---

## Challenge Tasks

### Task 1: Scaffold the Chart and Study the Raw Manifests
Make sure you have the AI-BankApp repo cloned:
```bash
cd AI-BankApp-DevOps
```

Study the raw manifests you are converting:
```bash
ls k8s/
```

<img width="912" height="361" alt="image" src="https://github.com/user-attachments/assets/95a11dd3-1f75-4048-bbcc-cb47183ad060" />



Map each file to what it does:

| File | Purpose |
|------|---------|
| `namespace.yml` | Creates `bankapp` namespace |
| `configmap.yml` | MySQL host, port, database, Ollama URL |
| `secrets.yml` | MySQL credentials (base64 encoded) |
| `pv.yml` | StorageClass (gp3 via EBS CSI) |
| `pvc.yml` | PVCs for MySQL (5Gi) and Ollama (10Gi) |
| `bankapp-deployment.yml` | BankApp with init containers, probes, envFrom |
| `mysql-deployment.yml` | MySQL with EBS volume mount, probes |
| `ollama-deployment.yml` | Ollama with postStart model pull, probes |
| `service.yml` | ClusterIP services for all 3 components |
| `hpa.yml` | HPA for BankApp (2-4 replicas, 70% CPU) |
| `gateway.yml` | Envoy Gateway + HTTPRoute + TLS |
| `cert-manager.yml` | Let's Encrypt ClusterIssuer |

Now scaffold a Helm chart:
```bash
mkdir helm-chart && cd helm-chart
helm create bankapp
```
<img width="1141" height="136" alt="image" src="https://github.com/user-attachments/assets/8f518ec9-2d94-4358-8eb3-44a3e3645056" />


Delete the generated template files -- you will write your own from the raw manifests:
```bash
rm -rf bankapp/templates/*.yaml bankapp/templates/tests/
```

Keep `_helpers.tpl` and `NOTES.txt` -- you will customize them.

<img width="1062" height="226" alt="image" src="https://github.com/user-attachments/assets/0bb4d38e-c2ae-4475-878d-03b1c02c41cb" />


---

### Task 2: Define Chart.yaml and values.yaml
Edit `bankapp/Chart.yaml`:
```yaml
apiVersion: v2
name: bankapp
description: AI-BankApp -- Spring Boot banking application with MySQL and Ollama AI chatbot
type: application
version: 0.1.0
appVersion: "1.0.0"
maintainers:
  - name: TrainWithShubham
    url: https://github.com/TrainWithShubham
keywords:
  - bankapp
  - spring-boot
  - mysql
  - ollama
  - ai
```

Now create `bankapp/values.yaml` -- extract every hardcoded value from the raw manifests into configurable values:
```yaml
# BankApp configuration
bankapp:
  replicaCount: 4
  image:
    repository: trainwithshubham/ai-bankapp-eks
    tag: "latest"
    pullPolicy: Always
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  service:
    type: ClusterIP
    port: 8080
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 4
    targetCPUUtilization: 70

# MySQL configuration
mysql:
  enabled: true
  image:
    repository: mysql
    tag: "8.0"
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  persistence:
    size: 5Gi
    storageClass: gp3

# Ollama AI configuration
ollama:
  enabled: true
  image:
    repository: ollama/ollama
    tag: "latest"
  model: tinyllama
  resources:
    requests:
      memory: "2Gi"
      cpu: "900m"
    limits:
      memory: "2.5Gi"
      cpu: "1500m"
  persistence:
    size: 10Gi
    storageClass: gp3

# Shared configuration
config:
  mysqlDatabase: bankappdb
  ollamaUrl: ""  # Auto-generated from service name if empty

# Secrets
secrets:
  mysqlRootPassword: Test@123
  mysqlUser: root
  mysqlPassword: Test@123

# Storage
storageClass:
  create: true
  name: gp3
  provisioner: ebs.csi.aws.com

# Gateway (optional -- for EKS with Envoy Gateway)
gateway:
  enabled: false
  hostname: ""
  tls:
    enabled: false
```

**Compare:** The raw `k8s/secrets.yml` has base64-encoded credentials hardcoded. The Helm chart uses `values.yaml` and templates the Secret, so each environment can override credentials without editing YAML.

## Raw Kubernetes Secret vs Helm Secret

### Raw Kubernetes (`k8s/secrets.yml`)

Credentials are manually Base64 encoded and hardcoded.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: bankapp-secret
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: VGVzdEAxMjM=
  MYSQL_USER: cm9vdA==
  MYSQL_PASSWORD: VGVzdEAxMjM=
```

If you want to change the password, you must first encode it:

```bash
echo -n "NewPassword123" | base64
```

Then replace the encoded string in the YAML.

---

### Helm Template (`templates/secrets.yaml`)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "bankapp.fullname" . }}-secret
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: {{ .Values.secrets.mysqlRootPassword | b64enc | quote }}
  MYSQL_USER: {{ .Values.secrets.mysqlUser | b64enc | quote }}
  MYSQL_PASSWORD: {{ .Values.secrets.mysqlPassword | b64enc | quote }}
```

The credentials are stored as plain text in `values.yaml`:

```yaml
secrets:
  mysqlRootPassword: Test@123
  mysqlUser: root
  mysqlPassword: Test@123
```

Helm automatically Base64 encodes them using the `b64enc` function during rendering.

### Benefits

* No manual Base64 encoding.
* Credentials can be changed by editing only `values.yaml` or by using `--set` during installation.
* The same chart can be reused across development, staging, and production by supplying different values without modifying the template.








---

### Task 3: Write the Core Templates
Convert the raw manifests into Helm templates. Each template uses `{{ .Values }}` instead of hardcoded values.

**`bankapp/templates/configmap.yaml`** (from `k8s/configmap.yml`):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "bankapp.fullname" . }}-config
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
data:
  MYSQL_HOST: {{ include "bankapp.fullname" . }}-mysql
  MYSQL_PORT: "3306"
  MYSQL_DATABASE: {{ .Values.config.mysqlDatabase | quote }}
  OLLAMA_URL: {{ default (printf "http://%s-ollama:11434" (include "bankapp.fullname" .)) .Values.config.ollamaUrl | quote }}
  SERVER_FORWARD_HEADERS_STRATEGY: "native"
```

**`bankapp/templates/secrets.yaml`** (from `k8s/secrets.yml`):
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "bankapp.fullname" . }}-secret
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: {{ .Values.secrets.mysqlRootPassword | b64enc | quote }}
  MYSQL_USER: {{ .Values.secrets.mysqlUser | b64enc | quote }}
  MYSQL_PASSWORD: {{ .Values.secrets.mysqlPassword | b64enc | quote }}
```

Notice: `b64enc` automatically base64 encodes the values. No more manual encoding.

**`bankapp/templates/storage.yaml`** (from `k8s/pv.yml` + `k8s/pvc.yml`):
```yaml
{{- if .Values.storageClass.create }}
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: {{ .Values.storageClass.name }}
provisioner: {{ .Values.storageClass.provisioner }}
parameters:
  type: gp3
  fsType: ext4
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
{{- end }}
---
{{- if .Values.mysql.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "bankapp.fullname" . }}-mysql-pvc
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
spec:
  storageClassName: {{ .Values.mysql.persistence.storageClass }}
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ .Values.mysql.persistence.size }}
{{- end }}
---
{{- if .Values.ollama.enabled }}
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ include "bankapp.fullname" . }}-ollama-pvc
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
spec:
  storageClassName: {{ .Values.ollama.persistence.storageClass }}
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{ .Values.ollama.persistence.size }}
{{- end }}
```

<img width="1042" height="287" alt="image" src="https://github.com/user-attachments/assets/c396b949-947d-419a-b002-721cffff737b" />


---

### Task 4: Write the Deployment Templates
**`bankapp/templates/bankapp-deployment.yaml`** (from `k8s/bankapp-deployment.yml`):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "bankapp.fullname" . }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
spec:
  {{- if not .Values.bankapp.autoscaling.enabled }}
  replicas: {{ .Values.bankapp.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      app: {{ include "bankapp.fullname" . }}
  template:
    metadata:
      labels:
        app: {{ include "bankapp.fullname" . }}
    spec:
      initContainers:
        - name: wait-for-mysql
          image: busybox:1.36
          command: ["/bin/sh", "-c", "until nc -z {{ include "bankapp.fullname" . }}-mysql 3306; do sleep 2; done"]
          resources:
            requests: { memory: "32Mi", cpu: "50m" }
            limits: { memory: "64Mi", cpu: "100m" }
        {{- if .Values.ollama.enabled }}
        - name: wait-for-ollama
          image: busybox:1.36
          command: ["/bin/sh", "-c", "until nc -z {{ include "bankapp.fullname" . }}-ollama 11434; do sleep 2; done"]
          resources:
            requests: { memory: "32Mi", cpu: "50m" }
            limits: { memory: "64Mi", cpu: "100m" }
        {{- end }}
      containers:
        - name: bankapp
          image: "{{ .Values.bankapp.image.repository }}:{{ .Values.bankapp.image.tag }}"
          imagePullPolicy: {{ .Values.bankapp.image.pullPolicy }}
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: {{ include "bankapp.fullname" . }}-config
            - secretRef:
                name: {{ include "bankapp.fullname" . }}-secret
          {{- with .Values.bankapp.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: 8080
            initialDelaySeconds: 30
            failureThreshold: 15
          livenessProbe:
            httpGet:
              path: /actuator/health
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10
            failureThreshold: 5
```

**Key template decisions:**
- Init containers dynamically reference the MySQL and Ollama service names via `{{ include "bankapp.fullname" . }}`
- Ollama init container is conditional (`{{- if .Values.ollama.enabled }}`)
- Health probes use `/actuator/health` -- Spring Boot's built-in health endpoint
- `replicas` is omitted when HPA is enabled (HPA manages the count)

**`bankapp/templates/mysql-deployment.yaml`** (from `k8s/mysql-deployment.yml`):
```yaml
{{- if .Values.mysql.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "bankapp.fullname" . }}-mysql
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      app: {{ include "bankapp.fullname" . }}-mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: {{ include "bankapp.fullname" . }}-mysql
    spec:
      containers:
        - name: mysql
          image: "{{ .Values.mysql.image.repository }}:{{ .Values.mysql.image.tag }}"
          ports:
            - containerPort: 3306
          env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: {{ include "bankapp.fullname" . }}-secret
                  key: MYSQL_ROOT_PASSWORD
            - name: MYSQL_DATABASE
              valueFrom:
                configMapKeyRef:
                  name: {{ include "bankapp.fullname" . }}-config
                  key: MYSQL_DATABASE
          {{- with .Values.mysql.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: mysql-storage
              mountPath: /var/lib/mysql
          readinessProbe:
            exec:
              command: ["mysqladmin", "ping", "-h", "localhost"]
            initialDelaySeconds: 15
            failureThreshold: 10
          livenessProbe:
            exec:
              command: ["mysqladmin", "ping", "-h", "localhost"]
            initialDelaySeconds: 30
            periodSeconds: 10
            failureThreshold: 5
      volumes:
        - name: mysql-storage
          persistentVolumeClaim:
            claimName: {{ include "bankapp.fullname" . }}-mysql-pvc
{{- end }}
```

**`bankapp/templates/ollama-deployment.yaml`** (from `k8s/ollama-deployment.yml`):
```yaml
{{- if .Values.ollama.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "bankapp.fullname" . }}-ollama
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      app: {{ include "bankapp.fullname" . }}-ollama
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: {{ include "bankapp.fullname" . }}-ollama
    spec:
      containers:
        - name: ollama
          image: "{{ .Values.ollama.image.repository }}:{{ .Values.ollama.image.tag }}"
          ports:
            - containerPort: 11434
          {{- with .Values.ollama.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          volumeMounts:
            - name: ollama-storage
              mountPath: /root/.ollama
          lifecycle:
            postStart:
              exec:
                command:
                  - /bin/sh
                  - -c
                  - |
                    until ollama list > /dev/null 2>&1; do sleep 2; done
                    ollama pull {{ .Values.ollama.model }}
          readinessProbe:
            exec:
              command: ["/bin/sh", "-c", "ollama list | grep -q {{ .Values.ollama.model }}"]
            initialDelaySeconds: 30
            failureThreshold: 30
          livenessProbe:
            httpGet:
              path: /
              port: 11434
            initialDelaySeconds: 60
            periodSeconds: 10
            failureThreshold: 5
      volumes:
        - name: ollama-storage
          persistentVolumeClaim:
            claimName: {{ include "bankapp.fullname" . }}-ollama-pvc
{{- end }}
```

Notice: the Ollama model name (`tinyllama`) is now a value (`{{ .Values.ollama.model }}`). You can switch models without editing YAML.

---

### Task 5: Write the Services and HPA Templates
**`bankapp/templates/services.yaml`** (from `k8s/service.yml`):
```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "bankapp.fullname" . }}-mysql
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    app: {{ include "bankapp.fullname" . }}-mysql
  ports:
    - port: 3306
---
{{- if .Values.ollama.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "bankapp.fullname" . }}-ollama
  namespace: {{ .Release.Namespace }}
spec:
  selector:
    app: {{ include "bankapp.fullname" . }}-ollama
  ports:
    - port: 11434
{{- end }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "bankapp.fullname" . }}-service
  namespace: {{ .Release.Namespace }}
spec:
  type: {{ .Values.bankapp.service.type }}
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
  selector:
    app: {{ include "bankapp.fullname" . }}
  ports:
    - port: {{ .Values.bankapp.service.port }}
      targetPort: 8080
```

**`bankapp/templates/hpa.yaml`** (from `k8s/hpa.yml`):
```yaml
{{- if .Values.bankapp.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "bankapp.fullname" . }}-hpa
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "bankapp.labels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "bankapp.fullname" . }}
  minReplicas: {{ .Values.bankapp.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.bankapp.autoscaling.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.bankapp.autoscaling.targetCPUUtilization }}
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
        - type: Pods
          value: 2
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Pods
          value: 1
          periodSeconds: 60
{{- end }}
```

<img width="1135" height="307" alt="image" src="https://github.com/user-attachments/assets/de517497-e0b1-4b92-92c8-143c177252db" />


---

### Task 6: Validate and Deploy
**Lint the chart:**
```bash
helm lint bankapp/
```

<img width="1097" height="115" alt="image" src="https://github.com/user-attachments/assets/8beecfd1-442b-40b9-93a7-c042df0281b1" />


**Render templates locally** -- see the final YAML without deploying:
```bash
helm template my-bankapp bankapp/
```

Review the output. Every `{{ }}` should be resolved to actual values.

<img width="1247" height="1191" alt="image" src="https://github.com/user-attachments/assets/30455e9e-0a35-42ed-af4a-cfc399fbb01e" />


**Render with overrides:**
```bash
helm template my-bankapp bankapp/ \
  --set bankapp.image.tag=abc1234 \
  --set bankapp.replicaCount=2 \
  --set ollama.enabled=false
```

Notice: setting `ollama.enabled=false` removes the Ollama Deployment, Service, PVC, and the init container from the BankApp. One boolean controls an entire component.

- I notice that setting ollama.enabled=false removes all Ollama-related resources.


<img width="1252" height="1267" alt="image" src="https://github.com/user-attachments/assets/48f13acf-b659-4327-9e03-c739e2584a7e" />


**Dry run against the cluster:**
```bash
helm install my-bankapp bankapp/ --dry-run --debug -n bankapp --create-namespace
```

<img width="1812" height="1260" alt="image" src="https://github.com/user-attachments/assets/1e1446a5-00e3-4f0e-871f-ca8c58ece44f" />


**Deploy for real (on Kind -- skip StorageClass creation since Kind uses its own):**
```bash
helm install my-bankapp bankapp/ \
  -n bankapp --create-namespace \
  --set storageClass.create=false \
  --set mysql.persistence.storageClass=standard \
  --set ollama.persistence.storageClass=standard
```

<img width="1247" height="377" alt="image" src="https://github.com/user-attachments/assets/009c7e6c-453e-40f2-bb1e-cc0c4306a4a7" />
<img width="1490" height="382" alt="image" src="https://github.com/user-attachments/assets/bb472a74-56d5-4af7-8fd9-4f1b26dcaf65" />
<img width="1482" height="382" alt="image" src="https://github.com/user-attachments/assets/3cb4f4c6-b9bd-4819-8fc8-35838cf6dc5d" />


Verify:
```bash
helm list -n bankapp
kubectl get all -n bankapp
kubectl get pvc -n bankapp
kubectl get configmap,secret -n bankapp
```

<img width="1422" height="868" alt="image" src="https://github.com/user-attachments/assets/507cff4d-6e3e-4f4b-a205-92bbfc6db028" />


Wait for all pods to be ready (Ollama takes time to pull the model):
```bash
kubectl get pods -n bankapp -w
```

<img width="1217" height="135" alt="image" src="https://github.com/user-attachments/assets/1a148e92-9d27-4407-865f-df65d614c8cd" />


Access the app:
```bash
kubectl port-forward svc/my-bankapp-service -n bankapp 8080:8080
```

Open `http://localhost:8080` -- you should see the AI-BankApp login page.


<img width="2560" height="1272" alt="image" src="https://github.com/user-attachments/assets/d1c49f87-5493-4f67-b5e5-d88456031d37" />
<img width="2560" height="1272" alt="image" src="https://github.com/user-attachments/assets/fea78bf0-a275-47fa-b84c-a10becb39543" />
<img width="2560" height="1272" alt="image" src="https://github.com/user-attachments/assets/cd4449c5-bf6a-4675-9327-938d653d83cd" />
<img width="2557" height="1380" alt="image" src="https://github.com/user-attachments/assets/c6ed0e77-4c4d-499b-b944-9de349249bd5" />
<img width="2560" height="1272" alt="image" src="https://github.com/user-attachments/assets/239296d8-c845-46e0-94b2-11f58233ef24" />
<img width="2552" height="1377" alt="image" src="https://github.com/user-attachments/assets/419313e7-f0a7-42b3-ac46-509ec4d81e01" />
<img width="2552" height="1382" alt="image" src="https://github.com/user-attachments/assets/558ac389-2835-42c2-a4f0-ab704eaaefe1" />

---

**Compare: 12 raw YAML files vs 1 Helm command.** Same result, but now configurable, versionable, and rollback-safe.



| Raw Kubernetes Manifests                                                    | Helm Chart                                                              |
| --------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| 12 separate YAML files to manage                                            | Single Helm chart with one install command                              |
| Hardcoded values (images, passwords, storage sizes)                         | Configurable through `values.yaml`                                      |
| Manual edits required for every environment                                 | Override values using `--set` or custom values files                    |
| Secrets stored as base64-encoded strings in YAML                            | Secrets generated dynamically using Helm's `b64enc` function            |
| Enabling/disabling a component requires editing multiple YAML files         | A single flag like `ollama.enabled=false` removes all related resources |
| Difficult to version and upgrade                                            | Versioned Helm releases with upgrade and rollback support               |
| No release history                                                          | Helm tracks release history                                             |
| Rollback requires manually applying older YAML files                        | One-command rollback using `helm rollback`                              |
| Deploy each manifest individually with multiple `kubectl apply -f` commands | Deploy the complete application using one `helm install` command        |

### Deployment Comparison

**Raw Kubernetes manifests**

```bash
kubectl apply -f namespace.yml
kubectl apply -f configmap.yml
kubectl apply -f secrets.yml
kubectl apply -f pv.yml
kubectl apply -f pvc.yml
kubectl apply -f mysql-deployment.yml
kubectl apply -f ollama-deployment.yml
kubectl apply -f bankapp-deployment.yml
kubectl apply -f service.yml
kubectl apply -f hpa.yml
kubectl apply -f gateway.yml
kubectl apply -f cert-manager.yml
```

**Helm**

```bash
helm install my-bankapp bankapp \
  -n bankapp \
  --create-namespace \
  --set storageClass.create=false \
  --set mysql.persistence.storageClass=standard \
  --set ollama.persistence.storageClass=standard
```

### Key Takeaways

* Converted **12 Kubernetes manifests** into a reusable **Helm chart**.
* Centralized configuration in **`values.yaml`**.
* Templates use **Go templating** (`{{ .Values }}`) instead of hardcoded values.
* Secrets are generated dynamically using **`b64enc`**.
* Components such as Ollama can be enabled or disabled with a single configuration value (`ollama.enabled=false`).
* Helm provides **release management, upgrades, and rollbacks**, making deployments easier to maintain in production.

---


**Clean up:**
```bash
helm uninstall my-bankapp -n bankapp
```

<img width="1267" height="52" alt="image" src="https://github.com/user-attachments/assets/2d1c9e2e-4dac-42b1-9363-6bf16ab854f2" />


---


# Documentation

Convert the AI-BankApp Kubernetes manifests into a reusable Helm chart.

Instead of deploying multiple YAML files individually, the complete application can now be deployed using a single Helm command.

---

# Project Structure

```
helm-chart/
└── bankapp/
    ├── Chart.yaml
    ├── values.yaml
    ├── templates/
    │   ├── _helpers.tpl
    │   ├── NOTES.txt
    │   ├── configmap.yaml
    │   ├── secrets.yaml
    │   ├── storage.yaml
    │   ├── bankapp-deployment.yaml
    │   ├── mysql-deployment.yaml
    │   ├── ollama-deployment.yaml
    │   ├── services.yaml
    │   └── hpa.yaml
```

---

# Raw Kubernetes Manifests vs Helm Templates

| Raw Manifest | Helm Template | Purpose |
|--------------|--------------|---------|
| namespace.yml | Namespace passed using `--namespace` | Namespace creation |
| configmap.yml | templates/configmap.yaml | Application configuration |
| secrets.yml | templates/secrets.yaml | MySQL credentials |
| pv.yml | templates/storage.yaml | StorageClass |
| pvc.yml | templates/storage.yaml | MySQL & Ollama PVCs |
| bankapp-deployment.yml | templates/bankapp-deployment.yaml | Spring Boot deployment |
| mysql-deployment.yml | templates/mysql-deployment.yaml | MySQL deployment |
| ollama-deployment.yml | templates/ollama-deployment.yaml | Ollama deployment |
| service.yml | templates/services.yaml | Services |
| hpa.yml | templates/hpa.yaml | Horizontal Pod Autoscaler |
| gateway.yml | (Optional) | Gateway API |
| cert-manager.yml | (Optional) | TLS Certificates |

---

# values.yaml Explained

## BankApp

```yaml
bankapp:
  replicaCount: 4
```

Number of application replicas when HPA is disabled.

```yaml
image:
  repository:
  tag:
  pullPolicy:
```

Docker image details.

```yaml
service:
  type: ClusterIP
  port: 8080
```

Application service configuration.

```yaml
autoscaling:
```

Controls the Horizontal Pod Autoscaler.

---

## MySQL

```yaml
mysql:
```

Contains:

- image
- resources
- PVC size
- storage class
- enable/disable MySQL

---

## Ollama

```yaml
ollama:
```

Contains:

- image
- model
- resources
- PVC
- enable/disable AI service

Changing

```yaml
model: tinyllama
```

to

```yaml
model: llama3
```

deploys a different model without editing templates.

---

## Shared Config

```yaml
config:
```

Stores

- database name
- Ollama URL

---

## Secrets

```yaml
secrets:
```

Stores

- MYSQL_ROOT_PASSWORD
- MYSQL_USER
- MYSQL_PASSWORD

These values are automatically Base64 encoded using Helm's **b64enc** function.

---

## StorageClass

```yaml
storageClass:
```

Controls

- whether StorageClass is created
- StorageClass name
- CSI provisioner

---

## Gateway

Optional Gateway API configuration.

---

# Go Template Syntax Cheat Sheet

### Read values

```yaml
{{ .Values.bankapp.replicaCount }}
```

Reads values from values.yaml.

---

### if

```yaml
{{- if .Values.ollama.enabled }}
...
{{- end }}
```

Conditionally renders resources.

---

### range

```yaml
{{- range .Values.list }}
```

Loops over lists.

---

### with

```yaml
{{- with .Values.bankapp.resources }}
resources:
{{ toYaml . | nindent 2 }}
{{- end }}
```

Temporarily changes context.

---

### include

```yaml
{{ include "bankapp.fullname" . }}
```

Calls helper templates.

---

### toYaml

Converts objects into valid YAML.

Example

```yaml
resources:
{{ toYaml .Values.bankapp.resources | nindent 2 }}
```

---

### nindent

Adds indentation.

Example

```yaml
{{ include "bankapp.labels" . | nindent 4 }}
```

---

### b64enc

Automatically Base64 encodes secrets.

Example

```yaml
MYSQL_PASSWORD: {{ .Values.secrets.mysqlPassword | b64enc }}
```

No manual encoding required.

---

# helm template Output

Render manifests locally

```bash
helm template my-bankapp bankapp/
```

Rendered resources include

```
StorageClass
PersistentVolumeClaim
PersistentVolumeClaim

ConfigMap

Secret

Deployment
Deployment
Deployment

Service
Service
Service

HorizontalPodAutoscaler
```

Every Go template expression (`{{ }}`) is replaced with actual values from `values.yaml`.

---

# Overriding Values

Example

```bash
helm template my-bankapp bankapp \
--set bankapp.image.tag=abc1234 \
--set bankapp.replicaCount=2 \
--set ollama.enabled=false
```

Helm overrides values without editing any YAML files.

---

# Disabling Ollama

Setting

```yaml
ollama:
  enabled: false
```

or

```bash
--set ollama.enabled=false
```

removes all Ollama resources automatically.

The following resources are **not rendered**:

- Ollama Deployment
- Ollama Service
- Ollama PVC
- wait-for-ollama init container

Only the following remain:

- BankApp Deployment
- MySQL Deployment
- MySQL PVC
- BankApp Service
- MySQL Service
- ConfigMap
- Secret
- HPA

This demonstrates one of Helm's biggest advantages: **a single configuration flag can enable or disable an entire application component.**

---

# Validation

Lint chart

```bash
helm lint bankapp/
```

Output

```
1 chart(s) linted, 0 chart(s) failed
```

Render templates

```bash
helm template my-bankapp bankapp/
```

Deploy

```bash
helm install my-bankapp bankapp \
-n bankapp \
--create-namespace
```

---

# Raw Kubernetes vs Helm

| Raw Kubernetes | Helm |
|---------------|------|
| 12 YAML files | 1 Helm chart |
| Hardcoded values | Configurable values.yaml |
| Manual edits | --set overrides |
| Manual Base64 encoding | b64enc |
| Multiple kubectl apply commands | Single helm install |
| Difficult upgrades | helm upgrade |
| Manual rollback | helm rollback |
| No release history | Helm release history |

---

# Key Learning

- Built a reusable Helm chart for AI-BankApp.
- Replaced hardcoded values with configurable values.yaml.
- Used Go templates to generate Kubernetes manifests dynamically.
- Learned helper functions like include, toYaml, nindent, and b64enc.
- Used conditional rendering to enable or disable components.
- Validated the chart using helm lint and helm template before deployment.
- Reduced deployment from multiple YAML files to a single Helm command.

---

# Commands Used

```bash
helm lint bankapp/

helm template my-bankapp bankapp/

helm install my-bankapp bankapp \
  -n bankapp \
  --create-namespace \
  --set storageClass.create=false \
  --set mysql.persistence.storageClass=standard \
  --set ollama.persistence.storageClass=standard

helm list -n bankapp

kubectl get all -n bankapp

helm uninstall my-bankapp -n bankapp
```
