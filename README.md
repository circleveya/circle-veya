# Circle – Erlebnisse verbinden Menschen

Soziale Erlebnis-App: Menschen über **gemeinsame Aktivitäten** verbinden — nicht über oberflächliche Profile.

**Kernfrage:** *„Was möchtest du heute erleben?"*

## Dokumentation

| Datei | Inhalt |
|-------|--------|
| [`DOKUMENTATION.md`](DOKUMENTATION.md) | **Gesamtdokumentation** – Setup, Migrationen, Edge Functions, Event-Aggregation |
| [`VISION.md`](VISION.md) | Produktvision Kurzfassung |
| [`PROJEKT_VERLAUF.md`](PROJEKT_VERLAUF.md) | Chronologie v1.0–v2.4 |
| [`WEB_UI_STRATEGIE.md`](WEB_UI_STRATEGIE.md) | Web-First UI, Design-Spec |
| [`APP_DOCUMENTATION.md`](APP_DOCUMENTATION.md) | Technische Voll-Doku, Troubleshooting |
| [`supabase/README.md`](supabase/README.md) | Datenbank-Setup & Edge Functions |

## Schnellstart

```bash
flutter pub get

flutter run \
  --dart-define=SUPABASE_URL=https://DEIN-PROJEKT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=DEIN-KEY \
  --dart-define=USE_MOCK_LOCATION=true
```

Supabase-Migrationen `00000`–`00012` ausführen, dann optional Demo-Daten:

```sql
SELECT public.seed_demo_data('DEINE-USER-UUID');
```

## Tech-Stack

Flutter · Riverpod · go_router · Supabase (PostgreSQL, Auth, Realtime, Storage)
