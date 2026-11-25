// Run in Mongosh against dbsa after load-documents.js.
// These examples are intentionally one-time operations; reset the collection before replaying.

// 1. Add an unfinished reservation. Expected: acknowledged, insertedId 9001.
printjson(db.reservations.insertOne({
  _id: 9001,
  starts_at: ISODate("2032-05-01T10:00:00Z"),
  ends_at: ISODate("2032-05-01T12:00:00Z"),
  status: "active",
  client: { client_id: 8, full_name: "Dana Green", phone: "+380000000401" },
  pc: {
    pc_id: 6,
    seat_number: 1,
    club: { club_id: 3, name: "Cyber Club Campus", address: "3 Campus Street" },
    tariff: { tariff_id: 2, name: "Standard", price_per_hour: 150 }
  },
  payment: null
}));

// 2. Find reservations without payment. Expected: 5 documents after step 1.
printjson(db.reservations.find(
  { payment: null },
  { _id: 1, status: 1 }
).toArray());

// 3. Find bookings at the Central club and return nested client/payment fields.
// Expected: 5 documents from the original sample.
printjson(db.reservations.find(
  { "pc.club.name": "Cyber Club Center" },
  { _id: 1, "client.full_name": 1, "payment.amount": 1 }
).toArray());

// 4. Update the just-added reservation's end time. Expected: matchedCount 1, modifiedCount 1.
printjson(db.reservations.updateOne(
  { _id: 9001 },
  { $set: { ends_at: ISODate("2032-05-01T13:00:00Z") } }
));

// 5. Insert a disposable mistaken row, count, delete it, and count again.
// Expected: count 12 before delete, 11 after; deletedCount 1.
printjson(db.reservations.insertOne({ _id: 9002, status: "mistake" }));
print("before delete:", db.reservations.countDocuments());
printjson(db.reservations.deleteOne({ _id: 9002 }));
print("after delete:", db.reservations.countDocuments());

// 6. Run this exact insert a second time to see the duplicate _id error (E11000).
// Use an existing source document so the first run does not change it.
try {
  db.reservations.insertOne({
    _id: 1,
    starts_at: ISODate("2026-03-01T10:00:00+02:00"),
    ends_at: ISODate("2026-03-01T12:00:00+02:00"),
    status: "active",
    client: { client_id: 1, full_name: "Alice Anderson", phone: "+380000000301" },
    pc: {
      pc_id: 1,
      seat_number: 1,
      club: { club_id: 1, name: "Cyber Club Center", address: "1 Main Street" },
      tariff: { tariff_id: 1, name: "Basic", price_per_hour: 100 }
    },
    payment: { amount: 200, payment_method: "card" }
  });
} catch (error) {
  print(error.message);
}

// 7. Upsert a separate key twice. First result inserts once; second matches that row.
// Expected counts: 11 before, 12 after first run, still 12 after second run.
print("before upsert:", db.reservations.countDocuments());
printjson(db.reservations.updateOne(
  { _id: 10001 },
  { $set: { status: "active", sync_marker: "lab04-upsert" } },
  { upsert: true }
));
print("after first upsert:", db.reservations.countDocuments());
printjson(db.reservations.updateOne(
  { _id: 10001 },
  { $set: { status: "active", sync_marker: "lab04-upsert" } },
  { upsert: true }
));
print("after second upsert:", db.reservations.countDocuments());
