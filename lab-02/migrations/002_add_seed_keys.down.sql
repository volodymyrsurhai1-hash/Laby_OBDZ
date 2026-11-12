ALTER TABLE reservations
    DROP CONSTRAINT reservations_client_pc_time_status_key;

ALTER TABLE clubs
    DROP CONSTRAINT clubs_name_address_key;

ALTER TABLE clients
    DROP CONSTRAINT clients_email_not_blank;

ALTER TABLE clients
    DROP COLUMN email;
