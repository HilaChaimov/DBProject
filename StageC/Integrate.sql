-- ============================================================
-- INTEGRATE.SQL
-- Stage C: Integration of reportDB (Review System) with outerDB (Booking System)
-- Submitted by: Hila Chaimov, Talya Yakov
-- ============================================================

-- ============================================================
-- STEP 1: Enable dblink for cross-database data transfer
-- ============================================================

CREATE EXTENSION IF NOT EXISTS dblink;

-- ============================================================
-- STEP 2: Create new tables from outerDB schema
-- These tables do not exist in reportDB and are added as part of the integration
-- ============================================================

-- Categories (lookup table from outerDB – classifies attractions by audience)
CREATE TABLE IF NOT EXISTS categories (
    category_id INTEGER      NOT NULL,
    name        TEXT         NOT NULL,
    icon_identifier TEXT,
    PRIMARY KEY (category_id)
);

-- Difficulty Levels (lookup table from outerDB – classifies attraction difficulty)
CREATE TABLE IF NOT EXISTS difficulty_levels (
    difficulty_id INTEGER NOT NULL,
    name          TEXT    NOT NULL,
    PRIMARY KEY (difficulty_id)
);

-- Gallery Images (from outerDB – stores image URLs per attraction)
CREATE TABLE IF NOT EXISTS gallery_images (
    image_id      INTEGER             NOT NULL,
    image_url     VARCHAR(255)        NOT NULL,
    attraction_id INTEGER             NOT NULL,
    PRIMARY KEY (image_id),
    FOREIGN KEY (attraction_id) REFERENCES attraction(attraction_id)
);

-- Booking (mapped from outerDB bookings – represents a group reservation)
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

-- Booking Details (mapped from outerDB booking_details – which attractions are in each booking)
CREATE TABLE IF NOT EXISTS booking_details (
    booking_id    INTEGER NOT NULL,
    attraction_id INTEGER NOT NULL,
    ticket_count  INTEGER NOT NULL,
    PRIMARY KEY (booking_id, attraction_id),
    FOREIGN KEY (booking_id)    REFERENCES booking(booking_id),
    FOREIGN KEY (attraction_id) REFERENCES attraction(attraction_id)
);

-- ============================================================
-- STEP 3: ALTER existing tables to integrate outerDB fields
-- We modify existing tables rather than recreating them
-- ============================================================

-- customer: add outerDB user fields (avatar and hashed password)
ALTER TABLE customer
    ADD COLUMN IF NOT EXISTS avatar_url    VARCHAR(255),
    ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);

-- customer.phone was NOT NULL but outerDB users have no phone – make it optional
ALTER TABLE customer
    ALTER COLUMN phone DROP NOT NULL;

-- attraction: add outerDB fields (location, pricing, difficulty, category FK, etc.)
ALTER TABLE attraction
    ADD COLUMN IF NOT EXISTS location         VARCHAR(255),
    ADD COLUMN IF NOT EXISTS price_per_person NUMERIC(10,2),
    ADD COLUMN IF NOT EXISTS difficulty_id    INTEGER REFERENCES difficulty_levels(difficulty_id),
    ADD COLUMN IF NOT EXISTS duration_hours   INTEGER,
    ADD COLUMN IF NOT EXISTS target_audience  VARCHAR(100),
    ADD COLUMN IF NOT EXISTS avg_rating       NUMERIC(3,2),
    ADD COLUMN IF NOT EXISTS main_image_url   VARCHAR(255),
    ADD COLUMN IF NOT EXISTS category_id      INTEGER REFERENCES categories(category_id);

-- attraction.category was NOT NULL text – make it optional so outerDB attractions
-- can use category_id FK instead of the text field
ALTER TABLE attraction
    ALTER COLUMN category DROP NOT NULL;

-- ticket: add optional link to a booking (one booking can generate multiple tickets)
ALTER TABLE ticket
    ADD COLUMN IF NOT EXISTS booking_id INTEGER REFERENCES booking(booking_id);

-- review: outerDB reviews link directly to user+attraction (not through ticket).
-- We add two nullable FK columns to accommodate both review styles.
ALTER TABLE review
    ADD COLUMN IF NOT EXISTS direct_customer_id   INTEGER REFERENCES customer(customer_id),
    ADD COLUMN IF NOT EXISTS direct_attraction_id INTEGER REFERENCES attraction(attraction_id);

-- Make ticket_id nullable so outerDB-style reviews can be stored without a ticket
ALTER TABLE review
    ALTER COLUMN ticket_id DROP NOT NULL;

-- Drop the old NOT NULL check constraint that enforced ticket_id (if it exists separately)
-- The FK constraint remains; only the NOT NULL is removed above.

-- ============================================================
-- STEP 4: Import data from outerDB using dblink
-- Both databases are on the same PostgreSQL instance.
-- IDs are offset to avoid collisions:
--   outerDB users      → customer_id  + 20000
--   outerDB attractions → attraction_id + 500
--   outerDB reviews    → review_id    + 20000
-- ============================================================

SELECT dblink_connect('outerdb_conn', 'dbname=outerDB user=hilaTalya password=hilaTalya host=localhost');

-- 4a. Import categories
INSERT INTO categories (category_id, name, icon_identifier)
SELECT category_id, name, icon_identifier
FROM dblink('outerdb_conn',
    'SELECT category_id, name, icon_identifier FROM categories')
    AS t(category_id INTEGER, name TEXT, icon_identifier TEXT)
ON CONFLICT DO NOTHING;

-- 4b. Import difficulty_levels
INSERT INTO difficulty_levels (difficulty_id, name)
SELECT difficulty_id, name
FROM dblink('outerdb_conn',
    'SELECT difficulty_id, name FROM difficulty_levels')
    AS t(difficulty_id INTEGER, name TEXT)
ON CONFLICT DO NOTHING;

-- 4c. Import outerDB users → customer (offset customer_id by +20000)
INSERT INTO customer (customer_id, full_name, email, phone, register_date, avatar_url, password_hash)
SELECT
    user_id + 20000,
    name,
    email,
    NULL,
    created_at::DATE,
    avatar_url,
    password_hash
FROM dblink('outerdb_conn',
    'SELECT user_id, name, email, avatar_url, created_at, password_hash FROM users')
    AS t(user_id INTEGER, name VARCHAR(100), email VARCHAR(150),
         avatar_url VARCHAR(255), created_at TIMESTAMP, password_hash VARCHAR(255))
ON CONFLICT DO NOTHING;

-- 4d. Import outerDB attractions → attraction (offset attraction_id by +500)
--     city  ← location (both describe the place)
--     category (text) ← looked up from categories table
INSERT INTO attraction (attraction_id, attraction_name, city, category, description,
                        location, price_per_person, difficulty_id, duration_hours,
                        target_audience, avg_rating, main_image_url, category_id)
SELECT
    a.attraction_id + 500,
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
FROM dblink('outerdb_conn',
    'SELECT a.attraction_id, a.name, a.location, a.short_description, a.price,
            a.difficulty_id, a.duration, a.target_audience, a.avg_rating,
            a.main_image_url, a.category_id, c.name AS cat_name
     FROM attractions a
     JOIN categories c ON a.category_id = c.category_id')
    AS a(attraction_id INTEGER, name VARCHAR(150), location VARCHAR(255),
         short_description TEXT, price NUMERIC(10,2), difficulty_id INTEGER,
         duration INTEGER, target_audience VARCHAR(100), avg_rating NUMERIC(3,2),
         main_image_url VARCHAR(255), category_id INTEGER, cat_name TEXT)
    CROSS JOIN (SELECT NULL) AS c(cat_name)  -- dummy, cat_name comes from dblink
ON CONFLICT DO NOTHING;

-- Fix: redo without CROSS JOIN – cat_name is already in the dblink result
-- (the query above already returns cat_name as the last column; rewrite cleanly)
-- Truncate and redo:
DELETE FROM attraction WHERE attraction_id > 500;

INSERT INTO attraction (attraction_id, attraction_name, city, category, description,
                        location, price_per_person, difficulty_id, duration_hours,
                        target_audience, avg_rating, main_image_url, category_id)
SELECT
    attraction_id + 500,
    name,
    location,
    cat_name,
    short_description,
    location,
    price,
    difficulty_id,
    duration,
    target_audience,
    avg_rating,
    main_image_url,
    category_id
FROM dblink('outerdb_conn',
    'SELECT a.attraction_id, a.name, a.location, a.short_description, a.price,
            a.difficulty_id, a.duration, a.target_audience, a.avg_rating,
            a.main_image_url, a.category_id, c.name AS cat_name
     FROM attractions a
     JOIN categories c ON a.category_id = c.category_id')
    AS t(attraction_id INTEGER, name VARCHAR(150), location VARCHAR(255),
         short_description TEXT, price NUMERIC(10,2), difficulty_id INTEGER,
         duration INTEGER, target_audience VARCHAR(100), avg_rating NUMERIC(3,2),
         main_image_url VARCHAR(255), category_id INTEGER, cat_name TEXT)
ON CONFLICT DO NOTHING;

-- 4e. Import gallery_images (offset attraction_id by +500)
INSERT INTO gallery_images (image_id, image_url, attraction_id)
SELECT image_id, image_url, attraction_id + 500
FROM dblink('outerdb_conn',
    'SELECT image_id, image_url, attraction_id FROM gallery_images')
    AS t(image_id INTEGER, image_url VARCHAR(255), attraction_id INTEGER)
ON CONFLICT DO NOTHING;

-- 4f. Import bookings → booking (offset customer_id by +20000)
INSERT INTO booking (booking_id, booking_date, total_ticket_count, status,
                     contact_name, contact_email, contact_phone, created_at, customer_id)
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
FROM dblink('outerdb_conn',
    'SELECT booking_id, booking_date, ticket_count, status,
            contact_name, contact_email, contact_phone, created_at, user_id
     FROM bookings')
    AS t(booking_id INTEGER, booking_date DATE, ticket_count INTEGER,
         status VARCHAR(50), contact_name VARCHAR(100), contact_email VARCHAR(150),
         contact_phone VARCHAR(20), created_at TIMESTAMP, user_id INTEGER)
ON CONFLICT DO NOTHING;

-- 4g. Import booking_details (offset attraction_id by +500)
INSERT INTO booking_details (booking_id, attraction_id, ticket_count)
SELECT booking_id, attraction_id + 500, ticket_count
FROM dblink('outerdb_conn',
    'SELECT booking_id, attraction_id, ticket_count FROM booking_details')
    AS t(booking_id INTEGER, attraction_id INTEGER, ticket_count INTEGER)
ON CONFLICT DO NOTHING;

-- 4h. Import outerDB reviews → review
--     review_id offset +20000 | user_id offset +20000 | attraction_id offset +500
--     ticket_id = NULL (outerDB reviews are not linked to tickets)
INSERT INTO review (review_id, rating, title, content, review_date,
                    is_deleted, ticket_id, direct_customer_id, direct_attraction_id)
SELECT
    review_id + 20000,
    rating,
    NULL,
    COALESCE(comment, ''),
    created_at::DATE,
    FALSE,
    NULL,
    user_id + 20000,
    attraction_id + 500
FROM dblink('outerdb_conn',
    'SELECT review_id, rating, comment, created_at, user_id, attraction_id FROM reviews')
    AS t(review_id INTEGER, rating INTEGER, comment TEXT,
         created_at TIMESTAMP, user_id INTEGER, attraction_id INTEGER)
ON CONFLICT DO NOTHING;

-- ============================================================
-- STEP 5: Close dblink connection
-- ============================================================

SELECT dblink_disconnect('outerdb_conn');

-- ============================================================
-- STEP 6: Verify integration
-- ============================================================

SELECT 'customer rows total:'    AS info, COUNT(*) AS count FROM customer
UNION ALL
SELECT 'attraction rows total:',           COUNT(*) FROM attraction
UNION ALL
SELECT 'ticket rows total:',               COUNT(*) FROM ticket
UNION ALL
SELECT 'review rows total:',               COUNT(*) FROM review
UNION ALL
SELECT 'booking rows total:',              COUNT(*) FROM booking
UNION ALL
SELECT 'booking_details rows total:',      COUNT(*) FROM booking_details
UNION ALL
SELECT 'categories rows total:',           COUNT(*) FROM categories
UNION ALL
SELECT 'difficulty_levels rows total:',    COUNT(*) FROM difficulty_levels
UNION ALL
SELECT 'gallery_images rows total:',       COUNT(*) FROM gallery_images;
