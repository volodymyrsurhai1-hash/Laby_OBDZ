// Зразок команд MongoDB до лабораторної роботи №4 курсу «Організація баз даних і знань».
// Демонстраційна область - мережа прокату велосипедів (кроки 5-9 методичних вказівок).
//
// Файл показує оформлення команд, а не готову відповідь: назви колекцій, полів і значення
// замінюються на власну предметну область, після чого команди виконують у консолі Compass.
// Виконання цього файлу без переписування створює в базі чужі дані.
//
// Як виконувати: у MongoDB Compass відкрити вбудовану консоль (MongoSH),
// скопіювати туди потрібний блок і виконати. Перед першою командою - use dbsa.

use dbsa

// --- Крок 5. Наповнення колекції подій -------------------------------------
// Документи будують з тих самих рядків, які додав скрипт наповнення роботи №2.
// У _id лежить первинний ключ робочої таблиці; складений ключ - вкладений обʼєкт.
// Моменти часу - через ISODate, незаповнене значення - null.

db.rentals.insertMany([
  { _id: { inventory_number: "B-31",
           rented_at: ISODate("2026-03-12T10:15:00Z") },
    returned_at: ISODate("2026-03-12T11:15:00Z"),
    rental_price: 60.00,
    station:  { station_name: "Пункт №4", address: "Садова, 1" },
    customer: { customer_number: "К-114", last_name: "Коваль" },
    tariff:   { tariff_code: "Г1", tariff_name: "Погодинний" } },

  { _id: { inventory_number: "B-12",
           rented_at: ISODate("2026-03-12T11:40:00Z") },
    returned_at: ISODate("2026-03-13T11:40:00Z"),
    rental_price: 250.00,
    station:  { station_name: "Пункт №2", address: "Паркова, 5" },
    customer: { customer_number: "К-208", last_name: "Ткач" },
    tariff:   { tariff_code: "Д1", tariff_name: "Денний" } },

  { _id: { inventory_number: "B-44",
           rented_at: ISODate("2026-03-21T09:30:00Z") },
    returned_at: null,
    rental_price: 250.00,
    station:  { station_name: "Пункт №2", address: "Паркова, 5" },
    customer: { customer_number: "К-310", last_name: "Ковальчук" },
    tariff:   { tariff_code: "Д1", tariff_name: "Денний" } }
])

// Аналог count(*) роботи №2: число звіряють з кількістю рядків у робочій таблиці.
db.rentals.countDocuments()

// --- Крок 6. Чотири операції над документами -------------------------------

// 1. insertOne - подія, що триває: поле завершення ще не заповнене.
db.rentals.insertOne({
  _id: { inventory_number: "B-27",
         rented_at: ISODate("2026-03-14T10:00:00Z") },
  returned_at: null,
  rental_price: 60.00,
  station:  { station_name: "Пункт №4", address: "Садова, 1" },
  customer: { customer_number: "К-305", last_name: "Мельник" },
  tariff:   { tariff_code: "Г1", tariff_name: "Погодинний" }
})

// 2. find з умовою - «хто зараз катається».
//    У роботі №2 це питання вимагало зʼєднання трьох таблиць.
db.rentals.find({ returned_at: null })

// 3. find за вкладеним полем - шлях із крапкою береться в лапки;
//    другий аргумент - перелік полів, які повернути (список вибірки SELECT).
db.rentals.find(
  { "station.station_name": "Пункт №4" },
  { "customer.last_name": 1, rental_price: 1 }
)

// 4. updateOne - повернення дописує поле. У звіт: matchedCount і modifiedCount.
//    Умову копіюють із команди вставки: рівність вкладеного _id перевіряється цілком.
db.rentals.updateOne(
  { _id: { inventory_number: "B-27",
           rented_at: ISODate("2026-03-14T10:00:00Z") } },
  { $set: { returned_at: ISODate("2026-03-14T11:00:00Z") } }
)

// 5. deleteOne - прибрати помилково записану подію.
//    countDocuments() виконують до і після.
db.rentals.deleteOne({
  _id: { inventory_number: "B-27",
         rented_at: ISODate("2026-03-14T10:00:00Z") }
})

// --- Крок 7. Повторний запис ------------------------------------------------
// Повторний insertOne того самого документа завершується помилкою
// E11000 duplicate key error: поле _id унікальне завжди.
// Безпечний повторний запис - updateOne з upsert: true; його виконують двічі
// і порівнюють countDocuments() до першого запуску, після першого і після другого.

db.rentals.updateOne(
  { _id: { inventory_number: "B-31",
           rented_at: ISODate("2026-03-12T10:15:00Z") } },
  { $set: { rental_price: 60.00,
            station: { station_name: "Пункт №4", address: "Садова, 1" } } },
  { upsert: true }
)

// --- Крок 8. Агрегація ------------------------------------------------------
// $group - це GROUP BY, поле _id кроку $group - перелік стовпців групування,
// $sum - агрегатна функція, $sort - ORDER BY.
// $sum: 1 додає одиницю за документ (count(*)); $sum: "$поле" додає значення поля.
// Результат звіряють з показником роботи №3; розріз без жодної події в нього не потрапить.

db.rentals.aggregate([
  { $group: { _id: "$station.station_name",
              rental_count: { $sum: 1 },
              price_sum:    { $sum: "$rental_price" } } },
  { $sort: { price_sum: -1 } }
])

// --- Крок 9. Схема на читанні ----------------------------------------------
// Три документи різної форми в одній колекції; жодної міграції не знадобилося.

db.bikes.insertOne({ _id: "B-52", model: "City",
                     station_name: "Пункт №4" })

db.bikes.insertOne({ _id: "E-07", model: "E-City",
                     station_name: "Пункт №4", battery_percent: 82 })

db.bikes.insertOne({ _id: "K-03", model: "Kids",
                     station_name: "Пункт №2", wheel_size: 16,
                     max_rider_age: 8 })

// Ціна схеми на читанні: помилку в назві поля база приймає мовчки.
// Записуємо документ з полем statin_name замість station_name,
// потім шукаємо його за правильним полем і фіксуємо обидві відповіді.

db.bikes.insertOne({ _id: "B-99", model: "City",
                     statin_name: "Пункт №2" })

db.bikes.find({ station_name: "Пункт №2" })

// Прибираємо помилковий документ, щоб він не псував агрегацію.
db.bikes.deleteOne({ _id: "B-99" })
db.bikes.countDocuments()
