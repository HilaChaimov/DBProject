-- ============================================
-- ROLLBACK DEMO
-- סימון ביקורת כמחוקה ואז ביטול
-- ============================================

BEGIN;

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

-- אחרי העדכון
SELECT *
FROM REVIEW
WHERE review_id = (
    SELECT MIN(review_id)
    FROM REVIEW
    WHERE is_deleted = TRUE
      AND deleted_date = CURRENT_DATE
);

-- ביטול
ROLLBACK;

-- אחרי rollback
SELECT *
FROM REVIEW
WHERE review_id = (
    SELECT MIN(review_id)
    FROM REVIEW
    WHERE deleted_date IS NULL
);


-- ============================================
-- COMMIT DEMO
-- עדכון החלטת מנהל בדיווח ושמירת השינוי
-- ============================================

BEGIN;

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
SET admin_decision = 'rejected',
    decision_date = CURRENT_DATE
WHERE report_id = (
    SELECT MIN(report_id)
    FROM REVIEWREPORT
    WHERE admin_decision IS NULL
);

-- אחרי העדכון
SELECT *
FROM REVIEWREPORT
WHERE report_id = (
    SELECT MIN(report_id)
    FROM REVIEWREPORT
    WHERE admin_decision = 'rejected'
      AND decision_date = CURRENT_DATE
);

-- שמירה
COMMIT;

-- אחרי commit
SELECT *
FROM REVIEWREPORT
WHERE report_id = (
    SELECT MIN(report_id)
    FROM REVIEWREPORT
    WHERE admin_decision = 'rejected'
      AND decision_date = CURRENT_DATE
);