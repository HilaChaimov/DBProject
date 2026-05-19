-- ============================================================
-- Views.sql
-- Stage C: Views and Queries on Views
-- Database: dbintegrated
-- Submitted by: Hila Chaimov, Talya Yakov
-- ============================================================

-- ============================================================
-- VIEW 1: view_review_details
-- Perspective: Original Review System (our system)
-- Description: Full review details combining review data with customer
--              information, attraction details, reaction counts, and report
--              counts. Covers only ticket-based reviews (our original system).
-- ============================================================

CREATE OR REPLACE VIEW view_review_details AS
SELECT
    r.review_id,
    r.rating,
    r.title,
    r.content,
    r.review_date,
    r.is_deleted,
    c.customer_id,
    c.full_name        AS customer_name,
    c.email            AS customer_email,
    a.attraction_id,
    a.attraction_name,
    a.city,
    a.category,
    t.ticket_id,
    t.visit_date,
    COUNT(rr.reaction_id) FILTER (WHERE rr.reaction_type = 'like')    AS likes_count,
    COUNT(rr.reaction_id) FILTER (WHERE rr.reaction_type = 'dislike') AS dislikes_count,
    COUNT(DISTINCT rep.report_id)                                       AS reports_count
FROM review r
JOIN ticket          t   ON r.ticket_id     = t.ticket_id
JOIN customer        c   ON t.customer_id   = c.customer_id
JOIN attraction      a   ON t.attraction_id = a.attraction_id
LEFT JOIN reviewreaction rr  ON r.review_id = rr.review_id
LEFT JOIN reviewreport   rep ON r.review_id = rep.review_id
WHERE r.ticket_id IS NOT NULL
GROUP BY
    r.review_id, r.rating, r.title, r.content, r.review_date, r.is_deleted,
    c.customer_id, c.full_name, c.email,
    a.attraction_id, a.attraction_name, a.city, a.category,
    t.ticket_id, t.visit_date;


-- ============================================================
-- VIEW 1 – Query 1
-- Description: Top 10 most-reviewed attractions with average rating
--              and total engagement (likes + dislikes).
--              Useful for identifying the most popular attractions.
-- ============================================================

SELECT
    attraction_name,
    city,
    category,
    COUNT(*)                     AS review_count,
    ROUND(AVG(rating), 2)        AS avg_rating,
    SUM(likes_count)             AS total_likes,
    SUM(dislikes_count)          AS total_dislikes
FROM view_review_details
GROUP BY attraction_name, city, category
ORDER BY review_count DESC, avg_rating DESC
LIMIT 10;


-- ============================================================
-- VIEW 1 – Query 2
-- Description: Active (not deleted) reviews that received at least
--              one report, ordered by number of reports descending.
--              Useful for the admin moderation queue.
-- ============================================================

SELECT
    review_id,
    customer_name,
    attraction_name,
    rating,
    review_date,
    reports_count,
    likes_count,
    dislikes_count
FROM view_review_details
WHERE is_deleted = FALSE
  AND reports_count > 0
ORDER BY reports_count DESC, review_date DESC
LIMIT 10;


-- ============================================================
-- VIEW 2: view_booking_summary
-- Perspective: Booking System (outerDB)
-- Description: Full booking information combining booking records with
--              customer details, attraction details, difficulty level,
--              and category. Covers group bookings imported from outerDB.
-- ============================================================

CREATE OR REPLACE VIEW view_booking_summary AS
SELECT
    b.booking_id,
    b.booking_date,
    b.status               AS booking_status,
    b.total_ticket_count,
    b.contact_name,
    b.contact_email,
    c.customer_id,
    c.full_name            AS customer_name,
    a.attraction_id,
    a.attraction_name,
    a.city                 AS attraction_location,
    a.avg_rating,
    dl.name                AS difficulty_level,
    cat.name               AS category_name,
    bd.ticket_count        AS tickets_for_this_attraction,
    a.price_per_person,
    (bd.ticket_count * a.price_per_person) AS subtotal
FROM booking              b
JOIN customer             c   ON b.customer_id    = c.customer_id
JOIN booking_details      bd  ON b.booking_id     = bd.booking_id
JOIN attraction           a   ON bd.attraction_id = a.attraction_id
LEFT JOIN difficulty_level dl  ON a.difficulty_id = dl.difficulty_id
LEFT JOIN category         cat ON a.category_id   = cat.category_id;


-- ============================================================
-- VIEW 2 – Query 1
-- Description: Most booked attractions from the booking system,
--              showing total tickets sold through group bookings
--              and estimated revenue.
-- ============================================================

SELECT
    attraction_name,
    attraction_location,
    category_name,
    difficulty_level,
    COUNT(DISTINCT booking_id)         AS total_bookings,
    SUM(tickets_for_this_attraction)   AS total_tickets_booked,
    ROUND(AVG(avg_rating), 2)          AS avg_rating,
    ROUND(SUM(subtotal), 2)            AS estimated_revenue
FROM view_booking_summary
GROUP BY attraction_name, attraction_location, category_name, difficulty_level
ORDER BY total_tickets_booked DESC
LIMIT 10;


-- ============================================================
-- VIEW 2 – Query 2
-- Description: Customers with active or completed bookings from
--              2025 onwards, showing booking count and total tickets.
--              Useful for identifying high-value customers.
-- ============================================================

SELECT
    customer_id,
    customer_name,
    contact_email,
    COUNT(DISTINCT booking_id)         AS bookings_count,
    SUM(tickets_for_this_attraction)   AS total_tickets
FROM view_booking_summary
WHERE booking_status IN ('active', 'completed')
  AND EXTRACT(YEAR FROM booking_date) >= 2025
GROUP BY customer_id, customer_name, contact_email
ORDER BY bookings_count DESC, total_tickets DESC
LIMIT 10;


-- ============================================================
-- VIEW 3: view_attraction_overview
-- Perspective: Combined (both systems)
-- Description: A unified view of all attractions combining ticket sales
--              (review system) and group bookings (booking system) with
--              review statistics from both review types.
-- ============================================================

CREATE OR REPLACE VIEW view_attraction_overview AS
SELECT
    a.attraction_id,
    a.attraction_name,
    a.city,
    a.category,
    cat.name                                            AS category_name,
    dl.name                                             AS difficulty_level,
    a.avg_rating                                        AS stored_avg_rating,
    COUNT(DISTINCT t.ticket_id)                         AS individual_tickets_sold,
    COUNT(DISTINCT bd.booking_id)                       AS group_bookings_count,
    COUNT(DISTINCT CASE WHEN r.ticket_id IS NOT NULL
                        THEN r.review_id END)           AS ticket_reviews_count,
    COUNT(DISTINCT CASE WHEN r.direct_attraction_id IS NOT NULL
                        THEN r.review_id END)           AS direct_reviews_count,
    COUNT(DISTINCT r.review_id)                         AS total_reviews,
    ROUND(AVG(r.rating), 2)                             AS calculated_avg_rating
FROM attraction                a
LEFT JOIN category             cat ON a.category_id   = cat.category_id
LEFT JOIN difficulty_level     dl  ON a.difficulty_id = dl.difficulty_id
LEFT JOIN ticket               t   ON a.attraction_id = t.attraction_id
LEFT JOIN booking_details      bd  ON a.attraction_id = bd.attraction_id
LEFT JOIN review               r   ON (r.ticket_id            = t.ticket_id
                                    OR r.direct_attraction_id = a.attraction_id)
GROUP BY
    a.attraction_id, a.attraction_name, a.city, a.category,
    cat.name, dl.name, a.avg_rating;


-- ============================================================
-- VIEW 3 – Query 1
-- Description: Top 10 attractions with the most reviews,
--              from either the ticket system or the booking system.
-- ============================================================

SELECT
    attraction_name,
    city,
    COALESCE(category_name, category)  AS category,
    difficulty_level,
    individual_tickets_sold,
    group_bookings_count,
    total_reviews,
    ROUND(calculated_avg_rating, 2)    AS avg_rating
FROM view_attraction_overview
WHERE (individual_tickets_sold > 0 OR group_bookings_count > 0)
  AND total_reviews > 0
ORDER BY total_reviews DESC, calculated_avg_rating DESC NULLS LAST
LIMIT 10;


-- ============================================================
-- VIEW 3 – Query 2
-- Description: Average rating and total activity per category,
--              combining reviews and sales from both systems.
-- ============================================================

SELECT
    COALESCE(category_name, category)   AS category_label,
    COUNT(DISTINCT attraction_id)        AS attractions_count,
    SUM(total_reviews)                   AS total_reviews,
    ROUND(AVG(calculated_avg_rating), 2) AS avg_rating,
    SUM(individual_tickets_sold)         AS total_individual_tickets,
    SUM(group_bookings_count)            AS total_group_bookings
FROM view_attraction_overview
WHERE total_reviews > 0
GROUP BY COALESCE(category_name, category)
ORDER BY avg_rating DESC, total_reviews DESC;
