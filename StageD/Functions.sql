CREATE OR REPLACE FUNCTION fn_calculate_attraction_quality(p_attraction_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_avg_rating NUMERIC(3,2) := 0;
    v_tickets_count INT := 0;
    v_reviews_count INT := 0;
    v_cancelled_count INT := 0;
    v_reports_count INT := 0;
    v_quality_score NUMERIC := 0;
BEGIN
    -- Check that the attraction exists
    IF NOT EXISTS (
        SELECT 1
        FROM attraction
        WHERE attraction_id = p_attraction_id
    ) THEN
        RAISE EXCEPTION 'Attraction with id % does not exist', p_attraction_id;
    END IF;

    -- Get average rating from the attraction table
    SELECT COALESCE(avg_rating, 0)
    INTO v_avg_rating
    FROM attraction
    WHERE attraction_id = p_attraction_id;

    -- Count tickets for this attraction
    SELECT COUNT(*)
    INTO v_tickets_count
    FROM ticket
    WHERE attraction_id = p_attraction_id;

    -- Count cancelled tickets for this attraction
    SELECT COUNT(*)
    INTO v_cancelled_count
    FROM ticket
    WHERE attraction_id = p_attraction_id
      AND LOWER(ticket_status) = 'cancelled';

    -- Count reviews for this attraction through tickets
    SELECT COUNT(*)
    INTO v_reviews_count
    FROM review r
    JOIN ticket t ON r.ticket_id = t.ticket_id
    WHERE t.attraction_id = p_attraction_id
      AND COALESCE(r.is_deleted, FALSE) = FALSE;

    -- Count reports on reviews of this attraction
    SELECT COUNT(*)
    INTO v_reports_count
    FROM reviewreport rr
    JOIN review r ON rr.review_id = r.review_id
    JOIN ticket t ON r.ticket_id = t.ticket_id
    WHERE t.attraction_id = p_attraction_id;

    /*
        Quality score logic:
        - Average rating is the main part: rating 1-5 becomes 20-100.
        - Tickets add popularity points, up to 20.
        - Reviews add reliability points, up to 15.
        - Cancelled tickets reduce score.
        - Reports reduce score.
    */
    v_quality_score :=
          (v_avg_rating * 20)
        + LEAST(v_tickets_count, 20)
        + LEAST(v_reviews_count, 15)
        - (v_cancelled_count * 2)
        - (v_reports_count * 3);

    -- Prevent negative score
    IF v_quality_score < 0 THEN
        v_quality_score := 0;
    END IF;

    RETURN ROUND(v_quality_score, 2);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in fn_calculate_attraction_quality: %', SQLERRM;
        RETURN 0;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- Function 2:
-- Get customer activity level
--
-- Business meaning:
-- This function classifies a customer according to his/her activity
-- in the attractions system.
--
-- The classification is based on:
-- tickets purchased
-- used tickets
-- cancelled tickets
-- reviews written
-- reactions to reviews
--
-- PL/pgSQL elements:
-- implicit cursor, record, loop, conditions, exception
-- ============================================================

CREATE OR REPLACE FUNCTION fn_get_customer_activity_level(p_customer_id INT)
RETURNS VARCHAR(30) AS $$
DECLARE
    v_ticket_rec RECORD;

    v_total_tickets INT := 0;
    v_active_tickets INT := 0;
    v_used_tickets INT := 0;
    v_cancelled_tickets INT := 0;

    v_reviews_count INT := 0;
    v_reactions_count INT := 0;

    v_activity_level VARCHAR(30);
BEGIN
    -- Check that the customer exists
    IF NOT EXISTS (
        SELECT 1
        FROM customer
        WHERE customer_id = p_customer_id
    ) THEN
        RAISE EXCEPTION 'Customer with id % does not exist', p_customer_id;
    END IF;

    -- Implicit cursor:
    -- The FOR loop goes over all tickets of the customer.
    FOR v_ticket_rec IN
        SELECT ticket_id, ticket_status
        FROM ticket
        WHERE customer_id = p_customer_id
    LOOP
        v_total_tickets := v_total_tickets + 1;

        IF v_ticket_rec.ticket_status = 'active' THEN
            v_active_tickets := v_active_tickets + 1;

        ELSIF v_ticket_rec.ticket_status = 'used' THEN
            v_used_tickets := v_used_tickets + 1;

        ELSIF v_ticket_rec.ticket_status = 'cancelled' THEN
            v_cancelled_tickets := v_cancelled_tickets + 1;
        END IF;
    END LOOP;

    -- Count reviews written by this customer.
    -- In our schema, review is connected to customer through ticket.
    SELECT COUNT(*)
    INTO v_reviews_count
    FROM review r
    JOIN ticket t ON r.ticket_id = t.ticket_id
    WHERE t.customer_id = p_customer_id
      AND COALESCE(r.is_deleted, FALSE) = FALSE;

    -- Count reactions made by this customer
    SELECT COUNT(*)
    INTO v_reactions_count
    FROM reviewreaction
    WHERE customer_id = p_customer_id;

    -- Classify customer activity level
    IF v_total_tickets = 0
       AND v_reviews_count = 0
       AND v_reactions_count = 0 THEN

        v_activity_level := 'INACTIVE_CUSTOMER';

    ELSIF v_cancelled_tickets >= 5
          AND v_cancelled_tickets > (v_used_tickets + v_active_tickets) THEN

        v_activity_level := 'RISKY_CUSTOMER';

    ELSIF v_total_tickets >= 15
          AND v_used_tickets >= 8
          AND v_reviews_count >= 5
          AND v_reactions_count >= 10 THEN

        v_activity_level := 'VIP_CUSTOMER';

    ELSIF v_total_tickets >= 5
          OR v_reviews_count >= 3
          OR v_reactions_count >= 10 THEN

        v_activity_level := 'ACTIVE_CUSTOMER';

    ELSE
        v_activity_level := 'REGULAR_CUSTOMER';
    END IF;

    RETURN v_activity_level;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in fn_get_customer_activity_level: %', SQLERRM;
        RETURN 'ERROR';
END;
$$ LANGUAGE plpgsql;