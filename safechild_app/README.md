# Safety — Flutter client

Android, iOS and web client for the Safety platform. Lets anyone report a
disappearance, browse nearby alerts on a map, receive push notifications, and
submit photo sightings with ML Kit face detection.

## Requirements

- Flutter **3.47.4** stable (Dart SDK 3.13.3)
- Android Studio / Xcode, and a running `safechild-api` instance

## Setup

```bash
flutter pub get
flutter run
```

The API defaults to `http://127.0.0.1:8000/api`. Point it elsewhere with a
compile-time define:

```bash
# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api

# iOS simulator or a device on the same network
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api
```

`10.0.2.2` is the host loopback as seen from the Android emulator; `127.0.0.1`
there refers to the emulator itself.

## Configuration

| Define | Default | Purpose |
| --- | --- | --- |
| `API_BASE_URL` | `http://127.0.0.1:8000/api` | REST API root, including the `/api` prefix. |

Push notifications need the Firebase platform files (`android/app/google-services.json`,
`ios/Runner/GoogleService-Info.plist`). They are intentionally not committed.
Without them `main()` logs the failure and the app starts with notifications
disabled.

## Platform permissions

Android permissions are declared in `android/app/src/main/AndroidManifest.xml`.
iOS purpose strings live in `ios/Runner/Info.plist` — `NSLocationWhenInUseUsageDescription`,
`NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`. iOS terminates an
app that touches the camera, photo library or Core Location without them, so
keep these in sync with the features you add.

On **web** there is no permission prompt: browsers expose location only over
HTTPS. Handling degrades to a visible "location unavailable" message with a
retry action instead of throwing.

## Architecture

```
lib/
  main.dart                 app entry, Firebase init, MaterialApp + themes
  models/                   MissingChild (plain model, no code generation)
  services/                 api_service.dart, localization_service.dart,
                            notification_service.dart, theme_provider.dart
  screens/                  auth, home, map, report, child detail, settings, admin
  widgets/                  shared UI (alert cards, badges, ...)
```

State is Riverpod; networking is a single `Dio` client created by
`apiServiceProvider` and disposed with the container.

Notable behaviours:

- **Session expiry** — a 401 clears the stored token and pushes an event on
  `ApiService.sessionExpiredController`, which the auth screen listens for to
  navigate away once instead of racing a second redirect from `build`.
- **Error extraction** — `describeApiError()` in `api_service.dart` is the single
  place that turns a `DioException` into readable text. It only reads the body
  when it really is a `Map`; a misconfigured server answers with an HTML page,
  and indexing that as a Map would throw from inside the caller's `catch` and
  hide the original error.
- **Location** — permission and "location services off" states are caught,
  surfaced in the UI with a retry action, and every `setState` after an `await`
  is guarded by a `mounted` check.
- **No offline cache** — the removed Hive integration was never opened at
  runtime, so no persisted data is lost.

## Tests

```bash
flutter analyze   # must be clean
flutter test
```

`integration_test/e2e_login_test.dart` drives the real login flow; run it with
`flutter test integration_test` against a running API and a booted emulator.

## Localization

English and French strings live in `lib/services/localization_service.dart`.
**English is the default**: on a fresh install the app uses the device language
if it is `en` or `fr`, and English otherwise. Users can switch from the profile
screen, and the choice is persisted.

When adding a key, add it to **both** maps. A missing key falls back to the key
name itself and shows up in the UI as raw snake_case, so
`test/localization_service_test.dart` asserts the two maps stay in parity.

Use the helpers rather than string concatenation for anything that has to vary
by language:

| Helper | Renders |
| --- | --- |
| `tr.ageLabel(5)` | `5 years old` / `5 ans`, using the French singular `an` for one |
| `tr.missingSince(date)` | `Missing since Sep 14, 2026` / `Recherché depuis le 14 sept. 2026` |

Never branch on the language by comparing a translated string
(`tr.translate('home_title') == 'Accueil'`). That silently breaks the moment a
translation is edited. Add a real key instead.

`DateFormat` needs its locale data loaded before use, so `main()` calls
`initializeDateFormatting()` for every supported locale. Without it, `intl`
throws `LocaleDataException` and any localized date crashes the screen.
