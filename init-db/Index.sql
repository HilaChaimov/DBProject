-- ============================================
-- INDEX 1
-- על TICKET(customer_id)
-- מתאים לשאילתות שמחברות לקוחות וכרטיסים
-- ============================================

EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.full_name,
    COUNT(t.ticket_id) AS tickets_count
FROM CUSTOMER c
JOIN TICKET t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY tickets_count DESC;

CREATE INDEX idx_ticket_customer_id
ON TICKET(customer_id);

EXPLAIN ANALYZE
SELECT
    c.customer_id,
    c.full_name,
    COUNT(t.ticket_id) AS tickets_count
FROM CUSTOMER c
JOIN TICKET t ON c.customer_id = t.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY tickets_count DESC;


-- ============================================
-- INDEX 2
-- על REVIEW(ticket_id)
-- מתאים לשאילתות שמחברות כרטיסים וביקורות
-- ============================================

EXPLAIN ANALYZE
SELECT
    a.attraction_name,
    COUNT(r.review_id) AS reviews_count,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM ATTRACTION a
JOIN TICKET t ON a.attraction_id = t.attraction_id
JOIN REVIEW r ON t.ticket_id = r.ticket_id
GROUP BY a.attraction_name
ORDER BY avg_rating DESC;

CREATE INDEX idx_review_ticket_id
ON REVIEW(ticket_id);

EXPLAIN ANALYZE
SELECT
    a.attraction_name,
    COUNT(r.review_id) AS reviews_count,
    ROUND(AVG(r.rating), 2) AS avg_rating
FROM ATTRACTION a
JOIN TICKET t ON a.attraction_id = t.attraction_id
JOIN REVIEW r ON t.ticket_id = r.ticket_id
GROUP BY a.attraction_name
ORDER BY avg_rating DESC;


-- ============================================
-- INDEX 3
-- על REVIEWREACTION(review_id)
-- מתאים לספירת תגובות לפי ביקורת
-- ============================================

EXPLAIN ANALYZE
SELECT
    r.review_id,
    r.title,
    COUNT(rr.reaction_id) AS total_reactions
FROM REVIEW r
LEFT JOIN REVIEWREACTION rr ON r.review_id = rr.review_id
GROUP BY r.review_id, r.title
ORDER BY total_reactions DESC;

CREATE INDEX idx_reviewreaction_review_id
ON REVIEWREACTION(review_id);

EXPLAIN ANALYZE
SELECT
    r.review_id,
    r.title,
    COUNT(rr.reaction_id) AS total_reactions
FROM REVIEW r
LEFT JOIN REVIEWREACTION rr ON r.review_id = rr.review_id
GROUP BY r.review_id, r.title
ORDER BY total_reactions DESC;