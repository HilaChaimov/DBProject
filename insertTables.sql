-- ============================================
-- INSERT SAMPLE DATA
-- This script inserts sample data into all tables
-- in the correct order according to foreign keys
-- ============================================

-- ============================================
-- CUSTOMER
-- ============================================
INSERT INTO CUSTOMER (customer_id, full_name, email, phone, register_date) VALUES
(1, 'Hila Levi', 'hila1@example.com', '0501234567', '2024-01-10'),
(2, 'Noa Cohen', 'noa2@example.com', '0522345678', '2024-01-15'),
(3, 'Dana Mizrahi', 'dana3@example.com', '0533456789', '2024-02-01'),
(4, 'Yael Biton', 'yael4@example.com', '0544567890', '2024-02-12'),
(5, 'Maya Azulay', 'maya5@example.com', '0555678901', '2024-03-05');

-- ============================================
-- ATTRACTION
-- ============================================
INSERT INTO ATTRACTION (attraction_id, attraction_name, city, category, description) VALUES
(1, 'Sky Park', 'Tel Aviv', 'Adventure', 'Outdoor climbing and rope activities'),
(2, 'Water Fun', 'Haifa', 'Water Park', 'Family water attraction'),
(3, 'History Museum', 'Jerusalem', 'Museum', 'Museum with historical exhibitions'),
(4, 'Safari World', 'Ramat Gan', 'Zoo', 'Animal park and safari experience'),
(5, 'Luna Star', 'Eilat', 'Amusement Park', 'Rides and games for all ages');

-- ============================================
-- TICKET
-- ============================================
INSERT INTO TICKET (ticket_id, purchase_date, visit_date, price, ticket_status, customer_id, attraction_id) VALUES
(1, '2024-04-01', '2024-04-10', 120.00, 'active', 1, 1),
(2, '2024-04-02', '2024-04-12', 95.50, 'used', 2, 2),
(3, '2024-04-03', '2024-04-15', 80.00, 'cancelled', 3, 3),
(4, '2024-04-04', '2024-04-18', 150.00, 'used', 4, 4),
(5, '2024-04-05', '2024-04-20', 110.00, 'active', 5, 5);

-- ============================================
-- REVIEW
-- ============================================
INSERT INTO REVIEW (review_id, rating, title, content, review_date, is_deleted, deleted_date, ticket_id) VALUES
(1, 5, 'Amazing experience', 'Everything was organized and fun.', '2024-04-11', FALSE, NULL, 1),
(2, 4, 'Very good', 'Nice place and friendly staff.', '2024-04-13', FALSE, NULL, 2),
(3, 2, 'Not as expected', 'The attraction was crowded and less enjoyable.', '2024-04-16', FALSE, NULL, 3),
(4, 5, 'Highly recommended', 'Great experience for families.', '2024-04-19', FALSE, NULL, 4),
(5, 3, 'It was okay', 'The attraction was fine but could be improved.', '2024-04-21', FALSE, NULL, 5);

-- ============================================
-- REVIEWREACTION
-- ============================================
INSERT INTO REVIEWREACTION (reaction_id, reaction_type, reaction_date, review_id, customer_id) VALUES
(1, 'like', '2024-04-12', 1, 2),
(2, 'like', '2024-04-14', 2, 3),
(3, 'dislike', '2024-04-17', 3, 4),
(4, 'like', '2024-04-20', 4, 5),
(5, 'dislike', '2024-04-22', 5, 1);

-- ============================================
-- REVIEWREPORT
-- ============================================
INSERT INTO REVIEWREPORT (report_id, report_reason, report_description, report_date, admin_decision, decision_date, customer_id, review_id) VALUES
(1, 'Spam', 'The review seems irrelevant to the attraction.', '2024-04-13', 'Rejected', '2024-04-14', 3, 1),
(2, 'Offensive language', 'The review contains inappropriate words.', '2024-04-15', 'Approved', '2024-04-16', 4, 2),
(3, 'Misleading information', 'The review includes incorrect facts.', '2024-04-18', NULL, NULL, 5, 3),
(4, 'Spam', 'Repeated review content.', '2024-04-21', 'Approved', '2024-04-22', 1, 4),
(5, 'Harassment', 'The review targets staff personally.', '2024-04-23', NULL, NULL, 2, 5);