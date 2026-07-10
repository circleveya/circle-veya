# Supabase SQL – Übersicht

## Ordnerstruktur

```
supabase/
├── migrations/     # Schema-Historie (Timestamp-Namen – NICHT umbenennen)
├── scripts/        # Manuelle Ops-/Setup-/Fix-Skripte (SQL Editor)
│   ├── setup/      # Einmalige Einrichtung
│   ├── ops/        # Wartung / Cleanup
│   └── fixes/      # Hotfixes bei Fehlern
└── functions/      # Edge Functions (TypeScript)
```

## scripts/ – manuell im SQL Editor

| Datei | Zweck |
|-------|--------|
| `setup/01_postgis_prerequisite.sql` | PostGIS + pgcrypto aktivieren |
| `setup/02_external_events_host.sql` | System-Host `CircleVeya` anlegen |
| `ops/01_cleanup_demo_data.sql` | Demo-User & Seed-Daten entfernen |
| `ops/02_rename_external_events_host.sql` | Host `circle_events` → `CircleVeya` |
| `fixes/01_volatile_functions.sql` | Fix: non-volatile function + UPDATE |
| `fixes/02_sidebar_rpc_drop.sql` | Sidebar-RPCs droppen vor Neu-Deploy |

## migrations/ – Reihenfolge (CLI / Dashboard)

| Nr. | Datei | Kurzbeschreibung |
|-----|-------|------------------|
| 00000 | `…120000_enable_extensions.sql` | PostGIS, pgcrypto |
| 00001 | `…120001_create_profiles.sql` | Tabelle `profiles` |
| 00002 | `…120002_create_activities.sql` | Tabelle `activities` |
| 00003 | `…120003_create_connections.sql` | Tabelle `connections` |
| 00004 | `…120004_activity_visibility_matching.sql` | Sichtbarkeit, Matching-RPCs |
| 00005 | `…120005_create_chats.sql` | Chats, Messages |
| 00006 | `…120006_b2b_partner_filters.sql` | B2B-Filter, Location/Weather |
| 00007 | `…120007_profiles_gallery.sql` | Interessen, Galerie |
| 00008 | `…120008_friends_connections.sql` | Freunde suchen/hinzufügen |
| 00009 | `…120009_activity_images_optional_date.sql` | Bilder, optionales Datum |
| 00010 | `…120010_friend_direct_messages.sql` | Freund-DMs |
| 00011 | `…120011_external_events_and_discover_v2.sql` | Externe Events in activities (legacy) |
| 00012 | `…120012_external_event_sync_log.sql` | Sync-Log |
| 00013 | `…130013_phase2_phase3_features.sql` | Gamification, Reviews, Notifications |
| 00014 | `…130014_sidebar_rpc_functions.sql` | Sidebar-RPCs |
| 00015 | `…100015_rename_external_events_host.sql` | Host-Rename Migration |
| 00016 | `…110016_discover_activities_pagination.sql` | Discover LIMIT/OFFSET |
| 00017 | `…120017_discover_activities_date_filter.sql` | Discover Datumsfilter |
| 00018 | `…130018_discover_activities_light.sql` | Discover Performance |
| 00019 | `…120019_external_events_cache_and_cleanup.sql` | Cache-Tabelle `external_events` |

> **Hinweis:** Migrationen nicht umbenennen – Timestamps sind für `supabase db push` / History nötig.
