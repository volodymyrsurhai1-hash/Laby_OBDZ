-- Виконуйте кожну команду INSERT окремо в DBeaver у базі з виконаною міграцією.
-- Кожен INSERT порушує одне обмеження і має бути відхилений повністю.

-- Правило: імʼя клієнта обовʼязкове (NOT NULL).
-- Очікувано: null value in column "full_name" of relation "clients" violates not-null constraint
INSERT INTO clients (full_name, phone)
VALUES (NULL, '+380000000091');

-- Правило: номер телефону клієнта унікальний (UNIQUE).
-- Очікувано: duplicate key value violates unique constraint "clients_phone_key"
INSERT INTO clients (full_name, phone)
VALUES
    ('Тестовий клієнт 1', '+380000000092'),
    ('Тестовий клієнт 2', '+380000000092');

-- Правило: ціна тарифу не може бути відʼємною (CHECK).
-- Очікувано: new row for relation "tariffs" violates check constraint "tariffs_price_per_hour_check"
INSERT INTO tariffs (name, price_per_hour)
VALUES ('lab-negative-price', -1);

-- Правило: ідентифікатор тарифу є первинним ключем (PRIMARY KEY).
-- OVERRIDING SYSTEM VALUE дозволяє явно подати тестовий ID для GENERATED ALWAYS.
-- Очікувано: duplicate key value violates unique constraint "tariffs_pkey"
INSERT INTO tariffs (tariff_id, name, price_per_hour)
OVERRIDING SYSTEM VALUE
VALUES
    (999999, 'lab-primary-key-1', 1),
    (999999, 'lab-primary-key-2', 1);

-- Правило: платіж має посилатися на наявне бронювання (REFERENCES).
-- Очікувано: insert or update on table "payments" violates foreign key constraint "payments_reservation_id_fkey"
INSERT INTO payments (reservation_id, amount, payment_method)
VALUES (-1, 1, 'cash');
