-- Демонстраційне наповнення схеми: один клуб, один тариф,
-- два ПК, два клієнти, два бронювання й дві оплати.
-- Виконуйте файл один раз у базі після застосування 001 up.

WITH
new_club AS (
    INSERT INTO clubs (name, address)
    VALUES ('Demo Club', '1 Example Street')
    RETURNING club_id, name
),
new_tariff AS (
    INSERT INTO tariffs (name, price_per_hour)
    VALUES ('Demo Tariff', 200)
    RETURNING tariff_id
),
new_clients AS (
    INSERT INTO clients (full_name, phone)
    VALUES
        ('Demo Customer 1', '+380000000091'),
        ('Demo Customer 2', '+380000000092')
    RETURNING client_id, full_name, phone
),
new_pcs AS (
    INSERT INTO pcs (club_id, seat_number, tariff_id)
    SELECT c.club_id, seat.seat_number, t.tariff_id
    FROM new_club AS c
    CROSS JOIN new_tariff AS t
    CROSS JOIN (VALUES (1), (2)) AS seat(seat_number)
    RETURNING pc_id, seat_number
),
new_reservations AS (
    INSERT INTO reservations (
        client_id,
        pc_id,
        starts_at,
        ends_at,
        status
    )
    SELECT
        client.client_id,
        pc.pc_id,
        CURRENT_TIMESTAMP + INTERVAL '1 day',
        CURRENT_TIMESTAMP + INTERVAL '1 day 3 hours',
        'active'
    FROM new_pcs AS pc
    JOIN (VALUES
        (1, '+380000000091'),
        (2, '+380000000092')
    ) AS assignment(seat_number, phone)
        ON assignment.seat_number = pc.seat_number
    JOIN new_clients AS client
        ON client.phone = assignment.phone
    RETURNING
        reservation_id,
        pc_id,
        client_id,
        ends_at,
        starts_at
),
new_payments AS (
    INSERT INTO payments (reservation_id, amount, payment_method)
    SELECT reservation.reservation_id,
        tariff.price_per_hour
            * EXTRACT(EPOCH FROM (reservation.ends_at - reservation.starts_at)) / 3600,
        'card'
    FROM new_reservations AS reservation
    JOIN pcs AS pc ON pc.pc_id = reservation.pc_id
    JOIN tariffs AS tariff ON tariff.tariff_id = pc.tariff_id
    RETURNING payment_id, reservation_id
)
SELECT
    club.name AS club,
    pc.seat_number,
    client.full_name AS client,
    reservation.reservation_id,
    tariff.price_per_hour AS hourly_price,
    payment.payment_id,
    payment.payment_id IS NOT NULL AS paid
FROM new_reservations AS reservation
JOIN new_pcs AS pc
    ON pc.pc_id = reservation.pc_id
JOIN new_clients AS client
    ON client.client_id = reservation.client_id
JOIN new_payments AS payment
    ON payment.reservation_id = reservation.reservation_id
CROSS JOIN new_club AS club
CROSS JOIN new_tariff AS tariff_source
JOIN tariffs AS tariff
    ON tariff.tariff_id = tariff_source.tariff_id
ORDER BY pc.seat_number;
