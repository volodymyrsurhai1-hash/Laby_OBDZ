# Лабораторна робота №1. Моделювання предметної області та створення схеми бази даних

Виконавець: **Сургай Володимир**.

Предметна область: **мережа кіберклубів із попереднім бронюванням компʼютерів та оплатою**.

## 1. Предметна область

Мережа кіберклубів надає клієнтам компʼютерні місця для гри за спільними для мережі погодинними тарифами. Кожне місце належить конкретному клубу; його номер унікальний у межах клубу, а внутрішній ідентифікатор ПК унікальний у мережі. Клієнт бронює конкретне місце на визначений проміжок часу; система не дозволяє накладати активні бронювання одного ПК. Бронювання одразу резервує час, а оплату можна зареєструвати пізніше одним платежем. Погодинна ціна фіксується під час створення бронювання.

## 2. Бізнес-правила

| № | Правило | Де перевіряється | Обмеження або обґрунтування |
|---|---|---|---|
| 1 | Кожен клієнт має окремий ідентифікатор; номер телефону унікальний | схема | `PRIMARY KEY`, `UNIQUE`, `NOT NULL` |
| 2 | `pc_id` є глобальним ID компʼютера, а номер місця додатний і унікальний у межах клубу | схема | `IDENTITY`, `CHECK`, `UNIQUE (club_id, seat_number)` |
| 3 | Кожен ПК має один призначений тариф, який існує | схема | `NOT NULL`, `FOREIGN KEY` |
| 4 | Назва тарифу унікальна і не порожня | схема | `UNIQUE`, `CHECK` |
| 5 | Ціна тарифу та зафіксована ціна бронювання не можуть бути відʼємними; нуль дозволений | схема | `CHECK (price >= 0)` |
| 6 | Бронювання належить одному наявному клієнту й одному наявному ПК | схема | `NOT NULL`, `FOREIGN KEY` |
| 7 | Час закінчення бронювання має бути пізніше часу початку | схема | `CHECK (ends_at > starts_at)` |
| 8 | Активні бронювання одного ПК не перетинаються; скасовані не займають час | схема | обмеження `EXCLUDE` для часових інтервалів |
| 9 | Дозволені сусідні бронювання, якщо одне закінчується рівно тоді, коли починається наступне | схема | інтервал напіввідкритий: `[початок, кінець)` |
| 10 | Неактивний ПК не можна забронювати | схема | тригер перевіряє `pcs.is_active` |
| 11 | Ціна бронювання автоматично копіюється з тарифу ПК і зберігається при подальшій зміні тарифу | схема | тригер встановлює історичну `agreed_price_per_hour` |
| 12 | Статуси бронювання — `active` або `cancelled`; завершення визначається за `ends_at` | схема та запит | `CHECK`; окремий статус «завершена» не зберігається |
| 13 | ПК належить одному клубу; номер місця може повторюватися в різних клубах | схема | `NOT NULL`, `FOREIGN KEY`, `UNIQUE (club_id, seat_number)` |
| 14 | ПК у неактивному клубі не можна забронювати | схема | тригер перевіряє `clubs.is_active` |
| 15 | Бронювання може бути неоплаченим; до нього можна зареєструвати не більше одного платежу | схема | FK `payments.reservation_id` і `UNIQUE` |
| 16 | Платіж має невідʼємну суму й один із підтримуваних способів оплати | схема | `CHECK (amount >= 0)`, `CHECK (payment_method IN (...))` |

## 3. ER-модель

```mermaid
erDiagram
    КЛУБ ||--o{ ПК : містить
    ТАРИФ ||--o{ ПК : призначено
    КЛІЄНТ ||--o{ БРОНЮВАННЯ : створює
    ПК ||--o{ БРОНЮВАННЯ : бронюється
    БРОНЮВАННЯ ||--o| ОПЛАТА : оплачується

    КЛУБ {
        число club_id PK
        текст name
        текст address
        логічне is_active
    }
    ТАРИФ {
        число tariff_id PK
        текст назва
        число ціна_за_годину
    }
    ПК {
        число pc_id PK
        число club_id FK
        число seat_number
        логічне is_active
        число tariff_id FK
    }
    КЛІЄНТ {
        число client_id PK
        текст повне_імʼя
        текст телефон UK
    }
    БРОНЮВАННЯ {
        число reservation_id PK
        число client_id FK
        число pc_id FK
        дата_час starts_at
        дата_час ends_at
        текст статус
        число погоджена_ціна_за_годину
    }
    ОПЛАТА {
        число payment_id PK
        число reservation_id FK, UK
        число amount
        текст payment_method
        дата_час paid_at
    }
```

### Сутності

- **Тариф** — назва тарифу та його поточна ціна за годину.
- **Клуб** — філія мережі з назвою, адресою та ознакою активності.
- **ПК** — компʼютерне місце філії; `pc_id` — глобальний ID, а `seat_number` — номер місця в цьому клубі.
- **Клієнт** — людина, яка бронює місце; телефон є унікальним контактним номером.
- **Бронювання** — резервування одного ПК для одного клієнта на часовий інтервал.
- **Оплата** — фактично прийнятий платіж за бронювання, із сумою, способом і часом.

### Звʼязки

- Один тариф може бути призначений нулю або багатьом ПК; кожен ПК має рівно один тариф (1:N).
- Один клуб може містити нуль або багато ПК; кожен ПК належить рівно одному клубу (1:N). Номер місця унікальний тільки в межах свого клубу.
- Один клієнт може створити нуль або багато бронювань; кожне бронювання належить одному клієнту (1:N).
- Один ПК може мати багато бронювань у різний час; кожне бронювання стосується одного ПК (1:N). Часові інтервали активних бронювань не перетинаються.
- Одне бронювання може бути неоплаченим або мати один платіж; кожен платіж належить рівно одному бронюванню (1:0..1).
- Тариф бронювання визначається через призначений ПК. Погоджена ціна копіюється в бронювання як історичне значення.

### Перевірка за типовими помилками

- [x] Атрибут, який насправді є сутністю: тариф винесено в окрему сутність.
- [x] Звʼязок без кардинальності: усі звʼязки мають кардинальності.
- [x] Одна широка таблиця замість кількох сутностей: клуби, ПК, тарифи, клієнти, бронювання й оплати розділено.
- [x] Телефон або електронна пошта як первинний ключ: клієнт має окремий `client_id`; телефон — унікальний альтернативний ключ.

Результат перевірки: клуб, тариф, клієнт, ПК, бронювання й оплата моделюються окремо; усі звʼязки мають кардинальність; телефон не використовується як первинний ключ.

## 4. Ключі та реакції на видалення

### Первинні ключі

| Сутність | Потенційні ключі | Первинний ключ | Обґрунтування |
|---|---|---|---|
| Клуб | `club_id` | `club_id` | Сурогатний ключ незалежний від перейменування філії чи зміни адреси |
| Клієнт | `client_id`, унікальний `phone` | `client_id` | Сурогатний ключ не залежить від зміни контактного номера |
| ПК | `pc_id`, пара (`club_id`, `seat_number`) | `pc_id` | Глобальний сурогатний ID стабільний, навіть якщо місце перенумерують або перенесуть |
| Тариф | `tariff_id`, унікальна назва | `tariff_id` | Назву тарифу можна перейменувати |
| Бронювання | `reservation_id` | `reservation_id` | Сурогатний ключ стабільно ідентифікує історичний запис |
| Оплата | `payment_id`, унікальний `reservation_id` | `payment_id` | ID платежу не залежить від бронювання; унікальний FK обмежує бронювання одним платежем |

### Реакції на видалення

| Звʼязок | Реакція | Обґрунтування з погляду бізнесу |
|---|---|---|
| Клуб — ПК | `RESTRICT` | Філію з компʼютерами не видаляти; її можна позначити неактивною |
| Клієнт — Бронювання | `RESTRICT` | Не видаляти клієнта, якщо його бронювання потрібні в історії |
| ПК — Бронювання | `RESTRICT` | Не видаляти місце з історією; нові броні можна заборонити через `is_active = false` |
| Тариф — ПК | `RESTRICT` | Не видаляти тариф, призначений компʼютеру |
| Бронювання — Оплата | `RESTRICT` | Не видаляти бронювання, доки зберігається фінансовий запис |

## 5. Нормалізація

Нижче розглядаються тільки шість таблиць цієї схеми: `clubs`, `clients`, `tariffs`, `pcs`, `reservations` і `payments`. Нормалізація описує саме їх, а не іншу предметну область.

### Функціональні залежності в таблицях схеми

Кожна залежність нижче стосується окремої таблиці й випливає з її первинного або альтернативного ключа:

| Таблиця | Ключ | Функціональна залежність |
|---|---|---|
| `clubs` | `club_id` | `club_id → name, address, is_active` |
| `clients` | `client_id` | `client_id → full_name, phone` |
| `clients` | `phone UNIQUE` | `phone → client_id, full_name` |
| `tariffs` | `tariff_id` | `tariff_id → name, price_per_hour` |
| `tariffs` | `name UNIQUE` | `name → tariff_id, price_per_hour` |
| `pcs` | `pc_id` | `pc_id → club_id, seat_number, tariff_id, is_active` |
| `pcs` | `(club_id, seat_number) UNIQUE` | `(club_id, seat_number) → pc_id, tariff_id, is_active` |
| `reservations` | `reservation_id` | `reservation_id → client_id, pc_id, starts_at, ends_at, status, agreed_price_per_hour` |
| `payments` | `payment_id` | `payment_id → reservation_id, amount, payment_method, paid_at` |
| `payments` | `reservation_id UNIQUE` | `reservation_id → payment_id, amount, payment_method, paid_at` |

У `payments` остання залежність обмежує модель максимум однією оплатою на бронювання. Відсутність рядка в `payments` означає, що бронювання ще не має оплати.

### Як ці таблиці усувають аномалії

Як приклад поганого подання візьмемо одну широку таблицю бронювань, яка повторює поля клубу, клієнта, ПК і тарифу з відповідних таблиць цієї ж схеми:

```text
reservation_id, client_id, full_name, phone,
pc_id, club_id, club_name, address, seat_number,
tariff_id, tariff_name, current_price,
starts_at, ends_at, agreed_price_per_hour,
payment_id, amount, payment_method, paid_at
```

Для такої таблиці виникають конкретні аномалії:

- **Оновлення:** зміна телефону клієнта або адреси клубу потребує оновити багато рядків бронювань; пропущений рядок створює суперечливі дані.
- **Вставлення:** клієнта, клуб або тариф довелося б додавати разом із фіктивним бронюванням, бо всі дані зберігаються в одному рядку.
- **Видалення:** видалення останнього бронювання клієнта могло б стерти єдині збережені в цій таблиці імʼя й телефон цього клієнта.

У реальній схемі ці атрибути зберігаються у своїх таблицях і повʼязуються зовнішніми ключами. Наприклад, імʼя клієнта зберігається один раз у `clients`, а бронювання містить лише `client_id`.

### Перевірка 1NF, 2NF і 3NF

- **1NF:** у шести таблицях кожен стовпець зберігає одне значення, без списків чи повторюваних груп. Складні множинні дані для цих сутностей не зберігаються в одному полі.
- **2NF:** кожна таблиця має одностовпцевий первинний ключ (`club_id`, `client_id`, `tariff_id`, `pc_id`, `reservation_id` або `payment_id`). Тому немає неключових атрибутів, залежних лише від частини первинного ключа. Унікальний складений ключ ПК `(club_id, seat_number)` також визначає атрибути одного ПК цілком.
- **3NF:** дані клубу, клієнта, тарифу й ПК не зберігаються повторно в `reservations` або `payments`; ці таблиці посилаються на них через FK. Отже, описові атрибути залежать від ключа своєї таблиці, а не від іншого неключового атрибута.

`agreed_price_per_hour` у `reservations` — навмисний історичний знімок ціни на момент бронювання. Поточна ціна належить `tariffs`, а тригер копіює її у бронювання, щоб наступна зміна тарифу не переписала історичну домовленість. Це свідоме дублювання значення з різним змістом («поточна ціна» та «ціна погодженого бронювання»), а не твердження, що обидві ціни завжди однакові.

## 6. Реляційна схема

```mermaid
erDiagram
    clubs ||--o{ pcs : contains
    tariffs ||--o{ pcs : assigned_to
    clients ||--o{ reservations : creates
    pcs ||--o{ reservations : booked
    reservations ||--o| payments : paid_by
    clubs {
        integer club_id PK
        text name
        text address
        boolean is_active
    }
    tariffs {
        integer tariff_id PK
        text name UK
        numeric price_per_hour
    }
    pcs {
        integer pc_id PK
        integer club_id FK
        integer seat_number
        boolean is_active
        integer tariff_id FK
    }
    clients {
        integer client_id PK
        text full_name
        text phone UK
    }
    reservations {
        integer reservation_id PK
        integer client_id FK
        integer pc_id FK
        timestamptz starts_at
        timestamptz ends_at
        text status
        numeric agreed_price_per_hour
    }
    payments {
        integer payment_id PK
        integer reservation_id FK, UK
        numeric amount
        text payment_method
        timestamptz paid_at
    }
```

## 7. Середовище

Операційна система: Windows.

```powershell
docker compose up -d
docker compose ps
```

Фактичний стан PostgreSQL під час перевірки:

```text
NAME              IMAGE           SERVICE    STATUS
dbsa-postgres-1   postgres:18.6   postgres   Up
```

Підключення DBeaver: host `localhost`, port `5432`, database `dbsa`, username `student`, password `student`.

Схема `public` у `dbsa` містить `clubs`, `clients`, `pcs`, `reservations`, `payments` і `tariffs`. На момент останньої перевірки всі шість таблиць порожні; наповнення даними не входить до цієї лабораторної. Базу `dbsa_check` використовуємо окремо для циклу перевірки міграцій.

Для демонстраційних даних є окремий [seed-data.sql](seed-data.sql). Він додає один клуб, два місця, тариф, двох клієнтів, бронювання та оплати; файл можна виконати один раз після міграції `001 up`. Наповнення не є обовʼязковою частиною цієї лабораторної.

Дані зберігаються в іменованому томі `pgdata`, підключеному до `/var/lib/postgresql`. `docker compose down` видаляє контейнер, але зберігає том; `docker compose down -v` також видаляє том і дані.

Перевірка збереження: в окремому тимчасовому контейнері створено тестовий рядок, контейнер пересоздано з тим самим томом — рядок залишився. Тимчасовий контейнер і його том після перевірки видалено.

## 8. Створення схеми

- Міграція 001: [migrations/001_create_schema.up.sql](migrations/001_create_schema.up.sql), [migrations/001_create_schema.down.sql](migrations/001_create_schema.down.sql). Вона створює всю погоджену схему мережі кіберклубів із шести сутностей.
- `reservations_no_active_overlap` — обмеження `EXCLUDE` за ПК і часовим інтервалом; скасовані бронювання не враховуються. Воно перевірене тестовим SQL, оскільки наданий скрипт `check-schema.sql` показує обмеження типів `PRIMARY KEY`, `UNIQUE`, `FOREIGN KEY` і `CHECK`.
- Тригер `reservations_set_price` викликає `set_reservation_price()` перед вставленням бронювання або зміною його ПК. Функція перевіряє активність ПК і клубу та записує тарифну ціну у `agreed_price_per_hour`; неактивний ПК/клуб відхиляється.
- Один платіж належить одній броні; `UNIQUE` на `payments.reservation_id` забороняє повторну оплату в цій моделі. `paid_at` за замовчуванням отримує час реєстрації платежу.
- Для індексації виключення використовується розширення PostgreSQL `btree_gist`. Міграція `down` прибирає таблиці й тригерну функцію, але залишає розширення, щоб не видаляти його, якщо воно використовується іншими обʼєктами бази.

## 9. Перевірка обмежень

Файл перевірок: [constraint-checks.sql](constraint-checks.sql). Кожен тестовий `INSERT` виконується окремо: виділи одну команду в DBeaver і запусти її. PostgreSQL відхиляє цю команду; успішно вставлені тестові дані не залишаються.

| Правило | Обмеження | Повідомлення PostgreSQL |
|---|---|---|
| Імʼя клієнта обовʼязкове | `NOT NULL` | `null value in column "full_name" of relation "clients" violates not-null constraint` |
| Телефон унікальний | `UNIQUE` | `duplicate key value violates unique constraint "clients_phone_key"` |
| Ціна не відʼємна | `CHECK` | `new row for relation "tariffs" violates check constraint "tariffs_price_per_hour_check"` |
| ID тарифу — первинний ключ | `PRIMARY KEY` | `duplicate key value violates unique constraint "tariffs_pkey"` |
| Платіж посилається на наявне бронювання | `FOREIGN KEY` | `insert or update on table "payments" violates foreign key constraint "payments_reservation_id_fkey"` |

Додатково перевірено: номер місця унікальний у клубі; некоректний інтервал і бронювання в неактивному клубі або на неактивному ПК відхиляються; сусідні інтервали й бронювання скасованого часу дозволені; ціна старої броні не змінюється після зміни тарифу.

## 10. Цикл up — down — up

Цикл перевіряється в окремій базі `dbsa_check`; основна база `dbsa` під час тесту не змінюється. У `dbsa_check` застосовується `001 up`, потім `001 down`, перевіряється порожня схема, після чого `001 up` запускається повторно.

Результат [check-schema.sql](check-schema.sql) після першого `up`:

```text
  table_name  |    kind     |                   name                   |                                       definition
--------------+-------------+------------------------------------------+-----------------------------------------------------------------------------------------
clients       | стовпець    | client_id                                | integer NOT NULL GENERATED AS IDENTITY
clients       | стовпець    | full_name                                | text NOT NULL
clients       | стовпець    | phone                                    | text NOT NULL
clients       | PRIMARY KEY | clients_pkey                             | PRIMARY KEY (client_id)
clients       | UNIQUE      | clients_phone_key                        | UNIQUE (phone)
clients       | CHECK       | clients_full_name_check                  | CHECK ((btrim(full_name) <> ''::text))
clients       | CHECK       | clients_phone_check                      | CHECK ((btrim(phone) <> ''::text))
clubs         | стовпець    | club_id                                  | integer NOT NULL GENERATED ALWAYS AS IDENTITY
clubs         | стовпець    | name                                     | text NOT NULL
clubs         | стовпець    | address                                  | text NOT NULL
clubs         | стовпець    | is_active                                | boolean NOT NULL
clubs         | PRIMARY KEY | clubs_pkey                               | PRIMARY KEY (club_id)
clubs         | CHECK       | clubs_address_check                      | CHECK ((btrim(address) <> ''::text))
clubs         | CHECK       | clubs_name_check                         | CHECK ((btrim(name) <> ''::text))
payments      | стовпець    | payment_id                               | integer NOT NULL GENERATED ALWAYS AS IDENTITY
payments      | стовпець    | reservation_id                           | integer NOT NULL
payments      | стовпець    | amount                                   | numeric NOT NULL
payments      | стовпець    | payment_method                           | text NOT NULL
payments      | стовпець    | paid_at                                  | timestamp with time zone NOT NULL
payments      | PRIMARY KEY | payments_pkey                            | PRIMARY KEY (payment_id)
payments      | UNIQUE      | payments_reservation_id_key              | UNIQUE (reservation_id)
payments      | FOREIGN KEY | payments_reservation_id_fkey             | FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id) ON DELETE RESTRICT
payments      | CHECK       | payments_amount_check                    | CHECK ((amount >= (0)::numeric))
payments      | CHECK       | payments_payment_method_check            | CHECK ((payment_method = ANY (ARRAY['cash'::text, 'card'::text, 'online'::text])))
pcs           | стовпець    | pc_id                                    | integer NOT NULL GENERATED BY DEFAULT AS IDENTITY
pcs           | стовпець    | club_id                                  | integer NOT NULL
pcs           | стовпець    | seat_number                              | integer NOT NULL
pcs           | стовпець    | is_active                                | boolean NOT NULL
pcs           | стовпець    | tariff_id                                | integer NOT NULL
pcs           | PRIMARY KEY | pcs_pkey                                 | PRIMARY KEY (pc_id)
pcs           | UNIQUE      | pcs_club_seat_unique                     | UNIQUE (club_id, seat_number)
pcs           | FOREIGN KEY | pcs_club_id_fkey                         | FOREIGN KEY (club_id) REFERENCES clubs(club_id) ON DELETE RESTRICT
pcs           | FOREIGN KEY | pcs_tariff_id_fkey                       | FOREIGN KEY (tariff_id) REFERENCES tariffs(tariff_id) ON DELETE RESTRICT
pcs           | CHECK       | pcs_pc_id_check                          | CHECK ((pc_id > 0))
pcs           | CHECK       | pcs_seat_number_check                    | CHECK ((seat_number > 0))
reservations  | стовпець    | reservation_id                           | integer NOT NULL GENERATED ALWAYS AS IDENTITY
reservations  | стовпець    | client_id                                | integer NOT NULL
reservations  | стовпець    | pc_id                                    | integer NOT NULL
reservations  | стовпець    | starts_at                                | timestamp with time zone NOT NULL
reservations  | стовпець    | ends_at                                  | timestamp with time zone NOT NULL
reservations  | стовпець    | status                                   | text NOT NULL
reservations  | стовпець    | agreed_price_per_hour                    | numeric NOT NULL
reservations  | PRIMARY KEY | reservations_pkey                        | PRIMARY KEY (reservation_id)
reservations  | FOREIGN KEY | reservations_client_id_fkey              | FOREIGN KEY (client_id) REFERENCES clients(client_id) ON DELETE RESTRICT
reservations  | FOREIGN KEY | reservations_pc_id_fkey                  | FOREIGN KEY (pc_id) REFERENCES pcs(pc_id) ON DELETE RESTRICT
reservations  | CHECK       | reservations_agreed_price_per_hour_check | CHECK ((agreed_price_per_hour >= (0)::numeric))
reservations  | CHECK       | reservations_status_check                | CHECK ((status = ANY (ARRAY['active'::text, 'cancelled'::text])))
reservations  | CHECK       | reservations_valid_interval              | CHECK ((ends_at > starts_at))
tariffs       | стовпець    | tariff_id                                | integer NOT NULL GENERATED ALWAYS AS IDENTITY
tariffs       | стовпець    | name                                     | text NOT NULL
tariffs       | стовпець    | price_per_hour                           | numeric NOT NULL
tariffs       | PRIMARY KEY | tariffs_pkey                             | PRIMARY KEY (tariff_id)
tariffs       | UNIQUE      | tariffs_name_key                         | UNIQUE (name)
tariffs       | CHECK       | tariffs_name_not_blank                   | CHECK ((btrim(name) <> ''::text))
tariffs       | CHECK       | tariffs_price_per_hour_check             | CHECK ((price_per_hour >= (0)::numeric))
```

Після `down`: результат перевірки порожній — таблиць у схемі `public` немає.

Після повторного `up`: звіт збігається з першим; повторне створення `btree_gist` безпечне завдяки `IF NOT EXISTS`.

Висновок звірки з діаграмою розділу 6: таблиці, ключі та звʼязки відповідають реляційній схемі; додаткове обмеження `EXCLUDE` реалізує правило зайнятості ПК.
