-- 1. Load/update the club dimension before facts that reference it.
INSERT INTO dim_clubs (club_id, name, address, is_active)
SELECT club_id, name, address, is_active
FROM clubs
ON CONFLICT (club_id) DO UPDATE
SET name = EXCLUDED.name,
    address = EXCLUDED.address,
    is_active = EXCLUDED.is_active;

-- 2. Create one date row for every date in the source event period.
INSERT INTO dim_dates (date_key, year_number, month_label, day_of_week, is_weekend)
SELECT calendar_day::date,
       extract(year FROM calendar_day)::integer,
       to_char(calendar_day, 'YYYY-MM'),
       extract(isodow FROM calendar_day)::integer,
       extract(isodow FROM calendar_day) >= 6
FROM generate_series(
    (SELECT min(starts_at)::date FROM reservations)::timestamp,
    (SELECT max(starts_at)::date FROM reservations)::timestamp,
    INTERVAL '1 day'
) AS calendar_day
ON CONFLICT (date_key) DO NOTHING;

-- 3. Load one fact per reservation; payment absence means zero paid revenue.
INSERT INTO fact_reservations (
    reservation_id, club_key, date_key, reservation_hours, paid_amount, status
)
SELECT reservation.reservation_id,
       club.club_key,
       reservation.starts_at::date,
       round(extract(epoch FROM (reservation.ends_at - reservation.starts_at)) / 3600, 2),
       coalesce(payment.amount, 0),
       reservation.status
FROM reservations AS reservation
JOIN pcs AS pc ON pc.pc_id = reservation.pc_id
JOIN dim_clubs AS club ON club.club_id = pc.club_id
LEFT JOIN payments AS payment
  ON payment.reservation_id = reservation.reservation_id
ON CONFLICT (reservation_id) DO UPDATE
SET club_key = EXCLUDED.club_key,
    date_key = EXCLUDED.date_key,
    reservation_hours = EXCLUDED.reservation_hours,
    paid_amount = EXCLUDED.paid_amount,
    status = EXCLUDED.status;
