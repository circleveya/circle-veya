# Circle – Gesamtdokumentation

> **Circle – Erlebnisse verbinden Menschen.**  
> Vollständige Dokumentation aller umgesetzten Schritte, Setup-Anleitungen und Architektur.  
> **Stand:** v2.4 · 09.07.2026

---

## Inhaltsverzeichnis

1. [Projektüberblick](#1-projektüberblick)
2. [Tech-Stack & Architektur](#2-tech-stack--architektur)
3. [Komplettes Setup (Schritt für Schritt)](#3-komplettes-setup-schritt-für-schritt)
4. [Datenbank-Migrationen](#4-datenbank-migrationen)
5. [Edge Functions](#5-edge-functions)
6. [Externe Event-Aggregation](#6-externe-event-aggregation)
7. [Flutter-App – Features & Struktur](#7-flutter-app--features--struktur)
8. [Web-UI (3-Spalten-Layout)](#8-web-ui-3-spalten-layout)
9. [Betrieb, Cron & Monitoring](#9-betrieb-cron--monitoring)
10. [Projektverlauf (Chronologie)](#10-projektverlauf-chronologie)
11. [Weitere Dokumentation](#11-weitere-dokumentation)

---

## 1. Projektüberblick

**Circle** ist eine soziale Erlebnis-App. Menschen verbinden sich über **gemeinsame Aktivitäten** – nicht über oberflächliches Profil-Swiping.

| Kernfrage | Antwort |
|-----------|---------|
| Was macht die App? | Aktivitäten entdecken, erstellen, beitreten, chatten |
| Für wen? | Freunde, Bekannte und neue Menschen in der Nähe |
| Fokus Region | Schweiz (externe Events), Demo-Daten Berlin |
| Plattform-Priorität | **Web-First** (`flutter run -d chrome`), Mobile später |

**Supabase-Projekt:** `https://unvmyeqvhnmhlkxtkjgo.supabase.co`  
**Demo-User-UUID:** `eb0f85c8-18ad-4770-8c14-a5a862fcd572`

---

## 2. Tech-Stack & Architektur

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter Web / Mobile                                       │
│  Riverpod · go_router · Feature-first Clean Architecture    │
└──────────────────────────┬──────────────────────────────────┘
                           │ Supabase Client (Anon Key)
┌──────────────────────────▼──────────────────────────────────┐
│  Supabase                                                   │
│  ├── Auth (E-Mail)                                          │
│  ├── PostgreSQL + PostGIS (activities, profiles, …)       │
│  ├── Storage (avatars, activity-images, activity-photos)    │
│  ├── Realtime (Chat-Nachrichten)                            │
│  └── Edge Functions (Deno)                                  │
│       ├── generate-stock-image  → Pexels                    │
│       └── sync-external-events  → Eventbrite/Ticketmaster   │
└─────────────────────────────────────────────────────────────┘
```

| Schicht | Technologie |
|---------|-------------|
| Frontend | Flutter 3.x, Riverpod, go_router |
| Backend | Supabase (Postgres, Auth, Storage, Realtime) |
| Geo | PostGIS (`location_geo`, `discover_activities`) |
| Bilder | User-Upload, Pexels (Edge Function), externe Provider |
| Events | Eventbrite + Ticketmaster → `activities` Cache |

---

## 3. Komplettes Setup (Schritt für Schritt)

### 3.1 Repository & Flutter

```bash
git clone <repo>
cd Circle
flutter pub get
```

### 3.2 Supabase-Migrationen

Im [Supabase Dashboard](https://supabase.com/dashboard) → **SQL Editor** alle Migrationen **in Reihenfolge** ausführen:

| Nr. | Datei |
|-----|-------|
| 00000 | `supabase/migrations/20260708120000_enable_extensions.sql` |
| 00001 | `supabase/migrations/20260708120001_create_profiles.sql` |
| 00002 | `supabase/migrations/20260708120002_create_activities.sql` |
| 00003 | `supabase/migrations/20260708120003_create_connections.sql` |
| 00004 | `supabase/migrations/20260708120004_activity_visibility_matching.sql` |
| 00005 | `supabase/migrations/20260708120005_create_chats.sql` |
| 00006 | `supabase/migrations/20260708120006_b2b_partner_filters.sql` |
| 00007 | `supabase/migrations/20260708120007_profiles_gallery.sql` |
| 00008 | `supabase/migrations/20260708120008_friends_connections.sql` |
| 00009 | `supabase/migrations/20260708120009_activity_images_optional_date.sql` |
| 00010 | `supabase/migrations/20260708120010_friend_direct_messages.sql` |
| 00011 | `supabase/migrations/20260708120011_external_events_and_discover_v2.sql` |
| 00012 | `supabase/migrations/20260708120012_external_event_sync_log.sql` |

Alternativ mit CLI: `supabase db push`

### 3.3 Auth aktivieren

**Authentication → Providers** → E-Mail/Passwort aktivieren.  
Für Entwicklung: E-Mail-Bestätigung optional deaktivieren.

### 3.4 Demo-Daten (optional)

```sql
SELECT public.seed_demo_data('eb0f85c8-18ad-4770-8c14-a5a862fcd572');
```

Erzeugt Demo-Freunde (`lea_go`, `max_kick`, …) und Aktivitäten rund um **Berlin**.

### 3.5 App starten

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://unvmyeqvhnmhlkxtkjgo.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=DEIN-ANON-KEY \
  --dart-define=USE_MOCK_LOCATION=true
```

- URL **ohne** `/rest/v1/`
- `USE_MOCK_LOCATION=true` setzt Test-Standort Berlin (ohne GPS)

### 3.6 Edge Functions deployen

```bash
# Supabase CLI einloggen & Projekt verlinken
supabase login
supabase link --project-ref unvmyeqvhnmhlkxtkjgo

# Secrets
supabase secrets set PEXELS_API_KEY=dein-pexels-key
supabase secrets set EVENTBRITE_API_KEY=dein-eventbrite-token
supabase secrets set TICKETMASTER_API_KEY=dein-ticketmaster-key   # optional

# Deploy
supabase functions deploy generate-stock-image
supabase functions deploy sync-external-events
```

### 3.7 System-Host für externe Events

1. **Authentication → Users → Add user** (z. B. `circle-events@circle.app`)
2. UUID kopieren
3. `supabase/scripts/setup/02_external_events_host.sql` anpassen und im SQL Editor ausführen
4. Prüfen: `SELECT public.get_external_events_host_id();`

### 3.8 Cron für Event-Sync (empfohlen: alle 6h)

Siehe [Abschnitt 9](#9-betrieb-cron--monitoring).

---

## 4. Datenbank-Migrationen

### Übersicht

| Nr. | Inhalt |
|-----|--------|
| 00000 | PostGIS, pgcrypto |
| 00001 | `profiles`, Auth-Trigger |
| 00002 | `activities`, PostGIS-Index |
| 00003 | `connections` (Freund/Bekannter) |
| 00004 | Sichtbarkeit, Matching, `discover_activities` v1 |
| 00005 | Chats, Messages, Realtime |
| 00006 | Filter (`location_type`, `weather_condition`), Sponsoring |
| 00007 | Galerie, Interessen, Storage-Buckets |
| 00008 | Freunde-RPCs (`search_profiles`, `add_friend`, …) |
| 00009 | Optionales Datum/Bild, `activity-images` Bucket |
| 00010 | Freund-DMs (`get_or_create_friend_chat`) |
| 00011 | Externe Events, `discover_activities` v2, `cover_url` |
| 00012 | `external_event_sync_log` (Monitoring) |

### Wichtige Tabellen

**`activities`** – Kern-Entität für Community- und externe Events:

| Spalte | Beschreibung |
|--------|--------------|
| `source` | `user` (Community) oder `external` (Aggregator) |
| `external_id` | ID beim Provider (Eventbrite/Ticketmaster) |
| `external_provider` | `eventbrite`, `ticketmaster`, … |
| `external_url` | Link zur Original-Quelle |
| `image_source` | `user`, `pexels`, `external`, `fallback` |
| `location_geo` | PostGIS-Punkt (lng, lat) |
| `discovery_radius_km` | Sichtbarkeitsradius für Fremde |

**`profiles`** – User-Profile inkl. `cover_url` (Banner), `location` (GPS).

### Wichtige RPCs

| RPC | Zweck |
|-----|-------|
| `discover_activities(lat, lng, …)` | Feed/Entdecken mit Matching & Distanz |
| `join_activity_direct(activity_id)` | Freund tritt direkt bei |
| `express_interest(activity_id)` | Interesse bekunden |
| `get_my_connections()` | Freunde/Bekannte |
| `get_or_create_friend_chat(friend_id)` | Freund-DM |
| `get_external_events_host_id()` | System-Host für externe Events |

### Externe Events in Discover

Migration `00011` erweitert `discover_activities`:

- Externe Events: `viewer_action = 'external_link'` → Button **„Zur Quelle“**
- Sichtbar für alle (`can_view_activity` bypass für `source = external'`)
- Sortierung: Gesponsert → Extern → Datum

---

## 5. Edge Functions

### 5.1 `generate-stock-image` (Pexels)

**Pfad:** `supabase/functions/generate-stock-image/index.ts`

**Zweck:** Setzt `activities.image_url` automatisch, wenn beim Erstellen kein Bild hochgeladen wurde.

**Ablauf:**

1. Trigger: Database Webhook auf `activities` INSERT
2. Keywords aus Titel extrahieren (DE → EN Mapping)
3. Pexels API-Suche
4. `UPDATE activities SET image_url, image_source = 'pexels'`

**Webhook einrichten (Dashboard → Database → Webhooks):**

| Feld | Wert |
|------|------|
| Tabelle | `activities` |
| Events | `INSERT` |
| URL | `https://DEIN-PROJECT.supabase.co/functions/v1/generate-stock-image` |
| Headers | `Authorization: Bearer DEIN-ANON-KEY` |

**Manuell testen:**

```bash
curl -X POST "https://DEIN-PROJECT.supabase.co/functions/v1/generate-stock-image" \
  -H "Authorization: Bearer DEIN-ANON-KEY" \
  -H "Content-Type: application/json" \
  -d '{"record":{"id":"ACTIVITY-UUID","title":"Fussball spielen","image_url":null}}'
```

### 5.2 `sync-external-events` (Event-Aggregation)

**Pfad:** `supabase/functions/sync-external-events/index.ts`

**Zweck:** Lädt Schweizer Events von externen APIs und cached sie in `activities`.

**Provider:**

| Provider | API | Secret |
|----------|-----|--------|
| Eventbrite | `/v3/events/search/` | `EVENTBRITE_API_KEY` |
| Ticketmaster | Discovery API v2 | `TICKETMASTER_API_KEY` |

**Städte (je 50 km Radius):** Zürich, Bern, Basel, Genf, Lausanne, Luzern, Winterthur, St. Gallen, Lugano

**Ablauf pro Aufruf:**

```
1. get_external_events_host_id() → host_id (circle_events)
2. Für jede Stadt parallel: Eventbrite + Ticketmaster abfragen
3. Events normalisieren (einheitliches JSON-Schema)
4. Duplikate entfernen (provider:id)
5. UPSERT in activities (source = external)
6. Vergangene Events archivieren (status = cancelled)
7. Ergebnis in external_event_sync_log schreiben
```

**Response-Beispiel:**

```json
{
  "success": true,
  "started_at": "2026-07-09T09:00:00.000Z",
  "providers": ["eventbrite", "ticketmaster"],
  "cities": 9,
  "fetched": 142,
  "inserted": 38,
  "updated": 104,
  "archived": 12,
  "errors": []
}
```

**Manuell testen:**

```bash
curl -X POST "https://DEIN-PROJECT.supabase.co/functions/v1/sync-external-events" \
  -H "Authorization: Bearer DEIN-SERVICE-ROLE-KEY"
```

---

## 6. Externe Event-Aggregation

### Architektur-Prinzip

> **Kein Live-API-Call pro User.** Externe Events werden zentral synchronisiert und aus Postgres gelesen.

```mermaid
sequenceDiagram
    participant Cron as Supabase Cron (6h)
    participant EF as sync-external-events
    participant EB as Eventbrite API
    participant TM as Ticketmaster API
    participant DB as PostgreSQL
    participant App as Flutter App

    Cron->>EF: POST /sync-external-events
    EF->>EB: Events CH (9 Städte)
    EF->>TM: Events CH (9 Städte)
    EF->>EF: Normalisieren + Deduplizieren
    EF->>DB: UPSERT activities (source=external)
    EF->>DB: Archivieren vergangener Events
    EF->>DB: INSERT external_event_sync_log
    App->>DB: discover_activities(lat, lng)
    DB-->>App: Externe Events + viewer_action=external_link
    App->>App: Badge „Automatisch“, Button „Zur Quelle“
```

### Mapping extern → `activities`

| Externes Feld | DB-Spalte |
|---------------|-----------|
| `title` / `name` | `title` |
| `description` | `description` |
| `start.utc` / `dates.start` | `date_time` |
| Venue lat/lng | `location_geo` |
| Venue name | `location_name` |
| Logo / Image | `image_url` |
| Event-URL | `external_url` |
| Provider + ID | `external_provider`, `external_id` |
| — | `host_id` = `circle_events` |
| — | `source` = `external` |
| — | `visible_to_strangers` = `true` |

### UI-Kennzeichnung in der App

| Element | Umsetzung |
|---------|-----------|
| Badge | „Automatisch“ (lila, `Icons.public`) |
| Button | „Zur Quelle“ statt „Ich bin dabei!“ |
| Aktion | Öffnet `external_url` via `url_launcher` |
| Dateien | `activity_status_badges.dart`, `activity_enums.dart`, `url_utils.dart` |

### API-Keys besorgen

| Provider | Registrierung |
|----------|---------------|
| Eventbrite | [eventbrite.com/platform](https://www.eventbrite.com/platform/) → Private Token |
| Ticketmaster | [developer.ticketmaster.com](https://developer.ticketmaster.com/) → Discovery API Key |
| Pexels | [pexels.com/api](https://www.pexels.com/api/) |

---

## 7. Flutter-App – Features & Struktur

### Was die App heute kann

| Feature | Status |
|---------|--------|
| Auth (Login/Register) | ✅ |
| Entdecken (Hero + Grid, Filter, Suche) | ✅ |
| Feed (Sektionen nach sozialem Kreis) | ✅ |
| Aktivität erstellen (optional Datum/Bild) | ✅ |
| Aktivität löschen (Host) | ✅ |
| Zusagen / Interesse | ✅ |
| Externe Events („Zur Quelle“) | ✅ |
| Freunde suchen & hinzufügen | ✅ |
| Freund-DMs | ✅ |
| Event-Chats (Realtime) | ✅ |
| Profil (Cover, Stats, Tabs, Level) | ✅ |
| Galerie (Post-Event) | ✅ |
| Challenges (Mock UI) | ✅ |
| B2B / Gesponsert | ✅ |
| Web 3-Spalten-Layout (≥900px) | ✅ |

### Verzeichnisstruktur (Auszug)

```
lib/
├── core/
│   ├── layout/          # WebLayoutScaffold, Sidebar, Header, RightPanel
│   ├── theme/           # AppColors, Premium-Gradient
│   └── utils/           # url_utils.dart
├── features/
│   ├── activities/      # Domain, Provider, Cards, Detail
│   ├── challenges/      # Level, Mock-Challenges
│   ├── discovery/       # DiscoverHero, DiscoverGrid
│   ├── feed/            # FeedScreen
│   ├── friends/         # Freunde-Liste, Suche, DM
│   ├── home/            # HomeShell (Web/Mobile Routing)
│   └── profile/         # Cover-Banner, Tabs
```

### Wichtige Dateien

| Datei | Zweck |
|-------|-------|
| `home_shell.dart` | Web-Layout bei `kIsWeb && width >= 900` |
| `discover_feed_screen.dart` | Hero + Grid + externe Links |
| `discover_grid_card.dart` | Kompakte Karten mit Badges |
| `profile_view_screen.dart` | Cover, Stats, Tabs, embedded-Modus |
| `challenges_screen.dart` | Level + Fortschrittskarten |
| `activity_remote_datasource.dart` | RPC-Mapping inkl. `source`, `external_url` |

---

## 8. Web-UI (3-Spalten-Layout)

Design-Referenz: `WEB_UI_STRATEGIE.md` (Screenshots `image_0.jpg`–`image_2.jpg`)

```
┌──────────────┬────────────────────────────┬──────────────┐
│   Sidebar    │     Haupt-Inhalt           │   Widgets    │
│   (~240px)   │     Feed / Entdecken /     │   (~320px)   │
│              │     Profil / Challenges    │              │
└──────────────┴────────────────────────────┴──────────────┘
                    + WebHeader (Suche, Chat, Profil)
```

| Phase | Inhalt | Status |
|-------|--------|--------|
| Phase 1 | 3-Spalten-Grundgerüst, Feed-Route | ✅ |
| Phase 2 | Entdecken Hero+Grid, Profil-Banner, Challenges | ✅ |
| Phase 3 | Badges, Avatar-Stack, externe Links | ✅ |
| Phase 4 | Edge Functions, Migration 00011/00012 | ✅ |
| Phase 5 | Mobile Shell (< 900px) | ⬜ geplant |

---

## 9. Betrieb, Cron & Monitoring

### Cron-Job (pg_cron + pg_net)

Nach Aktivierung von `pg_cron` und `pg_net` im Supabase Dashboard:

```sql
SELECT cron.schedule(
  'sync-external-events-every-6h',
  '0 */6 * * *',
  $$
  SELECT net.http_post(
    url := 'https://unvmyeqvhnmhlkxtkjgo.supabase.co/functions/v1/sync-external-events',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true),
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);
```

> **Hinweis:** Service-Role-Key als Secret in Vault/`app.settings` hinterlegen – niemals im Client.

### Sync-Log prüfen

```sql
SELECT synced_at, providers, fetched, inserted, updated, archived, errors
FROM public.external_event_sync_log
ORDER BY synced_at DESC
LIMIT 10;
```

### Externe Events in der DB prüfen

```sql
SELECT title, external_provider, location_name, date_time, external_url
FROM public.activities
WHERE source = 'external' AND status = 'open'
ORDER BY date_time ASC
LIMIT 20;
```

### Häufige Fehler

| Problem | Lösung |
|---------|--------|
| `circle_events nicht gefunden` | `scripts/setup/02_external_events_host.sql` ausführen |
| `Kein API-Key gesetzt` | `supabase secrets set EVENTBRITE_API_KEY=...` |
| Keine Events im Feed | Migration 00011, Cron/Manuell-Sync, Standort CH-nah |
| Sync-Log leer | Migration 00012 ausführen |
| `discover_activities` Fehler | Migration 00011 (DROP + CREATE) |

---

## 10. Projektverlauf (Chronologie)

| Version | Datum | Highlights |
|---------|-------|------------|
| v1.0 | — | Flutter-Grundgerüst, Auth, Basis-Schema |
| v1.4 | — | Filter, B2B, Sponsoring |
| v1.5 | — | Profil, Galerie |
| v2.0 | 08.07. | Vision, Matching, Chat, PostGIS |
| v2.1 | 08.07. | Freunde-Tab, Demo-Seed |
| v2.2 | 08.07. | Optionales Datum/Bild, UI-Fixes |
| v2.3 | 08.07. | Löschen, Freund-DMs |
| **v2.4** | **09.07.** | **Web UI Phase 2, externe Events, Edge Functions** |

Details: `PROJEKT_VERLAUF.md`

---

## 11. Weitere Dokumentation

| Datei | Inhalt |
|-------|--------|
| [`DOKUMENTATION.md`](DOKUMENTATION.md) | Diese Gesamtdokumentation |
| [`VISION.md`](VISION.md) | Produktvision Kurzfassung |
| [`PROJEKT_VERLAUF.md`](PROJEKT_VERLAUF.md) | Chronologie & Migrationen |
| [`WEB_UI_STRATEGIE.md`](WEB_UI_STRATEGIE.md) | Web-First UI, Design-Spec, Architektur |
| [`APP_DOCUMENTATION.md`](APP_DOCUMENTATION.md) | Technische Voll-Doku, Troubleshooting §8 |
| [`supabase/README.md`](supabase/README.md) | DB-Setup, Edge Functions |
| [`supabase/scripts/setup/02_external_events_host.sql`](supabase/scripts/setup/02_external_events_host.sql) | System-Host anlegen |

---

*Erstellt: 09.07.2026 · Circle v2.4*
