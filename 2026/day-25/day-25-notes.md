# Day 25 – Git Reset vs Revert & Branching Strategies

## Challenge Tasks

### Task 1: Git Reset — Hands-On
##### 1. Make 3 commits in your practice repo (commit A, B, C)

<img width="745" height="431" alt="image" src="https://github.com/user-attachments/assets/c2044313-a57d-49da-89a5-aa626a14ba0e" />



##### 2. Use `git reset --soft` to go back one commit — what happens to the changes?
   
<img width="788" height="637" alt="image" src="https://github.com/user-attachments/assets/8e7f691b-c5ea-44af-94b7-50f49edd240d" />

**Observation:**
- Commit C is removed from history
- Changes from C are still staged
- File is ready to commit again

##### 3. Re-commit, then use `git reset --mixed` to go back one commit — what happens now?
  
<img width="717" height="310" alt="image" src="https://github.com/user-attachments/assets/54c198c8-212a-4f0d-a9bc-7d7208a81275" />

**Observation:**
- Commit C is removed
- Changes are not staged
- File is modified but unstaged

##### 4. Re-commit, then use `git reset --hard` to go back one commit — what happens this time?
 

  <img width="705" height="463" alt="image" src="https://github.com/user-attachments/assets/57710ccb-61e6-48a8-94cd-70d9f765e924" />

**Observation:**
- Commit C is removed
- Changes are completely deleted
- Working tree is clean

#### 5. Answer in your notes:
#### 5.1 What is the difference between `--soft`, `--mixed`, and `--hard`?

Think of Git like this:

* **HEAD** → your last commit (the snapshot Git remembers)
* **Staging area** → what will go into the *next* commit
* **Working directory** → your actual files on disk


 **Now imagine this timeline**

You had:

```
A → B → C   (HEAD at C)
```

Then you ran:

```bash
git reset --soft HEAD~1
```

Now:

```
A → B   (HEAD here)
```

But the changes from **C** are still sitting in staging.


 **What each mode REALLY does**

  **`--soft` (only moves HEAD)**

 “Pretend last commit never happened, but keep everything ready to commit again”

* HEAD → moved back
* Staging → stays (keeps C changes)
* Files → unchanged

**Case:**

```bash
git status
```

shows:

```bash
modified: file.txt   (staged)
```

Because Commit C became staged changes.



 🔹**`--mixed` (default)**

 “Undo commit AND unstage everything”

* HEAD → moved back
* Staging → cleared
* Files → still have changes

So:

```bash
git reset HEAD~1
```

Result:

* Changes from C are now **unstaged**
* You must `git add` again



**`--hard` (dangerous)**

 “Erase everything and go back in time”

* HEAD → moved back
* Staging → cleared
* Files → wiped to match commit

So:

```bash
git reset --hard HEAD~1
```

Result:

* Commit C gone
* Changes gone from files too



**Simple analogy** 

Imagine writing an assignment:

* **HEAD** = submitted version
* **Staging** = final draft ready to submit
* **Working dir** = rough notes

| Command   | What happens                           |
| --------- | -------------------------------------- |
| `--soft`  | un-submit, but final draft still ready |
| `--mixed` | un-submit, draft becomes rough notes   |
| `--hard`  | delete everything and go back          |



**Before reset:**

```
HEAD → C
Staging → clean
Files → clean
```

**After `--soft`:**

```
HEAD → B
Staging → changes from C
Files → same as before
```


**Why output makes sense**

```bash
modified: file.txt
```

This was your last commit’s change, now waiting to be recommitted



| Mode      | Keyword     | Meaning                                  |
| --------- | ----------- | ---------------------------------------- |
| `--soft`  | **KEEP**    | Keep everything (staged + files)         |
| `--mixed` | **UNSTAGE** | Unstage changes (files still there)      |
| `--hard`  | **DELETE**  | Delete everything (gone from everywhere) |

---

#### 5.2 Which one is destructive and why?

      ```bash
        git reset --hard
      ```
- Because it deletes all changes from:
  - staging area
  - working directory
- Data is lost permanently (unless recovered via git reflog)

---

#### 5.3 When would you use each one?

- `--soft` → Fix last commit (edit message or combine commits)
- `--mixed` → Unstage changes to modify them
- `--hard` → Discard all changes completely

---

##### 5.4 Should you ever use `git reset` on commits that are already pushed?

No (generally)

- It rewrites commit history
- Can break other developers’ work

 Only safe if:

- You are working alone OR
- You understand and use git push --force

---

### Task 2: Git Revert — Hands-On
1. Make 3 commits (commit X, Y, Z)

<img width="697" height="427" alt="image" src="https://github.com/user-attachments/assets/6d354062-aaf1-4988-a97e-dd9ef0f62d99" />

2. Revert commit Y (the middle one) — what happens?

<img width="937" height="651" alt="image" src="https://github.com/user-attachments/assets/d9e40479-69f9-47dd-a40a-2af645c9e6be" />

  **What happens now?**
    - Git creates a new commit to reverse it
    - But X and Z still exist

3. Check `git log` — is commit Y still in the history?
  <img width="552" height="301" alt="image" src="https://github.com/user-attachments/assets/bb4cdd19-4881-4f04-8216-c2ba0a119cec" />

Observations
- A new commit is created
- Changes from Y are removed But commit Y still exists in history
- History is preserved

4. Answer in your notes:
   - How is `git revert` different from `git reset`?
- git revert:
 - Creates a new commit
 - Undoes changes safely
 - Keeps history intact
- git reset:
 - Moves HEAD backward
 - Can remove commits from history
 - Rewrites history


   - Why is revert considered **safer** than reset for shared branches?

- It does NOT rewrite history
- Everyone’s commit history stays consistent (Safe for shared branches)
- No risk of breaking others’ work

   - When would you use revert vs reset?
- Use git revert:
 - On shared branches (main, develop)/pushed branches
 - After pushing commits
   - Want to undo changes safely
   - Want full history preserved     
 - When working in a team
- Use git reset:
 - Working on local branches
 - Rewriting history before pushing
 - For cleaning up commits


reset = "pretend commit never happened"  (dangerous if shared)
revert = "this happened, but we are undoing it safely by adding a new commit"  (safe)

---

### Task 3: Reset vs Revert — Summary

|                                      | `git reset`                                                   | `git revert`                                                    |
| ------------------------------------ | ------------------------------------------------------------- | --------------------------------------------------------------- |
| **What it does**                     | Moves HEAD to a previous commit (can rewrite history)         | Creates a new commit that undoes changes from a specific commit |
| **Removes commit from history?**     |  Yes                                                          |  No                                                            |
| **Safe for shared/pushed branches?** |  No                                                           |  Yes                                                           |
| **When to use**                      | Local cleanup, undo commits before pushing, rewriting history | Undo changes safely on shared/public branches                   |



---

### Task 4: Branching Strategies

1. **GitFlow**
    
Think of building an app

You don’t:
- build everything directly in production 
- you build → test → release → fix

GitFlow just organizes this process.

## Step-by-Step Flow (Very Simple)
1. main → Production
`main = live app (users are using it)`
- Only stable code goes here
- Never break this

2. develop → Work in progress
`develop = where team combines all features`
- Not live yet
- Used for testing integration

3. feature → Your work
`feature/login → build login feature`

**Flow:**

`develop → feature → develop`

You:
- create branch
- do work
- merge back

4. release → Prepare for launch
`develop → release → main`
- Fix bugs
- Test everything
- Then deploy

5. hotfix → Emergency fix
`main → hotfix → main + develop`
- Something broke in production 😬
- Fix fast
- Update both branches

---

SIMPLE DIAGRAM (Use THIS)

```bash
main ───────────── production

   \
    develop ───── integration
      \
       feature/*
      /
develop

      \
       release/*
      /       \
develop       main

main
  \
   hotfix/*
  /       \
main     develop


```
---

#### One-Line Flow 
```bash
Feature → Develop → Release → Main
Hotfix → Main → Develop
```

 **When/where it's used:**

    - Products with scheduled release cycles
    - Large teams
    - Systems needing version control (e.g., enterprise apps)

    **Pros:** 
    - Clear separation of concerns across features,releases,and hotfixes.
    - Clear structure
    - Supports parallel development
    - Stable releases

    **Cons:** 
    - Can result in long-lived branches,increasing the risk of merge conflicts.
    - Complex workflow
    - Slower delivery



#### Real-Life Analogy
- feature → building parts
- develop → assembling
- release → testing
- main → selling
- hotfix → fixing customer issues

#### Remember ONLY this:
- Don’t work directly on main
- Use feature branches
- Merge into develop
- Release → main
- Fix urgent bugs with hotfix

  



2. **GitHub Flow**

    **How it works:**

    - Everything in `main` should always be production-ready.
    - Create a `feature branch` from `main`
    - Make commits and push to the feature branch
    - Open a pull request(PR) for code review and automated tests.
    - Once approved, merge back to `main`.
    - Deploy immediately after merge.
    
Create feature branch → open PR → review → merge → deploy

    **Text Diagram:**
    ```text  
   
      [main] (Always Production-Ready)
        |
        o (Start)
        |
        |\_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 
        |                               \
        |                                \ [feature/login]
        |                                 |
        |                                 o (Commit 1)
        |                                 |
        |                                 o (Commit 2)
        |                                 |
        |                                 o (Pull Request & Review)
        |<_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _/
        |                               
        o (Merge & Auto-Deploy)
        |
        v
    ```

    **When/where it's used:**
    - Web applications
    - Continuous deployment environments
    - Most open-source projects

     **Pros:**
    - Simple and easy to follow
    - Fast development and deployment
    - Encourages code review
    
     **Cons:**
     - Can cause frequent merge conflicts in large teams
     - Less control over release versions

3. **Trunk-Based Development**

    **How it works:**

    - Single main branch (trunk)
    - Developers commit directly to main or use short-lived branches
    - Changes are small, incremental
    - Frequent commits and integrations

     **Text Diagram:**
     ```text
      [main] (The Trunk)
        |
        o (Start)
        |
        |\_ _ _ _ _ _ _ 
        |             \
        |              o (Dev A: Small Change)
        |<_ _ _ _ _ _ /
        |             /
        o (Merge & Test)
        |
        |\_ _ _ _ _ _ _ 
        |             \
        |              o (Dev B: Small Change)
        |<_ _ _ _ _ _ /
        |             /
        o (Merge & Test)
        |
        v
    ```

    **When/where it's used:**
    - SaaS products / fast-moving apps
    - CI/CD environments
    - High-performance engineering teams


    **Pros:**
    - Delivers the fastest feedback from dev to prod
    - Fast integration
    - Fewer merge conflicts
    - Continuous delivery friendly

    **Cons:**
    - Can be risky without tests
    - Requires strong testing/CI

4. Answer:

   - Which strategy would you use for a startup shipping fast?
        - Trunk-Based Development (best)
        - or GitHub Flow
        
   - Which strategy would you use for a large team with scheduled releases?

        - GitFlow

   - Which one does your favorite open-source project use?

        - [ https://github.com/jeffersonRibeiro/react-shopping-cart ] (GitHub Flow)
        - Uses GitHub Flow (feature branches + pull requests)

---

### Task 5: Git Commands Reference Update

https://github.com/malathi-shetty/devops-git-practice/blob/master/git-commands.md

