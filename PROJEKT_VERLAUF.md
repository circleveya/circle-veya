# Circle – Projektverlauf & Updates

> **Circle – Erlebnisse verbinden Menschen.**  
> Soziale App für gemeinsame Aktivitäten (nicht Profil-Swiping).  
> **Stand:** v2.6 · 21.07.2026

---

## Tech-Stack

| Bereich | Technologie |
|---------|-------------|
| App | Flutter, Riverpod, go_router |
| Backend | Supabase (Auth, Postgres, PostGIS, Storage, Realtime) |
| Architektur | Feature-first, Clean Architecture |

---

## Was die App heute kann

- **Auth** – Login/Register per E-Mail
- **Entdecken** – Aktivitäten im Feed, Filter (ein-/ausklappbar), Zusagen/Interesse
- **Erstellen** – Aktivität mit optionalem Datum & Titelbild; danach Sprung zu Meine Aktivitäten
- **Meine Events** – eigene Aktivitäten ansehen, **bearbeiten** und **löschen**
- **Aktivitäts-Detail** – Hero-Bild / SliverAppBar, Quiet Luxury
- **Freunde** – suchen, hinzufügen, **Direktnachrichten**
- **Chats** – Gruppenchat pro Event, DM bei Interesse, DM mit Freunden
- **Profil** – ansehen/bearbeiten, Avatar (Web-kompatibel), Cover-Banner, Level, Interessen
- **Galerie** – Fotos nach vergangenen Events
- **B2B** – Community Partner, gesponserte/featured Aktivitäten
- **Standort** – GPS-Radius oder Test-Standort Berlin

---

## Verlauf (Chronologie)

### v1.0 – Grundgerüst
- Flutter-Projekt angelegt
- Supabase: `profiles`, `activities`, `connections`
- Auth, Navigation, Basis-Architektur

### v1.4 – Filter & Partner
- Ort-Typ, Wetter, gesponserte Aktivitäten
- Discover-Filter, Featured-Ranking

### v1.5 – Profil & Galerie
- Profil bearbeiten, Avatar, Interessen
- Post-Event-Galerie (nur Teilnehmer)

### v2.0 – Vision & Stabilisierung
- Produktvision dokumentiert (`VISION.md`, `APP_DOCUMENTATION.md`)
- Matching-Logik: Freunde → Join, Bekannte/Fremde → Interesse
- Chat (Realtime), PostGIS-Discover
- Fixes: Trigger `AFTER INSERT`, idempotente Migrationen, Mock-GPS
- Demo-Seed: `seed_demo_data.sql`

### v2.1 – Freunde
- Tab **Freunde**: Liste, Username-Suche, Freund/Bekannter
- Migration `00008`, Demo-User (`lea_go`, `max_kick`, …)

### v2.2 – UI & optionale Felder
- Optionales Datum & Aktivitätsbild
- Profil-Upload Web-Fix (`uploadBinary`)
- Filter ein-/ausklappbar, farbiges Theme
- Zusagen/Interesse-Button repariert (Gesture-Konflikt)
- Migration `00009` (`image_url`, nullable `date_time`)

### v2.3 – Löschen & Freund-Chat
- Aktivität erstellen: Web-Crash behoben
- Host kann Aktivitäten löschen
- Freund-DMs: Chat-Icon bei Freunden
- Migration `00010` (`get_or_create_friend_chat`)

### v2.4 – Web UI Phase 2 & externe Events
- **3-Spalten-Web-Layout** (Sidebar, Header, rechtes Panel)
- **Entdecken:** Hero + responsives Grid (`DiscoverHero`, `DiscoverGridCard`)
- **Challenges:** Level-System, Fortschrittskarten (Mock bis DB)
- **Profil:** Cover-Banner, Stats-Zeile, Tabs (Über mich / Aktivitäten / Galerie / Bewertungen)
- Badges (Neu, Gesponsert, Automatisch), Avatar-Stack, externe Links (`Zur Quelle`)
- Edge Function `generate-stock-image` (Pexels)
- Edge Function `sync-external-events` (Eventbrite/Ticketmaster, 9 CH-Städte)
- Migration `00011` (externe Events, `discover_activities` v2, `cover_url`)
- Migration `00012` (`external_event_sync_log`)
- Gesamtdokumentation: `DOKUMENTATION.md`

---

## v2.6 – 21.07.2026 (Profiltypen, Team-Status, Chat WhatsApp-Style)

Session-Dokumentation der umgesetzten Schritte (Commits u. a. `7bfd447`, `4d06f0a`).

### 1. Profiltypen: Privatperson vs. Event-Profil

**Ziel:** Normale User und Event-Manager/Geschäfte klar trennen.

| Schritt | Was |
|---------|-----|
| 1.1 | Enum `user_type` erweitert: `standard`, `company` (legacy), **`event`**, **`dev`**, **`marketing`** |
| 1.2 | Trigger `handle_new_user`: liest `user_type` aus Auth-Metadaten (`standard` \| `event` \| `company`); **`dev`/`marketing` nie selbst wählbar** |
| 1.3 | Trigger `protect_profile_user_type`: Team-Status Dev/Marketing nicht per Client änderbar |
| 1.4 | Sponsoring erlaubt für `company` \| `event` \| `dev` |
| 1.5 | Registrierung: Karten **Privatperson** / **Event-Profil** (`register_screen.dart`) |
| 1.6 | Flutter: `ProfileAccountType` in `user_profile.dart` (`isEventOrganizer`, `isDev`, `isMarketing`) |

**Migrationen:**

- `supabase/migrations/20260721250000_profile_account_types.sql`
- `supabase/migrations/20260721260000_marketing_account_type.sql`

### 2. Team-Status (App-Team)

| Username | `user_type` | Badge (UI) | Bedeutung |
|----------|-------------|------------|-----------|
| CircleVeya | `dev` | **Dev** | App-Besitzer / Developer |
| Don | `marketing` | **Marketing** | Marketing / Markenaufbau |

- Badges im Profilkopf wie **Premium** (Icon + Pill, Schatten)
- Layout per `Wrap` → Badges **direkt neben dem Namen** (nicht weit rechts)
- Datei: `profile_view_screen.dart` → `_ProfileStatusBadge`

### 3. Rechtes Web-Panel – Navigation

| Karte | Ziel-Tab |
|-------|----------|
| Deine Challenges | `WebShellDestination.challenges` |
| Freunde online | `WebShellDestination.friends` |

- Mechanismus: `shellDestinationRequestProvider` → `HomeShell`
- Datei: `lib/core/layout/web_right_panel.dart`
- Online-Avatare öffnen weiterhin das Profil

### 4. Chat: Emojis, GIFs, WhatsApp-Stil

| Schritt | Was |
|---------|-----|
| 4.1 | Eingabezeile: **+** (Bild), **Smiley** links, **GIF-Badge** rechts, Senden |
| 4.2 | Icons: `WhatsAppSmileyIcon` + `WhatsAppGifIcon` („GIF“ im Rahmen) |
| 4.3 | Picker: Emoji-Raster + Kategorien; unten Umschalter Smiley \| GIF |
| 4.4 | Kein grauer Hover (`GestureDetector` statt `InkWell`) |
| 4.5 | GIF-Suche: lokaler Katalog + Edge Function `search-gifs` (optional Giphy) |
| 4.6 | GIF senden = URL in Nachricht (`message_type = gif`), kein Upload nötig |
| 4.7 | GIF-Bubbles kompakt (max. ca. 180×140 px) |

**Wichtige Dateien:**

| Datei | Zweck |
|-------|-------|
| `chat_room_screen.dart` | Composer + Picker |
| `chat_emoji_gif_panel.dart` | Emoji-/GIF-Panel |
| `whatsapp_chat_icons.dart` | Smiley- & GIF-Icons |
| `gif_catalog.dart` | Fallback-GIFs mit Tags |
| `gif_search_service.dart` | Suche (Edge + Katalog) |
| `message_bubble.dart` | Darstellung inkl. kleine GIFs |

**Edge Function `search-gifs`:**

```bash
# Optional für volle Giphy-Suche:
supabase secrets set GIPHY_API_KEY=dein-key
# Deploy bereits remote; lokal:
npx supabase functions deploy search-gifs
```

Ohne Key: Client filtert den eingebauten Katalog (z. B. „lol“, „danke“, „party“).

### 5. Deploy (Live)

| Was | Wie |
|-----|-----|
| Frontend | Push auf `main` → Vercel |
| DB | Migrationen remote angewendet (Enum + Trigger + Team-Zuweisung) |
| Edge | `search-gifs` deployed (`verify_jwt: true`) |

---

## Supabase-Migrationen (Reihenfolge)

| Nr. | Datei | Inhalt |
|-----|-------|--------|
| 00000 | `enable_extensions` | PostGIS, pgcrypto |
| 00001 | `create_profiles` | Profile, Avatars |
| 00002 | `create_activities` | Aktivitäten |
| 00003 | `create_connections` | Verbindungen |
| 00004 | `activity_visibility_matching` | Matching, Discover-RPC |
| 00005 | `create_chats` | Chat, DM, Realtime |
| 00006 | `b2b_partner_filters` | Filter, Sponsoring |
| 00007 | `profiles_gallery` | Galerie, Storage |
| 00008 | `friends_connections` | Freunde-RPCs |
| 00009 | `activity_images_optional_date` | Bilder, flexibles Datum |
| 00010 | `friend_direct_messages` | Freund-DMs |
| 00011 | `external_events_and_discover_v2` | Externe Events, Discover v2, Cover |
| 00012 | `external_event_sync_log` | Sync-Protokoll für Event-Aggregation |
| 20260721250000 | `profile_account_types` | `event`/`dev`, Signup-Trigger, Protect, Sponsoring |
| 20260721260000 | `marketing_account_type` | `marketing`, Don → Marketing, Protect erweitert |

Details & Troubleshooting: `DOKUMENTATION.md`, `supabase/README.md`

---

## App starten

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://DEIN-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=DEIN-KEY \
  --dart-define=USE_MOCK_LOCATION=true
```

**Demo-Daten laden** (nach Migrationen):

```sql
SELECT public.seed_demo_data('DEINE-USER-UUID');
```

---

## v2.5 – 10.07.2026 (Session-Update)

### Entdecken / UI
1. Filter in aufklappbares Panel / ModalBottomSheet (Wann, Entfernung, Standort)
2. Gradient-Hero „Find people. Create memories.“ + Event-Suche
3. Suchtext bleibt erhalten bei „keine Ergebnisse“ (Parent-Controller)
4. Globale Header-Suche nur außerhalb Entdecken; Entdecken hat eigenen Hero

### Bilder (Edge Function `fetch-activity-image`)
5. Groq → englisches Keyword → Pexels-Suche
6. Emblem-Fallback bei Fehler; detailliertes Logging
7. Bekanntes Live-Problem: **Pexels HTTP 401** = ungültiger `PEXELS_API_KEY` in Secrets

### Aktivitäten-Erlebnis
8. Detailansicht: voller Hero/`SliverAppBar`, `Hero`-Übergang vom Kartenbild
9. Host kann bearbeiten (Stift): Titel, Ort, Datum, Beschreibung
10. Nach Erstellen: Navigation zu **Meine Aktivitäten** (kein Erstellt-Popup)

### Deploy
- Frontend: Push auf `main` → Vercel
- Edge Functions: `npx supabase functions deploy fetch-activity-image`

---

## Geplant (noch nicht umgesetzt)

- Freundschaftsanfragen (Pending-State)
- Push-Benachrichtigungen
- Premium/IAP-Store-Anbindung (Vorteile teilweise schon live)
- Karte, KI-Empfehlungen, Kalender
- Optional: `GIPHY_API_KEY` für Live-GIF-Suche über Giphy

---

## Weitere Dokumentation

| Datei | Zweck |
|-------|-------|
| `DOKUMENTATION.md` | **Gesamtdokumentation** – Setup, Architektur, Edge Functions |
| `VISION.md` | Produktvision |
| `WEB_UI_STRATEGIE.md` | Web-First UI, Design-Spec, Architektur Stock/Events |
| `APP_DOCUMENTATION.md` | Vollständige technische Doku |
| `supabase/README.md` | DB-Setup & Fehlerhilfe |
| `README.md` | Quickstart |

---

*Kurzübersicht – für Details siehe `APP_DOCUMENTATION.md` Changelog §10.*
