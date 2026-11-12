-- Simple example data for the tables from laboratory work 1.
-- Run once after applying the schema migration to an empty database.

INSERT INTO tariffs (name, price_per_hour)
VALUES ('Practice Tariff', 100);

INSERT INTO clients (full_name, phone)
VALUES
    ('Practice Customer 1', '+380000000101'),
    ('Practice Customer 2', '+380000000102');

INSERT INTO clubs (name, address)
VALUES ('Practice Club', '2 Example Street');

INSERT INTO pcs (club_id, seat_number, tariff_id)
VALUES
    (
        (SELECT club_id
         FROM clubs
         WHERE name = 'Practice Club'
           AND address = '2 Example Street'),
        1,
        (SELECT tariff_id
         FROM tariffs
         WHERE name = 'Practice Tariff')
    ),
    (
        (SELECT club_id
         FROM clubs
         WHERE name = 'Practice Club'
           AND address = '2 Example Street'),
        2,
        (SELECT tariff_id
         FROM tariffs
         WHERE name = 'Practice Tariff')
    );

INSERT INTO reservations (client_id, pc_id, starts_at, ends_at, status)
VALUES
    (
        (SELECT client_id
         FROM clients
         WHERE phone = '+380000000101'),
        (SELECT pc_id
         FROM pcs
         WHERE seat_number = 1
           AND club_id = (
               SELECT club_id
               FROM clubs
               WHERE name = 'Practice Club'
                 AND address = '2 Example Street'
           )),
        TIMESTAMPTZ '2030-01-11 18:00:00+02',
        TIMESTAMPTZ '2030-01-11 20:00:00+02',
        'active'
    ),
    (
        (SELECT client_id
         FROM clients
         WHERE phone = '+380000000102'),
        (SELECT pc_id
         FROM pcs
         WHERE seat_number = 2
           AND club_id = (
               SELECT club_id
               FROM clubs
               WHERE name = 'Practice Club'
                 AND address = '2 Example Street'
           )),
        TIMESTAMPTZ '2030-01-11 18:00:00+02',
        TIMESTAMPTZ '2030-01-11 20:00:00+02',
        'active'
    );

INSERT INTO payments (reservation_id, amount, payment_method)
VALUES
    (
        (SELECT reservation_id
         FROM reservations
         WHERE client_id = (
             SELECT client_id
             FROM clients
             WHERE phone = '+380000000101'
         )
           AND pc_id = (
               SELECT pc_id
               FROM pcs
               WHERE seat_number = 1
                 AND club_id = (
                     SELECT club_id
                     FROM clubs
                     WHERE name = 'Practice Club'
                       AND address = '2 Example Street'
                 )
           )),
        200,
        'card'
    ),
    (
        (SELECT reservation_id
         FROM reservations
         WHERE client_id = (
             SELECT client_id
             FROM clients
             WHERE phone = '+380000000102'
         )
           AND pc_id = (
               SELECT pc_id
               FROM pcs
               WHERE seat_number = 2
                 AND club_id = (
                     SELECT club_id
                     FROM clubs
                     WHERE name = 'Practice Club'
                       AND address = '2 Example Street'
                 )
           )),
        200,
        'cash'
    );
