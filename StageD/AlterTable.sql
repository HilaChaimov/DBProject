-- ============================================================
-- AlterTable.sql
-- Stage 4 - PL/pgSQL Programming
-- Purpose:
-- Add columns that support business logic for attraction quality,
-- popularity, average rating, and management status.
-- ============================================================


-- ============================================================
-- 1. Add popularity score to attraction
-- ============================================================
-- This value will be updated automatically by a trigger when tickets are purchased.
ALTER TABLE attraction
ADD COLUMN IF NOT EXISTS popularity_score INTEGER DEFAULT 0;


-- ============================================================
-- 2. Add average rating to attraction
-- ============================================================
-- This value will be updated automatically by a trigger when reviews are added
-- or when review ratings are changed.
ALTER TABLE attraction
ADD COLUMN IF NOT EXISTS avg_rating NUMERIC(3,2);


-- ============================================================
-- 3. Add management status to attraction
-- ============================================================
-- This value will be updated by a procedure according to rating,
-- cancellations, reports, and popularity.
ALTER TABLE attraction
ADD COLUMN IF NOT EXISTS attraction_status VARCHAR(30) DEFAULT 'ACTIVE';


-- ============================================================
-- 4. Constraint for allowed attraction statuses
-- ============================================================
ALTER TABLE attraction
DROP CONSTRAINT IF EXISTS chk_attraction_status;

ALTER TABLE attraction
ADD CONSTRAINT chk_attraction_status
CHECK (
    attraction_status IN (
        'ACTIVE',
        'POPULAR',
        'NEEDS_REVIEW',
        'LOW_RATED'
    )
);


-- ============================================================
-- 5. Make sure existing rows have default values
-- ============================================================
UPDATE attraction
SET popularity_score = 0
WHERE popularity_score IS NULL;

UPDATE attraction
SET attraction_status = 'ACTIVE'
WHERE attraction_status IS NULL;


-- ============================================================
-- 6. Calculate initial popularity score from existing tickets
-- ============================================================
-- Counts active tickets for each attraction.
UPDATE attraction a
SET popularity_score = COALESCE((
    SELECT COUNT(*)
    FROM ticket t
    WHERE t.attraction_id = a.attraction_id
      AND LOWER(t.ticket_status) = 'active'
), 0);


-- ============================================================
-- 7. Calculate initial average rating from existing reviews
-- ============================================================
-- Reviews are connected to attractions through:
-- review -> ticket -> attraction
UPDATE attraction a
SET avg_rating = (
    SELECT ROUND(AVG(r.rating), 2)
    FROM review r
    JOIN ticket t ON r.ticket_id = t.ticket_id
    WHERE t.attraction_id = a.attraction_id
);