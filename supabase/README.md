# Supabase Setup – Circle

> Produktvision: [`../VISION.md`](../VISION.md) · Vollständige Doku: [`../APP_DOCUMENTATION.md`](../APP_DOCUMENTATION.md)

## 1. Migrationen ausführen

[Supabase Dashboard](https://supabase.com/dashboard) → **SQL Editor**

**Reihenfolge einhalten:**

| Nr. | Datei |
|-----|-------|
| 00000 | `migrations/20260708120000_enable_extensions.sql` |
| 00001 | `migrations/20260708120001_create_profiles.sql` |
| 00002 | `migrations/20260708120002_create_activities.sql` |
| 00003 | `migrations/20260708120003_create_connections.sql` |
| 00004 | `migrations/20260708120004_activity_visibility_matching.sql` |
| 00005 | `migrations/20260708120005_create_chats.sql` |
| 00006 | `migrations/20260708120006_b2b_partner_filters.sql` |
| 00007 | `migrations/20260708120007_profiles_gallery.sql` |
| 00008 | `migrations/20260708120008_friends_connections.sql` |
| 00009 | `migrations/20260708120009_activity_images_optional_date.sql` |
| 00010 | `migrations/20260708120010_friend_direct_messages.sql` |
| 00011 | `migrations/20260708120011_external_events_and_discover_v2.sql` |
| 00012 | `migrations/20260708120012_external_event_sync_log.sql` |
| 00013 | `migrations/20260708130013_phase2_phase3_features.sql` |
| 00014 | `migrations/20260708130014_sidebar_rpc_functions.sql` |

Alternativ: `supabase db push`

> **Hinweis:** Migrationen 00001–00004 sind idempotent (mehrfach ausführbar). Bei Fehlern siehe Abschnitt 3.

---

## 2. Auth

- **Authentication → Providers** → E-Mail/Passwort aktivieren
- Für Entwicklung: E-Mail-Bestätigung optional deaktivieren

---

## 3. Häufige Fehler

| Fehler | Lösung |
|--------|--------|
| `type "geography" does not exist` | `00000` ausführen + `GRANT USAGE ON SCHEMA extensions` |
| `type "geography" does not exist` | Zuerst `fix_postgis_prerequisite.sql` oder Migration `00000` ausführen |
| `type "…" already exists` | Migration teilweise gelaufen → gleiche Datei erneut ausführen |
| `policy "…" already exists` | Aktualisierte `00004` erneut ausführen |
| `activity_participants_activity_id_fkey` | Trigger-Fix: `AFTER INSERT` (siehe `APP_DOCUMENTATION.md` §8.4 D) |
| Spalte `location_type` fehlt | `00006` ausführen |
| Galerie/Interessen fehlen | `00007` ausführen |

Ausführliche Anleitung: **`APP_DOCUMENTATION.md` → Abschnitt 8**

---

## 4. Demo-Testdaten

1. `seed_demo_data.sql` komplett im SQL Editor ausführen
2. Eigene User-ID holen:

```sql
SELECT id, email FROM auth.users ORDER BY created_at DESC LIMIT 5;
```

3. Demo-Daten laden:

```sql
SELECT public.seed_demo_data('eb0f85c8-18ad-4770-8c14-a5a862fcd572');
```

Erzeugt Demo-Freunde (`lea_go`, `max_kick`, …) und Aktivitäten rund um Berlin.

**Freunde in der App:** Tab „Freunde“ → nach `lea` suchen → hinzufügen (falls Seed noch nicht gelaufen: Demo-User erscheinen trotzdem in der Suche).

---

## 5. Realtime (Chat)

Migration `00005` aktiviert Realtime für `messages`.  
Prüfen unter **Database → Replication**, falls Chat nicht live aktualisiert.

---

## 6. App starten

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://DEIN-PROJEKT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=DEIN-KEY
```

- URL **ohne** `/rest/v1/`
- Optional: `--dart-define=USE_MOCK_LOCATION=true` (GPS überspringen)

---

## 7. Storage Buckets (nach 00007 / 00009)

| Bucket | Zweck |
|--------|-------|
| `avatars` | Profilbilder |
| `activity-images` | Titelbilder beim Erstellen (optional) |
| `activity-photos` | Event-Galerie |

---

## 8. Edge Function: Automatische Stock-Bilder (Pexels)

**Pfad:** `functions/generate-stock-image/index.ts`

Setzt `activities.image_url` automatisch per Pexels-Suche, wenn noch kein Bild vorhanden ist.

### Deploy

```bash
# Pexels API-Key als Secret (https://www.pexels.com/api/)
supabase secrets set PEXELS_API_KEY=dein-pexels-key

# Function deployen
supabase functions deploy generate-stock-image
```

`SUPABASE_URL` und `SUPABASE_SERVICE_ROLE_KEY` werden von Supabase automatisch injiziert.

### Auslösen (Database Webhook)

Im Dashboard: **Database → Webhooks → Create**

| Feld | Wert |
|------|------|
| Tabelle | `activities` |
| Events | `INSERT` |
| URL | `https://DEIN-PROJECT.supabase.co/functions/v1/generate-stock-image` |
| HTTP Headers | `Authorization: Bearer DEIN-ANON-ODER-SERVICE-KEY` |

Payload enthält `record` mit der neu eingefügten Zeile. Die Function bricht ab, wenn `image_url` bereits gesetzt ist.

### Manuell testen

```bash
curl -X POST "https://DEIN-PROJECT.supabase.co/functions/v1/generate-stock-image" \
  -H "Authorization: Bearer DEIN-ANON-KEY" \
  -H "Content-Type: application/json" \
  -d '{"record":{"id":"ACTIVITY-UUID","title":"Fussball spielen","image_url":null}}'
```

**Hinweis:** Tabelle heißt `activities` (nicht `circle_events`).

---

## 9. Edge Function: Externe Events synchronisieren

**Pfad:** `functions/sync-external-events/index.ts`  
**Vollständige Doku:** [`../DOKUMENTATION.md`](../DOKUMENTATION.md) §5.2 und §6

Lädt Events aus **Eventbrite** und **Ticketmaster** für die Schweiz und upsertet sie in `activities` mit `source = 'external'`.

### Städte (9 × 50 km Radius)

Zürich, Bern, Basel, Genf, Lausanne, Luzern, Winterthur, St. Gallen, Lugano

### Voraussetzungen

1. Migration `00011` ausgeführt
2. Migration `00012` ausgeführt (Sync-Log, optional aber empfohlen)
3. System-Host `circle_events` angelegt → `setup_external_events_host.sql`
4. Mindestens ein API-Key als Secret

### System-Host anlegen

```bash
# 1. Dashboard → Authentication → Users → Add user
# 2. UUID in setup_external_events_host.sql eintragen
# 3. SQL im Editor ausführen
```

```sql
SELECT public.get_external_events_host_id();  -- darf nicht NULL sein
```

### Deploy

```bash
supabase secrets set EVENTBRITE_API_KEY=dein-eventbrite-token
supabase secrets set TICKETMASTER_API_KEY=dein-ticketmaster-key   # optional

supabase functions deploy sync-external-events
```

`SUPABASE_URL` und `SUPABASE_SERVICE_ROLE_KEY` werden von Supabase automatisch injiziert.

### Cron (empfohlen: alle 6h)

**Dashboard → Integrations → Cron** oder SQL mit `pg_cron` + `pg_net`:

```sql
SELECT cron.schedule(
  'sync-external-events-every-6h',
  '0 */6 * * *',
  $$
  SELECT net.http_post(
    url := 'https://DEIN-PROJECT.supabase.co/functions/v1/sync-external-events',
    headers := '{"Authorization": "Bearer DEIN-SERVICE-ROLE-KEY", "Content-Type": "application/json"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);
```

### Manuell testen

```bash
curl -X POST "https://DEIN-PROJECT.supabase.co/functions/v1/sync-external-events" \
  -H "Authorization: Bearer DEIN-SERVICE-ROLE-KEY"
```

**Erwartete Response:**

```json
{
  "success": true,
  "providers": ["eventbrite"],
  "fetched": 42,
  "inserted": 10,
  "updated": 32,
  "archived": 5,
  "errors": []
}
```

### Sync-Log prüfen

```sql
SELECT * FROM public.external_event_sync_log ORDER BY synced_at DESC LIMIT 5;
```

### In der App

Externe Events erscheinen unter **Entdecken** mit Badge „Automatisch“ und Button **„Zur Quelle“** (öffnet Eventbrite/Ticketmaster).

---

## 10. Migration 00013 – Bugfixes & Phase 2/3 Features

**Datei:** `migrations/20260708130013_phase2_phase3_features.sql`

### Kritische Bugfixes

| Problem | Lösung |
|---------|--------|
| `column reference "id" is ambiguous` in Discover/Feed | `discover_activities` neu mit `#variable_conflict use_column`, qualifizierte Spalten |
| RLS beim Erstellen von Aktivitäten | Policies für INSERT/UPDATE/DELETE/SELECT (eigene Events) explizit gesetzt |
| JOIN `select('*')` in Flutter | `getHostedActivities` nutzt explizite Spaltenliste |

### Neue Tabellen & Spalten

| Objekt | Zweck |
|--------|-------|
| `user_stats` | Level, XP, xp_needed |
| `user_challenges` | Aktive Challenges pro User |
| `reviews` | Bewertungen (1–5 Sterne) |
| `notifications` | In-App-Benachrichtigungen (Realtime) |
| `profiles.is_premium` | Premium-Status |
| `profiles.is_online`, `last_seen` | Online-Präsenz |

### Neue RPCs

| RPC | Zweck |
|-----|-------|
| `get_trending_activities` | Top 3 nach Teilnehmerzahl |
| `get_recommended_activities` | Interessen-Matching |
| `get_online_friends` | Online-Freunde |
| `get_user_level_stats` | Level + Challenges |
| `get_user_rating` | Bewertungs-Schnitt |
| `heartbeat_presence` | Online-Status setzen |
| `simulate_premium` | Premium testweise aktivieren |

### Trigger

- XP bei Aktivität erstellen (+50 Host)
- XP bei Teilnahme (+30 Teilnehmer, +10 Host)
- Level-Up wenn `xp >= xp_needed`
- Notification bei neuer Teilnahme
- Notification bei neuem externen Event in der Nähe (30 km)

### Nach Migration prüfen

```sql
-- Discover ohne ambiguous-id-Fehler
SELECT * FROM public.discover_activities(47.5569, 8.8982, NULL, NULL) LIMIT 3;

-- Stats für eigenen User
SELECT * FROM public.get_user_level_stats();

-- Trending
SELECT * FROM public.get_trending_activities(3);
```

### App-Start (lokale Keys)

```bash
flutter run -d chrome --dart-define-from-file=dart_define.local.json
```

GPS-Fallback: **Frauenfeld, CH** (wenn `USE_MOCK_LOCATION=true` oder Browser-GPS fehlschlägt).

Premium testen: **Einstellungen → „Simulieren“** (ruft `simulate_premium` auf).
