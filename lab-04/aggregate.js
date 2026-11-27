// Групуємо броні за клубом.
// Звіряємо з SQL-запитом Lab 3.

printjson(db.reservations.aggregate([
  {
    $match: {
      starts_at: {
        $gte: ISODate("2026-03-01T00:00:00+02:00"),
        $lt: ISODate("2026-04-01T00:00:00+02:00")
      }
    }
  },
  {
    $group: {
      _id: "$pc.club.name",
      reservation_count: { $sum: 1 },
      paid_amount_sum: { $sum: "$payment.amount" }
    }
  },
  { $match: { paid_amount_sum: { $gt: 250 } } },
  { $sort: { paid_amount_sum: -1, _id: 1 } }
]).toArray());
