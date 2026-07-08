# Stage E - Graphical Interface

## Project
Database Mini Project - Attractions and Tourism System

## Tools used
The graphical application was built using:

- Python
- Tkinter for the graphical interface
- psycopg2 for connecting to PostgreSQL
- PostgreSQL database after Stage D

## What the application supports

1. Main entrance screen through a tab-based interface.
2. CRUD operations for all database tables:
   - SELECT - viewing table data
   - INSERT - adding a new row
   - UPDATE - selecting a row and updating its fields
   - DELETE - deleting a selected row
3. Dynamic table loading from the PostgreSQL schema.
4. Foreign keys are displayed with friendly combo boxes when possible.
5. Running two meaningful queries:
   - Top attractions by reviews and average rating
   - Active customers report
6. Running Stage D functions:
   - `fn_calculate_attraction_quality`
   - `fn_get_customer_activity_level`
7. Running Stage D procedures:
   - `pr_refresh_attraction_popularity`
   - `pr_mark_problematic_attractions`

## How to run

1. Make sure Docker/PostgreSQL is running.
2. Make sure the database after Stage D is restored.
3. Copy `.env.example` to `.env`.
4. Update the database connection details in `.env` if needed.
5. Install dependencies:

```bash
pip install -r requirements.txt
```

6. Run the application:

```bash
python main.py
```

## Required screenshots for the report

Add screenshots to the `screenshots` folder:

1. Main application screen.
2. CRUD SELECT screen for one table.
3. INSERT operation before and after.
4. UPDATE operation before and after.
5. DELETE operation before and after.
6. Query 1 result.
7. Query 2 result.
8. Function result.
9. Procedure run success message.

## Suggested Git structure

```text
StageE/
├── main.py
├── db.py
├── requirements.txt
├── .env.example
├── README_StageE.md
└── screenshots/
```

## Suggested README report text

### Stage E - Graphical Interface

In this stage we created a graphical application that connects to the PostgreSQL database and allows the user to work with the system in a friendly way. The application was implemented in Python using Tkinter for the graphical screens and psycopg2 for database access.

The application includes a main entrance screen with navigation tabs. The CRUD screen allows the user to choose any table from the database and perform select, insert, update and delete operations. The table list and column list are loaded dynamically from the database schema, so the application can access all existing tables. When a table contains foreign keys, the system attempts to display user-friendly values instead of only raw IDs.

In addition, the application includes a screen for running selected queries from Stage B and programs from Stage D. From this screen the user can run reports about attractions and customers, calculate the quality score of an attraction, classify the activity level of a customer, and run procedures that update popularity and status values of attractions.

This interface demonstrates the connection between the graphical application and the database, including regular CRUD work and activation of database-side logic written in PL/pgSQL.
