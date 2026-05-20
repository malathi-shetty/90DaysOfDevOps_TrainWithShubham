# Day 24 – Advanced Git: Merge, Rebase, Stash & Cherry Pick

## Challenge Tasks

### Task 1: Git Merge — Hands-On
1. Create a new branch `feature-login` from `main`, add a couple of commits to it

 <img width="622" height="105" alt="image" src="https://github.com/user-attachments/assets/5873eaa1-5499-43c2-9a1f-a7bbbacce698" />

<img width="1153" height="405" alt="image" src="https://github.com/user-attachments/assets/03ed4ad6-24b7-4d50-9884-da6ccdb943d5" />


2. Switch back to `main` and merge `feature-login` into `main`

3. Observe the merge — did Git do a **fast-forward** merge or a **merge commit**?
- `fast-forward`

  <img width="645" height="202" alt="image" src="https://github.com/user-attachments/assets/1b92d581-09f9-4085-9a08-8459203cd857" />

<img width="635" height="152" alt="image" src="https://github.com/user-attachments/assets/7ceddaac-3267-4bc3-b900-2b1cda7bb2b6" />


4. Now create another branch `feature-signup`, add commits to it — but also add a commit to `main` before merging

<img width="1181" height="655" alt="image" src="https://github.com/user-attachments/assets/a8728405-8f1b-46c7-82cf-b215876dd893" />

      
5. Merge `feature-signup` into `main` — what happens this time?
   - Merge conflicts happen because the same file is edited in two branches.


    <img width="852" height="865" alt="image" src="https://github.com/user-attachments/assets/e259da77-73e4-426d-aa0e-7dcf6c4741d5" />



   - Resolved conflict

     <img width="855" height="311" alt="image" src="https://github.com/user-attachments/assets/2ddbaf16-71c7-44a9-ad01-b10fae4499b4" />


   - git log

      <img width="785" height="242" alt="image" src="https://github.com/user-attachments/assets/f995d69d-733c-4120-a70e-a2b70839d7a4" />


#### 6. Answer in your notes:
##### What is a fast-forward merge?

- A fast-forward merge happens when the branch you are merging into has no new commits since the feature branch was created.
-  Git simply moves the pointer forward — no new commit is created.

Example
```bash
main:        A — B
feature:         \— C — D
```

If main has not changed:
```bash
After merge:
main: A — B — C — D
```
- No merge commit
- Linear history
- Very clean

##### When does Git create a merge commit instead?

A merge commit is created when both branches have diverged, meaning:

main has new commits
feature branch also has new commits
🧠 Example
main:    A — B — C
               \
feature:        D — E

After merge:

main: A — B — C — M
               \   /
                D — E

- Git creates a new commit (M)
- History is preserved
- Shows real collaboration


##### What is a merge conflict?

A merge conflict happens when Git cannot automatically decide which change to keep.

This occurs when:

- The same file
- The same line
- Is modified in two different branches

###### How to create a conflict (hands-on)

**Step 1: Create a file in main**
```bash
echo "Hello from main" > demo.txt
git add .
git commit -m "Add demo file in main"
```

**Step 2: Create a branch**
```bash
git checkout -b feature-branch
```

**Step 3: Modify same line in feature branch**
```bash
echo "Hello from feature branch" > demo.txt
git add .
git commit -m "Update demo in feature branch"
```

**Step 4: Switch back to main and modify same line**

```bash
git checkout main
echo "Hello from main updated" > demo.txt
git add .
git commit -m "Update demo in main branch"
```
**Step 5: Try merging**
```bash
git merge feature-branch
```
- Now Git will show conflict like:

```bash
<<<<<<< HEAD
Hello from main updated
=======
Hello from feature branch
>>>>>>> feature-branch
```

###### How to fix conflict
1. Open file
2. Choose correct content (or combine both)
3. Remove conflict markers
4. Then:
```bash
git add demo.txt
git commit -m "Resolve merge conflict"
```
---

### Task 2: Git Rebase — Hands-On
1. Create a branch `feature-dashboard` from `main`, add 2-3 commits

     <img width="952" height="405" alt="image" src="https://github.com/user-attachments/assets/7b7b61f6-4596-441f-8d5b-dabe520e06a3" />


2. While on `main`, add a new commit (so `main` moves ahead)

     <img width="822" height="201" alt="image" src="https://github.com/user-attachments/assets/308a583b-85dd-4fdf-aff8-b725ac5de469" />



3. Switch to `feature-dashboard` and rebase it onto `main`

    <img width="828" height="402" alt="image" src="https://github.com/user-attachments/assets/e7a83835-9d2e-4a03-ac45-92d0cf955f51" />



4. Observe your `git log --oneline --graph --all` — how does the history look compared to a merge?

     <img width="811" height="257" alt="image" src="https://github.com/user-attachments/assets/7d77bb83-dfa5-47c9-aa49-0fdc6bf8a3ed" />


#### 5. Answer in your notes:
##### What does rebase actually do to your commits?
  - Rebase rewrites commit history by taking all commits from your feature branch and replaying them one by one on top of the latest commit of the target branch (usually main).

- It makes your branch look like it was created from the latest state of main.

##### How is the history different from a merge?
   **Merge**
- Preserves exact history as it happened
- Creates a merge commit
- Keeps branch structure visible

 Result: Non-linear history (real collaboration view)

 **Rebase**
- Moves commits on top of another branch
- Rewrites commit history (new commit IDs)
- Produces a clean, linear history
- No merge commit is created

 Result: Linear, clean history (looks like straight line)
 
##### Why should you **never rebase commits that have been pushed and shared** with others?
Rebasing changes commit IDs (hashes).

If commits are already:

- pushed to remote
- pulled by other developers

Then rebasing causes:

- history mismatch
- duplicate commits
- serious merge conflicts
- broken collaboration workflow

 Rule: Never rebase public/shared branches

##### When would you use rebase vs merge?
**Use Rebase when:**
- working on your local feature branch
- you want a clean, linear history
- before raising a PR (cleanup commits)

**Use Merge when:**
- working in a team/shared branch
- you want to preserve full history
- you want to show real development flow

---

### Task 3: Squash Commit vs Merge Commit
1. Create a branch `feature-profile`, add 4-5 small commits (typo fix, formatting, etc.)

      <img width="1031" height="711" alt="image" src="https://github.com/user-attachments/assets/8001fb77-a52e-4cc2-881b-13a7bdfe4361" />


2. Merge it into `main` using `--squash` — what happens?

     <img width="762" height="287" alt="image" src="https://github.com/user-attachments/assets/5187b6ab-74c0-41d7-a035-6013bde11ecb" />


3. Check `git log` — how many commits were added to `main`?
   
   - Exactly one commit was added to the main branch.(12abdc7)

    <img width="756" height="413" alt="image" src="https://github.com/user-attachments/assets/2e59e0ba-4a17-41fb-bcc8-c0cdee3d439a" />


4. Now create another branch `feature-settings`, add a few commits

     <img width="907" height="437" alt="image" src="https://github.com/user-attachments/assets/e849c03a-b1ea-4f4a-bddc-0911bbfc40b3" />



5. Merge it into `main` **without** `--squash` (regular merge) — compare the history

   - A regular merge preserves every individual commits 0982efc and f90be94 directly in the main history.

    <img width="757" height="993" alt="image" src="https://github.com/user-attachments/assets/18d03a39-e0b7-48ea-8bbe-05be83ecf9dc" />



##### 6. Answer in your notes:
###### What does squash merging do?
 Squash merging combines all commits from a feature branch into a single commit before merging into main.

- Instead of keeping multiple small commits, Git creates one clean commit on the target branch.

Result:
- Clean and simplified commit history
- Individual commit history is not preserved

###### When would you use squash merge vs regular merge?
  **Squash Merge**

Use when:

- Feature branch has many small or messy commits
- You want a clean and readable main branch history
-  are preparing code for production or PR cleanup

Best for: clean Git history

**Regular Merge**

Use when:

- You want to preserve full commit history
- You need to show step-by-step development work
- Working in teams where history matters

Best for: transparency and collaboration tracking


###### What is the trade-off of squashing?
Squashing provides a clean and linear history, but it comes at a cost:

Advantages
- Clean main branch
- Easy-to-read history
- Removes noise from small commits

Disadvantages
- Loses detailed commit history
- Harder to track step-by-step changes
- Debugging older changes becomes harder

---

### Task 4: Git Stash — Hands-On
1. Start making changes to a file but **do not commit**

<img width="832" height="226" alt="image" src="https://github.com/user-attachments/assets/ac1b915c-d831-4eea-91f6-2b42bacdad99" />

2. Now imagine you need to urgently switch to another branch — try switching. What happens?
- If there is no conflict,git allows the switch and your changes move with you.
- If there is a conflict,git blocks the switch to prevent overwriting your changes.

<img width="767" height="140" alt="image" src="https://github.com/user-attachments/assets/4815dfa4-dd46-4c5d-8ea8-939a877d159e" />




3. Use `git stash` to save your work-in-progress
<img width="826" height="52" alt="image" src="https://github.com/user-attachments/assets/7b73bc61-ec6e-4116-9018-064cc8260132" />

4. Switch to another branch, do some work, switch back
<img width="837" height="191" alt="image" src="https://github.com/user-attachments/assets/2d516d9d-491d-4038-8916-a494bd4c2d24" />

5. Apply your stashed changes using `git stash pop`
<img width="791" height="227" alt="image" src="https://github.com/user-attachments/assets/656e9be3-5efc-4aed-afab-749f5aefb1aa" />

6. Try stashing multiple times and list all stashes
<img width="768" height="277" alt="image" src="https://github.com/user-attachments/assets/6e5248ab-993b-40ae-927b-33bba64ca05f" />

7. Try applying a specific stash from the list

     <img width="686" height="216" alt="image" src="https://github.com/user-attachments/assets/416fd515-4ada-4e65-9e69-e06f97b8509c" />



#### 8. Answer in your notes:
##### What is the difference between `git stash pop` and `git stash apply`?

**git stash pop**
- Restores stashed changes into your working directory
- Removes the stash entry from the stash list after applying it

Use when you are sure you no longer need that stash again

**git stash apply**
- Restores stashed changes into your working directory
- Keeps the stash entry in the stash list

 Use when you may need to reuse the same stash later

 | Command         | Applies Changes | Keeps Stash?   |
| --------------- | --------------- | -------------- |
| git stash pop   |  Yes           |  No (deleted) |
| git stash apply |  Yes           |  Yes (kept)   |


##### When would you use stash in a real-world workflow?
     You use `git stash` when you need to temporarily save unfinished work without committing it.

 Real-world scenario:
- You are working on a feature branch
- Suddenly a critical production bug comes in
- You need to switch branches immediately

Instead of committing incomplete work, you do:
```bash
git stash
git switch main
```
Then later:
```bash
git stash pop
```
- This allows smooth context switching without losing work
- Very common in real DevOps / production workflows

---

### Task 5: Cherry Picking
1. Create a branch `feature-hotfix`, make 3 commits with different changes

    <img width="892" height="492" alt="image" src="https://github.com/user-attachments/assets/7cb12859-351c-40f0-b618-cf45666a80e9" />


   
2. Switch to `main`

   - Before cherry-pick: `4b4eac0` Improve login error messages
      
     <img width="637" height="107" alt="image" src="https://github.com/user-attachments/assets/ab492ac4-bbb5-4f05-a24b-103530274b6a" />



3. Cherry-pick **only the second commit** from `feature-hotfix` onto `main`
   - After resolving conflict: `bc0d4bd` (HEAD -> main) Improve login error messages
   - The commit ID changed because cherry-pick creates a new commit

     <img width="1377" height="837" alt="image" src="https://github.com/user-attachments/assets/a042ce82-db83-406d-a774-849a0f62ea53" />



4. Verify with `git log` that only that one commit was applied

    <img width="763" height="268" alt="image" src="https://github.com/user-attachments/assets/95e093f6-f154-4553-9ad2-321b7dfaf20d" />




#### 5. Answer in your notes:
#####  What does cherry-pick do?
- git cherry-pick applies a specific commit from one branch into another branch.

-  It creates a new commit in the target branch with a new commit ID, even though the content comes from an existing commit.

 Result: Selective commit transfer between branches

   
##### When would you use cherry-pick in a real project?
   
  Cherry-pick is used when you need only specific changes, without merging the entire branch.

Real-world use case:
- A bug fix is done in a feature branch
- You need that fix immediately in main or production
- But you don’t want to merge the whole feature branch

In this case:
```bash
git cherry-pick <commit-hash>
```
Common in:

- Hotfix deployments
- Production bug fixes
- Selective feature rollout
   
##### What can go wrong with cherry-picking?
1. Merge conflicts
- Happens if the same file or line was modified in both branches
- Requires manual resolution

2. Duplicate or confusing history
- Cherry-pick creates a new commit ID
- Same change appears in multiple branches with different hashes

This can make Git history harder to understand if overused

---
