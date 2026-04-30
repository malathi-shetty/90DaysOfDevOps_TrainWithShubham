# Day 26 – GitHub CLI: Manage GitHub from Your Terminal

### Task 1: Install and Authenticate
1. Install the GitHub CLI on your machine

<img width="872" height="430" alt="image" src="https://github.com/user-attachments/assets/319a8a92-8914-43ba-a29d-57e0a83d2a0b" />



2. Authenticate with your GitHub account

<img width="682" height="368" alt="image" src="https://github.com/user-attachments/assets/2a275cac-3076-4197-ab5a-6c21a5267112" />

<img width="2228" height="1027" alt="image" src="https://github.com/user-attachments/assets/fd492ff2-2323-4a82-9a91-1439314b96ea" />

<img width="1659" height="1312" alt="image" src="https://github.com/user-attachments/assets/f6731410-1675-4e50-9666-635c1b9d36ed" />

<img width="1116" height="666" alt="image" src="https://github.com/user-attachments/assets/cb43cfcd-67ec-49ac-aa04-d2a4fffdf88d" />


3. Verify you're logged in and check which account is active 

<img width="851" height="973" alt="image" src="https://github.com/user-attachments/assets/3ceaec32-2353-4e23-a2eb-1cab1b8dd494" />



4. Answer in your notes:
 ### What authentication methods does `gh` support?
1. Browser-based OAuth (recommended)
   - Opens browser for secure login

2. Personal Access Token (PAT)
   - Useful for automation and CI/CD

3. SSH authentication
   - Uses existing SSH keys

4. GitHub Enterprise authentication
   - For enterprise environments
     
---

### Task 2: Working with Repositories
1. Create a **new GitHub repo** directly from the terminal — make it public with a README

   <img width="873" height="430" alt="image" src="https://github.com/user-attachments/assets/9b6fae56-62cc-4c46-9e96-cbe4ff219a66" />

<img width="2082" height="1055" alt="image" src="https://github.com/user-attachments/assets/864a5835-366e-4429-949a-9348f4b71a52" />


2. Clone a repo using `gh` instead of `git clone`

   <img width="678" height="198" alt="image" src="https://github.com/user-attachments/assets/ff211516-3c73-4fe9-be4e-0569f7e7d49f" />


3. View details of one of your repos from the terminal

    <img width="858" height="237" alt="image" src="https://github.com/user-attachments/assets/9831a6c5-2d59-4e13-9048-aa4606cceb21" />


4. List all your repositories

    <img width="1330" height="630" alt="image" src="https://github.com/user-attachments/assets/faf3b986-294c-421d-807f-190f97646c3f" />


5. Open a repo in your browser directly from the terminal

   <img width="2157" height="1171" alt="image" src="https://github.com/user-attachments/assets/074871cb-ba0d-4b1a-a421-0fa28f7219fa" />


6. Delete the test repo you created (be careful!)

   <img width="1537" height="657" alt="image" src="https://github.com/user-attachments/assets/295b19fb-f338-495e-a380-83c2fff84382" />


---

### Task 3: Issues
1. Create an issue on one of your repos from the terminal — give it a title, body, and a label

  <img width="2363" height="1247" alt="image" src="https://github.com/user-attachments/assets/ec2fa838-fa86-465c-bdb5-767009581383" />


2. List all open issues on that repo

  <img width="777" height="191" alt="image" src="https://github.com/user-attachments/assets/8f97cf80-dc3f-434f-a61a-fd92f66e80b2" />


3. View a specific issue by its number

  <img width="776" height="247" alt="image" src="https://github.com/user-attachments/assets/abb63736-62f8-4fc7-bfea-681d42490693" />


4. Close an issue from the terminal

  <img width="2192" height="878" alt="image" src="https://github.com/user-attachments/assets/f93974d5-a8a6-419e-acc5-140f66376f4e" />



<img width="2541" height="1320" alt="image" src="https://github.com/user-attachments/assets/b94dab78-0ff7-4065-803f-a9053f667d41" />


   https://github.com/malathi-shetty/gh-cli-day26-repo/issues?q=is%3Aissue%20state%3Aclosed

6. Answer in your notes: How could you use `gh issue` in a script or automation?
 By combining `gh issue` commands in scripts, we can automate issue management in real DevOps workflows
 For example:
        - Check open issues
        - Add comments
        - Close issues

    - Example:
        ```bash
        gh issue list --repo malathi-shetty/gh-cli-day26-repo
        gh issue create --repo malathi-shetty/gh-cli-day26-repo --title "Bug: Login API failing" --body "Users are unable to login via API. Needs investigation."
        gh issue comment 1 --body "Checked automatically" --repo malathi-shetty/gh-cli-day26-repo
        gh issue close 2 --comment "Issue Resolved" --repo malathi-shetty/gh-cli-day26-repo
        gh issue list --state closed --repo malathi-shetty/gh-cli-day26-repo
        ```
Overall, `gh issue` allows GitHub issue management to be fully automated and integrated into DevOps pipelines.

---

### Task 4: Pull Requests
1. Create a branch, make a change, push it, and create a **pull request** entirely from the terminal

    <img width="2557" height="1288" alt="image" src="https://github.com/user-attachments/assets/743fdd3b-1cd6-4f12-be80-3b10fcb86ee6" />


2. List all open PRs on a repo

<img width="867" height="235" alt="image" src="https://github.com/user-attachments/assets/7b7b3271-2eda-4878-ac82-c59d181b64dc" />


3. View the details of your PR — check its status, reviewers, and checks

    <img width="903" height="133" alt="image" src="https://github.com/user-attachments/assets/11ebd193-395f-4172-879b-8480ab007a03" />



4. Merge your PR from the terminal

   <img width="2503" height="1170" alt="image" src="https://github.com/user-attachments/assets/a536ee53-1359-4342-89d2-f3d3cdcf9572" />



   https://github.com/malathi-shetty/gh-cli-day26-repo/pull/3 

6. Answer in your notes:

   - What merge methods does `gh pr merge` support?

    - --merge   (create a merge commit)
    - --squash  (combine all commits into one)
    - --rebase  (rebase and merge)

   - How would you review someone else's PR using `gh`?
    - gh pr checkout <pr-number>
    - gh pr view <pr-number>
    - gh pr review <pr-number> --approve
    - gh pr review <pr-number> --comment --body "Looks good"
    - gh pr review <pr-number> --request-changes

---

### Task 5: GitHub Actions & Workflows (Preview)
1. List the workflow runs on any public repo that uses GitHub Actions

<img width="1203" height="985" alt="image" src="https://github.com/user-attachments/assets/6018d6cd-8431-4050-86ed-bcfe8b9547e7" />


2. View the status of a specific workflow run

   <img width="1201" height="967" alt="image" src="https://github.com/user-attachments/assets/93473bad-6249-40f7-bbad-89028d1a72d3" />


3. Answer in your notes:
   How could `gh run` and `gh workflow` be useful in a CI/CD pipeline?

gh run and gh workflow help to:

- Check workflow status
- Monitor CI/CD pipelines
- Debug failed builds
- View logs from terminal
- Automate deployment checks

They allow you to manage workflows directly from scripts without manual interaction.
  
Example:

`gh run list --repo owner/repo`
`gh run view <run-id> --repo owner/repo`

---

These commands can be used in CI/CD pipelines to automate PR checks, issue tracking, and deployment monitoring.
