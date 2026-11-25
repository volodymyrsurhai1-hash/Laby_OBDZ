-- Run only once in the isolated dbsa_big database after schema and seed-data.sql.
-- Generates 10,000 clients and 100,000 reservations without overlapping
-- intervals on a PC. Recreate dbsa_big before repeating this script.

INSERT INTO clients (full_name, phone)
SELECT 'Generated Client ' || n,
       '+380999' || lpad(n::text, 6, '0')
FROM generate_series(1, 10000) AS n;

INSERT INTO reservations (client_id, pc_id, starts_at, ends_at, status)
SELECT 9 + (n % 10000),
       1 + (n % 6),
       TIMESTAMPTZ '2025-01-01 08:00:00+00' + n * INTERVAL '5 minutes',
       TIMESTAMPTZ '2025-01-01 08:20:00+00' + n * INTERVAL '5 minutes',
       'active'
FROM generate_series(1, 100000) AS n;

ANALYZE reservations;
