# Day 54 – Kubernetes ConfigMaps and Secrets

## Challenge Tasks

### Task 1: Create a ConfigMap from Literals
1. Use `kubectl create configmap` with `--from-literal` to create a ConfigMap called `app-config` with keys `APP_ENV=production`, `APP_DEBUG=false`, and `APP_PORT=8080`
2. Inspect it with `kubectl describe configmap app-config` and `kubectl get configmap app-config -o yaml`
3. Notice the data is stored as plain text — no encoding, no encryption

**Verify:** Can you see all three key-value pairs?

### Verification Result 

After running:

```bash id="ltl8dl"
kubectl describe configmap app-config
```

or

```bash id="jag3h6"
kubectl get configmap app-config -o yaml
```

Able to see all three key-value pairs:

```text id="4dfbtm"
APP_ENV=production
APP_DEBUG=false
APP_PORT=8080
```

### Observation

ConfigMaps store data as:

* Plain text
* Human-readable key-value pairs
* Not base64 encoded
* Not encrypted by default

This is why ConfigMaps should only be used for **non-sensitive configuration** such as:

* Application environment (`production`, `staging`)
* Feature flags
* Ports
* Logging levels

Sensitive information like passwords, API keys, and database credentials should be stored in Kubernetes **Secrets** instead.

<img width="832" height="708" alt="image" src="https://github.com/user-attachments/assets/33ec093d-ef96-47c4-ada8-a6447715d408" />


---

### Task 2: Create a ConfigMap from a File
1. Write a custom Nginx config file that adds a `/health` endpoint returning "healthy"

```bash
server {
    listen 80;

    location /health {
        return 200 "healthy";
        add_header Content-Type text/plain;
    }
}
```

2. Create a ConfigMap from this file using `kubectl create configmap nginx-config --from-file=default.conf=<your-file>`
```bash
kubectl create configmap nginx-config \
  --from-file=default.conf=default.conf
```
**What happened?**
- default.conf (left side of =) becomes the key in the ConfigMap.
- The contents of your local default.conf file become the value.
- When mounted later, Kubernetes will create a file named default.conf inside the container.


3. The key name (`default.conf`) becomes the filename when mounted into a Pod

**Verify:** Does `kubectl get configmap nginx-config -o yaml` show the file contents?

`Check the data: section:`
```bash
data:
  default.conf: |
    server {
        listen 80;

        location /health {
            return 200 "healthy";
            add_header Content-Type text/plain;
        }
    }
```
**What does this prove?**
- The ConfigMap contains the entire file content.
- The key is default.conf.
- When mounted into a Pod, Kubernetes will create a file named default.conf with exactly these contents.


### Does kubectl get configmap nginx-config -o yaml show the file contents?
Yes. The contents of default.conf are stored under the data.default.conf key in the ConfigMap YAML.

<img width="817" height="515" alt="image" src="https://github.com/user-attachments/assets/7515e38d-9ac6-47e9-a06d-bef586a6c26f" />


---

### Task 3: Use ConfigMaps in a Pod
1. Write a Pod manifest that uses `envFrom` with `configMapRef` to inject all keys from `app-config` as environment variables. Use a busybox container that prints the values.
2. Write a second Pod manifest that mounts `nginx-config` as a volume at `/etc/nginx/conf.d`. Use the nginx image.
3. Test that the mounted config works: `kubectl exec <pod> -- curl -s http://localhost/health`

Use environment variables for simple key-value settings. Use volume mounts for full config files.

**Verify:** Does the `/health` endpoint respond?

#### Environment Variables
```bash
APP_ENV=production
APP_DEBUG=false
APP_PORT=8080
```
#### Injected via:
```bash
envFrom:
  - configMapRef:
      name: app-config
```
#### Mounted Config File
```bash
/etc/nginx/conf.d/default.conf
```
#### Created from:
```bash
ConfigMap nginx-config
```
#### Health Endpoint
```bash
kubectl exec nginx-config-pod -- curl -s http://localhost/health
```
### Output:
```bash
healthy
```
That proves:
- The nginx-config ConfigMap was mounted correctly.
- default.conf was loaded by Nginx.
- The /health endpoint is working.
- The Pod is serving the custom configuration from the ConfigMap.

Yes, the `/health` endpoint responds with `healthy`.

#### Key Learning
- Use environment variables for simple key-value settings.
- Use volume mounts for full configuration files.
- ConfigMaps can be consumed both ways depending on the application's needs.

<img width="1033" height="426" alt="image" src="https://github.com/user-attachments/assets/1de25224-a38a-4b8f-91ff-2c5508946ae8" />


---

### Task 4: Create a Secret
1. Use `kubectl create secret generic db-credentials` with `--from-literal` to store `DB_USER=admin` and `DB_PASSWORD=s3cureP@ssw0rd`
2. Inspect with `kubectl get secret db-credentials -o yaml` — the values are base64-encoded
3. Decode a value: `echo '<base64-value>' | base64 --decode`

**base64 is encoding, not encryption.** Anyone with cluster access can decode Secrets. The real advantages are RBAC separation, tmpfs storage on nodes, and optional encryption at rest.

**Verify:** Can you decode the password back to plaintext?



Important Observation

Base64 is:
- Encoding
- Not encryption

Anyone who can read the Secret can decode it:
```bash
echo 'czNjdXJlUEBzc3cwcmQ=' | base64 --decode
```
Therefore Kubernetes Secrets provide benefits such as:
- RBAC access control
- Separation from ConfigMaps
- Storage in tmpfs when mounted
- Optional encryption at rest
But Base64 alone is **not security**.



#### Can you decode the password back to plaintext?

Yes, decode the password back to plaintext
```bash
s3cureP@ssw0rd
```

<img width="862" height="359" alt="image" src="https://github.com/user-attachments/assets/4dcef777-2d09-47a3-8a7a-3de3344e5bfc" />


---

### Task 5: Use Secrets in a Pod
1. Write a Pod manifest that injects `DB_USER` as an environment variable using `secretKeyRef`
2. In the same Pod, mount the entire `db-credentials` Secret as a volume at `/etc/db-credentials` with `readOnly: true`
3. Verify: each Secret key becomes a file, and the content is the decoded plaintext value

**Verify:** Are the mounted file values plaintext or base64?

#### Does each Secret key become a file?

Yes

```bash
/etc/db-credentials/
├── DB_USER
└── DB_PASSWORD
```
#### Are the mounted file values plaintext or Base64?

- Plaintext
```bash
admin
s3cureP@ssw0rd
```
- Not Base64
```bash
YWRtaW4=
czNjdXJlUEBzc3cwcmQ=
```
#### Key Learning
| Location                    | Representation |
| --------------------------- | -------------- |
| Secret YAML                 | Base64 encoded |
| Environment variable in Pod | Plaintext      |
| Mounted Secret file         | Plaintext      |

This distinction is exactly what Kubernetes does: it stores Secret data encoded in the API object, then automatically decodes it when exposing it to containers.

<img width="1471" height="696" alt="image" src="https://github.com/user-attachments/assets/fa6770a0-430e-4b74-a5c4-a4f884c7d49e" />


---

### Task 6: Update a ConfigMap and Observe Propagation
1. Create a ConfigMap `live-config` with a key `message=hello`
2. Write a Pod that mounts this ConfigMap as a volume and reads the file in a loop every 5 seconds
3. Update the ConfigMap: `kubectl patch configmap live-config --type merge -p '{"data":{"message":"world"}}'`
4. Wait 30-60 seconds — the volume-mounted value updates automatically
5. Environment variables from earlier tasks do NOT update — they are set at pod startup only

**Verify:** Did the volume-mounted value change without a pod restart?

Logs clearly demonstrate the behavior Kubernetes is designed for.

### Before the ConfigMap update

```text
Mon Jun  1 14:03:00 UTC 2026 -> hello
Mon Jun  1 14:03:05 UTC 2026 -> hello
...
Mon Jun  1 14:04:11 UTC 2026 -> hello
```

### After patching the ConfigMap

```text
Mon Jun  1 14:04:16 UTC 2026 -> world
Mon Jun  1 14:04:21 UTC 2026 -> world
Mon Jun  1 14:04:26 UTC 2026 -> world
...
```

### What this proves

The mounted file:

```text
/config/message
```

was automatically updated from:

```text
hello
```

to:

```text
world
```

without restarting the Pod.

### Verification Answer ✅

**Did the volume-mounted value change without a pod restart?**

 **Yes**

```text
hello
hello
hello
world
world
world
```

### Key Learning

| ConfigMap Usage      | Updates Automatically? |
| -------------------- | ---------------------- |
| Mounted as Volume    |  Yes                  |
| Environment Variable |  No                   |

### Why?

When a ConfigMap is mounted as a volume, Kubernetes periodically refreshes the files exposed to the container.

When a ConfigMap is injected as environment variables:

```yaml
env:
  - name: MESSAGE
    valueFrom:
      configMapKeyRef:
        name: live-config
        key: message
```

the value is copied into the process environment only once at Pod startup. Updating the ConfigMap later does not change the environment variable.

<img width="1631" height="870" alt="image" src="https://github.com/user-attachments/assets/4a0502e2-0037-40a9-a0a9-f45473869dc9" />


---

### Task 7: Clean Up
Delete all pods, ConfigMaps, and Secrets you created.




#  Step 1: Delete Pods

Run:

```bash
kubectl delete pod secret-demo
kubectl delete pod config-watcher
kubectl delete pod nginx-config-pod
```

If any pod name is different, check first:

```bash
kubectl get pods
```

Then delete accordingly.

---

#  Step 2: Delete ConfigMaps

Run:

```bash
kubectl delete configmap app-config
kubectl delete configmap nginx-config
kubectl delete configmap live-config
```

Verify:

```bash
kubectl get configmap
```

You should see either:

```text
No resources found
```

or only unrelated ones.

---

#  Step 3: Delete Secrets

Run:

```bash
kubectl delete secret db-credentials
```

Verify:

```bash
kubectl get secret
```

---

#  Step 4: Final Cluster Check (Recommended)

Make sure nothing from Day 54 remains:

```bash
kubectl get pods
kubectl get configmap
kubectl get secret
```

---

#  Expected Final State

```text
No resources found in default namespace
```

(or only system resources)

---



<img width="883" height="551" alt="image" src="https://github.com/user-attachments/assets/616343f4-d825-4b5e-8efb-3689782a2691" />


---





## What ConfigMaps and Secrets are and when to use each
### What are ConfigMaps?

ConfigMaps are Kubernetes objects used to store **non-sensitive configuration data** in key-value format.

They help separate configuration from application code so that container images do not need to be rebuilt when configuration changes.

#### Use cases:
- Application settings (APP_ENV, APP_PORT)
- Feature flags
- Configuration files (nginx.conf, app configs)

---

### What are Secrets?

Secrets are used to store **sensitive data** such as:
- passwords
- API keys
- database credentials

Although Secrets are stored as Base64 encoded values, they are **not encrypted by default**.

---

### ConfigMaps vs Secrets

| Feature | ConfigMap | Secret |
|----------|----------|--------|
| Data type | Non-sensitive | Sensitive |
| Encoding | Plain text | Base64 encoded |
| Encryption | No | Optional (at rest) |
| Use case | Config values | Credentials |

---

### The difference between environment variables and volume mounts

#### Environment Variables
- Injected using `env` or `envFrom`
- Available inside container process
- Set only at Pod startup
- Do NOT update when ConfigMap/Secret changes

Example:
```yaml
envFrom:
  - configMapRef:
      name: app-config
````

---

### Volume Mounts

* Mounted as files inside the container
* Can represent full configuration files
* Automatically updated when ConfigMap/Secret changes (eventual consistency)

Example:

```yaml
volumes:
  - name: config
    configMap:
      name: live-config
```

---

### Why base64 is encoding, not encryption

Kubernetes Secrets store values in Base64 format:

```
echo -n 'value' | base64
```

Base64 is:

*  Not encryption
*  Not secure by itself
*  Just encoding

Anyone with access can decode it:

```
echo '<encoded>' | base64 --decode
```

### Real security comes from:

* RBAC (Role-Based Access Control)
* Encryption at rest (optional feature in Kubernetes)
* Restricted access to Secrets

---

### How ConfigMap updates propagate to volumes but not env vars

### Volume-mounted ConfigMaps:

* Automatically updated inside running Pods
* No restart required
* Updates happen within ~30–60 seconds

### Environment variables:

* Do NOT update after Pod creation
* Require Pod restart to reflect changes

---

### Key Takeaways

* ConfigMaps = non-sensitive configuration
* Secrets = sensitive configuration (encoded, not encrypted)
* envFrom = inject all keys
* env + valueFrom = inject specific keys
* Volume mounts = dynamic updates
* Environment variables = static at startup



