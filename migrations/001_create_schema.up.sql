CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE tariffs (
    tariff_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL UNIQUE,
    price_per_hour numeric NOT NULL CHECK (price_per_hour >= 0),
    CONSTRAINT tariffs_name_not_blank CHECK (btrim(name) <> '')
);

CREATE TABLE clients (
    client_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name text NOT NULL CHECK (btrim(full_name) <> ''),
    phone text NOT NULL UNIQUE CHECK (btrim(phone) <> '')
);

CREATE TABLE pcs (
    pc_id integer PRIMARY KEY CHECK (pc_id > 0),
    is_active boolean NOT NULL DEFAULT true,
    tariff_id integer NOT NULL
        REFERENCES tariffs (tariff_id) ON DELETE RESTRICT
);

CREATE TABLE reservations (
    reservation_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    client_id integer NOT NULL
        REFERENCES clients (client_id) ON DELETE RESTRICT,
    pc_id integer NOT NULL
        REFERENCES pcs (pc_id) ON DELETE RESTRICT,
    starts_at timestamptz NOT NULL,
    ends_at timestamptz NOT NULL,
    status text NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'cancelled')),
    agreed_price_per_hour numeric NOT NULL
        CHECK (agreed_price_per_hour >= 0),
    CONSTRAINT reservations_valid_interval CHECK (ends_at > starts_at),
    CONSTRAINT reservations_no_active_overlap
        EXCLUDE USING gist (
            pc_id WITH =,
            tstzrange(starts_at, ends_at, '[)') WITH &&
        )
        WHERE (status = 'active')
);

CREATE FUNCTION set_reservation_price()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    pc_is_active boolean;
    pc_price numeric;
BEGIN
    SELECT p.is_active, t.price_per_hour
    INTO pc_is_active, pc_price
    FROM pcs AS p
    JOIN tariffs AS t ON t.tariff_id = p.tariff_id
    WHERE p.pc_id = NEW.pc_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'PC % does not exist', NEW.pc_id
            USING ERRCODE = '23503';
    END IF;

    IF NOT pc_is_active THEN
        RAISE EXCEPTION 'PC % is inactive and cannot be reserved', NEW.pc_id
            USING ERRCODE = '23514';
    END IF;

    NEW.agreed_price_per_hour := pc_price;
    RETURN NEW;
END;
$$;

CREATE TRIGGER reservations_set_price
BEFORE INSERT OR UPDATE OF pc_id ON reservations
FOR EACH ROW
EXECUTE FUNCTION set_reservation_price();
