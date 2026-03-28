**1. What is Infrastructure as Code (IaC)? Why does it matter in DevOps?**

“Infrastructure as Code means creating infrastructure using code instead of manually clicking in the cloud console.”

For example, instead of going to AWS and creating an EC2 server step by step, I can use Terraform and write a small file. Then with one command, the server is created automatically.

----

**Simple Example:**

**Without IaC (Manual way)**

You:

- Log into AWS
- Click “Create EC2”
- Choose settings
- Launch server

*Every time you do this, you might:*

- Forget something
- Make mistakes
- Do things differently

---

**With IaC (Code way)**

*You write a file like this (example using Terraform):*

```
resource "aws_instance" "my_server" {
  ami           = "ami-123456"
  instance_type = "t2.micro"
}
```

Then run a command:

`terraform apply`

- Server is created automatically

---

**Why IaC Matters in DevOps:**

*1. Makes infrastructure Repeatable*

You can create the same setup again anytime
- Same server, same config, no surprises

*2. Reduces Human Errors*

No manual clicking = fewer mistakes
- Code runs exactly as written

*3. Automation Friendly + CI/CD integration*

You can connect IaC with CI/CD pipelines
- Servers get created automatically when needed

*4. Everything is version-controlled (like code)*

Your infrastructure code can be saved in Git

You can:

- Track changes
- Roll back if something breaks
- Collaborate with team

*5. Reusable*

Write once, use many times
- Same code works for dev, test, and production

**Super Simple Summary**

1. IaC = Managing infrastructure using code instead of manual setup
   ```
   IaC = Write code → Create infrastructure → No manual work
   ```
3. It helps DevOps by making systems:
- Consistent
- Automated
- Easy to manage
- Less error-prone


----

**2. What problems does IaC solve compared to manually creating resources in the AWS console?**


IaC solves many problems that we face when creating resources manually in the AWS console.

1. **Inconsistency**
- When we create resources **manually**, dev, test, and production _environments can be different_.
- _Example:_
-- Dev = 2GB RAM,
-- Prod = 4GB RAM → causes bugs

**IaC Fix**, the same code creates identical environments every time.

2. **Human Errors**
- Manual steps can lead to mistakes like wrong configurations or missing settings.
- _Example:_ Forgot to open port 80 → website not accessible

**IaC Fix:** Reduces mistakes because everything is predefined in code.

3. **No Repeatability** 
- Manually recreating the same infrastructure is difficult.
- _Example:_ Can’t easily rebuild same infrastructure for staging
  
**IaC Fix:** We can reuse the same file and recreate infrastructure anytime.

4. **No Version Control**
- In manual setup, we don’t know who changed what.
- _Example:_  Someone changed config → no idea who or why

**IaC Fix:**  Store code in Git to track changes and roll back if needed.

5. **Time-Consuming Process** 
- Creating resources manually takes time, especially at scale.
- _Example:_ Need 10 servers → repeat the same steps 10 times

**IaC Fix:**  Automates the process and creates multiple resources in seconds with one command.

6. **Team Collaboration Issues** 
- Manual setups depend on individuals and can vary between team members.
- Knowledge is not shared.
- _Example:_ Each person sets things differently

**IaC Fix:**  Standardizes the process and make team collaboration easier.

7. **No Visibility Before Changes** 
- In manual setup, we don’t know the impact before making changes.
- _Example:_ Update config → unexpected issues

**IaC Fix:**  Tools like Terraform provide a plan (`terraform plan`) to preview changes before applying them.

8. **Scaling difficulties**
- Manual work doesn’t scale well as infrastructure grows.
- _Example:_ Adding 50 servers manually is difficult

**IaC Fix:**  Using variables and loops → Allows us to create multiple resources easily.

9. **Configuration Drift** 
- Manual changes in the console can make systems inconsistent.
- _Example:_ Someone changes settings in AWS console → config mismatch

**IaC Fix:**  IAC helps detect and fix these differences to keep infrastructure consistent.

“So overall, IaC makes infrastructure consistent, automated, scalable, and easier to manage compared to manual setup.”









---

How is Terraform different from AWS CloudFormation, Ansible, and Pulumi?

---

What does it mean that Terraform is "declarative" and "cloud-agnostic"?
