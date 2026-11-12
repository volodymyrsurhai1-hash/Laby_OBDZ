-- Запити виконувати окремо після lab-02/seed-data.sql.

-- Запит 1. Які клієнти з бронюваннями й оплатами мають ім'я на A?
-- Рядків: 2.
SELECT DISTINCT client.client_id, client.full_name, client.phone
FROM clients AS client
JOIN reservations AS reservation
  ON reservation.client_id = client.client_id
LEFT JOIN payments AS payment
  ON payment.reservation_id = reservation.reservation_id
WHERE client.full_name LIKE 'A%'
  AND payment.payment_id IS NOT NULL
ORDER BY client.full_name, client.client_id
LIMIT 2;

-- Запит 2. Які бронювання не оплачені онлайн?
-- Неоплачені бронювання не проходять умову через UNKNOWN. Рядків: 5.
SELECT reservation.reservation_id, payment.payment_method
FROM reservations AS reservation
LEFT JOIN payments AS payment
  ON payment.reservation_id = reservation.reservation_id
WHERE payment.payment_method NOT LIKE 'online'
ORDER BY reservation.reservation_id;

-- Виправлений запит 2: включити бронювання без оплати.
-- Рядків: 10.
SELECT reservation.reservation_id, payment.payment_method
FROM reservations AS reservation
LEFT JOIN payments AS payment
  ON payment.reservation_id = reservation.reservation_id
WHERE payment.payment_method IS NULL
   OR payment.payment_method NOT LIKE 'online'
ORDER BY reservation.reservation_id;

-- Запит 3. Які тарифи коштують від 100 до 180 за годину включно?
-- Рядків: 3.
SELECT tariff_id, name, price_per_hour
FROM tariffs
WHERE price_per_hour BETWEEN 100 AND 180
ORDER BY price_per_hour, tariff_id
LIMIT 3;

-- Запит 4. Які активні бронювання почалися у березні 2026 року?
-- Межі часу задані напівінтервалом. Рядків: 8.
SELECT reservation_id, client_id, pc_id, starts_at, ends_at
FROM reservations
WHERE status IN ('active')
  AND starts_at >= TIMESTAMPTZ '2026-03-01 00:00:00+02'
  AND starts_at < TIMESTAMPTZ '2026-04-01 00:00:00+02'
ORDER BY starts_at, reservation_id;

-- Запит 5. Які оплати внесено готівкою або карткою?
-- Після сортування і LIMIT: 4 рядки.
SELECT payment_id, reservation_id, amount, payment_method
FROM payments
WHERE payment_method IN ('cash', 'card')
ORDER BY amount DESC, payment_id
LIMIT 4;

-- Запит 6. Які бронювання без оплати або скасовані належать клієнтам
-- із телефоном заданого префікса? Дужки задають порядок OR перед AND.
-- Рядків: 5.
SELECT reservation.reservation_id, client.full_name, payment.payment_method
FROM reservations AS reservation
JOIN clients AS client
  ON client.client_id = reservation.client_id
LEFT JOIN payments AS payment
  ON payment.reservation_id = reservation.reservation_id
WHERE (payment.payment_id IS NULL OR reservation.status = 'cancelled')
  AND client.phone LIKE '+38000000030%'
ORDER BY reservation.reservation_id
LIMIT 5;

-- З'єднання 1. Які бронювання належать яким клієнтам?
-- INNER JOIN: 12 рядків; кожне бронювання має рівно одного клієнта.
SELECT reservation.reservation_id, reservation.starts_at,
       client.client_id, client.full_name
FROM reservations AS reservation
JOIN clients AS client
  ON client.client_id = reservation.client_id
ORDER BY reservation.starts_at, reservation.reservation_id;

-- З'єднання 2. Відновити стовпці «поганої» таблиці з роботи №1.
-- Рядків: 12 — по одному на бронювання; оплата може бути відсутня.
SELECT reservation.reservation_id,
       reservation.client_id,
       client.full_name,
       client.phone,
       pc.pc_id,
       club.club_id,
       club.name AS club_name,
       club.address,
       pc.seat_number,
       tariff.tariff_id,
       tariff.name AS tariff_name,
       tariff.price_per_hour AS current_price,
       reservation.starts_at,
       reservation.ends_at,
       payment.payment_id,
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
ORDER BY reservation.starts_at, reservation.reservation_id;

-- З'єднання 3. Які клієнти ще не мають бронювань?
-- LEFT JOIN лишає клієнта без пари; рядків: 1.
SELECT client.client_id, client.full_name
FROM clients AS client
LEFT JOIN reservations AS reservation
  ON reservation.client_id = client.client_id
WHERE reservation.reservation_id IS NULL
ORDER BY client.client_id;
