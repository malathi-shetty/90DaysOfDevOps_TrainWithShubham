# Day 33 – Docker Compose: Multi-Container Basics

## Challenge Tasks

### Task 1: Install & Verify
1. Check if Docker Compose is available on your machine
2. Verify the version

<img width="1232" height="1286" alt="image" src="https://github.com/user-attachments/assets/347ea6ed-2e3d-427b-8ff0-06b7f0d9db28" />


 


---

### Task 2: Your First Compose File
1. Create a folder `compose-basics`

<img width="567" height="138" alt="image" src="https://github.com/user-attachments/assets/b34f309f-e979-4da5-9baa-93d30178cc08" />

2. Write a `docker-compose.yml` that runs a single **Nginx** container with port mapping

<img width="701" height="240" alt="image" src="https://github.com/user-attachments/assets/14144d14-f277-45e8-8e33-73a828c0d1cf" />


3. Start it with `docker compose up`
4. Access it in your browser

<img width="2410" height="1161" alt="image" src="https://github.com/user-attachments/assets/bd2ad76b-69a9-45be-83af-96b57b86d25a" />


5. Stop it with `docker compose down`

<img width="1453" height="313" alt="image" src="https://github.com/user-attachments/assets/56508c6e-d3a3-4fb5-b3fd-72d90e8fc820" />


[docker-compose.yml](scripts/compose-basics/docker-compose.yml)

---

### Task 3: Two-Container Setup
Write a `docker-compose.yml` that runs:
- A **WordPress** container
- A **MySQL** container

They should:
- Be on the same network (Compose does this automatically)
- MySQL should have a named volume for data persistence
- WordPress should connect to MySQL using the service name

Start it, access WordPress in your browser, and set it up.

<img width="695" height="688" alt="image" src="https://github.com/user-attachments/assets/e695de83-7c93-4ea0-b562-3a6e239fd3d4" />

<img width="1902" height="1025" alt="image" src="https://github.com/user-attachments/assets/86959b95-9b76-4d63-960b-d8743faf0bdb" />


<img width="1913" height="796" alt="image" src="https://github.com/user-attachments/assets/1871ab8d-7207-429f-941a-ab7038f6f456" />

<img width="1907" height="1013" alt="image" src="https://github.com/user-attachments/assets/dac22313-5c4c-4435-a77d-4a9ce2e54409" />

<img width="1632" height="297" alt="image" src="https://github.com/user-attachments/assets/729749ed-5881-429e-ba7d-2b8e9cc78c30" />

<img width="1918" height="721" alt="image" src="https://github.com/user-attachments/assets/90f79705-deda-4e3e-a851-6f248530e185" />

<img width="1918" height="992" alt="image" src="https://github.com/user-attachments/assets/7a2bd493-6e0d-464c-afc8-3a659bd8cf6e" />

<img width="1918" height="883" alt="image" src="https://github.com/user-attachments/assets/86539d1e-9e4d-48f9-86cc-2df81c40fd78" />

**Verify:** Stop and restart with `docker compose down` and `docker compose up` — is your WordPress data still there?

- Yes,wordpress data is there.

<img width="1112" height="831" alt="image" src="https://github.com/user-attachments/assets/76638fa0-14f8-492d-9a8e-7b17c32c550e" />



[wordpress-compose](scripts/wordpress-compose/)
    

---

### Task 4: Compose Commands
Practice and document these:
1. Start services in **detached mode**

    `docker compose up -d`


2. View running services

    `docker compose ps`


3. View **logs** of all services
```bash
docker compose logs -f      # all services
docker compose logs -f db   # specific service
```

<img width="1638" height="1234" alt="image" src="https://github.com/user-attachments/assets/f985f079-a427-490f-bd7b-6a5d93acf233" />


5. View logs of a **specific** service

<img width="1625" height="1195" alt="image" src="https://github.com/user-attachments/assets/477b00c1-75af-4663-9105-a09a1c33c1f9" />


5. **Stop** services without removing

    `docker compose stop`
<img width="687" height="176" alt="image" src="https://github.com/user-attachments/assets/58940366-1506-4983-a490-ba16d30e39dd" />


6. **Remove** everything (containers, networks)

    `docker compose down`
<img width="900" height="428" alt="image" src="https://github.com/user-attachments/assets/0b9e5210-eb19-4da8-960d-5e7595189772" />


7. **Rebuild** images if you make a change

    `docker compose up --build`

<img width="1630" height="506" alt="image" src="https://github.com/user-attachments/assets/339635e6-6a9d-4751-ba84-bc0763a75856" />

Docker Compose = “Run multiple containers as one application”

---

### Task 5: Environment Variables
1. Add environment variables directly in your `docker-compose.yml`
2. Create a `.env` file and reference variables from it in your compose file
3. Verify the variables are being picked up

<img width="737" height="1383" alt="image" src="https://github.com/user-attachments/assets/532a5b43-8bc0-4662-9b3e-2c0621b9e0fd" />

<img width="882" height="993" alt="image" src="https://github.com/user-attachments/assets/a3f6d4b9-dfb4-4d4a-bb69-75a75d1e8387" />

<img width="857" height="1055" alt="image" src="https://github.com/user-attachments/assets/36a1004b-3914-4c91-a7e7-ada7c957cc33" />

    [db service file](scripts/envVar/db service/docker-compose.yml)

    [Env](scripts/envVar)
        


## Key Learnings

- Docker Compose runs multiple containers as a single application
- Services communicate using service names (DNS instead of IPs)
- Volumes persist data even if containers are deleted
- Environment variables help separate configuration from code
