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
<img width="995" height="857" alt="image" src="https://github.com/user-attachments/assets/03b0044f-af53-4c7d-9d0c-74d8692d03a7" />

### Relevant Files
- `DataImportFiles/generate_csv_data.py`
- `DataImportFiles/customer.csv`
- `DataImportFiles/attraction.csv`
- `DataImportFiles/ticket.csv`
- `DataImportFiles/review.csv`
- `DataImportFiles/reviewreaction.csv`
- `DataImportFiles/reviewreport.csv`
- `DataImportFiles/import_from_csv.sql`
---

## Method 2 – Manual Insertion

In this method, data was inserted manually using SQL `INSERT` statements.

### Description
This method is useful for testing the schema, verifying constraints, and inserting initial sample records.

### Screenshot
<img width="1066" height="844" alt="image" src="https://github.com/user-attachments/assets/64be801e-17a7-442e-83c6-fcac554aa4d9" />


### Relevant Files
- `insertTables.sql`

---

## Method 3 – mockaroo


### Screenshot
<img width="1882" height="734" alt="image" src="https://github.com/user-attachments/assets/16fb511e-e711-4332-9a16-66c10e2024b1" />
<img width="1877" height="756" alt="צילום מסך 2026-04-14 135335" src="https://github.com/user-attachments/assets/d30c59d6-d064-4c4e-99d8-0d0cdde8e73d" />


### Relevant Files
- `DataImportFiles/atraction2.csv`
---

# Backup and Restore



## Backup
<img width="879" height="678" alt="image" src="https://github.com/user-attachments/assets/bcf5ba63-19cd-48e5-8ba1-b2f6deb2ce33" />

A backup of the database was created and saved as:
- `backup_2026-04-14.backup`

## Restore
<img width="1843" height="820" alt="image" src="https://github.com/user-attachments/assets/00e3e9b1-f7ac-4b38-89a1-c7e9b23818fe" />

The restore process was performed using the backup file in order to verify that the database can be recovered successfully.

---
# Stage B – Queries and Constraints

## Introduction

In this stage, we queried the database using non-trivial `SQL` queries, added constraints and indexes, and demonstrated the use of transactions with `ROLLBACK` and `COMMIT`.

The queries were written to match the future GUI screens of the system and to provide meaningful information based on multiple related tables, as required in the project instructions.

This stage includes:
- 8 `SELECT` queries
- 3 `UPDATE` queries
- 3 `DELETE` queries
- 3 new constraints
- 3 indexes
- `ROLLBACK` and `COMMIT` demonstrations

---

## SELECT Queries

### SELECT 1A – Tickets with Customer and Attraction Details using `JOIN`

#### Description
This query displays tickets together with the details of the customer who purchased them and the attraction for which the ticket was bought.  
Its purpose is to provide a complete purchase view in one screen.

#### SQL Code
```sql
SELECT
    t.ticket_id,
    t.purchase_date,
    t.visit_date,
    t.price,
    t.ticket_status,
    c.customer_id,
    c.full_name,
    c.email,
    a.attraction_id,
    a.attraction_name,
    a.city,
    a.category
FROM TICKET t
JOIN CUSTOMER c ON t.customer_id = c.customer_id
JOIN ATTRACTION a ON t.attraction_id = a.attraction_id
ORDER BY t.purchase_date DESC, t.ticket_id;
```
<img width="1548" height="785" alt="image" src="https://github.com/user-attachments/assets/c84f4f35-96b4-43e0-b051-8b3fd6bfed49" />

---
SSELECT 1B – Tickets with Customer and Attraction Details using SUBQUERY
Description

This query returns the same information as the previous query, but instead of using JOIN, it uses subqueries in order to retrieve customer and attraction details.
```sql
SELECT
    t.ticket_id,
    t.purchase_date,
    t.visit_date,
    t.price,
    t.ticket_status,
    t.customer_id,
    (SELECT c.full_name
     FROM CUSTOMER c
     WHERE c.customer_id = t.customer_id) AS full_name,
    (SELECT c.email
     FROM CUSTOMER c
     WHERE c.customer_id = t.customer_id) AS email,
    t.attraction_id,
    (SELECT a.attraction_name
     FROM ATTRACTION a
     WHERE a.attraction_id = t.attraction_id) AS attraction_name,
    (SELECT a.city
     FROM ATTRACTION a
     WHERE a.attraction_id = t.attraction_id) AS city,
    (SELECT a.category
     FROM ATTRACTION a
     WHERE a.attraction_id = t.attraction_id) AS category
FROM TICKET t
ORDER BY t.purchase_date DESC, t.ticket_id;
```
<img width="1540" height="855" alt="image" src="https://github.com/user-attachments/assets/5ca19810-d4dc-4653-9750-526eeb703fa3" />

Both queries return the same information.
However, the JOIN version is usually more efficient because the database engine performs a direct join between the relevant tables.
In the SUBQUERY version, repeated lookups may be performed for each row, which can make it less efficient on larger datasets.
Therefore, SELECT 1A is considered more efficient and also easier to read.
---
SELECT 2A – Reviews with Customer and Attraction Details using JOIN
Query Description
This query displays reviews written in the system, together with the details of the customer who wrote the review and the details of the attraction the review refers to.  
To retrieve this information, the query goes through the `TICKET` table, because the review is linked to a ticket, and the ticket is linked both to the customer and to the attraction.
SQL Code
```sql
SELECT
    r.review_id,
    r.title,
    r.rating,
    r.content,
    r.review_date,
    r.is_deleted,
    c.customer_id,
    c.full_name,
    a.attraction_id,
    a.attraction_name,
    a.city,
    t.ticket_id
FROM REVIEW r
JOIN TICKET t ON r.ticket_id = t.ticket_id
JOIN CUSTOMER c ON t.customer_id = c.customer_id
JOIN ATTRACTION a ON t.attraction_id = a.attraction_id
ORDER BY r.review_date DESC, r.review_id;
```
<img width="1598" height="776" alt="image" src="https://github.com/user-attachments/assets/54a83adb-1c69-4256-bc51-c6bd9e594f15" />

---
SELECT 2B – Reviews with Customer and Attraction Details using SUBQUERY
Query Description
This query returns the same information as the previous query, but instead of using `JOIN`, it uses subqueries to retrieve the customer name and attraction name.
SQL Code
```sql
SELECT
    r.review_id,
    r.title,
    r.rating,
    r.content,
    r.review_date,
    r.is_deleted,
    r.ticket_id,
    (SELECT c.full_name
     FROM CUSTOMER c
     JOIN TICKET t ON c.customer_id = t.customer_id
     WHERE t.ticket_id = r.ticket_id) AS full_name,
    (SELECT a.attraction_name
     FROM ATTRACTION a
     JOIN TICKET t ON a.attraction_id = t.attraction_id
     WHERE t.ticket_id = r.ticket_id) AS attraction_name,
    (SELECT a.city
     FROM ATTRACTION a
     JOIN TICKET t ON a.attraction_id = t.attraction_id
     WHERE t.ticket_id = r.ticket_id) AS city
FROM REVIEW r
ORDER BY r.review_date DESC, r.review_id;
```
<img width="1500" height="817" alt="image" src="https://github.com/user-attachments/assets/0d0b35e9-d890-436f-9867-c22203233c3d" />

Comparison and Efficiency
Here as well, both queries return the same information, but in different ways.  
In the `JOIN` version, the data is retrieved through direct joins between the relevant tables, so it is usually more efficient and easier to understand.  
In the `SUBQUERY` version, subqueries are used for each row, and therefore on larger datasets this approach may be less efficient.  
For this reason, `SELECT 2A` is considered preferable in terms of efficiency and readability.
---
SELECT 3A – Counting Reactions per Review using LEFT JOIN and GROUP BY
Query Description
This query displays, for each review, the total number of reactions, as well as how many reactions are of type `like` and how many are of type `dislike`.  
The purpose of this query is to analyze the level of user engagement for each review.
SQL Code
```sql
SELECT
    r.review_id,
    r.title,
    r.rating,
    r.review_date,
    COUNT(rr.reaction_id) AS total_reactions,
    COUNT(CASE WHEN rr.reaction_type = 'like' THEN 1 END) AS likes_count,
    COUNT(CASE WHEN rr.reaction_type = 'dislike' THEN 1 END) AS dislikes_count
FROM REVIEW r
LEFT JOIN REVIEWREACTION rr ON r.review_id = rr.review_id
GROUP BY r.review_id, r.title, r.rating, r.review_date
ORDER BY total_reactions DESC, r.review_id;
```
<img width="1611" height="782" alt="image" src="https://github.com/user-attachments/assets/81b773d9-9b2d-44ca-836c-0e26aa260c13" />

---
SELECT 3B – Counting Reactions per Review using SUBQUERY
Query Description
This query returns the same information as the previous query, but performs the counting by using separate subqueries for each review.
SQL Code
```sql
SELECT
    r.review_id,
    r.title,
    r.rating,
    r.review_date,
    (SELECT COUNT(*)
     FROM REVIEWREACTION rr
     WHERE rr.review_id = r.review_id) AS total_reactions,
    (SELECT COUNT(*)
     FROM REVIEWREACTION rr
     WHERE rr.review_id = r.review_id
       AND rr.reaction_type = 'like') AS likes_count,
    (SELECT COUNT(*)
     FROM REVIEWREACTION rr
     WHERE rr.review_id = r.review_id
       AND rr.reaction_type = 'dislike') AS dislikes_count
FROM REVIEW r
ORDER BY total_reactions DESC, r.review_id;
```
<img width="1623" height="777" alt="image" src="https://github.com/user-attachments/assets/ad7873b8-3b7a-4cee-a899-f8859c1efcd1" />

Comparison and Efficiency
In `SELECT 3A`, a `LEFT JOIN` was performed between reviews and reactions, followed by `GROUP BY` and aggregation.  
In `SELECT 3B`, several subqueries were executed separately for each review.  
Usually, the `JOIN + GROUP BY` approach is more efficient, because it allows the database engine to process the data in a more centralized way.  
In contrast, with subqueries, each review may require multiple additional scans of the `REVIEWREACTION` table, so it is usually less efficient on larger datasets.
---
SELECT 4A – Reviews Reported at Least Once using EXISTS
Query Description
This query displays reviews that were reported at least once, together with the customer details and attraction details related to the review.  
Its purpose is to display content that requires administrative review.
SQL Code
```sql
SELECT
    r.review_id,
    r.title,
    r.rating,
    r.review_date,
    t.ticket_id,
    a.attraction_name,
    c.full_name
FROM REVIEW r
JOIN TICKET t ON r.ticket_id = t.ticket_id
JOIN ATTRACTION a ON t.attraction_id = a.attraction_id
JOIN CUSTOMER c ON t.customer_id = c.customer_id
WHERE EXISTS (
    SELECT 1
    FROM REVIEWREPORT rep
    WHERE rep.review_id = r.review_id
)
ORDER BY r.review_date DESC, r.review_id;
```
<img width="887" height="820" alt="image" src="https://github.com/user-attachments/assets/840b5d6f-562c-493d-820d-39a406f15583" />

---
SELECT 4B – Reviews Reported at Least Once using IN
Query Description
This query returns the same reported reviews, but instead of `EXISTS` it uses `IN` to check whether the review ID appears in the reports table.
SQL Code
```sql
SELECT
    r.review_id,
    r.title,
    r.rating,
    r.review_date,
    t.ticket_id,
    a.attraction_name,
    c.full_name
FROM REVIEW r
JOIN TICKET t ON r.ticket_id = t.ticket_id
JOIN ATTRACTION a ON t.attraction_id = a.attraction_id
JOIN CUSTOMER c ON t.customer_id = c.customer_id
WHERE r.review_id IN (
    SELECT rep.review_id
    FROM REVIEWREPORT rep
)
ORDER BY r.review_date DESC, r.review_id;
```
<img width="1612" height="818" alt="image" src="https://github.com/user-attachments/assets/27cbf4bd-6d48-464d-82ae-c3ca11d36b3c" />

Comparison and Efficiency
In the first version we used `EXISTS`, and in the second version we used `IN`.  
When the purpose is only to check whether a matching row exists in another table, `EXISTS` is often considered more efficient, because the database engine can stop as soon as a match is found.  
In contrast, `IN` checks whether the value belongs to the set returned by the subquery, and this may be less efficient when the dataset is large.  
Therefore, in this case the `EXISTS` solution is considered preferable.
---
SELECT 5 – Ticket Purchases by Year and Month
Query Description
This query summarizes ticket purchases in the system by year and month of the purchase date.  
It shows how many tickets were purchased in each period, the total revenue, and the average ticket price.  
This query is suitable for a managerial sales analysis screen.
SQL Code
```sql
SELECT
    EXTRACT(YEAR FROM t.purchase_date) AS purchase_year,
    EXTRACT(MONTH FROM t.purchase_date) AS purchase_month,
    COUNT(*) AS tickets_count,
    SUM(t.price) AS total_revenue,
    ROUND(AVG(t.price), 2) AS avg_ticket_price
FROM TICKET t
GROUP BY
    EXTRACT(YEAR FROM t.purchase_date),
    EXTRACT(MONTH FROM t.purchase_date)
ORDER BY purchase_year DESC, purchase_month DESC;
```
<img width="1586" height="781" alt="image" src="https://github.com/user-attachments/assets/8b4522bf-3f99-4505-bf01-c85a550e2db9" />

---
SELECT 6 – Attraction Ranking by Average Reviews and Number of Reviews
Query Description
This query ranks attractions in the system by their average rating and by the number of reviews written about them.  
In addition, it displays the minimum and maximum rating for each attraction.  
This query is suitable for a screen showing top attractions.
SQL Code
```sql
SELECT
    a.attraction_id,
    a.attraction_name,
    a.city,
    a.category,
    COUNT(r.review_id) AS reviews_count,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    MIN(r.rating) AS min_rating,
    MAX(r.rating) AS max_rating
FROM ATTRACTION a
JOIN TICKET t ON a.attraction_id = t.attraction_id
JOIN REVIEW r ON t.ticket_id = r.ticket_id
GROUP BY a.attraction_id, a.attraction_name, a.city, a.category
ORDER BY avg_rating DESC, reviews_count DESC, a.attraction_id;
```
<img width="1610" height="795" alt="image" src="https://github.com/user-attachments/assets/a9f25295-569e-4fcf-a0d3-6a27335ecda0" />

---
SELECT 7 – Customers Who Wrote the Most Reviews
Query Description
This query displays the most active customers in the system in terms of writing reviews.  
For each customer, it shows the number of reviews written, the average rating they gave, and the date of their latest review.  
This query is suitable for a managerial user activity analysis screen.
SQL Code
```sql
SELECT
    c.customer_id,
    c.full_name,
    c.email,
    COUNT(r.review_id) AS reviews_written,
    ROUND(AVG(r.rating), 2) AS avg_given_rating,
    MAX(r.review_date) AS last_review_date
FROM CUSTOMER c
JOIN TICKET t ON c.customer_id = t.customer_id
JOIN REVIEW r ON t.ticket_id = r.ticket_id
GROUP BY c.customer_id, c.full_name, c.email
ORDER BY reviews_written DESC, last_review_date DESC, c.customer_id;
```
<img width="1591" height="788" alt="image" src="https://github.com/user-attachments/assets/cbeff4c5-edfe-49e0-88f2-153cdf7372e0" />

---
SELECT 8 – Reports by Reason and by Month
Query Description
This query displays reports submitted on reviews, grouped by report reason, year, and month.  
In addition, it shows how many reports already received an admin decision and how many are still pending.  
This query is suitable for an administrative moderation screen.
SQL Code
```sql
SELECT
    rep.report_reason,
    EXTRACT(YEAR FROM rep.report_date) AS report_year,
    EXTRACT(MONTH FROM rep.report_date) AS report_month,
    COUNT(*) AS reports_count,
    COUNT(CASE WHEN rep.admin_decision IS NOT NULL THEN 1 END) AS decided_reports,
    COUNT(CASE WHEN rep.admin_decision IS NULL THEN 1 END) AS pending_reports
FROM REVIEWREPORT rep
GROUP BY
    rep.report_reason,
    EXTRACT(YEAR FROM rep.report_date),
    EXTRACT(MONTH FROM rep.report_date)
ORDER BY report_year DESC, report_month DESC, reports_count DESC;
```
<img width="1616" height="780" alt="image" src="https://github.com/user-attachments/assets/5e412c44-c275-472d-854c-91f05e2aaa43" />

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
