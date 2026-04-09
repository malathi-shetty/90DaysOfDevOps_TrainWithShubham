Day 02 – Linux Architecture, Processes & systemd

Linux Architecture (Simple View)
---

Think of Linux like a restaurant:

Customer (You) → Waiter → Kitchen → Cooking Equipment

In Linux terms:

User → Applications → Shell → Kernel → Hardware

---

🔹 Applications (What you use)

These are the tools you open daily.

Examples:

Code editor (like VS Code)
Browser (Chrome)
Terminal
Docker

- These run in user space (they don’t directly touch hardware)

Real-life example:
Like ordering food from a menu — you don’t go into the kitchen yourself.

-----

🔹 Shell (The middleman)

The shell is where you type commands.
It takes your instructions and passes them to the system.

Examples:
- bash
- zsh

Common commands:
- ls → list files
- cd → change folder
- mkdir → create folder

- It acts like a translator between you and the system

Real-life example:
The waiter who takes your order to the kitchen.

---

🔹 Kernel (The brain)

This is the core of Linux (written in C).

It controls:

- CPU (processing)
- Memory (RAM)
- Disk (storage)
- Devices (keyboard, mouse)

- It connects software to hardware (via system calls)

- It handles communication between software and hardware (acts like a bridge)

Real-life example:
The chef in the kitchen who actually cooks your food.

(User space = where apps run, Kernel space = where core system runs)

----

🔹 Hardware (The physical stuff)

This includes:

CPU
RAM
Hard disk
Input/output devices

Real-life example:
The stove, utensils, and ingredients used to cook.

---

**How a Command Works**

When you type a command:

`Command → Shell → Program → Kernel → Hardware → Output`

Example:
You type ls
→ Shell understands it
→ Kernel fetches file list
→ You see output

---

**Core Concepts**
- Everything in Linux is treated like a file
- Every running program = a process
- Shell = messenger
- Kernel = brain

---

**Boot Process**

When you turn on your system:

1. Power ON
2. BIOS checks hardware
3. GRUB loads Linux kernel
4. Kernel starts
5. **systemd (PID 1)** starts
6. Services like nginx, ssh, docker start

In short: system wakes up step-by-step

---

**systemd & Process Management**

🔹 What is systemd?

It’s the system manager.

- First process started (PID 1)
- Controls everything after boot

 It manages:

- Starting services
- Service dependencies
- Logs (journald)
- Restarting failed services

systemd manages services using units (service files/configs)

**Real-life example:**
Like a manager in a company making sure every department runs properly.

---

**Processes in Linux**

A process = a running program

Example:
Opening Chrome = starting a process

Each process has a unique PID (Process ID)

---

🔹**How processes are created**

fork() → creates a copy (child process)
exec() → loads a new program into it

Example:
Make a copy → assign a job

---

🔹 Process States
---
- Running (R) → actively working
- Sleeping (S) → waiting (like waiting for input)
- Stopped (T) → paused
- Zombie (Z) → finished but not cleaned
- Uninterruptible (D) → waiting for disk/network

**Real-life example:**
Like people in an office:
- Working
- Waiting
- On hold
- Done but paperwork pending

Useful Linux Commands
---
**File & Folder**
- touch → create file
- mkdir → create folder
- cp → copy
- mv → move
- rm → delete

**Network**
- ip addr → check IP
- ping google.com → test internet

---

**System Monitoring**
- df -h → disk usage
- free -h → memory usage

---

**Process Management**
- ps aux → show all processes
- ps -a → active processes
- top → live system view
- ps aux | grep name → search process
- kill <PID> → stop process

-----

**Service Management (systemd):**
- systemctl start <service>
- systemctl stop <service>
- systemctl status <service>
- systemctl restart <service>
- systemctl enable <service>
- journalctl → check logs

---

**Why This Matters (DevOps)**

Linux runs most servers in the world.

Knowing this helps me:
- Debug crashes
- Fix slow systems
- Monitor performance

systemd helps in:
- Managing services
- Troubleshooting issues
- Automating tasks

---

**Summary**
- Linux works in layers
- Kernel = brain, Shell = communicator, systemd = manager
- Processes are everything running in the system
- Commands + systemd = daily control tools

---

here’s my work: notes in some more depth:

- https://90-days-devops-with-shubham.hashnode.dev/devops-overview-my-day-02-learning-a
-  https://90-days-devops-with-shubham.hashnode.dev/devops-overview-my-day-02-learning-b
 - https://90-days-devops-with-shubham.hashnode.dev/devops-overview-my-day-02-learning-c
-  https://90-days-devops-with-shubham.hashnode.dev/devops-overview-my-day-02-learning-d
 - https://90-days-devops-with-shubham.hashnode.dev/devops-overview-my-day-02-learning-e

---

Use hashtags: #90DaysOfDevOps #DevOpsKaJosh #TrainWithShubham

Happy Learning
TrainWithShubham
