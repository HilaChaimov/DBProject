-- ============================================
-- ROLLBACK DEMO
-- Mark Review as Deleted and Cancel the Change
-- ============================================

BEGIN;

-- Before
SELECT *
FROM REVIEW
WHERE review_id = 2;

-- Update
UPDATE REVIEW
SET is_deleted = TRUE,
    deleted_date = CURRENT_DATE
WHERE review_id = 2;

-- After Update
SELECT *
FROM REVIEW
WHERE review_id = 2;

-- Rollback
ROLLBACK;

-- After Rollback
SELECT *
FROM REVIEW
WHERE review_id = 2;


-- ============================================
-- COMMIT DEMO
-- Update Admin Decision and Save the Change
-- ============================================

BEGIN;

-- Before
SELECT *
FROM REVIEWREPORT
WHERE report_id = 35;

-- Update
UPDATE REVIEWREPORT
SET admin_decision = 'rejected',
    decision_date = CURRENT_DATE
WHERE report_id = 35;

-- After Update
SELECT *
FROM REVIEWREPORT
WHERE report_id = 35;

-- Commit
COMMIT;

-- After Commit
SELECT *
FROM REVIEWREPORT
WHERE report_id = 35;