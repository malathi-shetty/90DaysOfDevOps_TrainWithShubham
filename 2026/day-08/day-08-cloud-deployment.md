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

<img width="2560" height="3382" alt="image" src="https://github.com/user-attachments/assets/d1f31c8b-e967-47c2-9a6c-3fcf02c800a6" />

<img width="1913" height="762" alt="image" src="https://github.com/user-attachments/assets/a5df82c4-056c-4a39-9fa0-010dc974d53c" />



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

<img width="2493" height="911" alt="image" src="https://github.com/user-attachments/assets/3e70221e-509e-42d0-8342-c8a233f7ac1c" />

<img width="772" height="825" alt="image" src="https://github.com/user-attachments/assets/d364f0e3-d982-4f01-8163-fa99eaf6f230" />



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

<img width="547" height="38" alt="image" src="https://github.com/user-attachments/assets/aa1e55a6-59fb-40ca-adfb-bbd75fe49378" />


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

<img width="1192" height="483" alt="image" src="https://github.com/user-attachments/assets/1178ccf1-0be0-42db-9100-43ebce2a86c6" />


---

## Part 3: Security Group Configuration & Web Access

- Added inbound rule:
  - Type: HTTP
  - Port: 80
  - Source: 0.0.0.0/0
 
  <img width="2122" height="627" alt="image" src="https://github.com/user-attachments/assets/bb48fced-6f46-4601-8e92-740e270c5376" />


### Test Web Access

Open browser:

```
http://<your-instance-ip>
```

✅ Nginx welcome page loaded successfully

<img width="1755" height="551" alt="image" src="https://github.com/user-attachments/assets/9748e06a-10dc-416b-b419-ecd6e0b9bfb9" />


---

## Part 4: Docker Apache container

### Run Apache container in Docker

```bash
docker run -d -p 8081:80 --name apache-server httpd
```

### Test Docker Apache

```bash
curl localhost:8081
```

<img width="1562" height="562" alt="image" src="https://github.com/user-attachments/assets/a64f73b8-74fc-488c-aa04-cfe8d0d72b8b" />



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


<img width="1907" height="881" alt="image" src="https://github.com/user-attachments/assets/f3aafcd7-7806-4ce1-af79-d645bf011234" />


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
