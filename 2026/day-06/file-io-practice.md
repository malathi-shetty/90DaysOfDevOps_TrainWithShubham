# Day 06 – Linux Fundamentals: Read & Write Text Files

Practiced basic file operations: create, write, append, and read text files.

### 


---

🔹 Step 1: Create Folder
```
- mkdir devops
- cd devops
```

Purpose: Create and move into working directory

---

🔹 Step 2: Create File
``` 
touch notes.txt
```
Purpose: Creates an empty file

---

🔹 Step 3: Write to File (Overwrite)
```
echo "Today is Day 6/90 of my DevOps journey" > notes.txt
```
OR
```
cat > notes.txt
```
**Explanation:**

- ```>``` overwrites file content
- ```cat >``` allows manual input
- Redirection is used to write into file
  
---

🔹 Step 4: Append to File
```
echo "Linux file handling practice" >> notes.txt
echo "Understanding overwrite with >" >> notes.txt
echo "Appending new lines using >>" >> notes.txt
```
**Explanation:**

- ```>>``` appends content
- Existing data is preserved
  
---

🔹 Step 5: Write & Display using tee
```echo "Redirection is powerful" | tee -a notes.txt```

**Explanation:**

- tee writes + displays output
- -a appends

---

🔹 **Step 6: Add Multiple Lines (Heredoc)**
```
cat <<EOF >> heredoc.txt
cat reads full file
head reads top lines
tail reads bottom lines
These skills help in DevOps
EOF
```

**Explanation:**

- Adds multiple lines at once
- Useful for configs and scripts

---

🔹 Step 7: Read Full File
```
cat heredoc.txt
```

Purpose: 
- Displays full file content

---

🔹 Step 8: Read Top Lines
```
head heredoc.txt
head -n 2 heredoc.txt
head -n 3 heredoc.txt
```
**Explanation:**

- Default → 10 lines
- ```-n``` → specific lines

---

🔹 Step 9: Read Bottom Lines
```
- tail -n 2 heredoc.txt
- tail -n 3 heredoc.txt
```

Purpose: 
- Shows last lines (useful for logs)

---

🔹 Step 10: Search in File
```
cat heredoc.txt | grep head
```

Purpose: 
- Filters lines containing specific word

---

🔹 Step 11: Save Output + Display
```
tail -2 heredoc.txt | tee output.txt
```

Purpose:

- Saves output to another file
- Displays at same time

---

**Commands Practiced**
- touch → file creation
- echo > → overwrite
- echo >> → append
- tee → write + display
- cat → read full file
- head → read top lines
- tail → read bottom lines
- grep → search text
- heredoc → multi-line input

---

**Learnings**
- ```>``` overwrites file
- ```>>``` appends data
- tee -a writes + displays
- cat reads full file
- head/tail read partial content

- Logs, configs, and scripts are text files
- File handling is used daily in debugging and automation

---
Hashnode: https://90-days-devops-with-shubham.hashnode.dev/day-06-linux-fundamentals-mastering-file-read-write
---

#90DaysOfDevOps
#DevOpsKaJosh
#TrainWithShubham
#HappyLearningWithTrainWithShubham
