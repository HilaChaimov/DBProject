-- ============================================
-- SELECT 1A
-- כרטיסים עם פרטי לקוח ואטרקציה - דרך JOIN
-- ============================================

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


-- ============================================
-- SELECT 1B
-- כרטיסים עם פרטי לקוח ואטרקציה - דרך SUBQUERY
-- ============================================

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


-- ============================================
-- SELECT 2A
-- ביקורות עם פרטי לקוח ואטרקציה - דרך JOIN
-- REVIEW -> TICKET -> CUSTOMER / ATTRACTION
-- ============================================

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


-- ============================================
-- SELECT 2B
-- ביקורות עם פרטי לקוח ואטרקציה - דרך SUBQUERY
-- ============================================

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


-- ============================================
-- SELECT 3A
-- ספירת תגובות לכל ביקורת - דרך LEFT JOIN + GROUP BY
-- ============================================

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


-- ============================================
-- SELECT 3B
-- ספירת תגובות לכל ביקורת - דרך SUBQUERY
-- ============================================

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


-- ============================================
-- SELECT 4A
-- ביקורות שדווחו לפחות פעם אחת - דרך EXISTS
-- ============================================

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


-- ============================================
-- SELECT 4B
-- ביקורות שדווחו לפחות פעם אחת - דרך IN
-- ============================================

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


-- ============================================
-- SELECT 5
-- סיכום רכישות לפי שנה וחודש
-- שימוש בשדות תאריך
-- ============================================

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


-- ============================================
-- SELECT 6
-- דירוג אטרקציות לפי ממוצע ביקורות וכמות ביקורות
-- ============================================

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


-- ============================================
-- SELECT 7
-- לקוחות שכתבו הכי הרבה ביקורות
-- ============================================

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


-- ============================================
-- SELECT 8
-- דוחות לפי סיבת דיווח וחודש
-- שימוש בשדות תאריך
-- ============================================

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


-- ============================================
-- UPDATE 1
-- עדכון סטטוס כרטיס
-- ============================================

-- לפני
SELECT *
FROM TICKET
WHERE ticket_id = (
    SELECT MIN(ticket_id)
    FROM TICKET
    WHERE ticket_status <> 'used'
);

-- עדכון
UPDATE TICKET
SET ticket_status = 'used'
WHERE ticket_id = (
    SELECT MIN(ticket_id)
    FROM TICKET
    WHERE ticket_status <> 'used'
);

-- אחרי
SELECT *
FROM TICKET
WHERE ticket_id = (
    SELECT MIN(ticket_id)
    FROM TICKET
    WHERE ticket_status = 'used'
);


-- ============================================
-- UPDATE 2
-- עדכון החלטת מנהל בדיווח + תאריך החלטה
-- ============================================

-- לפני
SELECT *
FROM REVIEWREPORT
WHERE report_id = (
    SELECT MIN(report_id)
    FROM REVIEWREPORT
    WHERE admin_decision IS NULL
);

-- עדכון
UPDATE REVIEWREPORT
SET admin_decision = 'approved',
    decision_date = CURRENT_DATE
WHERE report_id = (
    SELECT MIN(report_id)
    FROM REVIEWREPORT
    WHERE admin_decision IS NULL
);

-- אחרי
SELECT *
FROM REVIEWREPORT
WHERE report_id = (
    SELECT MIN(report_id)
    FROM REVIEWREPORT
    WHERE admin_decision = 'approved'
      AND decision_date = CURRENT_DATE
);


-- ============================================
-- UPDATE 3
-- סימון ביקורת כמחוקה
-- ============================================

-- לפני
SELECT *
FROM REVIEW
WHERE review_id = (
    SELECT MIN(review_id)
    FROM REVIEW
    WHERE is_deleted = FALSE
);

-- עדכון
UPDATE REVIEW
SET is_deleted = TRUE,
    deleted_date = CURRENT_DATE
WHERE review_id = (
    SELECT MIN(review_id)
    FROM REVIEW
    WHERE is_deleted = FALSE
);

-- אחרי
SELECT *
FROM REVIEW
WHERE review_id = (
    SELECT MIN(review_id)
    FROM REVIEW
    WHERE is_deleted = TRUE
      AND deleted_date = CURRENT_DATE
);


-- ============================================
-- DELETE 1
-- מחיקת תגובה אחת
-- ============================================

-- לפני
SELECT *
FROM REVIEWREACTION
WHERE reaction_id = (
    SELECT MIN(reaction_id)
    FROM REVIEWREACTION
);

-- מחיקה
DELETE FROM REVIEWREACTION
WHERE reaction_id = (
    SELECT MIN(reaction_id)
    FROM REVIEWREACTION
);

-- אחרי
SELECT *
FROM REVIEWREACTION
WHERE reaction_id = (
    SELECT MIN(reaction_id)
    FROM REVIEWREACTION
);


-- ============================================
-- DELETE 2
-- מחיקת דיווח אחד
-- ============================================

-- לפני
SELECT *
FROM REVIEWREPORT
WHERE report_id = (
    SELECT MIN(report_id)
    FROM REVIEWREPORT
);

-- מחיקה
DELETE FROM REVIEWREPORT
WHERE report_id = (
    SELECT MIN(report_id)
    FROM REVIEWREPORT
);

-- אחרי
SELECT *
FROM REVIEWREPORT
WHERE report_id = (
    SELECT MIN(report_id)
    FROM REVIEWREPORT
);


-- ============================================
-- DELETE 3
-- מחיקת ביקורת שאין לה תגובות ואין לה דיווחים
-- כדי לא להיתקע על FK
-- ============================================

-- לפני
SELECT *
FROM REVIEW
WHERE review_id = (
    SELECT MIN(r.review_id)
    FROM REVIEW r
    WHERE NOT EXISTS (
        SELECT 1
        FROM REVIEWREACTION rr
        WHERE rr.review_id = r.review_id
    )
      AND NOT EXISTS (
        SELECT 1
        FROM REVIEWREPORT rep
        WHERE rep.review_id = r.review_id
    )
);

-- מחיקה
DELETE FROM REVIEW
WHERE review_id = (
    SELECT MIN(r.review_id)
    FROM REVIEW r
    WHERE NOT EXISTS (
        SELECT 1
        FROM REVIEWREACTION rr
        WHERE rr.review_id = r.review_id
    )
      AND NOT EXISTS (
        SELECT 1
        FROM REVIEWREPORT rep
        WHERE rep.review_id = r.review_id
    )
);

-- אחרי
SELECT *
FROM REVIEW
WHERE review_id = (
    SELECT MIN(r.review_id)
    FROM REVIEW r
    WHERE NOT EXISTS (
        SELECT 1
        FROM REVIEWREACTION rr
        WHERE rr.review_id = r.review_id
    )
      AND NOT EXISTS (
        SELECT 1
        FROM REVIEWREPORT rep
        WHERE rep.review_id = r.review_id
    )
);