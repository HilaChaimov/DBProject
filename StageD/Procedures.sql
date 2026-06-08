-- ============================================================
-- Procedures.sql
-- Stage 4 - PL/pgSQL Programming
-- Project: Attractions and Tourism - Review System
-- ============================================================


-- ============================================================
-- Procedure 1:
-- Refresh popularity_score for all attractions
--
-- Business meaning:
-- The popularity score is calculated from existing ticket data.
-- active ticket     = +1
-- used ticket       = +2
-- cancelled ticket  = -1
-- group booking ticket = +1
--
-- PL/pgSQL elements:
-- explicit cursor, record, loop, DML update, conditions, exception
-- ============================================================

CREATE OR REPLACE PROCEDURE pr_refresh_attraction_popularity()
LANGUAGE plpgsql
AS $$
DECLARE
    v_attraction_rec RECORD;

    v_active_tickets_count INT := 0;
    v_used_tickets_count INT := 0;
    v_cancelled_tickets_count INT := 0;
    v_group_tickets_count INT := 0;

    v_new_popularity_score INT := 0;

    cur_attractions CURSOR FOR
        SELECT attraction_id, attraction_name
        FROM attraction
        ORDER BY attraction_id;
BEGIN
    OPEN cur_attractions;

    LOOP
        FETCH cur_attractions INTO v_attraction_rec;
        EXIT WHEN NOT FOUND;

        -- Count regular tickets by status
        SELECT COUNT(*)
        INTO v_active_tickets_count
        FROM ticket
        WHERE attraction_id = v_attraction_rec.attraction_id
          AND ticket_status = 'active';

        SELECT COUNT(*)
        INTO v_used_tickets_count
        FROM ticket
        WHERE attraction_id = v_attraction_rec.attraction_id
          AND ticket_status = 'used';

        SELECT COUNT(*)
        INTO v_cancelled_tickets_count
        FROM ticket
        WHERE attraction_id = v_attraction_rec.attraction_id
          AND ticket_status = 'cancelled';

        -- Count group booking tickets only if booking_details exists
        IF to_regclass('booking_details') IS NOT NULL THEN
            EXECUTE
                'SELECT COALESCE(SUM(ticket_count), 0)
                 FROM booking_details
                 WHERE attraction_id = $1'
            INTO v_group_tickets_count
            USING v_attraction_rec.attraction_id;
        ELSE
            v_group_tickets_count := 0;
        END IF;

        -- Calculate score
        v_new_popularity_score :=
            GREATEST(
                  v_active_tickets_count
                + (v_used_tickets_count * 2)
                + v_group_tickets_count
                - v_cancelled_tickets_count,
                0
            );

        -- DML update
        UPDATE attraction
        SET popularity_score = v_new_popularity_score
        WHERE attraction_id = v_attraction_rec.attraction_id;

        RAISE NOTICE 'Attraction % updated with popularity_score = %',
            v_attraction_rec.attraction_id,
            v_new_popularity_score;
    END LOOP;

    CLOSE cur_attractions;

EXCEPTION
    WHEN OTHERS THEN
        IF cur_attractions%ISOPEN THEN
            CLOSE cur_attractions;
        END IF;

        RAISE NOTICE 'Error in pr_refresh_attraction_popularity: %', SQLERRM;
END;
$$;



-- ============================================================
-- Procedure 2:
-- Mark problematic / popular attractions
--
-- Business meaning:
-- The procedure updates attraction_status according to:
-- rating, number of reviews, number of reports, cancellations,
-- and popularity_score.
--
-- Possible statuses:
-- ACTIVE
-- POPULAR
-- NEEDS_REVIEW
-- LOW_RATED
--
-- PL/pgSQL elements:
-- explicit cursor, record, loop, DML update, conditions, exception
-- ============================================================

CREATE OR REPLACE PROCEDURE pr_mark_problematic_attractions()
LANGUAGE plpgsql
AS $$
DECLARE
    v_attraction_rec RECORD;

    v_avg_rating NUMERIC(10,2) := 0;
    v_reviews_count INT := 0;
    v_reports_count INT := 0;
    v_cancelled_tickets_count INT := 0;

    v_new_status VARCHAR(30);

    cur_attractions CURSOR FOR
        SELECT attraction_id, attraction_name, popularity_score
        FROM attraction
        ORDER BY attraction_id;
BEGIN
    OPEN cur_attractions;

    LOOP
        FETCH cur_attractions INTO v_attraction_rec;
        EXIT WHEN NOT FOUND;

        -- Calculate average rating and number of active reviews
        SELECT
            COALESCE(ROUND(AVG(r.rating), 2), 0),
            COUNT(r.review_id)
        INTO
            v_avg_rating,
            v_reviews_count
        FROM review r
        LEFT JOIN ticket t ON r.ticket_id = t.ticket_id
        WHERE COALESCE(r.is_deleted, FALSE) = FALSE
          AND (
                t.attraction_id = v_attraction_rec.attraction_id
                OR r.direct_attraction_id = v_attraction_rec.attraction_id
              );

        -- Count reports on reviews of this attraction
        SELECT COUNT(DISTINCT rep.report_id)
        INTO v_reports_count
        FROM reviewreport rep
        JOIN review r ON rep.review_id = r.review_id
        LEFT JOIN ticket t ON r.ticket_id = t.ticket_id
        WHERE
            t.attraction_id = v_attraction_rec.attraction_id
            OR r.direct_attraction_id = v_attraction_rec.attraction_id;

        -- Count cancelled tickets
        SELECT COUNT(*)
        INTO v_cancelled_tickets_count
        FROM ticket
        WHERE attraction_id = v_attraction_rec.attraction_id
          AND ticket_status = 'cancelled';

        -- Business logic for status
        IF v_reports_count >= 10 OR v_cancelled_tickets_count >= 20 THEN
            v_new_status := 'NEEDS_REVIEW';

        ELSIF v_reviews_count >= 5 AND v_avg_rating < 3 THEN
            v_new_status := 'LOW_RATED';

        ELSIF v_attraction_rec.popularity_score >= 50 AND v_avg_rating >= 3.5 THEN
            v_new_status := 'POPULAR';

        ELSE
            v_new_status := 'ACTIVE';
        END IF;

        -- DML update
        UPDATE attraction
        SET attraction_status = v_new_status
        WHERE attraction_id = v_attraction_rec.attraction_id;

        RAISE NOTICE 'Attraction % status updated to %',
            v_attraction_rec.attraction_id,
            v_new_status;
    END LOOP;

    CLOSE cur_attractions;

EXCEPTION
    WHEN OTHERS THEN
        IF cur_attractions%ISOPEN THEN
            CLOSE cur_attractions;
        END IF;

        RAISE NOTICE 'Error in pr_mark_problematic_attractions: %', SQLERRM;
END;
$$;