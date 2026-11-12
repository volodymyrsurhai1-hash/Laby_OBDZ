-- Наповнення кіберклубів: п'ять тарифів, вісім клієнтів, чотири клуби,
-- шість ПК, дванадцять бронювань і сім оплат.
-- Перед запуском застосуйте міграцію 001 до порожньої бази.
-- Для клубів і бронювань ID задані явно, бо в базовій схемі немає природного унікального ключа.

INSERT INTO tariffs (name, price_per_hour)
VALUES
    ('Basic', 100),
    ('Standard', 150),
    ('Evening', 180),
    ('Club Rate', 250),
    ('Premium', 300)
ON CONFLICT (name) DO NOTHING;

INSERT INTO clients (full_name, phone)
VALUES
    ('Alice Anderson', '+380000000301'),
    ('Andrew Baker', '+380000000302'),
    ('Anna Brown', '+380000000303'),
    ('Aaron Carter', '+380000000304'),
    ('Bob Davis', '+380000000305'),
    ('Bella Evans', '+380000000306'),
    ('Charlie Foster', '+380000000307'),
    ('Dana Green', '+380000000401')
ON CONFLICT (phone) DO NOTHING;

INSERT INTO clubs (club_id, name, address)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 'Cyber Club Center', '1 Main Street'),
    (2, 'Cyber Club Riverside', '2 River Street'),
    (3, 'Cyber Club Campus', '3 Campus Street'),
    (4, 'Cyber Club Empty', '4 Empty Street')
ON CONFLICT (club_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('clubs', 'club_id'), (SELECT MAX(club_id) FROM clubs));

INSERT INTO pcs (club_id, seat_number, tariff_id)
VALUES
    (1, 1, 1),
    (1, 2, 2),
    (1, 3, 3),
    (2, 1, 1),
    (2, 2, 5),
    (3, 1, 2)
ON CONFLICT (club_id, seat_number) DO NOTHING;

INSERT INTO reservations (reservation_id, client_id, pc_id, starts_at, ends_at, status)
OVERRIDING SYSTEM VALUE
VALUES
    (1, 1, 1, TIMESTAMPTZ '2026-03-01 10:00:00+02', TIMESTAMPTZ '2026-03-01 12:00:00+02', 'active'),
    (2, 2, 1, TIMESTAMPTZ '2026-03-01 12:00:00+02', TIMESTAMPTZ '2026-03-01 14:00:00+02', 'active'),
    (3, 3, 2, TIMESTAMPTZ '2026-03-02 18:00:00+02', TIMESTAMPTZ '2026-03-02 20:00:00+02', 'cancelled'),
    (4, 4, 2, TIMESTAMPTZ '2026-03-02 18:00:00+02', TIMESTAMPTZ '2026-03-02 20:00:00+02', 'active'),
    (5, 5, 3, TIMESTAMPTZ '2026-03-03 09:00:00+02', TIMESTAMPTZ '2026-03-03 12:00:00+02', 'active'),
    (6, 6, 4, TIMESTAMPTZ '2026-03-05 10:00:00+02', TIMESTAMPTZ '2026-03-05 12:00:00+02', 'active'),
    (7, 7, 5, TIMESTAMPTZ '2026-03-10 14:00:00+02', TIMESTAMPTZ '2026-03-10 16:00:00+02', 'active'),
    (8, 1, 6, TIMESTAMPTZ '2026-03-15 18:00:00+02', TIMESTAMPTZ '2026-03-15 20:00:00+02', 'active'),
    (9, 2, 5, TIMESTAMPTZ '2026-03-31 18:30:00+02', TIMESTAMPTZ '2026-03-31 20:30:00+02', 'active'),
    (10, 3, 6, TIMESTAMPTZ '2026-04-05 12:00:00+02', TIMESTAMPTZ '2026-04-05 14:00:00+02', 'active'),
    (11, 4, 1, TIMESTAMPTZ '2026-04-09 16:00:00+02', TIMESTAMPTZ '2026-04-09 18:00:00+02', 'active'),
    (12, 5, 4, TIMESTAMPTZ '2026-04-20 09:00:00+02', TIMESTAMPTZ '2026-04-20 10:00:00+02', 'active')
ON CONFLICT (reservation_id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('reservations', 'reservation_id'), (SELECT MAX(reservation_id) FROM reservations));

INSERT INTO payments (reservation_id, amount, payment_method)
VALUES
    (1, 200, 'card'),
    (4, 300, 'cash'),
    (5, 540, 'online'),
    (6, 200, 'card'),
    (8, 300, 'online'),
    (10, 300, 'cash'),
    (12, 100, 'cash')
ON CONFLICT (reservation_id) DO NOTHING;
