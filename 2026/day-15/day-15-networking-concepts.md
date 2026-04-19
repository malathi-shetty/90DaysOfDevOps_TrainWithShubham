# Day 15 – Networking Concepts: DNS, IP, Subnets & Ports

## Overview
Today I learned the core networking building blocks every DevOps engineer must know:
- DNS resolution
- IP addressing (public vs private)
- CIDR & subnetting
- Ports and services

---

# Task 1: DNS – How Names Become IPs

## What happens when you type `google.com` in a browser?

1. Browser checks local DNS cache  
2. If not found, it queries a DNS resolver  
3. Resolver contacts root → TLD → authoritative DNS servers  
4. IP address is returned  
5. Browser creates TCP connection (HTTPS)  
6. HTTP request is sent → response received → page rendered  

👉 Flow:  
`URL → DNS → IP → TCP → TLS → HTTP → Response → Render`

---

## What are these record types? Write one line each: `A, AAAA, CNAME, MX, NS`


| Record    | Meaning                   | Real Example                                     |
| --------- | ------------------------- | ------------------------------------------------ |
| **A**     | Maps domain → IPv4        | `google.com → 142.250.73.142`                    |
| **AAAA**  | Maps domain → IPv6        | `google.com → 2404:6800:4009:80b::200e`          |
| **CNAME** | Alias → another domain    | `www.amazon.com → d3ag4hukkh62yn.cloudfront.net` |
| **MX**    | Mail server for domain    | `gmail.com → alt1.gmail-smtp-in.l.google.com`    |
| **NS**    | Authoritative DNS servers | `google.com → ns1.google.com, ns2.google.com`    |

 

---

## Run: dig google.com — identify the A record and TTL from the output

<img width="685" height="422" alt="image" src="https://github.com/user-attachments/assets/57ee782d-282a-4354-a37d-33f37dd90dd5" />


From your dig google.com output:

- A Record (IPv4 address) → 142.250.73.142
- TTL (Time To Live) → 141 seconds

👉 Meaning: Your system can cache this IP for **141 seconds** before asking DNS again.

---

# Task 2: IP Addressing

## What is IPv4?

An IPv4 address is a **32-bit numerical identifier** used to identify devices on a network.

* Format: `192.168.1.10`
* 4 octets (8 bits each)
* Range: 0–255 per octet

👉 Structure:

* Network portion
* Host portion

---

## Difference between public and private IPs — give one example of each

| Type    | Description           | Example      |
| ------- | --------------------- | ------------ |
| Public  | Internet accessible   | 8.8.8.8      |
| Private | Internal network only | 192.168.1.10 |

---

## What are the private IP ranges?
##  10.x.x.x, 172.16.x.x – 172.31.x.x, 192.168.x.x

* `10.0.0.0 – 10.255.255.255`
* `172.16.0.0 – 172.31.255.255`
* `192.168.0.0 – 192.168.255.255`

---

## Run: `ip addr show` — identify which of your IPs are private

<img width="885" height="355" alt="image" src="https://github.com/user-attachments/assets/9de82f8a-51e8-45e4-a995-c957d6dac06a" />


```bash
inet 172.31.32.167/20
inet 172.17.0.1/16
```

* **172.31.32.167** → Private (AWS instance)
* **172.17.0.1** → Private (Docker network)
* **127.0.0.1** → Loopback

---

# Task 3: CIDR & Subnetting

## What does `/24` mean in 192.168.1.0/24?

* `/24` → 24 bits for network
* Remaining 8 bits → hosts

---

## How many usable hosts in a /24? A /16? A /28?

```
Usable Hosts = 2^(32 - CIDR) - 2
```

| CIDR | Usable Hosts |
| ---- | ------------ |
| /24  | 254          |
| /16  | 65,534       |
| /28  | 14           |

---

## Why do we subnet?

* Reduce broadcast traffic
* Improve performance
* Increase security
* Efficient IP usage
* Better organization

---

## CIDR Table

| CIDR | Subnet Mask     | Total IPs | Usable Hosts |
| ---- | --------------- | --------- | ------------ |
| /24  | 255.255.255.0   | 256       | 254          |
| /16  | 255.255.0.0     | 65,536    | 65,534       |
| /28  | 255.255.255.240 | 16        | 14           |

---

# Task 4: Ports – The Doors to Services

## What is a port?

A port is a **logical endpoint** that identifies a service on a machine.

* IP → device
* Port → service

Example: `192.168.1.10:80`

---

## Why do we need ports?

* Multiple services on one machine
* Proper traffic routing
* Security control

---

## Common Ports

| Port  | Service |
| ----- | ------- |
| 22    | SSH     |
| 80    | HTTP    |
| 443   | HTTPS   |
| 53    | DNS     |
| 3306  | MySQL   |
| 6379  | Redis   |
| 27017 | MongoDB |

---

## Run `ss -tulpn` — match at least 2 listening ports to their services 

<img width="1002" height="403" alt="image" src="https://github.com/user-attachments/assets/b7988b61-4c56-4a8b-9869-4daf4fc47920" />


```bash
0.0.0.0:22      → SSH
127.0.0.53:53   → DNS
```

👉 Matches:

* **22 → SSH**
* **53 → DNS**

---

# Task 5: Putting It Together

## You run `curl http://myapp.com:8080` — what networking concepts from today are involved?

* DNS resolves domain → IP
* TCP connection to port 8080
* HTTP request sent
* Server responds

👉 Flow:
**DNS → IP → TCP → Port → HTTP**

---

## Your app can't reach a database at `10.0.1.50:3306` — what would you check first?

Check in order:

1. Network connectivity → `ping`
2. Port access → is 3306 open?
3. Firewall / security groups
4. Database service running
5. Binding (not just localhost)

👉 Rule:
**Network → Port → Firewall → Service**

---

# What I Learned

1. DNS translates domain names into IPs using a hierarchical system.
2. CIDR and subnetting define network size and improve efficiency & security.
3. Ports allow multiple services to run on a single machine and route traffic correctly.


#90DaysOfDevOps #DevOpsKaJosh #TrainWithShubham
