// Execute in Neo4j Browser. All node and relationship creation uses MERGE.
// The subgraph is copied from reservation IDs 1, 2, and 8 in lab-02/seed-data.sql.

MERGE (c:Club {club_id: 1})
SET c.name = 'Cyber Club Center', c.address = '1 Main Street', c.is_active = true;
MERGE (c:Club {club_id: 2})
SET c.name = 'Cyber Club Riverside', c.address = '2 River Street', c.is_active = true;
MERGE (c:Club {club_id: 3})
SET c.name = 'Cyber Club Campus', c.address = '3 Campus Street', c.is_active = true;
MERGE (c:Club {club_id: 4})
SET c.name = 'Cyber Club Empty', c.address = '4 Empty Street', c.is_active = true;

MERGE (t:Tariff {tariff_id: 1})
SET t.name = 'Basic', t.price_per_hour = 100;
MERGE (t:Tariff {tariff_id: 2})
SET t.name = 'Standard', t.price_per_hour = 150;
MERGE (t:Tariff {tariff_id: 5})
SET t.name = 'Premium', t.price_per_hour = 300;

MERGE (p:PC {pc_id: 1})
SET p.seat_number = 1, p.is_active = true;
MERGE (p:PC {pc_id: 5})
SET p.seat_number = 2, p.is_active = true;
MERGE (p:PC {pc_id: 6})
SET p.seat_number = 1, p.is_active = true;

MERGE (client:Client {client_id: 1})
SET client.full_name = 'Alice Anderson', client.phone = '+380000000301';
MERGE (client:Client {client_id: 2})
SET client.full_name = 'Andrew Baker', client.phone = '+380000000302';

MATCH (club:Club {club_id: 1})
MATCH (pc:PC {pc_id: 1})
MERGE (club)-[:HAS_PC]->(pc);
MATCH (club:Club {club_id: 2})
MATCH (pc:PC {pc_id: 5})
MERGE (club)-[:HAS_PC]->(pc);
MATCH (club:Club {club_id: 3})
MATCH (pc:PC {pc_id: 6})
MERGE (club)-[:HAS_PC]->(pc);

MATCH (pc:PC {pc_id: 1})
MATCH (tariff:Tariff {tariff_id: 1})
MERGE (pc)-[:USES_TARIFF]->(tariff);
MATCH (pc:PC {pc_id: 5})
MATCH (tariff:Tariff {tariff_id: 5})
MERGE (pc)-[:USES_TARIFF]->(tariff);
MATCH (pc:PC {pc_id: 6})
MATCH (tariff:Tariff {tariff_id: 2})
MERGE (pc)-[:USES_TARIFF]->(tariff);

MATCH (client:Client {client_id: 1})
MATCH (pc:PC {pc_id: 1})
MERGE (client)-[booking:BOOKED {reservation_id: 1}]->(pc)
SET booking.starts_at = datetime('2026-03-01T10:00:00+02:00'),
    booking.ends_at = datetime('2026-03-01T12:00:00+02:00'),
    booking.status = 'active',
    booking.payment_amount = 200,
    booking.payment_method = 'card';

MATCH (client:Client {client_id: 2})
MATCH (pc:PC {pc_id: 1})
MERGE (client)-[booking:BOOKED {reservation_id: 2}]->(pc)
SET booking.starts_at = datetime('2026-03-01T12:00:00+02:00'),
    booking.ends_at = datetime('2026-03-01T14:00:00+02:00'),
    booking.status = 'active';

MATCH (client:Client {client_id: 1})
MATCH (pc:PC {pc_id: 6})
MERGE (client)-[booking:BOOKED {reservation_id: 8}]->(pc)
SET booking.starts_at = datetime('2026-03-15T18:00:00+02:00'),
    booking.ends_at = datetime('2026-03-15T20:00:00+02:00'),
    booking.status = 'active',
    booking.payment_amount = 300,
    booking.payment_method = 'online';

// NEIGHBOUR_OF is extra area knowledge not stored in the relational schema.
MATCH (a:Club {club_id: 1})
MATCH (b:Club {club_id: 2})
MERGE (a)-[:NEIGHBOUR_OF]->(b);
MATCH (a:Club {club_id: 2})
MATCH (b:Club {club_id: 3})
MERGE (a)-[:NEIGHBOUR_OF]->(b);
MATCH (a:Club {club_id: 3})
MATCH (b:Club {club_id: 4})
MERGE (a)-[:NEIGHBOUR_OF]->(b);

// Idempotence checks: after either run, expect 12 nodes and 12 relationships.
MATCH (n) RETURN count(n) AS nodes;
MATCH ()-[r]->() RETURN count(r) AS relationships;
