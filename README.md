# DBProject

## Database Mini Project  
**Submitted by:** Hila Chaimov, Talya Yakov  
**System:** Attractions and Tourism  
**Selected Unit:** Review System  

---

# Table of Contents

1. [Introduction](#introduction)
2. [System Screens Designed with AI](#system-screens-designed-with-ai)
3. [Link to AI Studio](#link-to-ai-studio)
4. [ERD Diagram](#erd-diagram)
5. [DSD Diagram](#dsd-diagram)
6. [Design Decisions](#design-decisions)
7. [Data Insertion Methods](#data-insertion-methods)
8. [Backup and Restore](#backup-and-restore)
9. [Missing Items to Complete](#missing-items-to-complete)

---

# Introduction

This project presents a database design for an **Attractions and Tourism** system, focusing on a **Review System**.

The purpose of the system is to manage reviews written by customers about tourist attractions and to support interactions around these reviews.  
The system stores information about customers, attractions, tickets, reviews, reactions to reviews, and reports submitted on reviews.

The main functionality of the system includes:
- managing customers and their registration details
- storing attractions and their categories
- managing tickets purchased for attractions
- allowing customers to write reviews for purchased attractions
- allowing customers to react to reviews
- allowing customers to report reviews when needed

The system was designed in a **top-down approach**, as required in the project instructions: first, we designed the screens using Google AI Studio, and then we derived the database structure and relationships from the screens and the required functionality. :contentReference[oaicite:1]{index=1}

---

# System Screens Designed with AI

In the first stage of the project, we designed the system screens using **Google AI Studio**.  
These screens helped us understand the user flow and define the database entities and relationships.
<img width="597" height="584" alt="צילום מסך 2026-03-17 012201" src="https://github.com/user-attachments/assets/c2a88a53-8df7-433d-879e-c3d4f69b1ef2" />
<img width="908" height="604" alt="צילום מסך 2026-03-17 012146" src="https://github.com/user-attachments/assets/408ef400-e74c-4752-b2ac-6290c0962f55" />
<img width="1524" height="771" alt="צילום מסך 2026-03-17 012138" src="https://github.com/user-attachments/assets/3130d251-c7e8-4302-9d2a-f1042de7f803" />
<img width="1735" height="751" alt="צילום מסך 2026-03-17 012106" src="https://github.com/user-attachments/assets/e9fe2307-079b-4d9c-826e-c6a3ebed6f9c" />
<img width="911" height="788" alt="צילום מסך 2026-03-17 012240" src="https://github.com/user-attachments/assets/b1f7e65b-ef5c-48ad-bd71-a64afafe46dc" />


---

# Link to AI Studio

[Open the AI Studio App](https://ai.studio/apps/1da9ab35-02f4-4f42-80d1-14f1e5014ec7)

---

# ERD Diagram

The following ERD describes the main entities in the system and the relationships between them.

<img width="4512" height="1902" alt="erdplus (1)" src="https://github.com/user-attachments/assets/391c44bf-60ce-4bc0-a108-985ad8a48be6" />

---

# DSD Diagram

The following DSD presents the relational schema generated from the ERD design.

<img width="4512" height="1902" alt="erdplus (2)" src="https://github.com/user-attachments/assets/586a90d7-e036-473c-80a2-cb3a18d12e20" />

---

# Design Decisions

During the design process, we made several important decisions:

## 1. Separation into Main Functional Entities
We divided the system into several core entities:
- **Customer** – stores customer personal and registration details
- **Attraction** – stores information about attractions
- **Ticket** – stores ticket purchase and visit information
- **Review** – stores customer reviews on attractions
- **ReviewReaction** – stores reactions to reviews
- **ReviewReport** – stores reports submitted about reviews

This separation makes the database clearer, reduces redundancy, and supports normalization.

## 2. Review System Based on Actual Visits
The system connects reviews to tickets, which helps represent a more realistic logic: reviews are related to actual attraction visits and not just random submissions.

## 3. Support for User Interaction
We added separate entities for:
- **ReviewReaction**
- **ReviewReport**

This allows the system not only to store reviews, but also to support customer interaction and moderation processes.

## 4. Use of Meaningful Date Attributes
The database includes several important date fields, such as:
- `purchase_date`
- `visit_date`
- `review_date`
- `reaction_date`
- `report_date`
- `decision_date`
- `deleted_date`
- `register_date`

Using multiple meaningful date attributes follows the project requirement and also supports future queries and system tracking. :contentReference[oaicite:2]{index=2}

## 5. Normalization Considerations
The schema was designed to support at least **3NF**, in order to reduce duplication and preserve consistency between customers, attractions, tickets, reviews, and reports. :contentReference[oaicite:3]{index=3}

## 6. Optional Fields
Some fields were intentionally defined as optional, such as:
- attraction description
- review title
- deleted date
- report description
- admin decision
- decision date

This allows more flexibility in real system usage.

---

# Data Insertion Methods

According to the project requirements, data should be inserted using at least three methods. At the moment, two methods were selected/planned in this project: Python-generated CSV files and manual insertion. A third method still needs to be completed if it has not yet been prepared. :contentReference[oaicite:4]{index=4}

## Method 1 – CSV Files Generated by Python Script

In this method, a Python script was used to generate CSV files containing data for the database tables.

### Description
This method is useful for generating a large amount of structured data efficiently and preparing it for import into the database.

### Screenshot
![CSV Generation Screenshot](PASTE_CSV_SCREENSHOT_HERE)

### Relevant Files
- Python script that generates CSV files
- CSV files for the relevant tables
- SQL import file for loading the CSV data into the database

---

## Method 2 – Manual Insertion

In this method, data was inserted manually using SQL `INSERT` statements.

### Description
This method is useful for testing the schema, verifying constraints, and inserting initial sample records.

### Screenshot
![Manual Insert Screenshot](PASTE_MANUAL_INSERT_SCREENSHOT_HERE)

### Relevant Files
- `insertTables.sql` or another manual insert SQL file

---

## Method 3 – mockaroo
<img width="1882" height="734" alt="image" src="https://github.com/user-attachments/assets/16fb511e-e711-4332-9a16-66c10e2024b1" />
<img width="1877" height="756" alt="צילום מסך 2026-04-14 135335" src="https://github.com/user-attachments/assets/d30c59d6-d064-4c4e-99d8-0d0cdde8e73d" />



### Screenshot
![Third Method Screenshot](PASTE_THIRD_METHOD_SCREENSHOT_HERE)

### Relevant Files
- `PASTE_RELEVANT_FILES_HERE`

---

# Backup and Restore

<img width="879" height="678" alt="image" src="https://github.com/user-attachments/assets/bcf5ba63-19cd-48e5-8ba1-b2f6deb2ce33" />

- a restore process
- screenshots of both actions in the README :contentReference[oaicite:6]{index=6}

## Backup
Not completed yet.

## Restore
Not completed yet.

---

# Missing Items to Complete

The following items are still missing and should be added before submission:

1. The AI-generated screen screenshots  
2. ERD image file inside the repository  
3. DSD image file inside the repository  
4. Screenshots for:
   - CSV generation/import
   - manual insertion
   - third insertion method
5. A third data insertion method  
6. Backup screenshot  
7. Restore screenshot  
8. Exact file/folder names in the repository

---

# Summary

This project presents a database for an **Attractions and Tourism** system with a focus on a **Review System**.

The database was designed based on AI-generated screens and includes the main entities required for storing customers, attractions, tickets, reviews, reactions, and reports.

At this stage, the project already includes:
- system definition
- AI Studio link
- ERD and DSD design
- design decisions
- two selected data insertion methods

The remaining parts to complete are mainly:
- screenshots
- third insertion method
- backup and restore documentation
