# Day 23 – Git Branching & Working with GitHub

### Task 1: Understanding Branches
1. What is a branch in Git?
- A branch is a separate line of development in a Git repository.
- It allows you to work on features, bug fixes, or experiments without affecting the main codebase.
- You can think of it as an isolated copy of your project.

2. Why do we use branches instead of committing everything to `main`?
- Keeps the main branch stable and production-ready
- Allows multiple developers to work independently
- Makes it easier to test features before merging
- Prevents breaking the main codebase

3. What is `HEAD` in Git?
- `HEAD` is a reference to your current position in the repository.
- It usually points to the latest commit on the current branch, but can also point directly to a specific commit (detached HEAD).
- It tells Git where you are in the project.

4. What happens to your files when you switch branches?
- Git updates your working directory to match the selected branch
- Files may change, appear, or disappear depending on the branch
- If you have uncommitted changes, Git may prevent switching to avoid losing work

---

### Task 2: Branching Commands — Hands-On

1. List all branches in your repo
- `git branch`

     <img width="608" height="85" alt="image" src="https://github.com/user-attachments/assets/a29ef59b-7f52-4387-9cdd-890fc96d50ad" />


2. Create a new branch called `feature-1`
- `git branch feature-1`

   <img width="737" height="72" alt="image" src="https://github.com/user-attachments/assets/8d8befb8-2a90-4b61-99ba-e74dd5e4aa38" />


3. Switch to `feature-1`
- `git switch feature-1`
     
     <img width="691" height="72" alt="image" src="https://github.com/user-attachments/assets/01fc1092-a616-4937-8e39-67a65eaa8310" />


4. Create a new branch and switch to it in a single command — call it `feature-2`
- `git switch -c feature-2`
- `git checkout -b feature-3`

    <img width="748" height="161" alt="image" src="https://github.com/user-attachments/assets/d8717016-ac03-4010-b128-883b465c5e64" />



5. Try using `git switch` to move between branches — how is it different from `git checkout`?
- `git switch <branch>`   : Used only for switching branches (simpler and safer)
- `git checkout <branch>` : Multi-purpose command (switch branches + restore files)

   <img width="702" height="257" alt="image" src="https://github.com/user-attachments/assets/8278bcfc-9a7e-4156-971e-9a82849e51b2" />


6. Make a commit on `feature-1` that does **not** exist on `main`
- `git commit -m "Add git branch command section to git-commands.md"`

  <img width="968" height="236" alt="image" src="https://github.com/user-attachments/assets/1a7816ee-0465-4c66-9557-93e87e7b5d60" />


7. Switch back to `master` — verify that the commit from `feature-1` is not there

    <img width="1184" height="405" alt="image" src="https://github.com/user-attachments/assets/1cb3a211-ec38-434e-a578-409a4d524c67" />


8. Delete a branch you no longer need
- `git branch -d feature-2`

    <img width="723" height="87" alt="image" src="https://github.com/user-attachments/assets/5b1b1d68-c07b-44d8-ab4a-2e4748de2a69" />


9. Add all branching commands to your `git-commands.md`

    https://github.com/malathi-shetty/devops-git-practice/blob/master/git-commands.md

   If you have uncommitted changes, Git may prevent switching branches to avoid losing work

---

### Task 3: Push to GitHub
1. Create a **new repository** on GitHub (do NOT initialize it with a README)

     <img width="1711" height="1065" alt="image" src="https://github.com/user-attachments/assets/9a0c3d43-29db-4b93-8efa-cd2ef0d8fe33" />


2. Connect your local `devops-git-practice` repo to the GitHub remote

<img width="1660" height="497" alt="image" src="https://github.com/user-attachments/assets/715f7132-a953-4df7-91ba-8c0edb87aad3" />


3. Push your `master/main` branch to GitHub

    <img width="736" height="297" alt="image" src="https://github.com/user-attachments/assets/b3fd4fa6-3279-403e-a0a7-f1a8f4561d56" />


4. Push `feature-1` branch to GitHub

    <img width="817" height="346" alt="image" src="https://github.com/user-attachments/assets/7d3a5aaf-0b68-41e6-8d9b-460f2f482e4f" />



5. Verify both branches are visible on GitHub

   <img width="1203" height="801" alt="image" src="https://github.com/user-attachments/assets/4a05281f-50bd-42d7-93ed-107657a54690" />


6. What is the difference between `origin` and `upstream`?
- `origin`: Your repository (where you push changes)
  Example: https://github.com/malathi-shetty/devops-git-practice

- `upstream`: The original repository you forked from
  Example: https://github.com/jeffersonRibeiro/react-shopping-cart

---

### Task 4: Pull from GitHub

1. Make a change to a file **directly on GitHub** (use the GitHub editor)

    <img width="2141" height="1136" alt="image" src="https://github.com/user-attachments/assets/35b25f0b-3f79-4e50-9251-c698dff58531" />


2. Pull that change to your local repo

   <img width="1002" height="1077" alt="image" src="https://github.com/user-attachments/assets/3960d1a8-4ace-42bc-87d2-cf5d90c71d01" />


3. What is the difference between `git fetch` and `git pull`?
- `git fetch`: downloads changes but does NOT merge
- `git pull` : downloads AND merges changes into your current branch

- git pull = git fetch + git merge (done automatically)


### Task 5: Clone vs Fork
1. **Clone** any public repository from GitHub to your local machine

    <img width="1146" height="307" alt="image" src="https://github.com/user-attachments/assets/c429f8db-d574-4986-ac3d-b9e574a9b293" />



2. **Fork** the same repository on GitHub, then clone your fork

    <img width="2050" height="892" alt="image" src="https://github.com/user-attachments/assets/30a1aa64-2573-45db-96c5-cf37ce89db4f" />


<img width="1091" height="356" alt="image" src="https://github.com/user-attachments/assets/ecf585ed-8456-4457-a715-efd8cb852f4b" />



3. What is the difference between clone and fork?

        - `clone` :
              - Copies a repository to your local machine
              - No connection to your GitHub account
        - `fork` :
              - Creates a copy of a repository in your GitHub account
              - Used for contributing to other projects
   
4. When would you clone vs fork?
   
        - `clone when`:
             - You just want a local copy
             - You have direct access to the repo

        - `fork when`
             - You want to contribute to someone else’s project
             - You don’t have write access
             
             
5. After forking, how do you keep your fork in sync with the original repo?
   
      - After forking and cloning my fork, I add the original repository as an upstream remote.Then I fetch changes from upstream, merge the upstream default branch into my current branch,and push the updates to my fork.
      - Example:
        ```bash
        # Add upstream repo
          git remote add upstream https://github.com/original-owner/repo.git
        
        git checkout main

        # Fetch updates
        git fetch upstream

        # Merge updates
        git merge upstream/main
        git push origin main
        ```
    <img width="1172" height="766" alt="image" src="https://github.com/user-attachments/assets/cd925551-7c32-4990-a768-e8a6629f0142" />

    In real-world projects, developers create feature branches instead of working directly on the main/master branch. This helps in code review, testing, and maintaining a stable production environment.

---

#90DaysOfDevOps #DevOpsKaJosh #TrainWithShubham
