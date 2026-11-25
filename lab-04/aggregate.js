// Group the copied reservation events by club.
// Compare the result with the SQL query in lab-03/analytic-queries.sql.

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
