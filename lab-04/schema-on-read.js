// Run in Mongosh after load-documents.js. The collection accepts different shapes.
printjson(db.pcs.insertOne({
  _id: 901,
  pc_id: 1,
  seat_number: 1
}));

printjson(db.pcs.insertOne({
  _id: 902,
  pc_id: 4,
  seat_number: 1,
  monitor_refresh_hz: 144
}));

printjson(db.pcs.insertOne({
  _id: 903,
  pc_id: 6,
  seat_number: 1,
  monitor_refresh_hz: 240,
  gpu_model: "RTX 4070"
}));

// The misspelled field is accepted, but a lookup by the correct name finds nothing.
printjson(db.pcs.insertOne({
  _id: 904,
  pc_id: 99,
  seat_numer: 9
}));
printjson(db.pcs.find({ seat_number: 9 }).toArray());
printjson(db.pcs.deleteOne({ _id: 904 }));
print("remaining PC documents:", db.pcs.countDocuments());
