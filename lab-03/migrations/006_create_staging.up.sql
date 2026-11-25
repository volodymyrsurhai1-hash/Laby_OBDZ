CREATE TABLE stage_reservations (
    source_row integer PRIMARY KEY,
    reservation_id_raw text,
    client_id_raw text,
    pc_id_raw text,
    club_id_raw text,
    starts_at_raw text,
    ends_at_raw text,
    status_raw text,
    paid_amount_raw text
);

CREATE TABLE stage_rejects (
    source_row integer PRIMARY KEY,
    reject_reason text NOT NULL
);
