-- Six rows from a fictional additional branch export; all columns arrive as text.
INSERT INTO stage_reservations (
    source_row, reservation_id_raw, client_id_raw, pc_id_raw, club_id_raw,
    starts_at_raw, ends_at_raw, status_raw, paid_amount_raw
)
VALUES
    (1, '90001', '1', '1', '1', '2026-03-20 10:00:00+02', '2026-03-20 12:00:00+02', 'active', ''),
    (2, '90002', '1', '1', '1', 'not-a-date', '2026-03-20 12:00:00+02', 'active', '0'),
    (3, '90001', '1', '1', '1', '2026-03-20 10:00:00+02', '2026-03-20 12:00:00+02', 'active', ''),
    (4, '90004', '', '1', '1', '2026-03-21 10:00:00+02', '2026-03-21 11:00:00+02', 'active', '0'),
    (5, '90005', '1', '1', '1', '2026-03-22 12:00:00+02', '2026-03-22 11:00:00+02', 'active', '0'),
    (6, '90006', '1', '1', '1', '2026-03-23 10:00:00+02', '2026-03-23 11:00:00+02', 'pending', '0');
