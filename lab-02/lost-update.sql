-- Виконуйте команди по одній у двох вікнах Query Tool (сеанси A та B).
-- До кожного досліду поверніть Club Rate до 250 однією командою UPDATE.

-- Дослід 1. READ COMMITTED: обидва сеанси записують число, обчислене зі старого 250.
-- Має бути: 250 - 10% + 30 = 255. Фактично буде 280.
-- Крок 1. Сеанс A
BEGIN;
SELECT price_per_hour FROM tariffs WHERE name = 'Club Rate'; -- 250
-- Крок 2. Сеанс B
BEGIN;
SELECT price_per_hour FROM tariffs WHERE name = 'Club Rate'; -- 250
-- Крок 3. Сеанс A
UPDATE tariffs SET price_per_hour = 225 WHERE name = 'Club Rate';
-- Крок 4. Сеанс B: блокується, бо сеанс A ще не завершив транзакцію.
UPDATE tariffs SET price_per_hour = 280 WHERE name = 'Club Rate';
-- Крок 5. Сеанс A
COMMIT;
-- UPDATE 1 у сеансі B тепер завершується.
-- Крок 6. Сеанс B
COMMIT;
SELECT price_per_hour FROM tariffs WHERE name = 'Club Rate'; -- 280 замість 255

-- Дослід 2. REPEATABLE READ: конфлікт виявляється, транзакцію B треба повторити.
-- Перед дослідом: UPDATE tariffs SET price_per_hour = 250 WHERE name = 'Club Rate';
-- Крок 1. Сеанс A
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT price_per_hour FROM tariffs WHERE name = 'Club Rate'; -- 250
-- Крок 2. Сеанс B
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT price_per_hour FROM tariffs WHERE name = 'Club Rate'; -- 250
-- Крок 3. Сеанс A
UPDATE tariffs SET price_per_hour = 225 WHERE name = 'Club Rate';
-- Крок 4. Сеанс B: блокується.
UPDATE tariffs SET price_per_hour = 280 WHERE name = 'Club Rate';
-- Крок 5. Сеанс A
COMMIT;
-- У сеансі B очікується could not serialize access due to concurrent update.
-- Крок 6. Сеанс B
ROLLBACK;
-- Повтор транзакції B з нового значення 225:
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT price_per_hour FROM tariffs WHERE name = 'Club Rate'; -- 225
UPDATE tariffs SET price_per_hour = 255 WHERE name = 'Club Rate';
COMMIT;
SELECT price_per_hour FROM tariffs WHERE name = 'Club Rate'; -- 255

-- Дослід 3. READ COMMITTED: UPDATE рахує від поточного значення після зняття блокування.
-- Перед дослідом: UPDATE tariffs SET price_per_hour = 250 WHERE name = 'Club Rate';
-- Крок 1. Сеанс A
BEGIN;
-- Крок 2. Сеанс B
BEGIN;
-- Крок 3. Сеанс A
UPDATE tariffs
SET price_per_hour = price_per_hour * 0.9
WHERE name = 'Club Rate';
-- Крок 4. Сеанс B: блокується до COMMIT сеансу A.
UPDATE tariffs
SET price_per_hour = price_per_hour + 30
WHERE name = 'Club Rate';
-- Крок 5. Сеанс A
COMMIT;
-- UPDATE 1 у B додає 30 до вже змінених 225.
-- Крок 6. Сеанс B
COMMIT;
SELECT price_per_hour FROM tariffs WHERE name = 'Club Rate'; -- 255
