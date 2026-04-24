# Day 20 – Bash Scripting Challenge: Log Analyzer and Report Generator


## Challenge Tasks

### Task 1: Input and Validation
Validates input file path and existence.

   [validate](scripts/task1_validate.sh)
   
<img width="558" height="162" alt="image" src="https://github.com/user-attachments/assets/1522c54d-b51f-484c-a182-38833e8b6732" />



---

### Task 2: Error Count
Counts total ERROR and Failed occurrences.

   [ErrorCount](scripts/task2_error_count.sh)
   
  <img width="746" height="207" alt="image" src="https://github.com/user-attachments/assets/02e7f175-3832-4f5e-8bcf-d3a31737f64a" />


---

### Task 3: Critical Events
Displays CRITICAL events with line numbers.



   [critical.sh](scripts/task3/critical.sh)
   
  <img width="747" height="290" alt="image" src="https://github.com/user-attachments/assets/3543bc0c-c050-4106-aa7c-4496519c758d" />


---

### Task 4: Top Error Messages
Finds top 5 most frequent error messages.


   [TopErrorMessages](scripts/task4_top_errors.sh)
   
  <img width="645" height="261" alt="image" src="https://github.com/user-attachments/assets/19a6f89e-31e8-495d-ac8d-de9a3ba6dd45" />


---

### Task 5: Summary Report
Generates structured report file.

[SummaryReport](scripts/task5_report.sh)
[TextLogReport](scripts/log_report_2026-04-24.txt)

<img width="742" height="531" alt="image" src="https://github.com/user-attachments/assets/71a1015d-4200-464d-b054-f4f4f003c803" />


### Task 6 (Optional): Archive Processed Logs
Moves processed logs into archive folder.


   [archive](scripts/archive/sample_log.log)
   
   ![images](images/analyzer.png)

   <img width="648" height="423" alt="image" src="https://github.com/user-attachments/assets/3cfa84cc-f3d2-4239-af56-6dd4ce56b716" />



### 7. log_analyzer.sh
Combined script performing all tasks together.

[log_analyzer](scripts/log_analyzer.sh)

<img width="585" height="667" alt="image" src="https://github.com/user-attachments/assets/d78abbac-2ff9-4b2c-8e7c-10c22cffb1e1" />


### 8. log_generator.sh
Generates random log files for testing.

[log_generator](scripts/log_generator.sh)

<img width="956" height="797" alt="image" src="https://github.com/user-attachments/assets/0dfb4f0e-2f96-46f8-80ac-cbdff682bd55" />

---

## What I Learned
- How to break a larger automation problem into smaller focused scripts (input validation, error counting, critical events, top errors) and then combine them into one complete solution.
- How to use core Linux tools like grep, awk, sort, uniq, sed, and wc together to extract meaningful insights from raw log data.
- Bash scripting can automate real-world log analysis tasks efficiently.
- Combining grep + awk + sort + uniq is a powerful pattern for log processing and data analysis.
- The importance of defensive scripting—validating inputs and handling missing files before processing.
- How to generate structured summary reports with dynamic filenames using date.
- File handling and path management are critical when working with scripts that move or modify files.
- How to automate post-processing tasks like archiving analyzed logs to keep directories clean and organized.

