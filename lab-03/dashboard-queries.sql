-- Card: total paid revenue in March 2026.
SELECT date.month_label, coalesce(sum(fact.paid_amount), 0) AS revenue
FROM fact_reservations AS fact
JOIN dim_dates AS date ON date.date_key = fact.date_key
WHERE date.month_label = '2026-03'
GROUP BY date.month_label
ORDER BY date.month_label;

-- Bar chart: reservations per club, including clubs with no reservations.
SELECT club.name, count(fact.reservation_id) AS reservation_count
FROM dim_clubs AS club
LEFT JOIN fact_reservations AS fact ON fact.club_key = club.club_key
GROUP BY club.club_key, club.name
ORDER BY reservation_count DESC, club.name;

-- Time series: daily paid revenue.
SELECT date.date_key, coalesce(sum(fact.paid_amount), 0) AS revenue
FROM dim_dates AS date
LEFT JOIN fact_reservations AS fact ON fact.date_key = date.date_key
WHERE date.month_label = '2026-03'
GROUP BY date.date_key
ORDER BY date.date_key;
