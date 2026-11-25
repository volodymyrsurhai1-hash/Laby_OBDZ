// Group the copied reservation events by club.
// Compare the result with the SQL query in lab-04/README.md.

printjson(db.reservations.aggregate([
  {
    $group: {
      _id: "$pc.club.name",
      reservation_count: { $sum: 1 },
      paid_amount_sum: { $sum: "$payment.amount" }
    }
  },
  { $sort: { paid_amount_sum: -1, _id: 1 } }
]).toArray());
