-- Run against the database populated by lab-02/seed-data.sql.

-- Query 1. How many reservations are in each status?
-- Expected: 2 rows; active = 11, cancelled = 1.
SELECT status, count(*) AS reservation_count
FROM reservations
GROUP BY status
ORDER BY status;

-- Query 2. Which clubs earned more than 250 from paid March reservations?
-- Expected: 2 rows; Center = 1040.00 (5 reservations), Campus = 300.00 (1).
SELECT club.name,
       count(reservation.reservation_id) AS reservation_count,
       coalesce(sum(payment.amount), 0) AS paid_amount
FROM reservations AS reservation
JOIN pcs AS pc ON pc.pc_id = reservation.pc_id
JOIN clubs AS club ON club.club_id = pc.club_id
LEFT JOIN payments AS payment ON payment.reservation_id = reservation.reservation_id
WHERE reservation.starts_at >= TIMESTAMPTZ '2026-03-01 00:00:00+02'
  AND reservation.starts_at <  TIMESTAMPTZ '2026-04-01 00:00:00+02'
GROUP BY club.club_id, club.name
HAVING coalesce(sum(payment.amount), 0) > 250
ORDER BY paid_amount DESC;

-- Query 3. How many active reservations and payments does each PC have?
-- Expected: 6 rows; PC 1 = 3/1, PC 2 = 1/1, PC 3 = 1/1,
-- PC 4 = 2/2, PC 5 = 2/0, PC 6 = 2/2.
SELECT pc.pc_id,
       count(CASE WHEN reservation.status = 'active' THEN 1 END) AS active_reservations,
       count(CASE WHEN payment.payment_id IS NOT NULL THEN 1 END) AS paid_reservations
FROM pcs AS pc
LEFT JOIN reservations AS reservation ON reservation.pc_id = pc.pc_id
LEFT JOIN payments AS payment ON payment.reservation_id = reservation.reservation_id
GROUP BY pc.pc_id
ORDER BY pc.pc_id;

-- Query 4. How many payments exceed the average payment?
-- Expected: 1 row; 4 payments exceed the average 277.14.
SELECT count(*) AS payments_above_average
FROM payments
WHERE amount > (SELECT avg(amount) FROM payments);

-- Query 5. What is the average number of reservations per day that had reservations?
-- Expected: 1 row; 1.20 reservations per event day (12 reservations on 10 days).
SELECT round(avg(daily.reservation_count), 2) AS average_per_event_day
FROM (
    SELECT starts_at::date AS reservation_day, count(*) AS reservation_count
    FROM reservations
    GROUP BY starts_at::date
) AS daily;

-- Query 6. How many reservations belong to every club, including an empty club?
-- Expected: 4 rows; Center = 6, Riverside = 4, Campus = 2, Empty = 0.
SELECT club.name, count(reservation.reservation_id) AS reservation_count
FROM clubs AS club
LEFT JOIN pcs AS pc ON pc.club_id = club.club_id
LEFT JOIN reservations AS reservation ON reservation.pc_id = pc.pc_id
GROUP BY club.club_id, club.name
ORDER BY reservation_count DESC, club.name;
