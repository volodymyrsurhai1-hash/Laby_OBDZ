BEGIN;

ALTER TABLE clubs
ADD COLUMN max_places integer NOT NULL DEFAULT 15,
ADD CONSTRAINT clubs_max_places_positive
    CHECK (max_places > 0);


CREATE OR REPLACE FUNCTION check_pc_capacity()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    capacity integer;
    installed bigint;
BEGIN
    SELECT max_places
    INTO capacity
    FROM clubs
    WHERE club_id = NEW.club_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Club % does not exist', NEW.club_id
            USING ERRCODE = '23503';
    END IF;

    SELECT count(*)
    INTO installed
    FROM pcs
    WHERE club_id = NEW.club_id
      AND (TG_OP = 'INSERT' OR pc_id <> NEW.pc_id);

    IF NEW.seat_number > capacity OR installed >= capacity THEN
        RAISE EXCEPTION 'Club capacity exceeded'
            USING ERRCODE = '23514';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER pcs_check_club_capacity
BEFORE INSERT OR UPDATE OF club_id, seat_number
ON pcs
FOR EACH ROW
EXECUTE FUNCTION check_pc_capacity();


CREATE OR REPLACE FUNCTION check_club_max_places()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    installed bigint;
    highest_seat integer;
BEGIN
    IF NEW.max_places < OLD.max_places THEN
        SELECT count(*), COALESCE(max(seat_number), 0)
        INTO installed, highest_seat
        FROM pcs
        WHERE club_id = NEW.club_id;

        IF installed > NEW.max_places OR highest_seat > NEW.max_places THEN
            RAISE EXCEPTION 'New limit is below the club capacity in use'
                USING ERRCODE = '23514';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER clubs_check_max_places
BEFORE UPDATE OF max_places
ON clubs
FOR EACH ROW
EXECUTE FUNCTION check_club_max_places();

COMMIT;