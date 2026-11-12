-- Розмір таблиць та індексів: лабораторна робота №3.
--
-- Як виконати: у pgAdmin відкрити Query Tool для бази, яку потрібно перевірити
-- (у роботі №3 - для бази заміру dbsa_big), відкрити цей файл і виконати його цілком.
-- Результат - одна таблиця: для кожної таблиці й кожного індексу схеми public
-- його назва, вид, розмір у зрозумілому вигляді і розмір у байтах.
-- Порожній результат означає, що в схемі public немає жодної таблиці.
--
-- Скрипт показує першу складову ціни індексу - зайняте місце. Друга складова,
-- сповільнення команд INSERT, UPDATE і DELETE, у роботі не вимірюється.
--
-- Запит лише читає системний каталог і нічого не змінює в базі.
-- Розбирати його текст не потрібно.

SELECT cls.relname::text AS object_name,
       CASE cls.relkind
           WHEN 'r' THEN 'таблиця'
           WHEN 'i' THEN 'індекс'
           ELSE cls.relkind::text
       END AS object_kind,
       pg_size_pretty(pg_relation_size(cls.oid)) AS size_pretty,
       pg_relation_size(cls.oid) AS size_bytes
FROM pg_catalog.pg_class AS cls
JOIN pg_catalog.pg_namespace AS nsp ON nsp.oid = cls.relnamespace
WHERE nsp.nspname = 'public'
  AND cls.relkind IN ('r', 'i')
ORDER BY pg_relation_size(cls.oid) DESC, cls.relname;
