# treekr

A loyalty system where shop visits generate planted trees for customers. A physical device detects each visit and sends an HTTP event to the service. Every X visits, a new tree is planted for that customer.

---

## Requirements

- Ruby 4.0+ and Bundler
- Docker (optional)

## Getting started

### Local

```bash
bundle install
bundle exec ruby db/seeds.rb   # optional — populate with sample data
bundle exec ruby app.rb
```

Open `http://localhost:4567`.

### Docker

```bash
docker compose up
```

## Environment variables

| variable          | description                                    | default              |
|-------------------|------------------------------------------------|----------------------|
| `VISITS_PER_TREE` | visits required to plant one tree              | `5`                  |
| `DATABASE_URL`    | Sequel connection string                       | `sqlite://treekr.db` |
| `PORT`            | server port                                    | `4567`               |

> **Note:** `VISITS_PER_TREE` is intentionally not configurable at runtime from the frontend. Changing it requires a server restart and would retroactively affect all historical tree counts — it is a deployment-level decision, not a user-facing setting.

---

## API

All API endpoints are under `/api`. No versioning in this iteration (see [Technical decisions](#technical-decisions)).

### `POST /api/visits`

Records a visit event from a device.

```bash
curl -X POST http://localhost:4567/api/visits \
  -H 'Content-Type: application/json' \
  -d '{"customer_id": "alice_01", "device_id": "door_a"}'
```

**Response `201`**
```json
{
  "id": "alice_01",
  "total_visits": 6,
  "trees_planted": 1,
  "last_connection": "2026-06-19T10:32:00Z"
}
```

**Error responses**
- `400` — missing or blank `customer_id` / `device_id`, or invalid JSON body
- `500` — database error

### `GET /api/customers`

Returns all customers. Intended for devices to resolve customer identities before building visit payloads.

```bash
curl http://localhost:4567/api/customers
```

**Response `200`**
```json
[
  { "id": "alice_01", "total_visits": 20, "trees_planted": 4, "last_connection": "2026-06-19T10:32:00Z" },
  { "id": "bob_02",   "total_visits": 12, "trees_planted": 2, "last_connection": "2026-06-19T09:15:00Z" }
]
```

### `GET /api/customers/:id`

Returns a single customer by ID.

```bash
curl http://localhost:4567/api/customers/alice_01
```

**Response `200`** — same shape as a single element from `GET /api/customers`  
**Response `404`** — `{ "error": "Customer not found" }`

### `GET /api/stats/hourly`

Returns visit counts grouped by hour for the last 24 hours. Always returns exactly 24 buckets — hours with no activity have `visits: 0`.

```bash
curl http://localhost:4567/api/stats/hourly
```

**Response `200`**
```json
[
  { "hour": "2026-06-18T10:00:00Z", "visits": 3 },
  { "hour": "2026-06-18T11:00:00Z", "visits": 0 },
  ...
]
```

---

## Technical decisions

**Sinatra over Rails** — the scope is a handful of endpoints with no server-rendered views, background jobs, or admin interface. Rails would add significant boilerplate and indirection with no benefit. Sinatra lets the solution speak for itself and demonstrates the ability to calibrate the tool to the problem.

**SQLite + Sequel over in-memory storage** — SQLite provides real persistence across restarts and native SQL aggregation for the hourly stats query, with zero operational overhead (no separate process, no network configuration). Sequel is the idiomatic ORM for Sinatra projects: clean query DSL, first-class migrations, and trivial migration to PostgreSQL by changing the connection string alone.

**`trees_planted` is not persisted** — it is derived on the fly as `total_visits / VISITS_PER_TREE` (integer division). Storing it would require keeping it in sync on every write, adding error surface with no real benefit at this data volume. If the dataset grew large enough to make this calculation expensive, it could be denormalised as a deliberate optimisation.

**API is not versioned** — adding `/v1/` prefixes before there is a second version is speculative complexity. The decision is documented here so future maintainers understand it was intentional, not an oversight.

**Repository pattern with dependency injection** — services receive repositories as constructor arguments rather than instantiating them directly. This keeps business logic decoupled from Sequel and makes unit tests possible without touching the database. The repositories are the only layer that knows about Sequel.

**`visited_at` is set server-side** — the device clock cannot be trusted. A misconfigured or manipulated timestamp from a device would corrupt the visit history. The server records `Time.now.utc` at the moment the request is received.

**`customer_id` and `device_id` are strings** — these identifiers come from an external system (the physical device). Imposing an `Integer` type would mean making assumptions about a system outside our scope.

**Built with Claude Code** — this project was developed using [Claude Code](https://claude.com/claude-code) (Anthropic) as a pair programming assistant, driving architecture discussions, TDD cycles, and code review throughout.

---

## Limitations and future evolution

- **No horizontal scaling** — SQLite is single-writer. Migrating to PostgreSQL requires changing only the `DATABASE_URL` connection string; no application code changes are needed.
- **No authentication** — a production deployment would add an API key or similar mechanism to protect the `POST /api/visits` endpoint from arbitrary writes.
- **No pagination** — `GET /api/customers` returns all records. Acceptable at this scale; would need a `limit`/`offset` or cursor strategy as the customer base grows.
- **No device registry** — devices are identified by a free-form string. A device management layer would allow decommissioning devices and associating them with specific locations.
