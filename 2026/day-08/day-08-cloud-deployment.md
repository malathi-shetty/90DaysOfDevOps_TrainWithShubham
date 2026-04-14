# Day 08 – Cloud Server Setup: Docker, Nginx & Web Deployment

Deployed a real web server on a cloud VM, expose it securely to the internet, and collect logs — simulating a real-world DevOps workflow.

---

## Cloud Environment
- Provider: AWS EC2 (Free Tier)
- OS: Ubuntu 22.04 LTS
- Instance Type: t2/t3.micro
- SSH Tool: Terminal / Git Bash / PuTTY
- Web Server: Nginx
- Container Runtime: Docker

https://github.com/malathi-shetty/90DaysOfDevOps_TrainWithShubham/blob/master/2026/day-08/Images/Launch-an-instance-EC2.png?raw=true

https://github.com/malathi-shetty/90DaysOfDevOps_TrainWithShubham/blob/master/2026/day-08/Images/EC2-Instance.png?raw=true

---

## Part 1: Launch EC2 Instance & SSH Access

### Step 1: Create EC2 Instance
- Launched Ubuntu EC2 instance
- Created and downloaded key pair (`.pem` / `.ppk`)
- Configured Security Group:
  - SSH (22) → My IP
  - HTTP (80) → Anywhere (0.0.0.0/0)

### Step 2: Connect via SSH

```bash
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@<your-instance-ip>
```

[📸 Screenshot: `ssh-connection.png`](https://github.com/malathi-shetty/90DaysOfDevOps_TrainWithShubham/blob/master/2026/day-08/Images/ssh-connection1.png?raw=true)

https://github.com/malathi-shetty/90DaysOfDevOps_TrainWithShubham/blob/master/2026/day-08/Images/ssh-connection.png?raw=true

---

## Part 2: Install Docker & Nginx

### Step 1: Update System

```bash
sudo apt update && sudo apt upgrade -y
```

---

### Step 2: Install Docker

```bash
sudo apt install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker
```

### Verify Docker

```bash
sudo docker run hello-world
```

### Avoid using sudo

```bash
sudo usermod -aG docker ubuntu
newgrp ubuntu
```

https://github.com/malathi-shetty/90DaysOfDevOps_TrainWithShubham/blob/master/2026/day-08/Images/docker%20group.png?raw=true

---

### Step 3: Install Nginx

```bash
sudo apt install nginx -y
```

### Start & Enable Nginx

```bash
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl status nginx
```

### Verify Locally

```bash
curl localhost
```

---

## Part 3: Security Group Configuration & Web Access

- Added inbound rule:
  - Type: HTTP
  - Port: 80
  - Source: 0.0.0.0/0
 
  https://github.com/malathi-shetty/90DaysOfDevOps_TrainWithShubham/blob/master/2026/day-08/Images/Inbound%20Rules%20.png?raw=true

### Test Web Access

Open browser:

```
http://<your-instance-ip>
```

✅ Nginx welcome page loaded successfully

[📸 Screenshot: `nginx-webpage.png`](https://github.com/malathi-shetty/90DaysOfDevOps_TrainWithShubham/blob/master/2026/day-08/Images/nginx-webpage.png?raw=true)

---

## Part 4: Docker Apache container

### Run Apache container in Docker

```bash
docker run -d -p 8081:80 --name apache-server httpd
```

### Test Docker Nginx

```bash
curl localhost:8081
```

https://github.com/malathi-shetty/90DaysOfDevOps_TrainWithShubham/blob/master/2026/day-08/Images/Apache%20container.png?raw=true

---

## Extract Nginx Logs

### Step 1: View Logs

```bash
sudo tail -f /var/log/nginx/access.log
sudo cat /var/log/nginx/error.log
```

---

### Step 2: Save Logs to File

```bash
sudo cp /var/log/nginx/access.log ~/nginx-logs.txt
sudo chown ubuntu:ubuntu ~/nginx-logs.txt
```

### Verify File

```bash
ls -l ~/nginx-logs.txt
cat ~/nginx-logs.txt
```

---

### Step 3: Download Logs to Local Machine

```bash
scp -i your-key.pem ubuntu@<your-instance-ip>:~/nginx-logs.txt .
```

[📸 Screenshot: `logs_capture.png`](https://github.com/malathi-shetty/90DaysOfDevOps_TrainWithShubham/blob/master/2026/day-08/Images/docker-nginx.png?raw=true)

---

## Commands Used

1. chmod 400 your-key.pem  
2. ssh -i your-key.pem ubuntu@<ip>  
3. sudo apt update && sudo apt upgrade -y  
4. sudo apt install docker.io -y  
5. sudo systemctl start docker  
6. sudo systemctl enable docker  
7. sudo docker run hello-world  
8. sudo usermod -aG docker ubuntu  
9. newgrp ubuntu  
10. sudo apt install nginx -y  
11. sudo systemctl start nginx  
12. sudo systemctl enable nginx  
13. sudo systemctl status nginx  
14. curl localhost  
15. docker run -d -p 8080:80 nginx  
16. curl localhost:8080  
17. sudo tail -f /var/log/nginx/access.log  
18. sudo cp /var/log/nginx/access.log ~/nginx-logs.txt  
19. sudo chown ubuntu:ubuntu ~/nginx-logs.txt  
20. scp -i your-key.pem ubuntu@<ip>:~/nginx-logs.txt .
21. docker run -d -p 8081:80 --name apache-server httpd
22. docker ps -a
23. curl localhost:8081

---

## Challenges Faced

-  SSH permission denied → fixed using `chmod 400`
-  Nginx not accessible → opened port 80 in security group
-  Docker permission issue → added user to docker group
-  SCP failed initially → ran command on local machine instead of server
-  Permission issue copying logs → used `sudo` and `chown`

---

## What I Learned

- How to launch and manage a cloud server using AWS EC2  
- Importance of Security Groups (firewall rules)  
- Installing and managing services like Docker & Nginx  
- Running applications inside containers  
- Accessing and exporting logs for debugging  

---



Successfully deployed a cloud-based Nginx web server, exposed it to the internet, ran a containerized version using Docker, and collected logs for monitoring — completing a full basic DevOps workflow.
