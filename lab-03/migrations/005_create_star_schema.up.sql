CREATE TABLE dim_clubs (
    club_key integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    club_id integer NOT NULL UNIQUE,
    name text NOT NULL,
    address text NOT NULL,
    is_active boolean NOT NULL
);

CREATE TABLE dim_dates (
    date_key date PRIMARY KEY,
    year_number integer NOT NULL,
    month_label text NOT NULL,
    day_of_week integer NOT NULL,
    is_weekend boolean NOT NULL
);

CREATE TABLE fact_reservations (
    reservation_id integer PRIMARY KEY,
    club_key integer NOT NULL
        REFERENCES dim_clubs (club_key) ON DELETE RESTRICT,
    date_key date NOT NULL
        REFERENCES dim_dates (date_key) ON DELETE RESTRICT,
    reservation_hours numeric(8, 2) NOT NULL
        CHECK (reservation_hours > 0),
    paid_amount numeric(10, 2) NOT NULL
        CHECK (paid_amount >= 0),
    status text NOT NULL
        CHECK (status IN ('active', 'cancelled'))
);
