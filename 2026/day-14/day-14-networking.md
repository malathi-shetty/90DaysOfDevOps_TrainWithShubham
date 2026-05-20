# Day 14 – Networking Fundamentals & Hands-on Checks

---


## OSI vs TCP/IP

### OSI Model (7 Layers – Conceptual Framework)

Explains how data travels between devices.

1. **Physical** → cables, fiber, Wi-Fi signals
2. **Data Link** → MAC address, Ethernet, frames
3. **Network** → IP addressing & routing
4. **Transport** → TCP (reliable), UDP (connectionless)
5. **Session** → manages sessions (login/session control)
6. **Presentation** → encryption/decryption, formatting (SSL/TLS, MIME)
7. **Application** → HTTP, HTTPS, DNS, FTP, SMTP

---

### TCP/IP Model (4 Layers – Real Internet Model)

1. **Network Access (Link)** → Ethernet, Wi-Fi, MAC
2. **Internet** → IP, ICMP, ARP
3. **Transport** → TCP, UDP
4. **Application** → HTTP, HTTPS, DNS, SSH

---

## Layer Mapping

| OSI          | TCP/IP      | Notes                 |
| ------------ | ----------- | --------------------- |
| L7 + L6 + L5 | Application | User-facing protocols |
| L4           | Transport   | Ports, reliability    |
| L3           | Internet    | Routing               |
| L2 + L1      | Link        | Hardware + MAC        |

---

## Protocol Placement

* **IP** → Internet layer
* **TCP/UDP** → Transport layer
* **HTTP/HTTPS, DNS, FTP, SMTP** → Application layer

---

## Quick Concept Bullets 

* OSI has 7 layers (L1–L7) while TCP/IP has 4 layers (Link, Internet, Transport, Application).
* OSI is conceptual; TCP/IP is practical.
* IP works at Internet layer, TCP/UDP at Transport layer, HTTP/HTTPS/DNS at Application layer.
* Example: `curl https://example.com` = Application (HTTP) over Transport (TCP) over Internet (IP).

---

##  Flow

```bash
curl https://example.com
```

Full breakdown:

1. DNS lookup → resolve domain → IP
2. TCP handshake → SYN → SYN-ACK → ACK
3. TLS handshake → encryption setup
4. HTTP request sent
5. Server responds
6. Data split into TCP segments
7. Routed via IP across networks
8. Delivered via MAC + physical medium

---

# Hands-on Networking Checklist

## Targets Used

* google.com
* github.com
* nexustekfusion.in
* localhost / EC2

---

## 1. Identity

```bash
hostname -I
ip addr
```

### Observed

1️⃣ hostname -I
```bash
172.31.32.167 172.17.0.1
```

What it means:
- machine has **multiple IPs**

👉 172.31.32.167 → your main private IP (EC2 network)
👉 172.17.0.1 → secondary/internal/public-mapped IP (cloud networking)

 Observation
- System has multiple IP addresses assigned
- 172.71.x.x indicates cloud private network (EC2 VPC)
- Shows machine is connected to more than one network interface/path

2️⃣ ip addr (this is the real detailed one)
🔹 Interface 1: lo (Loopback)
```bash
1: lo:
inet 127.0.0.1/8
```

Meaning:
- This is localhost
- Used for internal communication inside the system

👉 Example:
```bash
curl localhost
```

 Observation:
- 127.0.0.1 is loopback → used for internal testing
- Always present, never leaves the machine

🔹 Interface 2: ens5 (MAIN NETWORK)
```bash
2: ens5:
inet 172.71.56.167
```
Meaning:
- This is your actual network interface (like WiFi/Ethernet)
- Connected to AWS network

👉 This is the IP used when:

- You SSH into server
- Server connects to internet

Extra lines:

```bash
link/ether 06:cc:88:71:71:3f
```
👉 This is MAC address (Layer 2 identity)

```bash
state UP
```
👉 Interface is active

 Observation:
- ens5 is the primary active network interface
- Has IP 172.71.56.167 → used for external communication
- Interface is UP and functioning correctly

🔹 Interface 3: docker0
```bash
3: docker0:
inet 172.17.0.1
state DOWN
```
Meaning:
- This is created by Docker
- Used for container networking

👉 172.17.0.1 = Docker bridge network

```bash
state DOWN
```
👉 No containers currently running OR inactive

Observation:
- Docker bridge network exists (172.17.0.1)
- Currently inactive (DOWN)
- Will be used when containers run

# Identity Observation
- Multiple IP addresses observed using hostname -I
- 172.71.56.167 is the primary private IP (EC2 network)
- Loopback interface (127.0.0.1) is used for internal communication
- ens5 is the main active network interface (UP)
- Docker bridge network (172.17.0.1) exists but is currently DOWN

---

## 2. Reachability

```bash
ping -c 4 google.com
```

### Observed Variations

* Successfully pinged google.com with 0% packet loss
* Average latency ~6 ms indicating fast and stable network
* DNS resolution worked correctly (domain resolved to IP)
* Confirms the system has proper internet connectivity

👉 Fastest connectivity check

🔹 **ICMP clarification:**

* `ping` uses ICMP, not TCP/UDP
* Works at Network layer
* ICMP sits at Network/Internet layer

---

## 3. Network Path

```bash
traceroute google.com
# OR
tracepath google.com
```

### Observed

traceroute Observation
* Traceroute shows ~5 hops from EC2 instance to destination
* Initial latency ~6 ms remains stable across hops
* Some hops return * * * due to ICMP filtering (expected behavior)
* Destination reached successfully (google.com)
* Presence of multiple IPs in a single hop indicates load-balanced routing


tracepath Observation
* Traffic passes through multiple network hops before reaching destination
* Initial hops show low latency (~0.07 ms → 6 ms), indicating normal routing
* Some hops show “no reply” due to ICMP filtering (expected behavior)
* Indicates packets are traversing internal AWS network and external internet

---

## 4. Ports & Services

```bash
ss -tulpn
# or
netstat -tulpn
```

### Observed Ports

| Port        | Service (Interpretation) | Notes                           |
| ----------- | ------------------------ | ------------------------------- |
| 22          | SSH                      | Remote login to your EC2        |
| 53          | DNS resolver             | Local DNS (systemd-resolved)    |
| 68          | DHCP                     | IP assignment from network      |
| 323         | NTP                      | Time sync service               |
| 4330        | Custom service           | Some app running                |
| 44321–44323 | Custom ports             | Likely app / ephemeral services |
| 46283       | Local process            | Internal app (localhost only)   |

Ports & Services Observation
* SSH service is running on port 22 and listening on all interfaces
* DNS resolver is active on port 53 (localhost)
* DHCP client is using port 68 for IP assignment
* NTP service is running on port 323 for time synchronization
* Multiple custom ports are listening, indicating background or application services

---

## 5. DNS Resolution

```bash
dig google.com
# or
nslookup google.com
```

### Observed

* Resolved IP:

* google.com resolved to IP 142.250.69.174
* Query time was ~2 ms, indicating fast DNS response
* Resolver used: 127.0.0.53 (local system DNS)
* nslookup also returned an IPv6 address, showing dual-stack support
* Confirms DNS resolution is working correctly

---

## 6. HTTP Check

```bash
curl -I https://google.com

curl -IL https://google.com
```

### Observed

* Initial request returned 301 redirect to https://www.google.com
* Final response returned 200 OK, confirming successful request
* Response uses HTTP/2
* Headers include cookies, cache-control, and security policies
* Confirms application layer (HTTP/HTTPS) is working correctly

---

## 7. Connections Snapshot

```bash
netstat -an | head
```

### Observed

- Multiple services are in LISTEN state (ports 22, 53, 4330, 44321–44323)
- No ESTABLISHED connections observed in the first few lines
- Indicates system is ready to accept connections but no active sessions at that moment
- Output is truncated (head), so full connection state may include more entries

---

# Mini Task: Port Probe & Interpret

## Identify Listening Ports

From ss -tulpn:

* 22 → SSH
* 53 → DNS (local resolver)
* 4330 → custom application
* 44321, 44322, 44323 → custom/local services
* 80 → HTTP (not running)
* 45381 → no service (random port)
  
---

## Test Ports

```bash
nc -zv localhost 22
nc -zv localhost 4330
nc -zv localhost 44321
nc -zv localhost 44322
nc -zv localhost 44323
nc -zv localhost 80
nc -zv localhost 53
nc -zv localhost 45381
```

### Observed Results

* localhost:22 →  Success (SSH reachable)
* localhost:4330 →  Success (service reachable)
* localhost:44321 →  Success (custom service reachable)
* localhost:44322 →  Success (custom service reachable)
* localhost:44323 →  Success (custom service reachable)
* localhost:80 → Connection refused (no HTTP service running)
* localhost:45381 →  Connection refused (no service running)
* localhost:53 →  Connection refused

👉 Note: DNS (port 53) is running on 127.0.0.53 / 127.0.0.54, not on 127.0.0.1, so it is not reachable via localhost.

---

🔹 **Additional Check**
```bash
curl -I http://localhost:4330
```

Result:  Error
👉 Indicates service is not HTTP-based, even though port is open.

---

## Observation:
* Ports 22, 4330, 44321, 44322, 44323 are open & reachable (connection successful using nc).
* Ports 80 and 45381 are not reachable (connection refused - no service running).
* Port 53 is listening only on 127.0.0.53/54, so it is not reachable via localhost (127.0.0.1).
* curl on port 4330 failed, indicating the service is not HTTP-based.
* Firewall(ufw) is inactive, so no ports are blocked.

### If a Port is Not Reachable:

Perform the following checks:
1. Check if service is running:

```bash
sudo systemctl status <service>
```

2 .Check listening ports:

```bash
ss -tulpn | grep <port>
```

3. Check correct IP binding (very important)
* 0.0.0.0 → accessible from all interfaces
* 127.0.0.1 or 127.x.x.x → limited to local system

4. Check firewall:
```bash
sudo ufw status
iptables -L
```

5. Check cloud firewall (AWS Security Groups)
* Ensure required ports are allowed for inbound traffic

---

## Reflection 

🔹 1. Which command gives you the fastest signal when something is broken?

```bash
 nc -zv <host> <port> (netcat)
nc -zv localhost 22
```

Why?

* It directly tests: “Can I reach this port or not?”
* No DNS complexity (if you use IP)
* No protocol complexity (like HTTP)

Meaning:
*  succeeded → network + port + service reachable
*  connection refused → service NOT running or wrong binding
*  timeout → firewall / network issue

 So fastest raw signal = connectivity check

🔹 2. What layer (OSI/TCP-IP) would you inspect next if DNS fails? If HTTP 500 shows up?

* DNS = Application layer (Layer 7)

But don’t jump there first.

Correct thinking:

```bash
Step 1 → Network layer (IP reachability)
Step 2 → Transport (port 53)
Step 3 → Application (DNS itself)
```

Practical flow:
```bash
ping 8.8.8.8              # Network layer (IP working?)
nc -zv 8.8.8.8 53         # Transport (DNS port reachable?)
dig google.com            # Application (DNS working?)
```

👉 If dig fails but ping works → DNS problem (Layer 7)

🔹 2.1. If HTTP 500 appears → what layer?

HTTP 500 = Application layer issue

👉 Important:

* Network is OK
* Port is open 
* Server responded 

But:

*  App crashed / bug / backend issue

Layers:

| Layer                        | Status   |
| ---------------------------- | -------- |
| Network                      | OK       |
| Transport (TCP 80/443)       | OK       |
| Application (web server/app) | broken |


🔹 3. Two follow-up checks you’d run in a real incident.

**Check 1: Service health**

```bash
sudo systemctl status <service>
journalctl -u <service> --no-pager
```

Finds:
* crashes
* misconfig
* startup failure
  
**Check 2: Port + binding verification**
```bash
ss -tulpn | grep <port>
```

Check:
* Is it listening?
* On 0.0.0.0 (external) OR 127.0.0.1 (local only)?
  
**Firewall**
```bash
sudo ufw status
iptables -L
```

**Cloud firewall**
* Security Groups
* Inbound rules (port allowed?)

---

### Insights

* `curl -I` quickly reveals HTTP status, headers, and redirects (application layer).
* `traceroute` shows hop-by-hop network path and latency (network layer).
* DNS can return multiple IPs for a domain (load balancing / redundancy).
* Some services behave differently on TCP vs UDP (e.g., DNS uses UDP by default).
* Service reachability depends on correct IP binding (`0.0.0.0` vs `127.0.0.x`).

---

#90DaysOfDevOps
#DevOpsKaJosh
#TrainWithShubham
#Happy Learning
