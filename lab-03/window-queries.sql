-- Нумерація бронювань за часом.
SELECT reservation_id,
       starts_at,
       row_number() OVER (ORDER BY starts_at, reservation_id) AS booking_number
FROM reservations
ORDER BY starts_at, reservation_id;
