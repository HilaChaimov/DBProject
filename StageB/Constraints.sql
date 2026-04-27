-- ============================================
-- CONSTRAINT 1
-- Valid Ticket Status Values
-- ============================================

ALTER TABLE TICKET
ADD CONSTRAINT chk_ticket_status
CHECK (ticket_status IN ('active', 'used', 'cancelled'));

-- Invalid Insert Test
INSERT INTO TICKET
(ticket_id, purchase_date, visit_date, price, ticket_status, customer_id, attraction_id)
VALUES
(
    401,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days',
    100.00,
    'invalid_status',
    1,
    1
);


-- ============================================
-- CONSTRAINT 2
-- Review Deletion Logic
-- ============================================

ALTER TABLE REVIEW
ADD CONSTRAINT chk_review_deleted_logic
CHECK (
    (is_deleted = FALSE AND deleted_date IS NULL)
    OR
    (is_deleted = TRUE AND deleted_date IS NOT NULL)
);

-- Invalid Insert Test
INSERT INTO REVIEW
(review_id, rating, title, content, review_date, is_deleted, deleted_date, ticket_id)
VALUES
(
    402,
    4,
    'Invalid Review',
    'This insert should fail because the deletion fields are inconsistent.',
    CURRENT_DATE,
    FALSE,
    CURRENT_DATE,
    1
);


-- ============================================
-- CONSTRAINT 3
-- Admin Decision Requires Decision Date
-- ============================================

ALTER TABLE REVIEWREPORT
ADD CONSTRAINT chk_reviewreport_decision_date
CHECK (
    (admin_decision IS NULL AND decision_date IS NULL)
    OR
    (admin_decision IS NOT NULL AND decision_date IS NOT NULL)
);

-- Invalid Insert Test
INSERT INTO REVIEWREPORT
(report_id, report_reason, report_description, report_date, admin_decision, decision_date, customer_id, review_id)
VALUES
(
    403,
    'spam',
    'This insert should fail because admin_decision exists without decision_date.',
    CURRENT_DATE,
    'approved',
    NULL,
    1,
    1
);