-- Перевірка схеми бази даних: лабораторна робота №1.
--
-- Як виконати: у pgAdmin відкрити Query Tool для бази, де створено схему,
-- відкрити цей файл і виконати його цілком.
-- Результат - одна таблиця: для кожної таблиці схеми public спершу її стовпці
-- з типами й позначкою NOT NULL, потім обмеження PRIMARY KEY, UNIQUE,
-- FOREIGN KEY і CHECK з повним визначенням.
-- Рядок «УВАГА» зʼявляється, якщо таблиця не має первинного ключа.
-- Порожній результат означає, що в схемі public немає жодної таблиці.
--
-- Запит лише читає системний каталог і нічого не змінює в базі.
-- Розбирати його текст не потрібно: вибірку даних розглядають лекції 6-7.

WITH user_tables AS (
    SELECT cls.oid,
           cls.relname::text AS table_name
    FROM pg_catalog.pg_class AS cls
    JOIN pg_catalog.pg_namespace AS nsp ON nsp.oid = cls.relnamespace
    WHERE nsp.nspname = 'public'
      AND cls.relkind IN ('r', 'p')
),
report_rows AS (
    -- стовпці: тип, обовʼязковість, стовпець ідентичності
    SELECT t.table_name,
           1 AS section_order,
           att.attnum::integer AS item_order,
           'стовпець' AS kind,
           att.attname::text AS name,
           format_type(att.atttypid, att.atttypmod)
               || CASE WHEN att.attnotnull THEN ' NOT NULL' ELSE '' END
               || CASE WHEN att.attidentity <> '' THEN ' GENERATED AS IDENTITY' ELSE '' END AS definition
    FROM user_tables AS t
    JOIN pg_catalog.pg_attribute AS att ON att.attrelid = t.oid
    WHERE att.attnum > 0
      AND NOT att.attisdropped

    UNION ALL

    -- обмеження: первинний ключ, унікальність, зовнішні ключі, перевірки
    SELECT t.table_name,
           2,
           CASE con.contype WHEN 'p' THEN 1 WHEN 'u' THEN 2 WHEN 'f' THEN 3 ELSE 4 END,
           CASE con.contype
               WHEN 'p' THEN 'PRIMARY KEY'
               WHEN 'u' THEN 'UNIQUE'
               WHEN 'f' THEN 'FOREIGN KEY'
               ELSE 'CHECK'
           END,
           con.conname::text,
           pg_get_constraintdef(con.oid)
               || CASE WHEN con.contype = 'f' AND con.confdeltype = 'a'
                       THEN ' (ON DELETE не вказано: видалення заборонено)'
                       ELSE '' END
    FROM user_tables AS t
    JOIN pg_catalog.pg_constraint AS con ON con.conrelid = t.oid
    WHERE con.contype IN ('p', 'u', 'f', 'c')

    UNION ALL

    -- попередження: таблиця без первинного ключа
    SELECT t.table_name,
           0,
           0,
           'УВАГА',
           '',
           'таблиця не має первинного ключа'
    FROM user_tables AS t
    WHERE NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_constraint AS con
        WHERE con.conrelid = t.oid
          AND con.contype = 'p'
    )
)
SELECT table_name,
       kind,
       name,
       definition
FROM report_rows
ORDER BY table_name, section_order, item_order, name;
