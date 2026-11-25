// Copy the same ten reservations (IDs 1-10) from lab-02/seed-data.sql.
// Run in MongoDB Compass Mongosh after: use dbsa

db.reservations.insertMany([
  {
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
  },
  {
    _id: 2,
    starts_at: ISODate("2026-03-01T12:00:00+02:00"),
    ends_at: ISODate("2026-03-01T14:00:00+02:00"),
    status: "active",
    client: { client_id: 2, full_name: "Andrew Baker", phone: "+380000000302" },
    pc: {
      pc_id: 1,
      seat_number: 1,
      club: { club_id: 1, name: "Cyber Club Center", address: "1 Main Street" },
      tariff: { tariff_id: 1, name: "Basic", price_per_hour: 100 }
    },
    payment: null
  },
  {
    _id: 3,
    starts_at: ISODate("2026-03-02T18:00:00+02:00"),
    ends_at: ISODate("2026-03-02T20:00:00+02:00"),
    status: "cancelled",
    client: { client_id: 3, full_name: "Anna Brown", phone: "+380000000303" },
    pc: {
      pc_id: 2,
      seat_number: 2,
      club: { club_id: 1, name: "Cyber Club Center", address: "1 Main Street" },
      tariff: { tariff_id: 2, name: "Standard", price_per_hour: 150 }
    },
    payment: null
  },
  {
    _id: 4,
    starts_at: ISODate("2026-03-02T18:00:00+02:00"),
    ends_at: ISODate("2026-03-02T20:00:00+02:00"),
    status: "active",
    client: { client_id: 4, full_name: "Aaron Carter", phone: "+380000000304" },
    pc: {
      pc_id: 2,
      seat_number: 2,
      club: { club_id: 1, name: "Cyber Club Center", address: "1 Main Street" },
      tariff: { tariff_id: 2, name: "Standard", price_per_hour: 150 }
    },
    payment: { amount: 300, payment_method: "cash" }
  },
  {
    _id: 5,
    starts_at: ISODate("2026-03-03T09:00:00+02:00"),
    ends_at: ISODate("2026-03-03T12:00:00+02:00"),
    status: "active",
    client: { client_id: 5, full_name: "Bob Davis", phone: "+380000000305" },
    pc: {
      pc_id: 3,
      seat_number: 3,
      club: { club_id: 1, name: "Cyber Club Center", address: "1 Main Street" },
      tariff: { tariff_id: 3, name: "Evening", price_per_hour: 180 }
    },
    payment: { amount: 540, payment_method: "online" }
  },
  {
    _id: 6,
    starts_at: ISODate("2026-03-05T10:00:00+02:00"),
    ends_at: ISODate("2026-03-05T12:00:00+02:00"),
    status: "active",
    client: { client_id: 6, full_name: "Bella Evans", phone: "+380000000306" },
    pc: {
      pc_id: 4,
      seat_number: 1,
      club: { club_id: 2, name: "Cyber Club Riverside", address: "2 River Street" },
      tariff: { tariff_id: 1, name: "Basic", price_per_hour: 100 }
    },
    payment: { amount: 200, payment_method: "card" }
  },
  {
    _id: 7,
    starts_at: ISODate("2026-03-10T14:00:00+02:00"),
    ends_at: ISODate("2026-03-10T16:00:00+02:00"),
    status: "active",
    client: { client_id: 7, full_name: "Charlie Foster", phone: "+380000000307" },
    pc: {
      pc_id: 5,
      seat_number: 2,
      club: { club_id: 2, name: "Cyber Club Riverside", address: "2 River Street" },
      tariff: { tariff_id: 5, name: "Premium", price_per_hour: 300 }
    },
    payment: null
  },
  {
    _id: 8,
    starts_at: ISODate("2026-03-15T18:00:00+02:00"),
    ends_at: ISODate("2026-03-15T20:00:00+02:00"),
    status: "active",
    client: { client_id: 1, full_name: "Alice Anderson", phone: "+380000000301" },
    pc: {
      pc_id: 6,
      seat_number: 1,
      club: { club_id: 3, name: "Cyber Club Campus", address: "3 Campus Street" },
      tariff: { tariff_id: 2, name: "Standard", price_per_hour: 150 }
    },
    payment: { amount: 300, payment_method: "online" }
  },
  {
    _id: 9,
    starts_at: ISODate("2026-03-31T18:30:00+02:00"),
    ends_at: ISODate("2026-03-31T20:30:00+02:00"),
    status: "active",
    client: { client_id: 2, full_name: "Andrew Baker", phone: "+380000000302" },
    pc: {
      pc_id: 5,
      seat_number: 2,
      club: { club_id: 2, name: "Cyber Club Riverside", address: "2 River Street" },
      tariff: { tariff_id: 5, name: "Premium", price_per_hour: 300 }
    },
    payment: null
  },
  {
    _id: 10,
    starts_at: ISODate("2026-04-05T12:00:00+02:00"),
    ends_at: ISODate("2026-04-05T14:00:00+02:00"),
    status: "active",
    client: { client_id: 3, full_name: "Anna Brown", phone: "+380000000303" },
    pc: {
      pc_id: 6,
      seat_number: 1,
      club: { club_id: 3, name: "Cyber Club Campus", address: "3 Campus Street" },
      tariff: { tariff_id: 2, name: "Standard", price_per_hour: 150 }
    },
    payment: { amount: 300, payment_method: "cash" }
  }
]);

// Expected on the first run: 10.
print("reservation documents:", db.reservations.countDocuments());
