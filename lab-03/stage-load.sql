-- Part 1: reject missing required values and invalid input before casting.
INSERT INTO stage_rejects (source_row, reject_reason)
SELECT source_row,
       CASE
           WHEN nullif(btrim(reservation_id_raw), '') IS NULL THEN 'reservation_id is missing'
           WHEN nullif(btrim(client_id_raw), '') IS NULL THEN 'client_id is missing'
           WHEN nullif(btrim(pc_id_raw), '') IS NULL THEN 'pc_id is missing'
           WHEN nullif(btrim(club_id_raw), '') IS NULL THEN 'club_id is missing'
           WHEN NOT pg_input_is_valid(reservation_id_raw, 'integer') THEN 'reservation_id is not an integer'
           WHEN NOT pg_input_is_valid(client_id_raw, 'integer') THEN 'client_id is not an integer'
           WHEN NOT pg_input_is_valid(pc_id_raw, 'integer') THEN 'pc_id is not an integer'
           WHEN NOT pg_input_is_valid(club_id_raw, 'integer') THEN 'club_id is not an integer'
           WHEN NOT pg_input_is_valid(starts_at_raw, 'timestamp with time zone') THEN 'starts_at is not a valid timestamp'
           WHEN NOT pg_input_is_valid(ends_at_raw, 'timestamp with time zone') THEN 'ends_at is not a valid timestamp'
           WHEN nullif(btrim(paid_amount_raw), '') IS NOT NULL
                AND NOT pg_input_is_valid(paid_amount_raw, 'numeric') THEN 'paid_amount is not numeric'
       END
FROM stage_reservations
WHERE nullif(btrim(reservation_id_raw), '') IS NULL
   OR nullif(btrim(client_id_raw), '') IS NULL
   OR nullif(btrim(pc_id_raw), '') IS NULL
   OR nullif(btrim(club_id_raw), '') IS NULL
   OR NOT pg_input_is_valid(reservation_id_raw, 'integer')
   OR NOT pg_input_is_valid(client_id_raw, 'integer')
   OR NOT pg_input_is_valid(pc_id_raw, 'integer')
   OR NOT pg_input_is_valid(club_id_raw, 'integer')
   OR NOT pg_input_is_valid(starts_at_raw, 'timestamp with time zone')
   OR NOT pg_input_is_valid(ends_at_raw, 'timestamp with time zone')
   OR (
       nullif(btrim(paid_amount_raw), '') IS NOT NULL
       AND NOT pg_input_is_valid(paid_amount_raw, 'numeric')
   )
ON CONFLICT (source_row) DO NOTHING;

-- Convert only rows that passed the input checks.
CREATE TEMP TABLE converted_stage_reservations ON COMMIT PRESERVE ROWS AS
SELECT stage.source_row,
       stage.reservation_id_raw::integer AS reservation_id,
       stage.client_id_raw::integer AS client_id,
       stage.pc_id_raw::integer AS pc_id,
       stage.club_id_raw::integer AS club_id,
       stage.starts_at_raw::timestamptz AS starts_at,
       stage.ends_at_raw::timestamptz AS ends_at,
       stage.status_raw AS status,
       nullif(btrim(stage.paid_amount_raw), '')::numeric AS paid_amount
FROM stage_reservations AS stage
LEFT JOIN stage_rejects AS rejected USING (source_row)
WHERE rejected.source_row IS NULL;

-- Part 2: reject contradictions after values have real types.
INSERT INTO stage_rejects (source_row, reject_reason)
SELECT source_row,
       CASE
           WHEN ends_at <= starts_at THEN 'ends_at must be later than starts_at'
           ELSE 'status must be active or cancelled'
       END
FROM converted_stage_reservations
WHERE ends_at <= starts_at
   OR status NOT IN ('active', 'cancelled')
ON CONFLICT (source_row) DO NOTHING;

-- DISTINCT removes the repeated event; the natural reservation ID is the fact key.
INSERT INTO fact_reservations (
    reservation_id, club_key, date_key, reservation_hours, paid_amount, status
)
SELECT DISTINCT converted.reservation_id,
       club.club_key,
       converted.starts_at::date,
       round(extract(epoch FROM (converted.ends_at - converted.starts_at)) / 3600, 2),
       coalesce(converted.paid_amount, 0),
       converted.status
FROM converted_stage_reservations AS converted
JOIN dim_clubs AS club ON club.club_id = converted.club_id
LEFT JOIN stage_rejects AS rejected USING (source_row)
WHERE rejected.source_row IS NULL
  AND converted.ends_at > converted.starts_at
  AND converted.status IN ('active', 'cancelled')
ON CONFLICT (reservation_id) DO UPDATE
SET club_key = EXCLUDED.club_key,
    date_key = EXCLUDED.date_key,
    reservation_hours = EXCLUDED.reservation_hours,
    paid_amount = EXCLUDED.paid_amount,
    status = EXCLUDED.status;
