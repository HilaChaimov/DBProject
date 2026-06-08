-- ============================================================
-- Triggers.sql
-- Stage 4 - PL/pgSQL Programming
-- Project: Attractions and Tourism - Review System
-- ============================================================


-- ============================================================
-- Trigger 1:
-- After inserting a ticket, update attraction popularity_score
--
-- Business meaning:
-- When a new ticket is purchased, the attraction becomes more popular.
-- active ticket = +1
-- used ticket   = +2
-- cancelled ticket does not increase popularity
-- ============================================================

CREATE OR REPLACE FUNCTION fn_trg_update_popularity_after_ticket_insert()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ticket_status = 'active' THEN
        UPDATE attraction
        SET popularity_score = COALESCE(popularity_score, 0) + 1
        WHERE attraction_id = NEW.attraction_id;

    ELSIF NEW.ticket_status = 'used' THEN
        UPDATE attraction
        SET popularity_score = COALESCE(popularity_score, 0) + 2
        WHERE attraction_id = NEW.attraction_id;
    END IF;

    RETURN NEW;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in ticket insert popularity trigger: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trg_update_popularity_after_ticket_insert ON ticket;

CREATE TRIGGER trg_update_popularity_after_ticket_insert
AFTER INSERT ON ticket
FOR EACH ROW
EXECUTE FUNCTION fn_trg_update_popularity_after_ticket_insert();



-- ============================================================
-- Trigger 2:
-- Refresh attraction average rating after review insert/update
-- ============================================================

CREATE OR REPLACE FUNCTION fn_refresh_attraction_avg_rating()
RETURNS TRIGGER AS $$
DECLARE
    v_attraction_id INT;
BEGIN
    -- Find the attraction related to the review through its ticket
    SELECT t.attraction_id
    INTO v_attraction_id
    FROM ticket t
    WHERE t.ticket_id = COALESCE(NEW.ticket_id, OLD.ticket_id);

    -- If no related attraction was found, stop safely
    IF v_attraction_id IS NULL THEN
        RAISE NOTICE 'No attraction found for this review ticket.';
        RETURN COALESCE(NEW, OLD);
    END IF;

    -- Update the stored average rating of the attraction
    UPDATE attraction a
    SET avg_rating = (
        SELECT ROUND(AVG(r.rating), 2)
        FROM review r
        JOIN ticket t ON r.ticket_id = t.ticket_id
        WHERE t.attraction_id = v_attraction_id
          AND COALESCE(r.is_deleted, FALSE) = FALSE
    )
    WHERE a.attraction_id = v_attraction_id;

    RAISE NOTICE 'Average rating updated for attraction %', v_attraction_id;

    RETURN COALESCE(NEW, OLD);

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error in fn_refresh_attraction_avg_rating: %', SQLERRM;
        RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trg_refresh_avg_rating_after_review_change ON review;

CREATE TRIGGER trg_refresh_avg_rating_after_review_change
AFTER INSERT OR UPDATE OF rating, is_deleted ON review
FOR EACH ROW
EXECUTE FUNCTION fn_refresh_attraction_avg_rating();