-- ============================================
-- CONSTRAINT 1
-- הגבלת ticket_status לערכים חוקיים בלבד
-- ============================================

ALTER TABLE TICKET
ADD CONSTRAINT chk_ticket_status
CHECK (ticket_status IN ('active', 'used', 'cancelled'));

-- בדיקת האילוץ - אמור להיכשל
INSERT INTO TICKET
(ticket_id, purchase_date, visit_date, price, ticket_status, customer_id, attraction_id)
VALUES
(
    99999901,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days',
    100.00,
    'invalid_status',
    (SELECT MIN(customer_id) FROM CUSTOMER),
    (SELECT MIN(attraction_id) FROM ATTRACTION)
);


-- ============================================
-- CONSTRAINT 2
-- אם review לא מחוקה, deleted_date חייב להיות NULL
-- ============================================

ALTER TABLE REVIEW
ADD CONSTRAINT chk_review_deleted_logic
CHECK (
    (is_deleted = FALSE AND deleted_date IS NULL)
    OR
    (is_deleted = TRUE AND deleted_date IS NOT NULL)
);

-- בדיקת האילוץ - אמור להיכשל
INSERT INTO REVIEW
(review_id, rating, title, content, review_date, is_deleted, deleted_date, ticket_id)
VALUES
(
    99999902,
    4,
    'Test Review',
    'This review should fail because deleted_date is not null while is_deleted is false',
    CURRENT_DATE,
    FALSE,
    CURRENT_DATE,
    (SELECT MIN(ticket_id) FROM TICKET)
);


-- ============================================
-- CONSTRAINT 3
-- אם קיימת החלטת מנהל, חייב להיות decision_date
-- ============================================

ALTER TABLE REVIEWREPORT
ADD CONSTRAINT chk_reviewreport_decision_date
CHECK (
    (admin_decision IS NULL AND decision_date IS NULL)
    OR
    (admin_decision IS NOT NULL AND decision_date IS NOT NULL)
);

-- בדיקת האילוץ - אמור להיכשל
INSERT INTO REVIEWREPORT
(report_id, report_reason, report_description, report_date, admin_decision, decision_date, customer_id, review_id)
VALUES
(
    99999903,
    'spam',
    'This report should fail because decision exists without decision_date',
    CURRENT_DATE,
    'approved',
    NULL,
    (SELECT MIN(customer_id) FROM CUSTOMER),
    (SELECT MIN(review_id) FROM REVIEW)
);