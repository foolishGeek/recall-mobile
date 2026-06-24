# recall-mobile

Flutter app for **Recall** — spaced revision. Stack: **Flutter + GetX + MVVM**.
Architecture spec: [`../Roadmap/sprints/ARCHITECTURE.md`](../Roadmap/sprints/ARCHITECTURE.md).
UI source of truth: [`../Design/handover/`](../Design/handover/).

## Running

This repo uses [FVM](https://fvm.app); prefix Flutter/Dart commands with `fvm`.

Environment values are read from a `--dart-define-from-file` JSON (never committed):

```bash
cp config/staging.example.json config/staging.json   # then fill in the secret values
fvm flutter pub get
fvm flutter run --dart-define-from-file=config/staging.json
```

In **VS Code / Cursor** just press Run — `.vscode/launch.json` already passes the file.
In **Android Studio**: Run config → "Additional run args" → `--dart-define-from-file=config/staging.json`.

Required keys (see [`../recall-backend/docs/DART-DEFINES.md`](../recall-backend/docs/DART-DEFINES.md)):
`ENV`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SENTRY_DSN`, `REVENUECAT_API_KEY`.
Empty `SENTRY_DSN` is allowed (Sentry init is skipped for local dev).

Cold start: `/splash` → `AuthGate` → sign-in / onboarding / today.

## Launcher icon

Dark ring mark. Source SVGs in `assets/logo/`; regenerate native icons with:

```bash
brew install librsvg   # one-time, for rsvg-convert
rsvg-convert -w 1024 -h 1024 assets/logo/app-icon-dark.svg -o assets/icon/app-icon-1024.png
fvm dart run flutter_launcher_icons
```

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
