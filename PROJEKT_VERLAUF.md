# Circle – Projektverlauf & Updates

> **Circle – Erlebnisse verbinden Menschen.**  
> Soziale App für gemeinsame Aktivitäten (nicht Profil-Swiping).  
> **Stand:** v2.4 · 09.07.2026

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
- **Erstellen** – Aktivität mit optionalem Datum & Titelbild, Sichtbarkeit (Freunde/Bekannte/Fremde)
- **Meine Events** – eigene Aktivitäten ansehen und **löschen**
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

### v2.4 – Web UI Phase 2 & externe Events *(aktuell)*
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

## Geplant (noch nicht umgesetzt)

- Freundschaftsanfragen (Pending-State)
- Push-Benachrichtigungen
- Circle-Gruppen, Challenges (Supabase-Backend), Premium/IAP
- Karte, KI-Empfehlungen, Kalender
- Profil-Tabs Inhalt (Aktivitäten/Galerie/Bewertungen live)

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
