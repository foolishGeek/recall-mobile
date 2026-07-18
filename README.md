# recall-mobile

Flutter app for **Recall** — spaced revision. Stack: **Flutter + GetX + MVVM**.
Architecture spec: [`../Roadmap/sprints/ARCHITECTURE.md`](../Roadmap/sprints/ARCHITECTURE.md).
UI source of truth: [`../Design/handover/`](../Design/handover/).

## Running

This repo uses [FVM](https://fvm.app); prefix Flutter/Dart commands with `fvm`.

Environment values are read from a `--dart-define-from-file` JSON (never committed):

```bash
cp config/staging.example.json config/staging.json   # then fill in the secret values
# or for Recall-prod:
cp config/prod.example.json config/prod.json         # then fill from secrets/LOCAL-SECRETS.md
fvm flutter pub get
fvm flutter run --flavor staging --dart-define-from-file=config/staging.json
# prod:
# fvm flutter run --flavor prod --dart-define-from-file=config/prod.json
```

In **VS Code / Cursor** pick **recall (staging)** or **recall (prod)** — `.vscode/launch.json` sets `--flavor` + the matching dart-define file.
In **Android Studio**: add `--flavor staging` (or `prod`) and `--dart-define-from-file=config/…`.

Required keys (see [`../recall-backend/docs/DART-DEFINES.md`](../recall-backend/docs/DART-DEFINES.md)):
`ENV`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SENTRY_DSN`, `REVENUECAT_API_KEY`.
Empty `SENTRY_DSN` is allowed (Sentry init is skipped for local dev).
Empty `REVENUECAT_API_KEY` is allowed (SDK no-ops until IAP is wired).

**Firebase:** no manual swap at run time — Android flavors pick the file automatically. The files are gitignored (source of truth in the backend vault); populate them once:

```bash
cp ../recall-backend/secrets/firebase/google-services.staging.json android/app/src/staging/google-services.json
cp ../recall-backend/secrets/firebase/google-services.prod.json    android/app/src/prod/google-services.json
```

- `src/staging/` → package `app.recall.staging`
- `src/prod/` → package `app.recall`

(iOS `GoogleService-Info.plist` deferred until Apple Developer / APNs — Android-first.)

Cold start: `/splash` → `AuthGate` → sign-in / onboarding / today.

## Launcher icon

Dark ring mark. Source SVGs in `assets/logo/`; regenerate native icons with:

```bash
brew install librsvg   # one-time, for rsvg-convert
rsvg-convert -w 1024 -h 1024 assets/logo/app-icon-dark.svg -o assets/icon/app-icon-1024.png
fvm dart run flutter_launcher_icons
```

## Release signing & AAB

Release builds read signing from `android/key.properties` (gitignored). Without
it, release falls back to the debug keystore, so a real upload key is required
before shipping to Play.

1. Generate an upload keystore (one-time; keep it safe + backed up):

```bash
keytool -genkey -v -keystore recall-mobile/android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Create `android/key.properties` from the template and fill in values:

```bash
cp android/key.properties.example android/key.properties
# edit storePassword / keyPassword / keyAlias / storeFile
```

3. Build the AAB (flavor + dart-defines required):

```bash
# staging → app.recall.staging (Play internal testing)
fvm flutter build appbundle --flavor staging --release \
  --dart-define-from-file=config/staging.json

# prod → app.recall (Play production / closed testing)
fvm flutter build appbundle --flavor prod --release \
  --dart-define-from-file=config/prod.json
```

Outputs: `build/app/outputs/bundle/<flavor>Release/app-<flavor>-release.aab`.
Don't upload a staging AAB to the production Play listing.

## Structure

```
lib/
  main.dart                 # bootstrap → Sentry → runApp(RecallApp)
  app/
    app.dart                # GetMaterialApp (theme, routes, initial binding)
    routes/                 # app_routes.dart (names) + app_pages.dart (GetPage list)
    bindings/               # initial_binding.dart (app-wide singletons)
  core/
    gates/                  # auth_gate, tier_gate
    theme/                  # RecallColors, RecallType, RecallMotion, RecallTheme, RecallShape
    widgets/                # shared UI kit + status widgets
    engine/                 # pure-Dart FSRS (filled S04)
    base/                   # base_controller, view_state
    utils/                  # app_env, recall_haptics
  data/
    models/ services/ repositories/ local/   # filled S03/S05
  modules/<feature>/        # view/ + controller/ + binding/ per screen
```

## Docs

- [Sprints + status](../Roadmap/sprints/STATUS.md) · [Canon decisions](../Roadmap/sprints/CANON-DECISIONS.md)
- [Coverage ledger](../Roadmap/sprints/COVERAGE-LEDGER.md)
