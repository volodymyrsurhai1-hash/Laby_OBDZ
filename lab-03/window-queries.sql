-- Сума оплат за ПК без згортання бронювань.
SELECT club.name AS club,
       pc.pc_id,
       payment.reservation_id,
       payment.amount,
       sum(payment.amount) OVER (
           PARTITION BY club.club_id, pc.pc_id
       ) AS pc_paid_total
FROM payments AS payment
JOIN reservations AS reservation
  ON reservation.reservation_id = payment.reservation_id
JOIN pcs AS pc
  ON pc.pc_id = reservation.pc_id
JOIN clubs AS club
  ON club.club_id = pc.club_id
ORDER BY club.name, pc.pc_id, reservation.starts_at, reservation.reservation_id;