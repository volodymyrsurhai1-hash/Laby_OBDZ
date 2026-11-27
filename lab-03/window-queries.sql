-- Оплати та сума за ПК.
SELECT reservation.pc_id,
       payment.reservation_id,
       payment.amount,
       sum(payment.amount) OVER (
           PARTITION BY reservation.pc_id
       ) AS pc_paid_total
FROM payments AS payment
JOIN reservations AS reservation USING (reservation_id)
ORDER BY reservation.pc_id, payment.reservation_id;
