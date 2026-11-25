# Rule base: cyber-club reservations

The rules describe one reservation request at a time. `client_under_limit` means the client
has fewer than two active (not cancelled) reservations in the evaluated workload. A request
is accepted only when the club and PC are active, its interval is valid, no active reservation
overlaps the requested interval on that PC, and the client is below the limit.

## 1. Production rules

| Rule | IF | THEN |
|---|---|---|
| P1 | The club is active **and** the selected PC is active. | The PC is operational. |
| P2 | The selected PC is inactive. | The PC is unavailable. |
| P3 | The selected club is inactive. | The club is unavailable. |
| P4 | An active reservation exists for the selected PC whose time range overlaps the requested range. | The requested slot is busy. |
| P5 | The PC is operational, the request interval is valid, and no active reservation overlaps it. | The slot is available. |
| P6 | The client has at least two active reservations. | The client has reached the reservation limit. |
| P7 | The slot is available, the request interval is valid, and the client has fewer than two active reservations. | The reservation may be accepted. |
| P8 | The PC is unavailable, the club is unavailable, the slot is busy, or the client has reached the limit. | The reservation must be refused. |

P1, P4, P5, and P6 can be evaluated from the request and Lab 1 data. P2 and P3 identify
unavailable resources. P5 depends on P1 and P7 depends on P5; P8 depends on P2, P3, P4,
or P6. Thus four rules use conclusions from other rules.

P7 and P8 have opposite conclusions. Their conditions do not overlap: acceptance requires
an available slot and fewer than two active reservations; refusal follows from a busy slot,
an unavailable resource, or at least two active reservations.

## 2. Source of each condition

| Rule | Condition | Source |
|---|---|---|
| P1 | Club is active | `clubs.is_active` |
| P1 | PC is active | `pcs.is_active` |
| P2 | PC is inactive | `pcs.is_active` |
| P3 | Club is inactive | `clubs.is_active` |
| P4 | Existing reservation is active | `reservations.status` |
| P4 | Existing interval overlaps request | `reservations.starts_at`, `reservations.ends_at`; requested interval is entered by the booking clerk |
| P5 | PC is operational | Conclusion of P1 |
| P5 | Requested interval is valid | `reservations.starts_at`, `reservations.ends_at` for existing rows; the new interval is entered by the client and checked by the booking application |
| P5 | No active overlap | Search in `reservations` by `pc_id`, `status`, `starts_at`, and `ends_at` |
| P6 | Client has at least two active reservations | Count rows in `reservations` by `client_id` and `status` |
| P7 | Slot is available | Conclusion of P5 |
| P7 | Requested interval is valid | Booking request entered by the client and checked by the booking application |
| P7 | Client has fewer than two active reservations | Count rows in `reservations` by `client_id` and `status` |
| P8 | PC is unavailable | Conclusion of P2 |
| P8 | Club is unavailable | Conclusion of P3 |
| P8 | Slot is busy | Conclusion of P4 |
| P8 | Client reached limit | Conclusion of P6 |

The schema does not record a pending, not-yet-inserted request. The client supplies its
requested start and end times; the booking application validates `ends_at > starts_at`.
The overlap check must run against current rows at decision time. PostgreSQL's exclusion
constraint remains the authoritative protection against concurrent conflicting inserts.

Rules based only on initial facts: P1, P2, P3, P4, and P6 (5).
Rules using derived conclusions: P5, P7, and P8 (3).

## 3. Forward-chaining examples

### Run 1: a free PC can be reserved

Initial working memory:

| Fact | Value |
|---|---|
| f1 | The club is active. |
| f2 | The selected PC is active. |
| f3 | The requested interval is valid. |
| f4 | No active reservation overlaps this PC and interval. |
| f5 | The client has one active reservation. |
| f6 | The client confirmed the request. |

Initial conflict set: P1.

| Cycle | Rule | New fact |
|---|---|---|
| 1 | P1 | f7: the PC is operational. |
| 2 | P5 | f8: the slot is available. |
| 3 | P7 | f9: the reservation may be accepted. |
| 4 | - | No new fact; fixed point. |

Facts: 6 initially, 9 at the fixed point. P2, P3, P4, P6, and P8 did not fire.

### Run 2: an overlapping booking must be refused

Initial working memory:

| Fact | Value |
|---|---|
| f1 | The club is active. |
| f2 | The selected PC is active. |
| f3 | The requested interval is valid. |
| f4 | An active reservation overlaps this PC and interval. |
| f5 | The client already has two active reservations. |
| f6 | The client confirmed the request. |

Initial conflict set: P1, P4, and P6. Apply them by rule number.

| Cycle | Rule | New fact |
|---|---|---|
| 1 | P1 | f7: the PC is operational. |
| 1 | P4 | f8: the slot is busy. |
| 1 | P6 | f9: the client has reached the limit. |
| 2 | P8 | f10: the reservation must be refused. |
| 3 | - | No new fact; fixed point. |

Facts: 6 initially, 10 at the fixed point. P2, P3, P5, and P7 did not fire.

The rules stayed the same; only the request and database facts changed. A rule not firing is
normal when its condition is absent; it is concerning only if a real situation should trigger a
rule but the required fact or rule source is missing.

## 4. Decision journal example

| Item | Recorded value |
|---|---|
| Decision | Accept one reservation request for an active PC. |
| Facts | f1-f6 from Run 1. |
| Rule-base version | `rules.md`, version 1 (record the Git commit when submitted). |
| Explanation | P1 establishes an operational PC; P5 establishes an available slot; P7 accepts the request because the client has one active reservation. |
| Confirmation | The club booking administrator confirms the decision. |
