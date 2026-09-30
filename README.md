# Safety

Community alert platform for missing children, missing adults and wanted
persons. People report a disappearance with a photo and a location, authorities
verify the report before it is broadcast, and anyone nearby can submit a
sighting that becomes a public heatmap.

- [`safechild-api/`](safechild-api) — Laravel 13 REST API, admin panel and
  notification fan-out (FCM push + Twilio SMS).
- [`safechild_app/`](safechild_app) — Flutter client (Android, iOS, web).

## Stack

| Layer | Technology |
| --- | --- |
| API | PHP 8.3+, Laravel 13, Sanctum (token auth) |
| Database | MySQL in production, SQLite for local dev |
| Alerts | Firebase Cloud Messaging (push), Twilio (SMS) |
| Client | Flutter, Riverpod, Dio, Geolocator, Image Picker, ML Kit face detection |

## Quick start

Two terminals, backend first.

```bash
# 1. API on http://127.0.0.1:8000
cd safechild-api
composer install
cp .env.example .env
php artisan key:generate
touch database/database.sqlite     # only when using DB_CONNECTION=sqlite
php artisan migrate --seed
php artisan serve
```

```bash
# 2. Flutter client
cd safechild_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

The API client defaults to `http://127.0.0.1:8000/api`, so the `--dart-define`
is only needed when you point the app at another host.

Seeded logins (password `password` for both):

| Role | Email |
| --- | --- |
| Authority | `police@safechild.gov` |
| Parent | `parent@example.com` |

See each subdirectory's README for the full setup.

## How an alert is published

1. Anyone signs up and files a report. It is stored as **pending**
   (`is_verified = false`).
2. Pending alerts are visible only to their author and to authorities, so an
   unverified claim never reaches the public feed or triggers notifications.
3. An authority verifies it (`POST /api/missing-children/{id}/verify`).
4. The app broadcasts FCM push notifications to users around the
   disappearance coordinates, in chunks of 500, and falls back to Twilio SMS for
   users without a push token.

Only the 0 → 1 verification transition broadcasts, so re-verifying an alert
does not spam every phone.

## Security model

- **Authority accounts cannot self-register.** Registering with `role=authority`
  succeeds only for an address listed in `AUTHORITY_EMAILS`. Everyone else is
  created as `parent`.
- **Role checks are Gates, not `role === 'authority'` string comparisons**, so
  they can be reused and tested.
- **Mass assignment is closed.** Only validated fields are persisted, so
  `user_id` and `is_verified` cannot be injected through `POST`/`PUT`.
- **Ownership is enforced** on alerts, sightings and danger zones. A stranger
  gets 403 on someone else's pending alert.
- **Nested user data is trimmed** to `id`, `name` and `role`; the FCM push token
  and phone number are never serialized into an alert response.
- **Auth endpoints are throttled**, password-reset OTPs are locked out after
  repeated attempts, and a password reset revokes all Sanctum tokens and
  sessions.
- Errors are returned as JSON for `/api/*` clients.

## Tests

```bash
cd safechild-api  && ./vendor/bin/pint --test && php artisan test
cd safechild_app  && flutter analyze && flutter test
```

The backend suite covers the authorization rules above as regression tests —
see `safechild-api/tests/Feature/`.

## Notes before deploying

- Set `APP_DEBUG=false`, a real `APP_KEY`, and a MySQL `DB_*` block.
- Supply `FIREBASE_PROJECT` / `FIREBASE_CREDENTIALS` for push and
  `TWILIO_SID` / `TWILIO_AUTH_TOKEN` / `TWILIO_NUMBER` for SMS. Without them
  the API still runs and logs that the channel was skipped.
- Set `AUTHORITY_EMAILS` to your real police/authority addresses.
- Notification fan-out currently runs **synchronously inside the request** that
  verifies an alert. That is fine for a handful of nearby users but will time
  out once the audience grows — move `NotificationService` behind a queued job
  before a real launch.
- Add the platform key files (`google-services.json`, `GoogleService-Info.plist`)
  for FCM on the client.
