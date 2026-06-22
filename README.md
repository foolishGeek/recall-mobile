# recall-mobile

Flutter app for **Recall**.

## Setup (Prompt 1)

- Flutter 3.x, Dart null-safety
- Flavors: `staging`, `prod` (`app.recall.staging` / `app.recall`)
- Config via `--dart-define`: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `ENV`

## Structure (after P1)

```
lib/
  theme/          # tokens — single source for UI
  engine/         # pure scheduling math (P5)
  data/           # repositories (P2)
  features/       # screens by tab
```

## UI

Pixel-perfect builds **must** match [`../Design/handover/`](../Design/HANDOVER.md).

## Git

Separate repository. Commit meaningful chunks after user approval. Do not push unless asked.

## Docs

- [Roadmap](../Roadmap/README.md)
- [PRD traceability](../Roadmap/PRD-traceability.md)
