-- Демонстрационные данные для упражнений с JOIN.
-- Скрипт можно запускать повторно: он не добавляет дубликаты.

BEGIN;

INSERT INTO clubs (name, address)
SELECT data.name, data.address
FROM (VALUES
    ('Join Demo Central', '10 Join Street'),
    ('Join Demo Riverside', '20 Join Street'),
    ('Join Demo Empty', '30 Join Street')
) AS data(name, address)
WHERE NOT EXISTS (
    SELECT 1
    FROM clubs AS club
    WHERE club.name = data.name
      AND club.address = data.address
);

INSERT INTO tariffs (name, price_per_hour)
VALUES
    ('Join Demo Basic', 100),
    ('Join Demo Standard', 150),
    ('Join Demo Premium', 220)
ON CONFLICT (name) DO NOTHING;

INSERT INTO clients (full_name, phone)
VALUES
    ('Join Demo Alice', '+380000000201'),
    ('Join Demo Bohdan', '+380000000202'),
    ('Join Demo Daria', '+380000000203'),
    ('Join Demo Maksym', '+380000000204'),
    ('Join Demo Olena', '+380000000205'),
    ('Join Demo Petro', '+380000000206'),
    ('Join Demo Sofia', '+380000000207'),
    ('Join Demo Without Booking', '+380000000208')
ON CONFLICT (phone) DO NOTHING;

INSERT INTO pcs (club_id, seat_number, tariff_id)
SELECT club.club_id, pc.seat_number, tariff.tariff_id
FROM (VALUES
    ('Join Demo Central', '10 Join Street', 1, 'Join Demo Basic'),
    ('Join Demo Central', '10 Join Street', 2, 'Join Demo Standard'),
    ('Join Demo Central', '10 Join Street', 3, 'Join Demo Premium'),
    ('Join Demo Riverside', '20 Join Street', 1, 'Join Demo Basic'),
    ('Join Demo Riverside', '20 Join Street', 2, 'Join Demo Standard')
) AS pc(club_name, club_address, seat_number, tariff_name)
JOIN clubs AS club
  ON club.name = pc.club_name
 AND club.address = pc.club_address
JOIN tariffs AS tariff
  ON tariff.name = pc.tariff_name
ON CONFLICT (club_id, seat_number) DO NOTHING;

INSERT INTO reservations (client_id, pc_id, starts_at, ends_at, status)
SELECT client.client_id,
       pc.pc_id,
       booking.starts_at,
       booking.ends_at,
       booking.status
FROM (VALUES
    ('+380000000201', 'Join Demo Central', '10 Join Street', 1,
     TIMESTAMPTZ '2031-02-01 10:00:00+02', TIMESTAMPTZ '2031-02-01 12:00:00+02', 'active'),
    ('+380000000202', 'Join Demo Central', '10 Join Street', 1,
     TIMESTAMPTZ '2031-02-01 12:00:00+02', TIMESTAMPTZ '2031-02-01 14:00:00+02', 'active'),
    ('+380000000203', 'Join Demo Central', '10 Join Street', 2,
     TIMESTAMPTZ '2031-02-01 10:00:00+02', TIMESTAMPTZ '2031-02-01 12:00:00+02', 'cancelled'),
    ('+380000000204', 'Join Demo Central', '10 Join Street', 2,
     TIMESTAMPTZ '2031-02-01 10:00:00+02', TIMESTAMPTZ '2031-02-01 12:00:00+02', 'active'),
    ('+380000000205', 'Join Demo Central', '10 Join Street', 3,
     TIMESTAMPTZ '2031-02-01 18:00:00+02', TIMESTAMPTZ '2031-02-01 21:00:00+02', 'active'),
    ('+380000000206', 'Join Demo Riverside', '20 Join Street', 1,
     TIMESTAMPTZ '2031-02-01 10:00:00+02', TIMESTAMPTZ '2031-02-01 13:00:00+02', 'active'),
    ('+380000000201', 'Join Demo Riverside', '20 Join Street', 2,
     TIMESTAMPTZ '2031-02-01 11:00:00+02', TIMESTAMPTZ '2031-02-01 12:00:00+02', 'active'),
    ('+380000000207', 'Join Demo Riverside', '20 Join Street', 2,
     TIMESTAMPTZ '2031-02-02 09:00:00+02', TIMESTAMPTZ '2031-02-02 11:00:00+02', 'cancelled')
) AS booking(phone, club_name, club_address, seat_number, starts_at, ends_at, status)
JOIN clients AS client
  ON client.phone = booking.phone
JOIN clubs AS club
  ON club.name = booking.club_name
 AND club.address = booking.club_address
JOIN pcs AS pc
  ON pc.club_id = club.club_id
 AND pc.seat_number = booking.seat_number
WHERE NOT EXISTS (
    SELECT 1
    FROM reservations AS existing
    WHERE existing.client_id = client.client_id
      AND existing.pc_id = pc.pc_id
      AND existing.starts_at = booking.starts_at
      AND existing.ends_at = booking.ends_at
);

INSERT INTO payments (reservation_id, amount, payment_method)
SELECT reservation.reservation_id, payment.amount, payment.payment_method
FROM (VALUES
    ('+380000000201', 'Join Demo Central', '10 Join Street', 1,
     TIMESTAMPTZ '2031-02-01 10:00:00+02', 200, 'card'),
    ('+380000000204', 'Join Demo Central', '10 Join Street', 2,
     TIMESTAMPTZ '2031-02-01 10:00:00+02', 300, 'cash'),
    ('+380000000205', 'Join Demo Central', '10 Join Street', 3,
     TIMESTAMPTZ '2031-02-01 18:00:00+02', 660, 'online'),
    ('+380000000206', 'Join Demo Riverside', '20 Join Street', 1,
     TIMESTAMPTZ '2031-02-01 10:00:00+02', 300, 'cash')
) AS payment(phone, club_name, club_address, seat_number, starts_at, amount, payment_method)
JOIN clients AS client
  ON client.phone = payment.phone
JOIN clubs AS club
  ON club.name = payment.club_name
 AND club.address = payment.club_address
JOIN pcs AS pc
  ON pc.club_id = club.club_id
 AND pc.seat_number = payment.seat_number
JOIN reservations AS reservation
  ON reservation.client_id = client.client_id
 AND reservation.pc_id = pc.pc_id
 AND reservation.starts_at = payment.starts_at
WHERE NOT EXISTS (
    SELECT 1
    FROM payments AS existing
    WHERE existing.reservation_id = reservation.reservation_id
)
ON CONFLICT (reservation_id) DO NOTHING;

COMMIT;

-- Каждый клуб и количество его ПК, включая клуб без ПК.
-- SELECT club.name, COUNT(pc.pc_id) AS pc_count
-- FROM clubs AS club
-- LEFT JOIN pcs AS pc ON pc.club_id = club.club_id
-- WHERE club.name LIKE 'Join Demo %'
-- GROUP BY club.club_id, club.name
-- ORDER BY club.name;

-- Клиенты без бронирований: LEFT JOIN и проверка отсутствующей пары.
-- SELECT client.full_name
-- FROM clients AS client
-- LEFT JOIN reservations AS reservation
--   ON reservation.client_id = client.client_id
-- WHERE client.phone LIKE '+3800000002%'
--   AND reservation.reservation_id IS NULL
-- ORDER BY client.full_name;

-- Брони и информация о платеже; неоплаченные брони имеют NULL в payment_id.
-- SELECT reservation.reservation_id, client.full_name, club.name AS club,
--        pc.seat_number, reservation.status, payment.amount, payment.payment_method
-- FROM reservations AS reservation
-- JOIN clients AS client ON client.client_id = reservation.client_id
-- JOIN pcs AS pc ON pc.pc_id = reservation.pc_id
-- JOIN clubs AS club ON club.club_id = pc.club_id
-- LEFT JOIN payments AS payment ON payment.reservation_id = reservation.reservation_id
-- WHERE client.phone LIKE '+3800000002%'
-- ORDER BY reservation.starts_at, reservation.reservation_id;

-- Для каждой брони показать ПК, тариф и клуб.
-- SELECT reservation.reservation_id, club.name AS club, pc.seat_number,
--        tariff.name AS tariff, tariff.price_per_hour
-- FROM reservations AS reservation
-- JOIN pcs AS pc ON pc.pc_id = reservation.pc_id
-- JOIN clubs AS club ON club.club_id = pc.club_id
-- JOIN tariffs AS tariff ON tariff.tariff_id = pc.tariff_id
-- WHERE club.name LIKE 'Join Demo %'
-- ORDER BY club.name, pc.seat_number, reservation.starts_at;
