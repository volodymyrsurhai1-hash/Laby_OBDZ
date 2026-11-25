SELECT 'clients' AS table_name, count(*) AS row_count FROM clients
UNION ALL
SELECT 'clubs', count(*) FROM clubs
UNION ALL
SELECT 'payments', count(*) FROM payments
UNION ALL
SELECT 'pcs', count(*) FROM pcs
UNION ALL
SELECT 'reservations', count(*) FROM reservations
UNION ALL
SELECT 'tariffs', count(*) FROM tariffs
ORDER BY table_name;
