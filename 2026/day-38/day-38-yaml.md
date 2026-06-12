# Day 38 – YAML Basics

---

# Challenge Tasks

## Task 1: Key-Value Pairs

Created `person.yaml` with the following fields:
- `name`
- `role`
- `experience_years`
- `learning` (boolean)

### person.yaml

```yaml
---
name: Malathi Shetty
role: DevOps Learner
experience_years: 4
learning: true
```

### Verification

Used:

```bash
cat person.yaml
cat -T person.yaml
```

Result:
- File formatting was clean
- No tabs were present
- Proper `key: value` structure was maintained

> Note: If `^I` appears while using `cat -T`, it means tabs are present and should be replaced with spaces.

<img width="482" height="262" alt="image" src="https://github.com/user-attachments/assets/0fae060c-9393-4c71-a0fe-7d15fd65a22f" />


---

## Task 2: Lists

Updated `person.yaml` by adding:
- `tools` list
- `hobbies` list using inline format

### Updated person.yaml

```yaml
---
name: Malathi Shetty
role: DevOps Learner
experience_years: 4
learning: true

tools:
  - Docker
  - Kubernetes
  - Jenkins
  - Terraform
  - Git
  - Linux
  - Python
  - Shell

hobbies: [travelling, reading]
```

## Two Ways to Write Lists in YAML

### 1. Block Style List

```yaml
tools:
  - Docker
  - Kubernetes
  - Jenkins
```

- More readable for long lists

### 2. Inline Style List

```yaml
hobbies: [travelling, reading]
```

- Useful for short/simple lists

<img width="498" height="382" alt="image" src="https://github.com/user-attachments/assets/a458c5b7-c7ce-4452-bfee-9d9522f39b97" />


---

## Task 3: Nested Objects

Created `server.yaml` with nested objects.

### server.yaml

```yaml
---
server:
  name: web-server-01
  ip: 192.168.1.10
  port: 8080

database:
  host: localhost
  name: app_db
  credentials:
    user: admin
    password: secret123
```

### Validation

Validated using:

```bash
yamllint server.yaml
```

Result:
- No warnings or errors
- YAML structure was valid

### What Happens When Tabs Are Used?

When tabs are used instead of spaces, YAML validation failed because:
- YAML does not allow tabs for indentation
- Only spaces should be used

`found character '\t' that cannot start any token`

### Notes

- `---` marks the beginning of a YAML document
- It is optional in many tools but recommended by linters
- Proper indentation is critical in YAML

<img width="647" height="662" alt="image" src="https://github.com/user-attachments/assets/49699cfd-cf67-4a76-97ce-3b8ffb77230c" />


---

## Task 4: Multi-line Strings

Added multi-line strings using:
- `|` literal style
- `>` folded style

### Updated server.yaml

```yaml
---
server:
  name: web-server-01
  ip: 192.168.1.10
  port: 8080

database:
  host: localhost
  name: app_db
  credentials:
    user: admin
    password: secret123

startup_script_literal: |
  #!/bin/bash
  echo "Starting application"
  systemctl start nginx
  systemctl status nginx

startup_script_folded: >
  This startup script initializes
  the application services and
  starts nginx automatically.
```

## Difference Between `|` and `>`

### `|` Literal Block Style
Preserves line breaks exactly as written.

Best used for:
- Shell scripts
- Configuration files
- Commands
- Multi-line logs

Example:

```yaml
script: |
  echo "Hello"
  systemctl restart nginx
```

### `>` Folded Style
Converts multiple lines into a single line.

Best used for:
- Long descriptions
- Documentation text
- Readable paragraphs

Example:

```yaml
description: >
  This is a long message
  written across multiple lines
  but stored as one line.
```

Result:

```text
This is a long message written across multiple lines but stored as one line.
```
<img width="598" height="506" alt="image" src="https://github.com/user-attachments/assets/1354acd0-88d8-47f6-b863-7695336e1c92" />


---

## Task 5: Validate Your YAML

### Install yamllint

```bash
sudo apt update
sudo apt install yamllint -y
yamllint --version
```

### Validate YAML Files

```bash
yamllint person.yaml
yamllint server.yaml
```

If everything is correct, no errors will be shown.

### Intentionally Break Indentation

Example with incorrect indentation:

```yaml
tools:
   - Docker
  - Kubernetes
```

Validation output:

```bash
person.yaml
  9:3  error  syntax error: expected <block end>, but found '<block sequence start>' (syntax)
```

<img width="971" height="456" alt="image" src="https://github.com/user-attachments/assets/c7a7baf1-cf19-41df-a53d-fb75605ac670" />


### Fix the YAML

Correct indentation:

```yaml
tools:
  - Docker
  - Kubernetes
```

After fixing:
- Validation completed successfully
- No errors were reported

<img width="1005" height="1042" alt="image" src="https://github.com/user-attachments/assets/934419a5-9c8d-4e67-abe6-8323a6073f48" />


---

## Task 6: Spot the Difference

### Correct YAML

```yaml
name: devops
tools:
  - docker
  - kubernetes
```

Explanation:
- Both list items are aligned correctly
- Proper indentation is maintained

### Broken YAML

```yaml
name: devops
tools:
- docker
  - kubernetes
```

### What’s Wrong?

- `docker` is not indented under `tools`
- `kubernetes` has inconsistent indentation
- YAML requires consistent spacing

### Fixed Version

```yaml
name: devops
tools:
  - docker
  - kubernetes
```

### Key Lesson

- YAML is whitespace-sensitive
- Consistent indentation is mandatory
- Standard indentation is 2 spaces

---

# What I Learned

1. YAML uses spaces only — tabs can cause validation errors.
2. Proper indentation is very important because YAML is whitespace-sensitive.
3. Lists in YAML can be written in two ways:
   - Block style using `-`
   - Inline style using `[ ]`
4. Nested objects are created using indentation.
5. `|` preserves line breaks, while `>` folds text into a single line.
6. `yamllint` is useful for validating YAML syntax and formatting issues quickly.

---

# Conclusion

Today I learned the fundamentals of YAML syntax, including:
- Key-value pairs
- Lists
- Nested objects
- Multi-line strings
- YAML validation using yamllint

I also learned how important indentation and spacing are in YAML files.
