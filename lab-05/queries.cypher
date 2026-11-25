// Query 1. Which active reservation has no payment?
// Expected: Andrew Baker, reservation 2.
MATCH (client:Client)-[booking:BOOKED]->(pc:PC)
WHERE booking.status = 'active'
  AND booking.payment_amount IS NULL
RETURN client.full_name AS client, booking.reservation_id AS reservation_id,
       pc.pc_id AS pc_id
ORDER BY reservation_id;

// Query 2. Which clubs are reachable from the Central club in one or two links?
// Expected: Riverside at 1 step, Campus at 2 steps.
MATCH path = (start:Club {club_id: 1})-[:NEIGHBOUR_OF*1..2]-(other:Club)
RETURN other.name AS club, length(path) AS steps
ORDER BY steps, club;

// Query 3. Check condition P6: clients with at least two active reservations.
// Expected: Alice Anderson has 2 active reservations.
MATCH (client:Client)-[booking:BOOKED]->(:PC)
WHERE booking.status = 'active'
WITH client, count(booking) AS active_reservations
WHERE active_reservations >= 2
RETURN client.full_name AS client, active_reservations
ORDER BY client;
