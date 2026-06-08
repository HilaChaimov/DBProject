-- ============================================================
-- MainPrograms.sql
-- Stage D - PL/pgSQL Programming
-- Project: Attractions and Tourism - Review System
-- ============================================================
-- Prerequisites (run in order before this file):
--   1. StageD/AlterTable.sql
--   2. StageD/Functions.sql
--   3. StageD/Procedures.sql
--   4. StageD/Triggers.sql
-- ============================================================


-- ============================================================
-- Main Program 1
-- Calls:
--   fn_calculate_attraction_quality  (Function 1)
--   pr_refresh_attraction_popularity (Procedure 1)
--
-- What it does:
--   Calculates and prints the quality score for a sample attraction,
--   then runs the procedure that refreshes popularity scores for
--   every attraction in the database.
-- ============================================================

DO $$
DECLARE
    v_attraction_id  INT     := 1;
    v_quality_score  NUMERIC;
BEGIN
    RAISE NOTICE '=== Main Program 1: Attraction Quality and Popularity Refresh ===';

    -- Step 1: call Function 1 to get the quality score for the sample attraction
    v_quality_score := fn_calculate_attraction_quality(v_attraction_id);
    RAISE NOTICE 'Quality score for attraction %: %', v_attraction_id, v_quality_score;

    -- Step 2: call Procedure 1 to recalculate popularity scores for all attractions
    RAISE NOTICE 'Calling pr_refresh_attraction_popularity for all attractions...';
    CALL pr_refresh_attraction_popularity();

    RAISE NOTICE '=== Main Program 1 completed successfully ===';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in Main Program 1: %', SQLERRM;
END;
$$;


-- ============================================================
-- Main Program 2
-- Calls:
--   fn_get_customer_activity_level  (Function 2)
--   pr_mark_problematic_attractions (Procedure 2)
--
-- What it does:
--   Classifies and prints the activity level for a sample customer,
--   then runs the procedure that updates attraction_status for
--   every attraction in the database.
-- ============================================================

DO $$
DECLARE
    v_customer_id    INT         := 1;
    v_activity_level VARCHAR(30);
BEGIN
    RAISE NOTICE '=== Main Program 2: Customer Activity and Attraction Status Update ===';

    -- Step 1: call Function 2 to classify the sample customer
    v_activity_level := fn_get_customer_activity_level(v_customer_id);
    RAISE NOTICE 'Activity level for customer %: %', v_customer_id, v_activity_level;

    -- Step 2: call Procedure 2 to update attraction_status for all attractions
    RAISE NOTICE 'Calling pr_mark_problematic_attractions for all attractions...';
    CALL pr_mark_problematic_attractions();

    RAISE NOTICE '=== Main Program 2 completed successfully ===';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in Main Program 2: %', SQLERRM;
END;
$$;
