-- Ідемпотентне демонстраційне наповнення: клуб, тариф, два ПК,
-- два клієнти, два бронювання та оплати за них.

BEGIN;

INSERT INTO clubs (name, address)
SELECT 'Demo Club', '1 Example Street'
WHERE NOT EXISTS (
    SELECT 1
    FROM clubs
    WHERE name = 'Demo Club'
      AND address = '1 Example Street'
);

INSERT INTO tariffs (name, price_per_hour)
VALUES ('Demo Tariff', 200)
ON CONFLICT (name) DO NOTHING;

INSERT INTO clients (full_name, phone)
VALUES
    ('Demo Customer 1', '+380000000091'),
    ('Demo Customer 2', '+380000000092')
ON CONFLICT (phone) DO NOTHING;

INSERT INTO pcs (club_id, seat_number, tariff_id)
SELECT club.club_id, seat.seat_number, tariff.tariff_id
FROM clubs AS club
CROSS JOIN tariffs AS tariff
CROSS JOIN (VALUES (1), (2)) AS seat(seat_number)
WHERE club.name = 'Demo Club'
  AND club.address = '1 Example Street'
  AND tariff.name = 'Demo Tariff'
ON CONFLICT (club_id, seat_number) DO NOTHING;

INSERT INTO reservations (client_id, pc_id, starts_at, ends_at, status)
SELECT client.client_id,
       pc.pc_id,
       TIMESTAMPTZ '2030-01-10 18:00:00+02',
       TIMESTAMPTZ '2030-01-10 21:00:00+02',
       'active'
FROM clients AS client
JOIN pcs AS pc
  ON pc.seat_number = CASE client.phone
      WHEN '+380000000091' THEN 1
      WHEN '+380000000092' THEN 2
  END
JOIN clubs AS club
  ON club.club_id = pc.club_id
WHERE client.phone IN ('+380000000091', '+380000000092')
  AND club.name = 'Demo Club'
  AND club.address = '1 Example Street'
  AND NOT EXISTS (
      SELECT 1
      FROM reservations AS existing
      WHERE existing.client_id = client.client_id
        AND existing.pc_id = pc.pc_id
  );

INSERT INTO payments (reservation_id, amount, payment_method)
SELECT reservation.reservation_id,
       tariff.price_per_hour
           * EXTRACT(EPOCH FROM (reservation.ends_at - reservation.starts_at)) / 3600,
       'card'
FROM reservations AS reservation
JOIN clients AS client
  ON client.client_id = reservation.client_id
JOIN pcs AS pc
  ON pc.pc_id = reservation.pc_id
JOIN clubs AS club
  ON club.club_id = pc.club_id
JOIN tariffs AS tariff
  ON tariff.tariff_id = pc.tariff_id
WHERE client.phone IN ('+380000000091', '+380000000092')
  AND club.name = 'Demo Club'
  AND club.address = '1 Example Street'
  AND NOT EXISTS (
      SELECT 1
      FROM payments AS existing
      WHERE existing.reservation_id = reservation.reservation_id
  )
ON CONFLICT (reservation_id) DO NOTHING;

COMMIT;

SELECT client.full_name,
       pc.seat_number,
       reservation.reservation_id,
       tariff.price_per_hour,
       payment.amount,
       payment.payment_method,
       payment.paid_at
FROM reservations AS reservation
JOIN clients AS client
  ON client.client_id = reservation.client_id
JOIN pcs AS pc
  ON pc.pc_id = reservation.pc_id
JOIN clubs AS club
  ON club.club_id = pc.club_id
JOIN tariffs AS tariff
  ON tariff.tariff_id = pc.tariff_id
LEFT JOIN payments AS payment
  ON payment.reservation_id = reservation.reservation_id
WHERE client.phone IN ('+380000000091', '+380000000092')
  AND club.name = 'Demo Club'
  AND club.address = '1 Example Street'
ORDER BY pc.seat_number;
