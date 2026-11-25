-- Query 1. Rank PCs by number of reservations. Ties are intentional.
-- Expected: 6 rows; PC 1 has 3, PCs 2/4/5/6 have 2, PC 3 has 1.
SELECT pc_id,
       count(*) AS reservation_count,
       rank() OVER (ORDER BY count(*) DESC) AS rank_place,
       dense_rank() OVER (ORDER BY count(*) DESC) AS dense_rank_place,
       row_number() OVER (ORDER BY count(*) DESC, pc_id) AS row_number_place
FROM reservations
GROUP BY pc_id
ORDER BY rank_place, pc_id;

-- Query 2. Daily paid revenue in March and its running total.
-- Expected days/totals: Mar 1 200; Mar 2 500; Mar 3 1040; Mar 5 1240; Mar 15 1540.
SELECT daily.reservation_day,
       daily.paid_amount,
       sum(daily.paid_amount) OVER (
           ORDER BY daily.reservation_day
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_total
FROM (
    SELECT reservation.starts_at::date AS reservation_day,
           sum(payment.amount) AS paid_amount
    FROM reservations AS reservation
    JOIN payments AS payment
      ON payment.reservation_id = reservation.reservation_id
    WHERE reservation.starts_at >= TIMESTAMPTZ '2026-03-01 00:00:00+02'
      AND reservation.starts_at <  TIMESTAMPTZ '2026-04-01 00:00:00+02'
    GROUP BY reservation.starts_at::date
) AS daily
ORDER BY daily.reservation_day;

-- Query 3. Moving average over the last three event-days in March.
-- Expected counts: 2.00, 2.00, 1.67, 1.33, 1.00, 1.00, 1.00.
-- The third output row averages Mar 1, Mar 2, and Mar 3.
SELECT daily.reservation_day,
       daily.reservation_count,
       round(avg(daily.reservation_count) OVER (
           ORDER BY daily.reservation_day
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ), 2) AS moving_avg_last_three_event_days
FROM (
    SELECT starts_at::date AS reservation_day, count(*) AS reservation_count
    FROM reservations
    WHERE starts_at >= TIMESTAMPTZ '2026-03-01 00:00:00+02'
      AND starts_at <  TIMESTAMPTZ '2026-04-01 00:00:00+02'
    GROUP BY starts_at::date
) AS daily
ORDER BY daily.reservation_day;

-- Window versus GROUP BY: both return one row per March event-day (7 rows),
-- but the window result keeps each daily count next to its running calculation.
