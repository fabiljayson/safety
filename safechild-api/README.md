# Safety API

Laravel 13 REST API for the Safety platform: authentication, missing-person
alerts, sightings, a danger-zone heatmap, an authority admin panel, and the
FCM/SMS notification fan-out.

## Requirements

- PHP **8.3+**
- Composer 2
- SQLite (local, zero-config) or MySQL 8

## Setup

```bash
composer install
cp .env.example .env
php artisan key:generate

# SQLite is the default; create the file so migrations can run.
touch database/database.sqlite

php artisan migrate --seed
php artisan serve            # http://127.0.0.1:8000
```

Seeded accounts, both with password `password`:

| Role | Email |
| --- | --- |
| Authority | `police@safechild.gov` |
| Parent | `parent@example.com` |

To use MySQL instead, set `DB_CONNECTION=mysql` plus the `DB_HOST`, `DB_PORT`,
`DB_DATABASE`, `DB_USERNAME` and `DB_PASSWORD` keys, then re-run
`php artisan migrate --seed`.

## Configuration

| Variable | Purpose |
| --- | --- |
| `AUTHORITY_EMAILS` | Comma-separated addresses allowed to register with the `authority` role. Everyone else registers as `parent`. |
| `FIREBASE_PROJECT`, `FIREBASE_CREDENTIALS` | Firebase Cloud Messaging credentials for push alerts. |
| `TWILIO_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_NUMBER` | Twilio credentials for the SMS fallback. |

Notifications degrade gracefully: if the Firebase or Twilio keys are missing,
the API still succeeds and logs which channel was skipped.

## Endpoints

All `/api/*` routes except `register`, `login`, `forgot-password` and
`reset-password` require a Sanctum bearer token.

| Method | Path | Notes |
| --- | --- | --- |
| `POST` | `/api/register` | Throttled. `role=authority` only honoured for a whitelisted address. |
| `POST` | `/api/login` | Throttled. Returns a personal access token. |
| `POST` | `/api/logout` | Revokes the current token. |
| `GET` | `/api/me` | Current user. |
| `POST` | `/api/forgot-password` | Sends a reset OTP. Locked out after repeated attempts. |
| `POST` | `/api/reset-password` | Consumes the OTP and revokes all tokens and sessions. |
| `GET` | `/api/missing-children` | Verified alerts for everyone; `?my_reports=true` for your own pending ones. |
| `POST` | `/api/missing-children` | Files a report, always starting as pending. |
| `GET` | `/api/missing-children/{id}` | Owner, or any authority. |
| `PUT` | `/api/missing-children/{id}` | Owner (status) or authority (status, `alert_type`, explicit `is_verified`). |
| `POST` | `/api/missing-children/{id}/verify` | Authority only. Broadcasts on the 0 → 1 transition. |
| `GET` | `/api/reports` | Sightings; supports `missing_child_id`. |
| `POST` | `/api/reports` | Submits a sighting (coordinates required). |
| `GET` | `/api/danger-zones` | Verified sightings plus your own pending ones. |
| `POST` | `/api/update-location` | Stores the caller's position for proximity alerts. |
| `POST` | `/api/update-fcm-token` | Stores the device push token. |

The admin panel lives under `/admin/*` and is guarded by the
`EnsureUserIsAuthority` middleware.

Responses are flat JSON (`{ "id": 1, "user": { "id": 2, "name": "..." } }`),
**not** wrapped in an API Resource `data` envelope — the Flutter client reads
the top-level shape.

## Authorization rules

- Pending alerts (`is_verified = false`) are readable only by their author and
  by authorities; they never appear in the public feed.
- `is_verified` cannot be set through `POST`/`PUT` by a citizen — that was the
  privilege-escalation path that let anyone broadcast their own alert. Only the
  authority-gated `/verify` endpoint sets it.
- An omitted `is_verified` is left untouched, so closing an alert as `found`
  does not silently retract it from the public feed.
- Nested user data is restricted to `id`, `name` and `role`. The FCM token and
  phone number are never serialized.

## Tests

```bash
./vendor/bin/pint --test   # code style
php artisan test           # 31 tests
```

`tests/Feature/MissingChildAuthorizationTest.php` and
`tests/Feature/ReportAndAuthHardeningTest.php` lock in the rules above,
including that only the verification transition triggers a broadcast.
