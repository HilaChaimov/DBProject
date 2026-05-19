-- ============================================================
-- integration.sql
-- Stage C: Full Integration of dbintegrated (backup2) with outerDB
-- Target database: dbintegrated
-- Submitted by: Hila Chaimov, Talya Yakov
--
-- ID Offset strategy (to avoid primary key conflicts):
--   outerDB users      → customer_id  = user_id       + 20000  (20001–40000)
--   outerDB attractions → attraction_id = attraction_id + 1000   (1001–21000)
--   outerDB reviews    → review_id    = review_id     + 21000  (21001–22000)
--   gallery_images     → attraction_id offset +1000
--   bookings           → customer_id  offset +20000
--   booking_details    → attraction_id offset +1000
-- ============================================================


-- ============================================================
-- STEP 1: Enable dblink for cross-database data access
-- ============================================================

CREATE EXTENSION IF NOT EXISTS dblink;


-- ============================================================
-- STEP 2: Create new tables (concepts from outerDB not in backup2)
-- ============================================================

-- Category: classifies attractions by audience type
CREATE TABLE IF NOT EXISTS category (
    category_id     INTEGER NOT NULL,
    name            TEXT    NOT NULL,
    icon_identifier TEXT,
    PRIMARY KEY (category_id)
);

-- DifficultyLevel: classifies attraction difficulty
CREATE TABLE IF NOT EXISTS difficulty_level (
    difficulty_id INTEGER NOT NULL,
    name          TEXT    NOT NULL,
    PRIMARY KEY (difficulty_id)
);

-- GalleryImage: multiple images per attraction
CREATE TABLE IF NOT EXISTS gallery_image (
    image_id      INTEGER      NOT NULL,
    image_url     VARCHAR(255) NOT NULL,
    attraction_id INTEGER      NOT NULL,
    PRIMARY KEY (image_id),
    FOREIGN KEY (attraction_id) REFERENCES attraction(attraction_id)
);

-- Booking: group reservation (one booking → multiple attractions)
CREATE TABLE IF NOT EXISTS booking (
    booking_id         INTEGER      NOT NULL,
    booking_date       DATE         NOT NULL,
    total_ticket_count INTEGER      NOT NULL CHECK (total_ticket_count > 0),
    status             VARCHAR(50)  NOT NULL,
    contact_name       VARCHAR(100) NOT NULL,
    contact_email      VARCHAR(150) NOT NULL,
    contact_phone      VARCHAR(20),
    created_at         TIMESTAMP    NOT NULL,
    customer_id        INTEGER      NOT NULL,
    PRIMARY KEY (booking_id),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

-- BookingDetails: which attractions belong to each booking (many-to-many)
CREATE TABLE IF NOT EXISTS booking_details (
    booking_id    INTEGER NOT NULL,
    attraction_id INTEGER NOT NULL,
    ticket_count  INTEGER NOT NULL,
    PRIMARY KEY (booking_id, attraction_id),
    FOREIGN KEY (booking_id)    REFERENCES booking(booking_id),
    FOREIGN KEY (attraction_id) REFERENCES attraction(attraction_id)
);


-- ============================================================
-- STEP 3: ALTER existing tables to add fields from outerDB
-- (modifying existing schema — NOT recreating tables)
-- ============================================================

-- ---- customer: add outerDB user fields ----
ALTER TABLE customer
    ADD COLUMN IF NOT EXISTS avatar_url    VARCHAR(255),
    ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);

-- phone existed in backup2 as NOT NULL, but outerDB users have no phone
ALTER TABLE customer
    ALTER COLUMN phone DROP NOT NULL;

-- ---- attraction: add outerDB fields ----
-- First add lookup FK columns (after tables exist)
ALTER TABLE attraction
    ADD COLUMN IF NOT EXISTS location         VARCHAR(255),
    ADD COLUMN IF NOT EXISTS price_per_person NUMERIC(10,2),
    ADD COLUMN IF NOT EXISTS duration_hours   INTEGER,
    ADD COLUMN IF NOT EXISTS target_audience  VARCHAR(100),
    ADD COLUMN IF NOT EXISTS avg_rating       NUMERIC(3,2),
    ADD COLUMN IF NOT EXISTS main_image_url   VARCHAR(255);

ALTER TABLE attraction
    ADD COLUMN IF NOT EXISTS category_id  INTEGER REFERENCES category(category_id),
    ADD COLUMN IF NOT EXISTS difficulty_id INTEGER REFERENCES difficulty_level(difficulty_id);

-- city and category were NOT NULL in backup2; outerDB attractions use
-- location for city and category_id instead of text category.
-- We allow category text to be NULL for outerDB rows (they use category_id).
ALTER TABLE attraction
    ALTER COLUMN category DROP NOT NULL;

-- ---- review: outerDB reviews link to user+attraction directly (no ticket) ----
ALTER TABLE review
    ADD COLUMN IF NOT EXISTS direct_customer_id   INTEGER REFERENCES customer(customer_id),
    ADD COLUMN IF NOT EXISTS direct_attraction_id INTEGER REFERENCES attraction(attraction_id);

-- Make ticket_id nullable so outerDB reviews (without a ticket) can be stored
ALTER TABLE review
    ALTER COLUMN ticket_id DROP NOT NULL;

-- Drop the old check constraint that implicitly relied on ticket_id logic
-- (the FK constraint on ticket_id is kept; only NOT NULL is removed)


-- ============================================================
-- STEP 4: Import data from outerDB via dblink
-- ============================================================

SELECT dblink_connect('outerdb', 'dbname=outerDB user=hilaTalya password=hilaTalya host=localhost');

-- ---- 4a. Import categories ----
INSERT INTO category (category_id, name, icon_identifier)
SELECT category_id, name, icon_identifier
FROM dblink('outerdb', 'SELECT category_id, name, icon_identifier FROM categories')
    AS t(category_id INTEGER, name TEXT, icon_identifier TEXT)
ON CONFLICT DO NOTHING;

-- ---- 4b. Import difficulty levels ----
INSERT INTO difficulty_level (difficulty_id, name)
SELECT difficulty_id, name
FROM dblink('outerdb', 'SELECT difficulty_id, name FROM difficulty_levels')
    AS t(difficulty_id INTEGER, name TEXT)
ON CONFLICT DO NOTHING;

-- ---- 4c. Import outerDB users → customer (offset +20000) ----
-- outerDB user_id 1–20000 → customer_id 20001–40000
INSERT INTO customer (customer_id, full_name, email, phone,
                      register_date, avatar_url, password_hash)
SELECT
    user_id + 20000,
    name,
    email,
    NULL,
    created_at::DATE,
    avatar_url,
    password_hash
FROM dblink('outerdb',
    'SELECT user_id, name, email, created_at, avatar_url, password_hash FROM users')
    AS t(user_id INTEGER, name VARCHAR(100), email VARCHAR(150),
         created_at TIMESTAMP, avatar_url VARCHAR(255), password_hash VARCHAR(255))
ON CONFLICT (email) DO NOTHING;

-- ---- 4d. Import outerDB attractions → attraction (offset +1000) ----
-- outerDB attraction_id 1–20000 → attraction_id 1001–21000
-- city ← location (both describe the place)
-- category (text) ← looked up from categories
INSERT INTO attraction (attraction_id, attraction_name, city, category, description,
                        location, price_per_person, difficulty_id, duration_hours,
                        target_audience, avg_rating, main_image_url, category_id)
SELECT
    a.attraction_id + 1000,
    a.name,
    a.location,
    c.cat_name,
    a.short_description,
    a.location,
    a.price,
    a.difficulty_id,
    a.duration,
    a.target_audience,
    a.avg_rating,
    a.main_image_url,
    a.category_id
FROM dblink('outerdb',
    'SELECT a.attraction_id, a.name, a.location, a.short_description, a.price,
            a.difficulty_id, a.duration, a.target_audience, a.avg_rating,
            a.main_image_url, a.category_id, c.name AS cat_name
     FROM attractions a
     JOIN categories c ON a.category_id = c.category_id')
    AS a(attraction_id INTEGER, name VARCHAR(150), location VARCHAR(255),
         short_description TEXT, price NUMERIC(10,2), difficulty_id INTEGER,
         duration INTEGER, target_audience VARCHAR(100), avg_rating NUMERIC(3,2),
         main_image_url VARCHAR(255), category_id INTEGER, cat_name TEXT)
ON CONFLICT DO NOTHING;

-- ---- 4e. Import gallery images (attraction_id offset +1000) ----
INSERT INTO gallery_image (image_id, image_url, attraction_id)
SELECT image_id, image_url, attraction_id + 1000
FROM dblink('outerdb', 'SELECT image_id, image_url, attraction_id FROM gallery_images')
    AS t(image_id INTEGER, image_url VARCHAR(255), attraction_id INTEGER)
ON CONFLICT DO NOTHING;

-- ---- 4f. Import bookings (customer_id offset +20000) ----
INSERT INTO booking (booking_id, booking_date, total_ticket_count, status,
                     contact_name, contact_email, contact_phone,
                     created_at, customer_id)
SELECT
    booking_id,
    booking_date,
    ticket_count,
    status,
    contact_name,
    contact_email,
    contact_phone,
    created_at,
    user_id + 20000
FROM dblink('outerdb',
    'SELECT booking_id, booking_date, ticket_count, status,
            contact_name, contact_email, contact_phone, created_at, user_id
     FROM bookings')
    AS t(booking_id INTEGER, booking_date DATE, ticket_count INTEGER,
         status VARCHAR(50), contact_name VARCHAR(100), contact_email VARCHAR(150),
         contact_phone VARCHAR(20), created_at TIMESTAMP, user_id INTEGER)
ON CONFLICT DO NOTHING;

-- ---- 4g. Import booking_details (attraction_id offset +1000) ----
INSERT INTO booking_details (booking_id, attraction_id, ticket_count)
SELECT booking_id, attraction_id + 1000, ticket_count
FROM dblink('outerdb',
    'SELECT booking_id, attraction_id, ticket_count FROM booking_details')
    AS t(booking_id INTEGER, attraction_id INTEGER, ticket_count INTEGER)
ON CONFLICT DO NOTHING;

-- ---- 4h. Import outerDB reviews → review ----
-- review_id offset +21000 (backup2 max is 20000 → new range 21001–22000)
-- ticket_id = NULL (outerDB reviews are not linked to tickets)
-- direct_customer_id = user_id + 20000
-- direct_attraction_id = attraction_id + 1000
INSERT INTO review (review_id, rating, title, content, review_date,
                    is_deleted, deleted_date,
                    ticket_id, direct_customer_id, direct_attraction_id)
SELECT
    review_id + 21000,
    rating,
    NULL,
    COALESCE(comment, ''),
    created_at::DATE,
    FALSE,
    NULL,
    NULL,
    user_id + 20000,
    attraction_id + 1000
FROM dblink('outerdb',
    'SELECT review_id, rating, comment, created_at, user_id, attraction_id
     FROM reviews')
    AS t(review_id INTEGER, rating INTEGER, comment TEXT,
         created_at TIMESTAMP, user_id INTEGER, attraction_id INTEGER)
ON CONFLICT DO NOTHING;

-- ============================================================
-- STEP 5: Close dblink connection
-- ============================================================

SELECT dblink_disconnect('outerdb');


-- ============================================================
-- STEP 6: Update sequences so future INSERTs don't conflict
-- ============================================================

-- (backup2 uses plain integer PKs without sequences, so no sequence update needed.
--  If sequences exist, uncomment and adjust the lines below.)
-- SELECT setval('customer_customer_id_seq', 40001);
-- SELECT setval('attraction_attraction_id_seq', 21001);
-- SELECT setval('review_review_id_seq', 22001);


-- ============================================================
-- STEP 7: Verify — row counts across all tables
-- ============================================================

SELECT 'customer'        AS table_name, COUNT(*) AS rows FROM customer
UNION ALL
SELECT 'attraction',                    COUNT(*) FROM attraction
UNION ALL
SELECT 'ticket',                        COUNT(*) FROM ticket
UNION ALL
SELECT 'review',                        COUNT(*) FROM review
UNION ALL
SELECT 'reviewreaction',                COUNT(*) FROM reviewreaction
UNION ALL
SELECT 'reviewreport',                  COUNT(*) FROM reviewreport
UNION ALL
SELECT 'booking',                       COUNT(*) FROM booking
UNION ALL
SELECT 'booking_details',               COUNT(*) FROM booking_details
UNION ALL
SELECT 'category',                      COUNT(*) FROM category
UNION ALL
SELECT 'difficulty_level',              COUNT(*) FROM difficulty_level
UNION ALL
SELECT 'gallery_image',                 COUNT(*) FROM gallery_image
ORDER BY table_name;
