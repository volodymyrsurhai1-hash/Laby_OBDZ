-- Перелік активних ПК, вільних у заданий проміжок.
-- Межі [) дозволяють почати наступне бронювання одразу після завершення попереднього.
WITH requested AS (
    SELECT tstzrange(
        '2030-01-10 18:00+00'::timestamptz,
        '2030-01-10 20:00+00'::timestamptz,
        '[)'
    ) AS slot
)
SELECT pc.pc_id,
       t.name AS tariff_name
FROM pcs AS pc
JOIN tariffs AS t ON t.tariff_id = pc.tariff_id
CROSS JOIN requested
WHERE pc.is_active
  AND NOT EXISTS (
      SELECT 1
      FROM reservations AS r
      WHERE r.pc_id = pc.pc_id
        AND r.status = 'active'
        AND tstzrange(r.starts_at, r.ends_at, '[)') && requested.slot
  )
ORDER BY pc.pc_id;
