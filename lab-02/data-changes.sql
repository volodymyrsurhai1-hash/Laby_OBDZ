-- Демонстрації виконуйте по черзі. Перед кожною зміною SELECT використовує
-- ту саму умову WHERE, що й відповідний UPDATE або DELETE.

-- Зміна 1. Закрити клуб без комп'ютерних місць після перевірки.
BEGIN;
SELECT club_id, name, is_active
FROM clubs
WHERE name LIKE 'Cyber Club Empty%';

UPDATE clubs
SET is_active = false
WHERE name LIKE 'Cyber Club Empty%';

SELECT club_id, name, is_active
FROM clubs
WHERE name LIKE 'Cyber Club Empty%';
COMMIT;

-- Зміна 2. Тимчасово вимкнути місця 1 і 2 центрального клубу.
-- Результат перевірки очікується лише в цій транзакції, тому виконуємо ROLLBACK.
BEGIN;
SELECT pc_id, seat_number, is_active
FROM pcs
WHERE club_id = (SELECT club_id FROM clubs WHERE name = 'Cyber Club Center')
  AND seat_number BETWEEN 1 AND 2;

UPDATE pcs
SET is_active = false
WHERE club_id = (SELECT club_id FROM clubs WHERE name = 'Cyber Club Center')
  AND seat_number BETWEEN 1 AND 2;

SELECT pc_id, seat_number, is_active
FROM pcs
WHERE club_id = (SELECT club_id FROM clubs WHERE name = 'Cyber Club Center')
  AND seat_number BETWEEN 1 AND 2;
ROLLBACK;

SELECT pc_id, seat_number, is_active
FROM pcs
WHERE club_id = (SELECT club_id FROM clubs WHERE name = 'Cyber Club Center')
  AND seat_number BETWEEN 1 AND 2;

-- Видалення 1. Видалити клієнта без бронювань; скасувати демонстраційну зміну.
BEGIN;
SELECT client.client_id, client.full_name
FROM clients AS client
WHERE client.phone = '+380000000401'
  AND NOT EXISTS (
      SELECT 1
      FROM reservations AS reservation
      WHERE reservation.client_id = client.client_id
  );

DELETE FROM clients AS client
WHERE client.phone = '+380000000401'
  AND NOT EXISTS (
      SELECT 1
      FROM reservations AS reservation
      WHERE reservation.client_id = client.client_id
  );

SELECT client_id, full_name
FROM clients
WHERE phone = '+380000000401';
ROLLBACK;

-- Реакція RESTRICT. Клієнта з бронюваннями видалити не можна.
BEGIN;
SELECT client_id, full_name
FROM clients
WHERE phone = '+380000000301';

DELETE FROM clients
WHERE phone = '+380000000301';
-- Очікується foreign key violation від reservations_client_id_fkey.
ROLLBACK;
