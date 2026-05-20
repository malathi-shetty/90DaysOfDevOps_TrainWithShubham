# Day 10 – File Permissions & File Operations Challenge

## 🔹 Task 1: Create Files

```bash
touch devops.txt
echo "These are my DevOps notes" > notes.txt
vim script.sh
```

Inside `vi`:
* Press `i` (insert mode)
* Add:

```bash
echo "Hello DevOps"
```

* Save and exit: `ESC + :wq`

Verify:

```bash
ls -l
```

---

## 🔹 Task 2: Read Files

```bash
cat notes.txt
vi -R script.sh
head -n 5 /etc/passwd
tail -n 5 /etc/passwd
```

---

## 🔹 Task 3: Understand Permissions

```bash
ls -l devops.txt notes.txt script.sh
```

### Output

```bash
-rw-r--r-- 1 user user 0 devops.txt
-rw-r--r-- 1 user user 25 notes.txt
-rw-r--r-- 1 user user 20 script.sh
```

### Explanation

* `rw-` → Owner: read & write
* `r--` → Group: read only
* `r--` → Others: read only
* No execute (`x`) permission → files cannot be run

---

## 🔹 Task 4: Modify Permissions

### 1. Make script executable

```bash
chmod +x script.sh
./script.sh
```

### 2. Make devops.txt read-only

```bash
chmod a-w devops.txt
```

### 3. Set notes.txt to 640

```bash
chmod 640 notes.txt
```

### 4. Create directory with 755

```bash
mkdir project
chmod 755 project
```

---

## 🔹 Task 5: Test Permissions

### 1. Write to read-only file

```bash
echo "test" >> devops.txt
```

Output:

```
Permission denied
```

**Permission Change:**

* Before: `-rw-r--r--`
* After: `-r--r--r--`

---

### 2. Execute without permission

```bash
chmod -x script.sh
./script.sh
```

 Output:

```
Permission denied
```

**Permission Flow:**

* Before execution: `-rwxr-xr-x`
* After removing execute: cannot run

---

### Directory Permission

```
project → drwxr-xr-x (755)
```

---

## 🔹 Understanding Permissions

Format: `rwxrwxrwx` (owner–group–others)

* `r = 4` → Read
* `w = 2` → Write
* `x = 1` → Execute

### Example: 664

* Owner → rw- (6)
* Group → rw- (6)
* Others → r-- (4)

---

## 🔹 Commands Used

```bash
touch devops.txt
echo "These are my DevOps notes" > notes.txt
vim script.sh
ls -l
cat notes.txt
vim -R script.sh
head -n 5 /etc/passwd
tail -n 5 /etc/passwd
chmod +x script.sh
chmod a-w devops.txt
chmod 640 notes.txt
mkdir project
chmod 755 project
```

---

## 🔹 What I Learned

* Linux file permissions control access using read, write, and execute.
* `chmod` modifies permissions using symbolic and numeric methods.
* Execute (`x`) permission is required to run scripts.
* Common permission sets:

  * `755` → rwxr-xr-x (directories)
  * `640` → rw-r----- (restricted files)
  * `444` → read-only (secure files)
* Avoid `777` as it grants full access to everyone.
* Always verify permissions using `ls -l`.

### Numeric 

* `7 = rwx`
* `6 = rw-`
* `5 = r-x`
* `4 = r--`

---

#90DaysOfDevOps #DevOpsKaJosh #TrainWithShubham #Happy Learning
