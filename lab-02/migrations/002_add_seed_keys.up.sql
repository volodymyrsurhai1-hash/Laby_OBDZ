ALTER TABLE clients
    ADD COLUMN email text;

ALTER TABLE clients
    ADD CONSTRAINT clients_email_not_blank
    CHECK (email IS NULL OR btrim(email) <> '');

ALTER TABLE clubs
    ADD CONSTRAINT clubs_name_address_key
    UNIQUE (name, address);

ALTER TABLE reservations
    ADD CONSTRAINT reservations_client_pc_time_status_key
    UNIQUE (client_id, pc_id, starts_at, ends_at, status);
