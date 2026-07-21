# Supabase Setup – Circle

> Produktvision: [`../VISION.md`](../VISION.md) · Vollständige Doku: [`../APP_DOCUMENTATION.md`](../APP_DOCUMENTATION.md)  
> SQL-Index: [`scripts/README.md`](scripts/README.md)

## Ordnerstruktur

```
supabase/
├── migrations/   # Schema-Historie (Timestamps – nicht umbenennen)
├── scripts/      # Manuelle Setup-/Ops-/Fix-Skripte
│   ├── setup/
│   ├── ops/
│   └── fixes/
└── functions/    # Edge Functions (TypeScript)
```

## 1. Migrationen ausführen

[Supabase Dashboard](https://supabase.com/dashboard) → **SQL Editor**

**Reihenfolge einhalten:** siehe Tabelle in `scripts/README.md` (00000–00019).

Alternativ: `supabase db push`

## 2. Manuelle Skripte

| Pfad | Zweck |
|------|--------|
| `scripts/setup/01_postgis_prerequisite.sql` | PostGIS aktivieren |
| `scripts/setup/02_external_events_host.sql` | Host CircleVeya anlegen |
| `scripts/ops/01_cleanup_demo_data.sql` | Demo-Daten entfernen |
| `scripts/ops/02_rename_external_events_host.sql` | Host umbenennen |
| `scripts/fixes/01_volatile_functions.sql` | VOLATILE-RPC-Fix |
| `scripts/fixes/02_sidebar_rpc_drop.sql` | Sidebar-RPCs droppen |

## 3. Häufige Fehler

| Fehler | Lösung |
|--------|--------|
| `type "geography" does not exist` | `scripts/setup/01_postgis_prerequisite.sql` oder Migration 00000 |
| `UPDATE is not allowed in a non-volatile function` | `scripts/fixes/01_volatile_functions.sql` |

Ausführliche Anleitung: **`APP_DOCUMENTATION.md` → Abschnitt 8** und bisherige Abschnitte unten in der Git-Historie / `scripts/README.md`.

## 4. Edge Functions

- `functions/sync-external-events` → Upsert in `public.external_events`
- `functions/generate-stock-image` → Pexels-Cover für User-Activities
- `functions/fetch-activity-image` → Groq-Keyword + Pexels
- `functions/search-gifs` → Chat-GIF-Suche (optional `GIPHY_API_KEY`)

```bash
npx supabase functions deploy sync-external-events
npx supabase functions deploy search-gifs
# optional:
# supabase secrets set GIPHY_API_KEY=...
```

## 5. App starten

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://DEIN-PROJEKT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=DEIN-KEY
```
