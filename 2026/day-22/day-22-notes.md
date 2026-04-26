# Day 22 – Introduction to Git: Your First Repository

## Challenge Tasks

### Task 1: Install and Configure Git
1. Verify Git is installed on your machine
2. Set up your Git identity — name and email
3. Verify your configuration

<img width="782" height="180" alt="image" src="https://github.com/user-attachments/assets/2b0962a8-ae1a-4b9a-9032-4d7f74c9d68b" />


### Task 2: Create Your Git Project
1. Create a new folder called `devops-git-practice`
2. Initialize it as a Git repository
3. Check the status — read and understand what Git is telling you
4. Explore the hidden `.git/` directory — look at what's inside

<img width="713" height="922" alt="image" src="https://github.com/user-attachments/assets/30070c85-092c-41cf-870c-256658fb8258" />


---

### Task 3: Create Your Git Commands Reference
1. Create a file called `git-commands.md` inside the repo
2. Add the Git commands you've used so far, organized by category:
   - **Setup & Config**
   - **Basic Workflow**
   - **Viewing Changes**
3. For each command, write:
   - What it does (1 line)
   - An example of how to use it

<img width="648" height="937" alt="image" src="https://github.com/user-attachments/assets/4b97d9b9-4b80-4d52-a7da-71376f58ef9b" />



### Task 4: Stage and Commit
1. Stage your file
2. Check what's staged
3. Commit with a meaningful message
4. View your commit history

<img width="901" height="405" alt="image" src="https://github.com/user-attachments/assets/75448b81-3bf4-4dcd-82b3-dad50e82968f" />



---

### Task 5: Make More Changes and Build History
1. Edit `git-commands.md` — add more commands as you discover them
2. Check what changed since your last commit
3. Stage and commit again with a different, descriptive message
4. Repeat this process at least **3 times** so you have multiple commits in your history
5. View the full history in a compact format

<img width="646" height="177" alt="image" src="https://github.com/user-attachments/assets/c1450871-6124-4260-8cfb-46b6ff07c366" />


---

### Task 6: Understand the Git Workflow
Answer these questions in your own words (add them to a `day-22-notes.md` file):
## 1. What is the difference between `git add` and `git commit`?
- `git add` tells Git which changes you want to include in the next commit.
- It moves selected changes from the working directory to the staging area.
- `git commit` saves those staged changes permanently in the repository with a message explaining what you changed.

In short:
- git add = prepare changes
- git commit = save changes

## 2. What does the **staging area** do? Why doesn't Git just commit directly?
The staging area is like a waiting room for changes. You choose what to include in your next commit.

It is an intermediate step where you prepare changes before committing them.

It allows you to:
- Select specific changes instead of committing everything
- Organize commits logically
- Review changes before saving them permanently

Git doesn’t commit directly because developers need better control over what goes into each commit. 
This helps in choosing exactly which changes to save and organizing commits properly.

## 3. What information does `git log` show you?
- `git log` displays the commit history of the repository.

It includes for each commit:
- Commit hash (ID)
- Author name and email
- Date of the commit
- Commit message

## 4. What is the `.git/` folder and what happens if you delete it?
- The `.git/` folder is the core of a Git repository. It stores all Git information for your project.

It contains:
- All commits and history
- Branch information
- Tags
- Configuration settings

If you delete the `.git/` folder:
- The project stops being a Git repository
- Git will no longer track your project
- All version history is permanently lost

## 5. What is the difference between a **working directory**, **staging area**, and **repository**?
- **Working Directory:** Where you create and modify files.
- **Staging Area:** Where you prepare selected changes for the next commit.
- **Repository:** Where all committed changes are stored permanently.

Flow:
- Working Directory → Staging Area → Repository
