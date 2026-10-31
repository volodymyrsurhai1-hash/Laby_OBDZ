CREATE OR REPLACE FUNCTION set_reservation_price()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    pc_is_active boolean;
    club_is_active boolean;
    pc_price numeric;
BEGIN
    SELECT p.is_active, c.is_active, t.price_per_hour
    INTO pc_is_active, club_is_active, pc_price
    FROM pcs AS p
    JOIN clubs AS c ON c.club_id = p.club_id
    JOIN tariffs AS t ON t.tariff_id = p.tariff_id
    WHERE p.pc_id = NEW.pc_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PC % does not exist', NEW.pc_id
            USING ERRCODE = '23503';
    END IF;

    IF NOT club_is_active THEN
        RAISE EXCEPTION 'Club for PC % is inactive and cannot be reserved', NEW.pc_id
            USING ERRCODE = '23514';
    END IF;

    IF NOT pc_is_active THEN
        RAISE EXCEPTION 'PC % is inactive and cannot be reserved', NEW.pc_id
            USING ERRCODE = '23514';
    END IF;

    NEW.agreed_price_per_hour := pc_price;
    RETURN NEW;
END;
$$;
