-- Операція: створити бронювання та внести оплату в одній транзакції.
-- Значення client_id = 8 і pc_id = 6 відповідають seed-data.sql у порожній БД.
-- Для повторного запуску використовуються нові явні ID після seed-рядків.

-- Частина 1. COMMIT: бронювання й оплата зберігаються разом.
BEGIN;
INSERT INTO reservations (reservation_id, client_id, pc_id, starts_at, ends_at, status)
OVERRIDING SYSTEM VALUE
VALUES (13, 8, 6, TIMESTAMPTZ '2032-05-01 10:00:00+02',
        TIMESTAMPTZ '2032-05-01 12:00:00+02', 'active')
ON CONFLICT (reservation_id) DO NOTHING;

INSERT INTO payments (reservation_id, amount, payment_method)
SELECT reservation_id, 300, 'card'
FROM reservations
WHERE client_id = 8
  AND pc_id = 6
  AND starts_at = TIMESTAMPTZ '2032-05-01 10:00:00+02'
ON CONFLICT (reservation_id) DO NOTHING;
COMMIT;

SELECT setval(pg_get_serial_sequence('reservations', 'reservation_id'), (SELECT MAX(reservation_id) FROM reservations));

SELECT reservation.reservation_id, client.full_name,
       payment.amount, payment.payment_method
FROM reservations AS reservation
JOIN clients AS client
  ON client.client_id = reservation.client_id
JOIN payments AS payment
  ON payment.reservation_id = reservation.reservation_id
WHERE reservation.client_id = 8
  AND reservation.pc_id = 6
  AND reservation.starts_at = TIMESTAMPTZ '2032-05-01 10:00:00+02';

-- Частина 2. ROLLBACK: в іншому часовому слоті обидва рядки скасовуються.
BEGIN;
INSERT INTO reservations (reservation_id, client_id, pc_id, starts_at, ends_at, status)
OVERRIDING SYSTEM VALUE
VALUES (14, 8, 6, TIMESTAMPTZ '2032-05-02 10:00:00+02',
        TIMESTAMPTZ '2032-05-02 12:00:00+02', 'active')
ON CONFLICT (reservation_id) DO NOTHING;

INSERT INTO payments (reservation_id, amount, payment_method)
SELECT reservation_id, 300, 'cash'
FROM reservations
WHERE client_id = 8
  AND pc_id = 6
  AND starts_at = TIMESTAMPTZ '2032-05-02 10:00:00+02'
ON CONFLICT (reservation_id) DO NOTHING;

SELECT reservation.reservation_id, payment.payment_id
FROM reservations AS reservation
JOIN payments AS payment
  ON payment.reservation_id = reservation.reservation_id
WHERE reservation.client_id = 8
  AND reservation.pc_id = 6
  AND reservation.starts_at = TIMESTAMPTZ '2032-05-02 10:00:00+02';
ROLLBACK;

SELECT reservation_id
FROM reservations
WHERE client_id = 8
  AND pc_id = 6
  AND starts_at = TIMESTAMPTZ '2032-05-02 10:00:00+02';

-- Частина 3. Помилка після першої зміни відкочує і бронювання, і оплату.
BEGIN;
INSERT INTO reservations (reservation_id, client_id, pc_id, starts_at, ends_at, status)
OVERRIDING SYSTEM VALUE
VALUES (15, 8, 6, TIMESTAMPTZ '2032-05-03 10:00:00+02',
        TIMESTAMPTZ '2032-05-03 12:00:00+02', 'active')
ON CONFLICT (reservation_id) DO NOTHING;

INSERT INTO payments (reservation_id, amount, payment_method)
SELECT reservation_id, 300, 'wire'
FROM reservations
WHERE client_id = 8
  AND pc_id = 6
  AND starts_at = TIMESTAMPTZ '2032-05-03 10:00:00+02';
-- Очікується помилка CHECK payment_method; наступний SELECT буде відхилено.
SELECT reservation_id
FROM reservations
WHERE client_id = 8
  AND pc_id = 6
  AND starts_at = TIMESTAMPTZ '2032-05-03 10:00:00+02';
COMMIT;
-- Після помилки COMMIT завершує транзакцію повідомленням ROLLBACK.
SELECT reservation_id
FROM reservations
WHERE client_id = 8
  AND pc_id = 6
  AND starts_at = TIMESTAMPTZ '2032-05-03 10:00:00+02';
