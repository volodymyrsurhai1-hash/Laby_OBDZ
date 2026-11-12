-- Наповнення кіберклубів: п'ять тарифів, вісім клієнтів, чотири клуби,
-- шість ПК, дванадцять бронювань і сім оплат.
-- Перед запуском застосуйте міграції 001 і 002 до порожньої бази.
-- Зовнішні ключі відповідають ID, які початкові міграції створюють у порожній БД.

INSERT INTO tariffs (name, price_per_hour)
VALUES
    ('Basic', 100),
    ('Standard', 150),
    ('Evening', 180),
    ('Club Rate', 250),
    ('Premium', 300)
ON CONFLICT (name) DO NOTHING;

INSERT INTO clients (full_name, phone, email)
VALUES
    ('Alice Anderson', '+380000000301', 'alice@cyber.test'),
    ('Andrew Baker', '+380000000302', NULL),
    ('Anna Brown', '+380000000303', 'anna@example.test'),
    ('Aaron Carter', '+380000000304', 'aaron@cyber.test'),
    ('Bob Davis', '+380000000305', 'bob@example.test'),
    ('Bella Evans', '+380000000306', NULL),
    ('Charlie Foster', '+380000000307', 'charlie@cyber.test'),
    ('Dana Green', '+380000000401', NULL)
ON CONFLICT (phone) DO NOTHING;

INSERT INTO clubs (name, address)
VALUES
    ('Cyber Club Center', '1 Main Street'),
    ('Cyber Club Riverside', '2 River Street'),
    ('Cyber Club Campus', '3 Campus Street'),
    ('Cyber Club Empty', '4 Empty Street')
ON CONFLICT (name, address) DO NOTHING;

INSERT INTO pcs (club_id, seat_number, tariff_id)
VALUES
    (1, 1, 1),
    (1, 2, 2),
    (1, 3, 3),
    (2, 1, 1),
    (2, 2, 5),
    (3, 1, 2)
ON CONFLICT (club_id, seat_number) DO NOTHING;

INSERT INTO reservations (client_id, pc_id, starts_at, ends_at, status)
VALUES
    (1, 1, TIMESTAMPTZ '2026-03-01 10:00:00+02', TIMESTAMPTZ '2026-03-01 12:00:00+02', 'active'),
    (2, 1, TIMESTAMPTZ '2026-03-01 12:00:00+02', TIMESTAMPTZ '2026-03-01 14:00:00+02', 'active'),
    (3, 2, TIMESTAMPTZ '2026-03-02 18:00:00+02', TIMESTAMPTZ '2026-03-02 20:00:00+02', 'cancelled'),
    (4, 2, TIMESTAMPTZ '2026-03-02 18:00:00+02', TIMESTAMPTZ '2026-03-02 20:00:00+02', 'active'),
    (5, 3, TIMESTAMPTZ '2026-03-03 09:00:00+02', TIMESTAMPTZ '2026-03-03 12:00:00+02', 'active'),
    (6, 4, TIMESTAMPTZ '2026-03-05 10:00:00+02', TIMESTAMPTZ '2026-03-05 12:00:00+02', 'active'),
    (7, 5, TIMESTAMPTZ '2026-03-10 14:00:00+02', TIMESTAMPTZ '2026-03-10 16:00:00+02', 'active'),
    (1, 6, TIMESTAMPTZ '2026-03-15 18:00:00+02', TIMESTAMPTZ '2026-03-15 20:00:00+02', 'active'),
    (2, 5, TIMESTAMPTZ '2026-03-31 18:30:00+02', TIMESTAMPTZ '2026-03-31 20:30:00+02', 'active'),
    (3, 6, TIMESTAMPTZ '2026-04-05 12:00:00+02', TIMESTAMPTZ '2026-04-05 14:00:00+02', 'active'),
    (4, 1, TIMESTAMPTZ '2026-04-09 16:00:00+02', TIMESTAMPTZ '2026-04-09 18:00:00+02', 'active'),
    (5, 4, TIMESTAMPTZ '2026-04-20 09:00:00+02', TIMESTAMPTZ '2026-04-20 10:00:00+02', 'active')
ON CONFLICT (client_id, pc_id, starts_at, ends_at, status) DO NOTHING;

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
