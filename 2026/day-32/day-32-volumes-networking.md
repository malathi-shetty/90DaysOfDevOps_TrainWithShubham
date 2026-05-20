# Day 32 – Docker Volumes & Networking

## Challenge Tasks

### Task 1: The Problem
1. Run a Postgres or MySQL container
    
<img width="937" height="497" alt="image" src="https://github.com/user-attachments/assets/a3a3a83e-a646-4803-bc05-2cc411eabbfa" />


2. Create some data inside it (a table, a few rows — anything)

<img width="793" height="431" alt="image" src="https://github.com/user-attachments/assets/3e6784c6-bef5-4d3a-a098-b3c890889494" />


3. Stop and remove the container

<img width="786" height="126" alt="image" src="https://github.com/user-attachments/assets/c7e142f5-b278-4b1a-b567-ea68b726ed22" />


4. Run a new one — is your data still there?

<img width="985" height="447" alt="image" src="https://github.com/user-attachments/assets/1791e74e-301c-4225-a107-e02e2583acce" />


##### is your data still there? Write what happened and why.

- No, DATA IS GONE
- Docker containers are ephemeral by design, meaning their filesystem is destroyed when the container is removed.
 That means:
   - Data is stored inside the container filesystem
   - When you run docker rm, the filesystem is deleted
   - So your database data is also gone

Think of it like:
   - A temporary VM that disappears when deleted
   - Without volumes:
     - Containers = stateless
     - Data = temporary

“I didn’t lose my data… I destroyed the container that was holding it.”

---

### Task 2: Named Volumes
1. Create a named volume

<img width="830" height="307" alt="image" src="https://github.com/user-attachments/assets/9b292ffb-b4bd-4fbd-a869-1b09dfe39614" />


2. Run the same database container, but this time **attach the volume** to it

<img width="1047" height="547" alt="image" src="https://github.com/user-attachments/assets/840b059c-3266-43ba-b499-9ffdf04394a6" />


3. Add some data, stop and remove the container

<img width="1180" height="1122" alt="image" src="https://github.com/user-attachments/assets/554b7fcb-3e3b-4eea-935c-5d44503f88e8" />


4. Run a brand new container with the **same volume**

<img width="1051" height="720" alt="image" src="https://github.com/user-attachments/assets/eeb13ef1-2057-43ac-bc00-3b3595e1c905" />

5. Is the data still there?
    - Yes, all previous data (tables and rows) persisted successfully.

Earlier:
 - Data was inside container → deleted with container 

Now:
 - Data is inside volume (pg-data) → independent of container 

### Key Concept

- Container = App
- Volume = Hard Disk

Even if container dies:
- Volume still exists

Before:

“Deleting container = losing everything”

Now:

“Container is disposable, data is not”

---

### Task 3: Bind Mounts
1. Create a folder on your host machine with an `index.html` file

<img width="593" height="125" alt="image" src="https://github.com/user-attachments/assets/b04ca65f-2956-4350-b403-b81c02e2227c" />


2. Run an Nginx container and **bind mount** your folder to the Nginx web directory

<img width="790" height="357" alt="image" src="https://github.com/user-attachments/assets/4ca5e6b9-41b4-4ff3-a991-948813357a56" />


3. Access the page in your browser

<img width="633" height="316" alt="image" src="https://github.com/user-attachments/assets/0688bbac-c7b8-4ca8-ac86-946c921167cd" />


4. Edit the `index.html` on your host — refresh the browser

<img width="1103" height="408" alt="image" src="https://github.com/user-attachments/assets/4d9fedb3-7fb4-4dd2-807e-4663c96ea96a" />

[mysite/index.html](scripts/mysite/index.html)



**What Just Happened**
- Your host folder = directly mounted into container
- Nginx reads files from that folder
- Any change on host = instantly reflected in container

**Volumes vs Bind Mounts**
    
**Volumes:**
- Managed by Docker.
- Stored in a part of the host filesystem (/var/lib/docker/volumes) which is managed by Docker.
- Not directly visible/editable easily
- Best for:
  - Databases
  - Persistent production data

**Bind Mounts:**
- Direct mapping to host filesystem
- You control exact folder
- Changes reflect instantly
- Best for:
  - Development
  - Live editing (code, HTML, configs)
 
**Simple Analogy**
- Volume = Docker-managed hard drive
- Bind Mount = Plugging your laptop folder directly into container

- Volumes are managed by Docker and ideal for persistence,
- while bind mounts directly map host directories and are ideal for development and real-time file updates.

---

### Task 4: Docker Networking Basics
1. List all Docker networks on your machine

<img width="593" height="141" alt="image" src="https://github.com/user-attachments/assets/5fddc10b-c157-45b2-ac74-a2ab81d8a746" />


- The bridge network is the default one.

2. Inspect the default `bridge` network

<img width="970" height="1161" alt="image" src="https://github.com/user-attachments/assets/26627dcc-f833-41f2-a28f-4a103572c043" />


- `docker network inspect` is the command used to retrieve detailed configuration and status information about a specific Docker network.
- This shows how Docker assigns internal IPs.

3. Run two containers on the default bridge — can they ping each other by **name**?


- Both are now on the default bridge network.
- Ubuntu image is minimal, so install ping
- Containers CANNOT resolve each other by name on default bridge.
    
<img width="897" height="845" alt="image" src="https://github.com/user-attachments/assets/39c5c809-9f71-4445-8064-5866367d04bc" />


4. Run two containers on the default bridge — can they ping each other by **IP**?

<img width="661" height="343" alt="image" src="https://github.com/user-attachments/assets/3758ec53-2120-4014-b25a-a1533a498f65" />


-   Yes
-   Containers on default bridge are isolated and don’t “know” each other by name.

| Test                | Result  |
| ------------------- | ------- |
| Ping by name (`c2`) |  Fail  |
| Ping by IP          |  Works |

**Why This Happens**
Default bridge network:
- No built-in DNS
- No name resolution
- Works using IP only

This is why:
- Default bridge is rarely used in real apps
- Custom networks are preferred


---

### Task 5: Custom Networks
1. Create a custom bridge network called `my-app-net`

<img width="642" height="206" alt="image" src="https://github.com/user-attachments/assets/9905268d-51ad-4373-8785-98997018dd57" />


2. Run two containers on `my-app-net`
3. Can they ping each other by **name** now?

- `yes they can ping each other by name`

<img width="765" height="843" alt="image" src="https://github.com/user-attachments/assets/dec96d75-1894-4586-88f5-f401a61150cb" />



4. Why does custom networking allow name-based communication but the default bridge doesn't?

**Default Bridge Network**
- No built-in DNS
- No automatic name resolution
- Containers must use IP addresses

**Custom Bridge Network (User-defined)**
- Has embedded DNS server
- Automatically resolves container names → IPs
- Enables service discovery

**Simple Explanation**

- On custom networks, Docker acts like a mini DNS server.

So when you do:
```bash
ping c4
```
Docker internally converts:
```bash
c4 → 172.x.x.x
```

- Custom Docker networks support name-based communication because they include an embedded DNS server that resolves container names to IP addresses.
- The default bridge network does not provide this feature, so containers must communicate using IP addresses.

---

### Task 6: Put It Together
1. Create a custom network
2. Run a **database container** (MySQL/Postgres) on that network with a volume for data
3. Run an **app container** (use any image) on the same network
4. Verify the app container can reach the database by container name

<img width="1185" height="1396" alt="image" src="https://github.com/user-attachments/assets/0d032958-4053-46b0-84c5-c2a3b68d46f4" />

### Result
- The app container successfully connected to the database using the container name `mydb`
- This confirms Docker's embedded DNS is working within the custom network

---

##  Final Takeaways

- Containers are ephemeral → data is lost without volumes
- Named volumes provide persistent storage independent of containers
- Bind mounts enable real-time file syncing for development
- Default bridge network lacks DNS-based service discovery
- Custom networks enable container communication using names
- Real-world applications combine volumes + networks for reliability
