// Зразок скрипта створення графа знань і запитів Cypher
// до лабораторної роботи №5 курсу «Організація баз даних і знань».
// Демонстраційна область - мережа прокату велосипедів (кроки 7-8 методичних вказівок).
//
// Файл показує оформлення команд, а не готову відповідь: мітки, властивості й значення
// замінюються на власну предметну область, після чого команди виконують у Neo4j Browser.
// Виконання цього файлу без переписування створює в графі чужі дані.
//
// Як виконувати: відкрити http://localhost:7474, підключитися (neo4j / studentpass)
// і скопіювати потрібний блок у рядок команд. Якщо Browser відмовляється виконати
// кілька команд поспіль, їх виконують по черзі.
//
// Правила запису: мітка - з великої літери в однині (Station), тип звʼязку -
// великими літерами через підкреслення (NEIGHBOUR_OF), властивість - малими
// літерами через підкреслення (station_name). Значення можуть бути українською.


// --- Крок 7. Створення графа на MERGE ---------------------------------------
// Лише MERGE, жодного CREATE: повторний запуск скрипта граф не подвоює -
// той самий прийом, що INSERT ... ON CONFLICT DO NOTHING у роботі №2.
// MERGE упізнає вершину за всім набором властивостей, перелічених у дужках,
// тому набір у вже виконаному скрипті не змінюють - як не редагують
// закомічений файл міграції.

// Пункти прокату.
MERGE (:Station {station_name: 'Пункт №2', address: 'Наукова, 14'});
MERGE (:Station {station_name: 'Пункт №4', address: 'Садова, 1'});
MERGE (:Station {station_name: 'Пункт №7', address: 'Гагаріна, 3'});
MERGE (:Station {station_name: 'Пункт №9', address: 'Полтавський Шлях, 20'});

// Тарифи.
MERGE (:Tariff {tariff_code: 'Г1', tariff_name: 'Погодинний'});
MERGE (:Tariff {tariff_code: 'Д1', tariff_name: 'Денний'});

// Клієнти.
MERGE (:Customer {customer_number: 'К-114', last_name: 'Коваль'});
MERGE (:Customer {customer_number: 'К-305', last_name: 'Мельник'});
MERGE (:Customer {customer_number: 'К-310', last_name: 'Ковальчук'});
MERGE (:Customer {customer_number: 'К-412', last_name: 'Бондар'});

// Велосипеди і пункт, до якого кожен приписано.
// Звʼязок LOCATED_AT - це зовнішній ключ bikes.station_name роботи №1.
MERGE (b:Bike {inventory_number: 'B-12', model: 'City'})
MERGE (s:Station {station_name: 'Пункт №2'})
MERGE (b)-[:LOCATED_AT]->(s);

MERGE (b:Bike {inventory_number: 'B-19', model: 'City'})
MERGE (s:Station {station_name: 'Пункт №9'})
MERGE (b)-[:LOCATED_AT]->(s);

MERGE (b:Bike {inventory_number: 'B-31', model: 'City'})
MERGE (s:Station {station_name: 'Пункт №4'})
MERGE (b)-[:LOCATED_AT]->(s);

MERGE (b:Bike {inventory_number: 'B-40', model: 'Kids'})
MERGE (s:Station {station_name: 'Пункт №7'})
MERGE (b)-[:LOCATED_AT]->(s);

// Тариф, за яким оплачується велосипед.
// Звʼязок PRICED_BY повторює стрілку «оплачується за» семантичної мережі лекції 10.
MERGE (b:Bike {inventory_number: 'B-12'})
MERGE (t:Tariff {tariff_code: 'Г1'})
MERGE (b)-[:PRICED_BY]->(t);

MERGE (b:Bike {inventory_number: 'B-40'})
MERGE (t:Tariff {tariff_code: 'Д1'})
MERGE (b)-[:PRICED_BY]->(t);

// Видачі. Властивості звʼязку - те, що в роботі №1 було стовпцями таблиці rentals.
// Моменти часу - через datetime(), а не текстом: та сама вимога, що до ISODate
// у роботі №4, інакше порівняння за часом працює як порівняння рядків.
MERGE (c:Customer {customer_number: 'К-114'})
MERGE (b:Bike {inventory_number: 'B-31'})
MERGE (c)-[:RENTED {rented_at:   datetime('2026-03-12T10:15:00Z'),
                    returned_at: datetime('2026-03-12T11:15:00Z'),
                    rental_price: 60.00}]->(b);

// Видача, що триває: властивість returned_at не записують зовсім.
// Властивість, якої немає, Neo4j повертає як NULL, і умова IS NULL її знаходить.
// Запис returned_at: null у MERGE до мети не веде.
MERGE (c:Customer {customer_number: 'К-305'})
MERGE (b:Bike {inventory_number: 'B-12'})
MERGE (c)-[:RENTED {rented_at: datetime('2026-03-13T09:00:00Z'),
                    rental_price: 180.00}]->(b);

MERGE (c:Customer {customer_number: 'К-310'})
MERGE (b:Bike {inventory_number: 'B-40'})
MERGE (c)-[:RENTED {rented_at: datetime('2026-03-13T08:30:00Z'),
                    rental_price: 120.00}]->(b);

// Сусідство пунктів - звʼязок, якого в реляційній схемі робіт №1-3 не було.
// Напрям у звʼязку є завжди, але сусідство зіставляють без напряму.
MERGE (a:Station {station_name: 'Пункт №4'})
MERGE (b:Station {station_name: 'Пункт №2'})
MERGE (a)-[:NEIGHBOUR_OF]->(b);

MERGE (a:Station {station_name: 'Пункт №4'})
MERGE (b:Station {station_name: 'Пункт №7'})
MERGE (a)-[:NEIGHBOUR_OF]->(b);

MERGE (a:Station {station_name: 'Пункт №7'})
MERGE (b:Station {station_name: 'Пункт №9'})
MERGE (a)-[:NEIGHBOUR_OF]->(b);


// --- Крок 7. Перевірка ідемпотентності --------------------------------------
// Числа записують після першого запуску скрипта, потім скрипт виконують удруге
// і записують числа ще раз. Вони мають збігтися.

MATCH (n) RETURN count(n) AS nodes;          // 14
MATCH ()-[r]->() RETURN count(r) AS rels;    // 12


// --- Крок 8. Запит 1. Зіставлення зі зразком з умовою -----------------------
// Питання області: хто зараз тримає велосипед, якого ще не повернуто?
// У роботі №2 те саме питання вимагало зʼєднання таблиць customers, rentals і bikes.
// Очікувана відповідь: Мельник - B-12, Ковальчук - B-40.

MATCH (c:Customer)-[r:RENTED]->(b:Bike)
WHERE r.returned_at IS NULL
RETURN c.last_name AS customer, b.inventory_number AS bike
ORDER BY customer;


// Той самий прийом зі словом NOT - зразок, якого немає.
// Питання області: який велосипед жодного разу не видавали?
// У роботі №2 це було ліве зʼєднання з IS NULL. Очікувана відповідь: B-19.

MATCH (b:Bike)
WHERE NOT (b)<-[:RENTED]-(:Customer)
RETURN b.inventory_number AS bike;


// --- Крок 8. Запит 2. Шлях змінної довжини ----------------------------------
// Питання області: куди можна перекинути велосипед з пункту №4 не більше ніж за два кроки?
// Зірочка з діапазоном 1..2 означає «пройти звʼязком від одного до двох разів»;
// стрілки немає, тому напрям не має значення.
// У SQL знадобилося б окреме зʼєднання на кожен крок, і глибину довелося б
// записати наперед. Очікувана відповідь: Пункт №2 і Пункт №7 - 1, Пункт №9 - 2.

MATCH path = (s:Station {station_name: 'Пункт №4'})
             -[:NEIGHBOUR_OF*1..2]-(other:Station)
RETURN other.station_name AS station,
       length(path) AS steps
ORDER BY steps, station;


// --- Крок 8. Запит 3. Перевірка умови правила -------------------------------
// Перевіряє умову правила П3: «у клієнта на руках два велосипеди або більше».
// count стоїть у частині WITH: окремої частини для групування в Cypher немає,
// групи утворюються за тим, що перелічено у WITH поруч з агрегатною функцією.
// Другий WHERE після WITH займає те саме місце, яке в SQL займає HAVING.
// Очікувана відповідь: без останнього WHERE - Мельник і Ковальчук по одному;
// з ним - жодного рядка, тобто правило П3 не спрацювало б.

MATCH (c:Customer)-[r:RENTED]->(:Bike)
WHERE r.returned_at IS NULL
WITH c, count(r) AS on_hand
WHERE on_hand >= 2
RETURN c.customer_number AS customer, on_hand;

// Запит перевірив умову одного правила і на цьому зупинився: що з його
// результату випливає наступне правило, запит не знає. Ланцюжок будує
// механізм виведення, і в цій роботі його роль виконує студент.
