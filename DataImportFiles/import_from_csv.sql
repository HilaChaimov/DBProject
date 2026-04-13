-- ============================================
-- IMPORT DATA FROM CSV FILES
-- ============================================

COPY CUSTOMER(customer_id, full_name, email, phone, register_date)
FROM 'C:/Users/hilac/Documents/הנדסת נתונים/DBProject/DataImportFiles/customer.csv'
DELIMITER ','
CSV HEADER;

COPY ATTRACTION(attraction_id, attraction_name, city, category, description)
FROM 'C:/Users/hilac/Documents/הנדסת נתונים/DBProject/DataImportFiles/attraction.csv'
DELIMITER ','
CSV HEADER;

COPY TICKET(ticket_id, purchase_date, visit_date, price, ticket_status, customer_id, attraction_id)
FROM 'C:/Users/hilac/Documents/הנדסת נתונים/DBProject/DataImportFiles/ticket.csv'
DELIMITER ','
CSV HEADER;

COPY REVIEW(review_id, rating, title, content, review_date, is_deleted, deleted_date, ticket_id)
FROM 'C:/Users/hilac/Documents/הנדסת נתונים/DBProject/DataImportFiles/review.csv'
DELIMITER ','
CSV HEADER;

COPY REVIEWREACTION(reaction_id, reaction_type, reaction_date, review_id, customer_id)
FROM 'C:/Users/hilac/Documents/הנדסת נתונים/DBProject/DataImportFiles/reviewreaction.csv'
DELIMITER ','
CSV HEADER;

COPY REVIEWREPORT(report_id, report_reason, report_description, report_date, admin_decision, decision_date, customer_id, review_id)
FROM 'C:/Users/hilac/Documents/הנדסת נתונים/DBProject/DataImportFiles/reviewreport.csv'
DELIMITER ','
CSV HEADER;