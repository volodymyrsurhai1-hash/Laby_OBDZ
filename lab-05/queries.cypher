// Запит 1. Які активні бронювання не мають оплати?
// Очікувано: Andrew Baker, бронювання №2.
MATCH (client:Client)-[booking:BOOKED]->(pc:PC)
WHERE booking.status = 'active'
  AND booking.payment_amount IS NULL
RETURN client.full_name AS client, booking.reservation_id AS reservation_id,
       pc.pc_id AS pc_id
ORDER BY reservation_id;

// Запит 2. До яких клубів від Center веде один або два зв'язки?
// Очікувано: Riverside — 1 крок, Campus — 2.
MATCH path = (start:Club {club_id: 1})-[:NEIGHBOUR_OF*1..2]-(other:Club)
RETURN other.name AS club, length(path) AS steps
ORDER BY steps, club;

// Запит 3. Перевірка П6: клієнти з двома чи більше активними бронюваннями.
// Очікувано: Alice Anderson — 2 активні бронювання.
MATCH (client:Client)-[booking:BOOKED]->(:PC)
WHERE booking.status = 'active'
WITH client, count(booking) AS active_reservations
WHERE active_reservations >= 2
RETURN client.full_name AS client, active_reservations
ORDER BY client;
