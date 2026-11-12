-- Зразок скрипта генерації даних для заміру: лабораторна робота №3, крок 3.
--
-- Це приклад для схеми прокату велосипедів з лекцій 5-7, а не готовий скрипт роботи.
-- Виконувати його як є не потрібно: студент переписує його під власну схему
-- у файл lab-03/generate-data.sql - зі своїми таблицями, стовпцями і значеннями.
--
-- Як виконати переписаний скрипт: у pgAdmin відкрити Query Tool для бази заміру
-- dbsa_big, у якій виконано всі файли *.up.sql робіт №1 і 2, і виконати файл цілком.
-- Виконання займає близько секунди; повторний запуск завершиться помилкою
-- первинного ключа, бо ті самі рядки вже є.
--
-- Правила, за якими побудовано цей зразок:
--   * рядки будуються з номера n, який дає generate_series;
--   * спершу додаються таблиці, на які посилається таблиця подій;
--   * значення ключів не перетинаються зі скриптом наповнення роботи №2
--     (там номери B-12 - B-44 і К-114 - К-412 та події 2026 року, тут - інші діапазони);
--   * дані вигадані: справжніх прізвищ, телефонів і адрес немає.

-- Пункт і тариф, на які посилаються згенеровані рядки.
INSERT INTO stations (station_name, address, city)
VALUES ('Пункт №7', 'Липова, 3', 'Харків')
ON CONFLICT (station_name) DO NOTHING;

INSERT INTO tariffs (tariff_code, tariff_name, price)
VALUES ('Г1', 'Погодинний', 60)
ON CONFLICT (tariff_code) DO NOTHING;

-- 10 000 клієнтів: К-10001 - К-20000.
INSERT INTO customers (customer_number, last_name, phone, registration_date)
SELECT 'К-' || (10000 + n),
       'Клієнт ' || n,
       NULL,
       date '2025-01-01'
FROM generate_series(1, 10000) AS n;

-- 500 велосипедів: B-5001 - B-5500, усі на пункті №7.
INSERT INTO bikes (inventory_number, frame_number, model, purchase_date, condition_rating, station_name)
SELECT 'B-' || (5000 + n),
       'FR-' || (5000 + n),
       'City',
       date '2024-01-01',
       5,
       'Пункт №7'
FROM generate_series(1, 500) AS n;

-- 100 000 видач від 1 січня 2025 року з кроком 5 хвилин, по 10 видач на клієнта.
-- n % 500 по колу перебирає велосипеди, n % 10000 - клієнтів;
-- дата й час видачі в кожному рядку різні, тому складений первинний ключ не порушується.
INSERT INTO rentals (inventory_number, rented_at, returned_at,
                     customer_number, station_name, tariff_code, rental_price)
SELECT 'B-' || (5001 + n % 500),
       timestamp '2025-01-01 08:00' + n * interval '5 minutes',
       timestamp '2025-01-01 09:00' + n * interval '5 minutes',
       'К-' || (10001 + n % 10000),
       'Пункт №7',
       'Г1',
       60
FROM generate_series(1, 100000) AS n;
