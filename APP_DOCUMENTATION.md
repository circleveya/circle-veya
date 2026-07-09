# Circle – App-Dokumentation

> **Circle – Erlebnisse verbinden Menschen.**  
> Eine soziale Erlebnis-App, die Menschen nicht über oberflächliche Profile, sondern über **gemeinsame Aktivitäten** zusammenbringt.

**Kernfrage der App:** *„Was möchtest du heute erleben?"* — nicht *„Wen möchtest du kennenlernen?"*

---

## 1. Projekt-Übersicht & Produktvision

### 1.1 Grundidee

**Circle** hilft Menschen, **echte Momente** mit anderen zu erleben. Das Ziel ist nicht, Kontakte zu sammeln, sondern gemeinsame Erinnerungen zu schaffen.

Viele Nutzer haben dasselbe Problem:

- Sie wissen nicht, **wo** sie Menschen kennenlernen können
- Sie finden **niemanden für bestimmte Aktivitäten** (Sport, Kultur, Gaming …)
- Sie haben Freunde, unternehmen aber **zu wenig zusammen**
- Nach einem **Umzug** oder in einer **neuen Stadt** fehlt ein soziales Umfeld

Circle löst das, indem es Menschen mit **passenden Aktivitäten** verbindet — der Fokus liegt auf dem Erlebnis, nicht auf endlosem Chatten ohne Treffen.

### 1.2 So funktioniert Circle (Produktflow)

```
1. Aktivität wählen          2. Passende Menschen finden       3. Erlebnis & Erinnerung
   „Was will ich tun?"    →     Freunde / Bekannte / Neue     →    Treffen + Memory
   Joggen, Kaffee, Gaming      gleiche Region & Interessen        Fotos, Teilnehmer, Ort
```

**Schritt 1 – Aktivität auswählen**  
Der Nutzer startet mit einer Idee, nicht mit einem Profil:

| Kategorie | Beispiele |
|-----------|-----------|
| Sport | Joggen, Fußball, Wandern |
| Social | Kaffee, Kochen, Gaming-Abend |
| Kultur | Kino, Konzerte, Kreativ |
| Lernen | Zusammen lernen, Buchclub |
| Entdecken | Neue Kulturen, Food, Natur |

**Schritt 2 – Circle erstellt Vorschläge**  
Die App sucht in drei Kreisen:

| Kreis | Verhalten |
|-------|-----------|
| **Freunde** | Direkt beitreten |
| **Bekannte** | Interesse bekunden → Host entscheidet |
| **Neue Menschen** | GPS-Radius + ähnliche Interessen → Interesse bekunden |

Beispiel: *„Samstag Wanderung"* — Max, Anna, Luca in gleicher Region mit passenden Interessen.

**Schritt 3 – Aktivitäten statt endloses Schreiben**  
Nach einem Match schlägt Circle konkrete Treffen vor (Ort, Termin, Teilnehmer). Chat dient der **Vorbereitung**, nicht dem Ersatz des Treffens.

### 1.3 Marktpositionierung

| Klassische Apps | Circle |
|-----------------|--------|
| „Wen möchtest du kennenlernen?" | „Was möchtest du heute erleben?" |
| Profil-Swiping | Activity Marketplace |
| Endloser Chat | Konkrete Aktivitäten & Termine |
| Digitale Kontakte | Gemeinsame Erinnerungen |

**Potenzial:** Soziales Netzwerk + Event-App + Freundschaftsplattform — mit Fokus auf **echten Begegnungen**.

### 1.4 Stärken & Herausforderungen

| Vorteile | Herausforderungen |
|----------|-------------------|
| Löst ein reales soziales Problem | Braucht kritische Nutzermasse pro Region |
| Nicht oberflächlich wie klassische Social Apps | Sicherheit & Moderation essentiell |
| Für Freunde, Familie und neue Kontakte | Lokale Vermarktung nötig |
| Hohe tägliche Nutzung möglich | Cold-Start: genug Aktivitäten am Anfang |
| Nutzer erzeugen den Inhalt selbst | |
| Weltweit skalierbar (Aktivitäten sind universell) | |

### 1.5 Hauptfunktionen (Produktvision)

| Feature | Beschreibung | Status |
|---------|--------------|--------|
| **Activity Marketplace** | Übersicht aller Aktivitäten in der Umgebung (Sport, Essen, Gaming, Kultur …); jeder kann Events erstellen | 🔄 MVP |
| **Circle Gruppen** | Dauerhafte Interessengruppen (Laufgruppe, Gaming Circle, Buchclub) mit Chat & Terminen | ⬜ Geplant |
| **Freundschaftsmodus** | Freundesliste, Suche, Freund/Bekannter hinzufügen | ✅ MVP |
| **Memory Feature** | Erinnerungen nach Aktivitäten: Bilder, Teilnehmer, Ort, Momente | 🔄 Teilweise |
| **Circle Challenges** | Gemeinsame Aufgaben, Abzeichen, Level (z. B. „3 neue Restaurants") | ⬜ Geplant |
| **Sicherheit & Vertrauen** | Verifizierte Profile, Bewertungen, Melden, öffentliche Treffpunkte | 🔄 Teilweise |
| **KI-Empfehlungen** | Passende Aktivitäten & Menschen vorschlagen | ⬜ Geplant |
| **B2B / Community Partner** | Verifizierte Unternehmen, gesponserte Events, Featured-Ranking | ✅ MVP |

**Legende:** ✅ umgesetzt · 🔄 teilweise · ⬜ geplant

### 1.6 MVP-Stand (technisch umgesetzt)

Was **heute in der App funktioniert** (Stand v2.2):

| Bereich | Umsetzung |
|---------|-----------|
| **Auth** | E-Mail Login/Register, Session |
| **Activity Marketplace** | Entdecken-Feed, Filter, Aktivität erstellen, Detail |
| **Drei Kreise** | Freunde (Join), Bekannte/Fremde (Interesse), GPS-Radius |
| **Matching** | Interesse bekunden, Annehmen/Ablehnen, Teilnehmerzähler |
| **Chat** | Gruppenchat pro Aktivität, DMs vor Annahme, Realtime |
| **Profile** | Tinder-ähnliche Ansicht, Bio, Alter, Interessen, Avatar |
| **Memory (Basis)** | Post-Event-Galerie (nur Teilnehmer, nur nach Event-Ende) |
| **Partner/B2B** | `user_type = company`, gesponserte Aktivitäten, Featured |
| **Standort** | PostGIS-Radius; Test-Fallback Berlin ohne GPS |
| **Demo-Daten** | `seed_demo_data()` für lokales Testen |

**Noch nicht umgesetzt:** Circle Gruppen, Challenges, Premium/IAP, Bewertungen-UI, Freundschaftsanfragen (Pending), Karte, Push, KI, Kalender.

### 1.7 Monetarisierung (Produktvision – noch nicht implementiert)

| Produkt | Preis | Inhalt |
|---------|-------|--------|
| **Circle Premium** | 6,99 €/Monat | Unbegrenzte Aktivitäten, mehr Vorschläge, erweiterte Suche, Interessen-Matching, Reisemodus, KI-Empfehlungen |
| **Activity Boost** | 1,99 € | 24h mehr Sichtbarkeit für eine Aktivität |
| **Circle Events Premium** | 4,99 € | Größere Gruppen, exklusive Aktivitäten |
| **Circle Memories Plus** | 2,99 €/Monat | Unbegrenzte Erinnerungen, private Alben, Jahresrückblicke |

Technische Umsetzung geplant über **In-App-Purchases** (StoreKit / Play Billing) + Supabase-Flags.

### 1.8 Sicherheit & Vertrauen (Roadmap)

| Maßnahme | Status |
|----------|--------|
| Profil mit Avatar, Bio, Alter | ✅ |
| Bewertungen nur nach Teilnahme | ⬜ DB geplant, UI fehlt |
| Verifizierte Partner (`user_type = company`) | ✅ manuell in Supabase |
| Meldefunktion / Moderation | ⬜ |
| Empfehlung öffentlicher Treffpunkte | ⬜ UX-Hinweis geplant |
| RLS auf allen Tabellen | ✅ |

### 1.9 Kernfunktionen (technische Kurzübersicht)

| Bereich | Beschreibung |
|---------|-------------|
| **Aktivitäten** | Erstellen; Datum/Ort; Sichtbarkeitskreise; Indoor/Outdoor-Filter |
| **Kreise** | Freunde (direkt), Bekannte (Interesse), Fremde (GPS-Radius) |
| **Matching** | Interesse, Annahme/Ablehnung, Teilnehmerverwaltung |
| **Chat** | Gruppenchat + DMs |
| **Profile** | Avatar, Bio, Alter, Interessen |
| **Memory** | Event-Galerie nach Teilnahme (kein Social-Feed) |
| **B2B** | Gesponserte Aktivitäten, Featured-Ranking |
| **Standort** | PostGIS + Mock-Berlin für Tests |

### 1.10 Tech-Stack

| Schicht | Technologie | Begründung |
|---------|-------------|------------|
| **Mobile App** | Flutter 3.x (iOS + Android) | Einheitliche UI, starke Performance, große Community |
| **State Management** | **Riverpod 2.x** (+ `flutter_riverpod`, `riverpod_annotation`) | Typsicher, testbar, weniger Boilerplate als Bloc; gute Async-Unterstützung für Supabase-Streams |
| **Navigation** | `go_router` | Deklarative Deep Links, typsichere Routen |
| **Backend** | **Supabase** (implementiert) | PostgreSQL, Auth, Realtime, Storage, Edge Functions |
| **Auth** | Supabase Auth | E-Mail/Passwort, OAuth (Google, Apple), Magic Link |
| **Datenbank** | PostgreSQL (Supabase) | Relationales Modell, RLS, PostGIS für Geo-Queries |
| **Realtime** | Supabase Realtime | Live-Chat, Teilnehmer-Updates, Interesse-Notifications |
| **Datei-Upload** | Supabase Storage | Profilbilder, Bewertungsfotos, Aktivitätsbilder |
| **Geo** | PostGIS (`geography`) | Radius-Suche für Gleichgesinnte-Aktivitäten |
| **Lokalisierung** | `flutter_localizations` + ARB | Deutsch/Englisch (erweiterbar) |
| **Karten** | `flutter_map` oder `google_maps_flutter` | Aktivitäten auf Karte anzeigen |
| **Push** | Firebase Cloud Messaging (FCM) + Supabase Edge Functions | Benachrichtigungen bei Interesse, Chat, Annahme |
| **Code-Generierung** | `freezed`, `json_serializable`, `riverpod_generator` | Immutable Models, weniger Fehler |
| **Testing** | `flutter_test`, `mocktail`, `integration_test` | Unit, Widget, Integration |

### 1.11 Architektur-Prinzipien

- **Feature-First** mit **Clean-Architecture-Layern** pro Feature (Presentation → Domain → Data)
- **Repository Pattern** als Abstraktionsschicht zu Supabase
- **Dependency Injection** über Riverpod Provider
- **Separation of Concerns**: UI kennt keine SQL-Queries
- **Offline-First** (spätere Phase): lokaler Cache mit `drift` oder `hive`
- **Security by Design**: Row Level Security (RLS) auf allen Tabellen in Supabase

### 1.12 Empfehlung: Riverpod statt Bloc

Für dieses Projekt wird **Riverpod** empfohlen:

- Supabase liefert Streams und Futures – Riverpod `AsyncNotifier` passt natürlich dazu
- Weniger Boilerplate bei vielen kleinen Features (Chat, Matching, Aktivitäten)
- Einfacheres Testing durch überschreibbare Provider
- `riverpod_annotation` reduziert manuelle Provider-Definitionen

Bloc bleibt eine valide Alternative, wenn das Team bereits tiefes Bloc-Wissen hat. Die Ordnerstruktur ist für beides kompatibel.

---

## 2. Ordnerstruktur (Feature-First + Clean Architecture)

### 2.1 Empfehlung

**Feature-First mit Clean-Architecture-Layern** ist optimal für Circle, weil:

- Features (Aktivitäten, Chat, Matching, B2B) klar voneinander getrennt sind
- Teams parallel an Features arbeiten können
- Shared Code zentral in `core/` und `shared/` liegt
- Jedes Feature eigenständig testbar bleibt

### 2.2 Vollständige Projektstruktur

```
circle/
├── APP_DOCUMENTATION.md          # Diese Datei
├── README.md
├── analysis_options.yaml
├── pubspec.yaml
│
├── lib/
│   ├── main.dart                 # App-Einstiegspunkt
│   ├── app.dart                  # MaterialApp, Theme, Router
│   │
│   ├── core/                     # App-übergreifende Infrastruktur
│   │   ├── config/
│   │   │   ├── env.dart                  # Supabase URL, Keys (über --dart-define)
│   │   │   └── app_config.dart
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   └── api_constants.dart
│   │   ├── errors/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── extensions/
│   │   │   ├── context_extensions.dart
│   │   │   └── datetime_extensions.dart
│   │   ├── network/
│   │   │   └── supabase_client.dart      # Singleton Supabase-Client
│   │   ├── router/
│   │   │   ├── app_router.dart
│   │   │   └── route_names.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   └── app_typography.dart
│   │   └── utils/
│   │       ├── validators.dart
│   │       └── geo_utils.dart
│   │
│   ├── shared/                   # Wiederverwendbare UI & Domain-Bausteine
│   │   ├── domain/
│   │   │   └── entities/                 # Basis-Entities (User, Pagination)
│   │   ├── data/
│   │   │   └── models/                   # Shared DTOs
│   │   └── presentation/
│   │       ├── widgets/                  # Buttons, Cards, Loading, Error
│   │       └── providers/                # Globale Provider (Auth-State)
│   │
│   └── features/
│       │
│       ├── auth/                         # Login, Register, OAuth
│       │   ├── data/
│       │   │   ├── datasources/
│       │   │   │   └── auth_remote_datasource.dart
│       │   │   ├── models/
│       │   │   │   └── auth_user_model.dart
│       │   │   └── repositories/
│       │   │       └── auth_repository_impl.dart
│       │   ├── domain/
│       │   │   ├── entities/
│       │   │   │   └── auth_user.dart
│       │   │   ├── repositories/
│       │   │   │   └── auth_repository.dart
│       │   │   └── usecases/
│       │   │       ├── sign_in.dart
│       │   │       ├── sign_up.dart
│       │   │       └── sign_out.dart
│       │   └── presentation/
│       │       ├── providers/
│       │       │   └── auth_provider.dart
│       │       ├── screens/
│       │       │   ├── login_screen.dart
│       │       │   └── register_screen.dart
│       │       └── widgets/
│       │
│       ├── profile/                      # Benutzerprofile
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │
│       ├── activities/                   # Aktivitäten CRUD, Feed, Detail
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │
│       ├── categories/                   # Aktivitätskategorien
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │
│       ├── circles/                      # Freunde, Bekannte, Fremde-Logik
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │
│       ├── matching/                     # Interesse bekunden, Annahme
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │
│       ├── participants/                 # Teilnehmerverwaltung
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │
│       ├── chat/                         # Gruppenchat + DMs
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │
│       ├── reviews/                      # Bewertungen + Foto-Upload
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │
│       ├── discovery/                    # GPS-Radius, Karte, Filter
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │
│       ├── friends/                      # Freundesliste, Anfragen
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │
│       ├── notifications/                # Push + In-App
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       │
│       └── community_partner/            # B2B: Unternehmen, Sponsoring
│           ├── data/
│           ├── domain/
│           └── presentation/
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── l10n/                                 # Lokalisierung (ARB-Dateien)
│   ├── app_de.arb
│   └── app_en.arb
│
├── test/                                 # Unit & Widget Tests
│   ├── features/
│   └── helpers/
│
├── integration_test/                     # E2E Tests
│
└── supabase/                             # Backend (im Repo mitversioniert)
    ├── migrations/                       # SQL-Migrationen
    ├── functions/                        # Edge Functions
    └── seed.sql                          # Testdaten
```

### 2.3 Layer-Verantwortlichkeiten pro Feature

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION (UI)                                      │
│  Screens, Widgets, Riverpod Providers/Notifiers          │
│  → kennt nur Domain (Entities, Use Cases)                 │
├─────────────────────────────────────────────────────────┤
│  DOMAIN (Business Logic)                                │
│  Entities, Repository Interfaces, Use Cases               │
│  → keine Abhängigkeit zu Flutter oder Supabase            │
├─────────────────────────────────────────────────────────┤
│  DATA (Infrastruktur)                                   │
│  Repository Impl, DataSources, Models (DTOs)             │
│  → spricht mit Supabase Client, Storage, Realtime       │
└─────────────────────────────────────────────────────────┘
```

### 2.4 Namenskonventionen

| Element | Konvention | Beispiel |
|---------|-----------|---------|
| Dateien | `snake_case` | `activity_repository.dart` |
| Klassen | `PascalCase` | `ActivityRepository` |
| Provider | `camelCase` + Suffix | `activitiesListProvider` |
| Screens | `*_screen.dart` | `activity_detail_screen.dart` |
| Entities | Substantiv | `Activity`, `ChatMessage` |
| Models (DTO) | `*Model` oder `*Dto` | `ActivityModel` |
| Use Cases | Verb-Phrase | `CreateActivity`, `ExpressInterest` |

---

## 3. Datenmodell-Entwurf (Supabase / PostgreSQL)

### 3.1 Entity-Relationship-Übersicht

```
auth.users (Supabase)
    │
    └── profiles (1:1)
            │
            ├── friendships (n:m, self-referencing)
            ├── activities (1:n, als creator)
            ├── activity_participants (n:m über activities)
            ├── activity_interests (n:m, Interesse bekunden)
            ├── reviews (1:n, als reviewer)
            ├── chat_members (n:m über chats)
            ├── messages (1:n, als sender)
            └── company_members (n:m über companies)

activities
    ├── categories (n:1)
    ├── companies (n:1, optional – gesponsert)
    ├── activity_participants
    ├── activity_interests
    ├── reviews
    └── chats (1:1, Gruppenchat)

chats
    ├── chat_members
    └── messages

companies
    ├── company_members
    └── activities (gesponserte)
```

### 3.2 Tabellen im Detail

#### `profiles` (erweitert auth.users)

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK, FK → `auth.users.id` | Supabase Auth User ID |
| `username` | `text` UNIQUE | Eindeutiger Anzeigename |
| `display_name` | `text` | Anzeigename |
| `avatar_url` | `text` | Supabase Storage URL |
| `bio` | `text` | Kurzbeschreibung |
| `location` | `geography(POINT)` | Letzter bekannter Standort |
| `location_updated_at` | `timestamptz` | Zeitstempel Standort |
| `average_rating` | `numeric(2,1)` | Durchschnittsbewertung (denormalisiert) |
| `review_count` | `int` DEFAULT 0 | Anzahl erhaltener Bewertungen |
| `is_verified_partner` | `boolean` DEFAULT false | B2B-Verifizierung |
| `created_at` | `timestamptz` | Erstellungszeitpunkt |
| `updated_at` | `timestamptz` | Letzte Änderung |

#### `categories`

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `name` | `text` UNIQUE | z. B. „Sport", „Kultur" |
| `slug` | `text` UNIQUE | z. B. `sport`, `kultur` |
| `icon` | `text` | Icon-Identifier |
| `sort_order` | `int` | Sortierung in UI |

#### `companies` (Community Partner / B2B)

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `name` | `text` | Unternehmensname |
| `slug` | `text` UNIQUE | URL-freundlicher Name |
| `description` | `text` | Beschreibung |
| `logo_url` | `text` | Logo in Storage |
| `website` | `text` | Website |
| `address` | `text` | Adresse |
| `location` | `geography(POINT)` | Standort |
| `is_verified` | `boolean` DEFAULT false | Verifizierungsstatus |
| `verified_at` | `timestamptz` | Verifizierungsdatum |
| `subscription_tier` | `text` | `free`, `basic`, `premium` |
| `created_at` | `timestamptz` | |
| `updated_at` | `timestamptz` | |

#### `company_members`

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `company_id` | `uuid` FK → `companies.id` | |
| `profile_id` | `uuid` FK → `profiles.id` | |
| `role` | `text` | `owner`, `admin`, `staff` |
| `created_at` | `timestamptz` | |

**UNIQUE** (`company_id`, `profile_id`)

#### `friendships`

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `requester_id` | `uuid` FK → `profiles.id` | Anfragender |
| `addressee_id` | `uuid` FK → `profiles.id` | Empfänger |
| `status` | `text` | `pending`, `accepted`, `declined`, `blocked` |
| `created_at` | `timestamptz` | |
| `updated_at` | `timestamptz` | |

**UNIQUE** (`requester_id`, `addressee_id`)

#### `activities`

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `creator_id` | `uuid` FK → `profiles.id` | Ersteller |
| `category_id` | `uuid` FK → `categories.id` | Kategorie |
| `company_id` | `uuid` FK → `companies.id` NULL | Optional: gesponsert |
| `title` | `text` | Titel |
| `description` | `text` | Beschreibung |
| `image_url` | `text` | Titelbild |
| `location` | `geography(POINT)` | Veranstaltungsort |
| `location_name` | `text` | Ortsname (lesbar) |
| `starts_at` | `timestamptz` | Startzeit |
| `ends_at` | `timestamptz` | Endzeit |
| `max_participants` | `int` NULL | Teilnehmerlimit (NULL = unbegrenzt) |
| `visibility` | `text` | `friends`, `acquaintances`, `public` |
| `status` | `text` | `draft`, `open`, `fixed`, `completed`, `cancelled` |
| `is_sponsored` | `boolean` DEFAULT false | Gesponserte Aktivität |
| `is_indoor` | `boolean` NULL | Indoor/Outdoor Filter |
| `is_rain_friendly` | `boolean` NULL | Regen-Modus Filter |
| `discovery_radius_km` | `numeric` NULL | Radius für Fremde (nur bei `public`) |
| `fixed_at` | `timestamptz` NULL | Zeitpunkt der Fixierung |
| `created_at` | `timestamptz` | |
| `updated_at` | `timestamptz` | |

**Status-Erklärung:**
- `draft` – Entwurf, nicht sichtbar
- `open` – Offen für Anmeldungen/Interesse
- `fixed` – Fixiert (Gruppenchat aktiv, keine neuen Teilnehmer)
- `completed` – Abgeschlossen (Bewertungen möglich)
- `cancelled` – Abgesagt

**Visibility-Erklärung:**
- `friends` – Nur Freunde, direkte Anmeldung
- `acquaintances` – Freunde + Bekannte (Freundesfreunde), Interesse bekunden
- `public` – Alle im GPS-Radius, Interesse bekunden

#### `activity_participants`

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `activity_id` | `uuid` FK → `activities.id` | |
| `profile_id` | `uuid` FK → `profiles.id` | |
| `status` | `text` | `joined`, `confirmed`, `attended`, `no_show`, `left` |
| `joined_via` | `text` | `direct`, `interest_accepted`, `invited` |
| `joined_at` | `timestamptz` | |
| `confirmed_at` | `timestamptz` NULL | |

**UNIQUE** (`activity_id`, `profile_id`)

#### `activity_interests` (Matches / Interesse)

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `activity_id` | `uuid` FK → `activities.id` | |
| `profile_id` | `uuid` FK → `profiles.id` | |
| `status` | `text` | `pending`, `accepted`, `declined`, `withdrawn` |
| `message` | `text` NULL | Optionale Nachricht beim Interesse |
| `created_at` | `timestamptz` | |
| `responded_at` | `timestamptz` NULL | |

**UNIQUE** (`activity_id`, `profile_id`)

#### `reviews`

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `activity_id` | `uuid` FK → `activities.id` | |
| `reviewer_id` | `uuid` FK → `profiles.id` | Bewertender |
| `reviewee_id` | `uuid` FK → `profiles.id` | Bewerteter (anderer Teilnehmer) |
| `rating` | `int` CHECK (1–5) | Sternebewertung |
| `comment` | `text` NULL | Textbewertung |
| `created_at` | `timestamptz` | |

**UNIQUE** (`activity_id`, `reviewer_id`, `reviewee_id`)

> Bewertungen sind nur möglich, wenn beide User `attended` bei derselben abgeschlossenen Aktivität waren. Wird per RLS + DB-Function erzwungen.

#### `review_photos`

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `review_id` | `uuid` FK → `reviews.id` | |
| `photo_url` | `text` | Storage URL |
| `sort_order` | `int` | Reihenfolge |
| `created_at` | `timestamptz` | |

#### `chats`

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `type` | `text` | `activity_group`, `direct` |
| `activity_id` | `uuid` FK → `activities.id` NULL | Nur bei Gruppenchat |
| `created_at` | `timestamptz` | |
| `updated_at` | `timestamptz` | Letzte Nachricht (denormalisiert) |

**Constraints:**
- `activity_group` → `activity_id` NOT NULL, UNIQUE
- `direct` → `activity_id` NULL

#### `chat_members`

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `chat_id` | `uuid` FK → `chats.id` | |
| `profile_id` | `uuid` FK → `profiles.id` | |
| `joined_at` | `timestamptz` | |
| `last_read_at` | `timestamptz` | Für Unread-Badge |

**UNIQUE** (`chat_id`, `profile_id`)

#### `messages`

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `chat_id` | `uuid` FK → `chats.id` | |
| `sender_id` | `uuid` FK → `profiles.id` | |
| `content` | `text` | Nachrichtentext |
| `message_type` | `text` | `text`, `image`, `system` |
| `metadata` | `jsonb` NULL | Zusatzdaten (Bild-URL etc.) |
| `created_at` | `timestamptz` | |
| `edited_at` | `timestamptz` NULL | |
| `deleted_at` | `timestamptz` NULL | Soft Delete |

#### `notifications`

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| `id` | `uuid` PK | |
| `recipient_id` | `uuid` FK → `profiles.id` | |
| `type` | `text` | `interest`, `interest_accepted`, `friend_request`, `chat_message`, `activity_fixed`, `review_received` |
| `title` | `text` | |
| `body` | `text` | |
| `data` | `jsonb` | Payload (activity_id, chat_id etc.) |
| `is_read` | `boolean` DEFAULT false | |
| `created_at` | `timestamptz` | |

### 3.3 Wichtige Datenbank-Funktionen (PostgreSQL)

| Funktion | Zweck |
|----------|-------|
| `find_activities_in_radius(lat, lng, radius_km)` | GPS-Umkreissuche mit PostGIS |
| `are_friends(user_a, user_b)` | Freundschaftsprüfung |
| `are_acquaintances(user_a, user_b)` | Bekanntschaftsprüfung (Freundesfreund, max. 2 Hops) |
| `can_review(reviewer, reviewee, activity)` | Bewertungsberechtigung prüfen |
| `fix_activity(activity_id)` | Aktivität fixieren + Gruppenchat erstellen |
| `update_profile_rating()` | Trigger: Durchschnittsbewertung aktualisieren |
| `handle_new_user()` | Trigger: Profil bei Auth-Signup anlegen |

### 3.4 Row Level Security (RLS) – Grundprinzipien

| Tabelle | Lesen | Schreiben |
|---------|-------|----------|
| `profiles` | Alle authentifiziert (eingeschränkte Felder) | Nur eigenes Profil |
| `activities` | Basierend auf `visibility` + Freundschaft + Radius | Nur Creator |
| `activity_interests` | Creator + eigene Interessen | Eigene Interessen |
| `activity_participants` | Teilnehmer + Creator | System/Creator |
| `messages` | Nur Chat-Mitglieder | Nur Chat-Mitglieder |
| `reviews` | Öffentlich lesbar | Nur berechtigte Reviewer |
| `companies` | Alle | Nur Company-Members mit Rolle |

### 3.5 Supabase Storage Buckets

| Bucket | Zugriff | Inhalt |
|--------|---------|--------|
| `avatars` | Public read, Owner write | Profilbilder |
| `activity-photos` | Public read, Participant write (nach Event) | Event-Galerie-Fotos |
| `activity-images` | Public read, Creator write | Aktivitätsbilder |
| `review-photos` | Public read, Reviewer write | Bewertungsfotos |
| `company-logos` | Public read, Company-Admin write | Firmenlogos |
| `chat-images` | Authenticated read, Member write | Chat-Bilder |

### 3.6 Realtime-Subscriptions

| Tabelle | Event | Verwendung |
|---------|-------|-----------|
| `messages` | INSERT | Live-Chat |
| `activity_interests` | INSERT, UPDATE | Interesse-Benachrichtigungen |
| `activity_participants` | INSERT, UPDATE | Teilnehmer-Updates |
| `notifications` | INSERT | In-App Notifications |
| `activities` | UPDATE | Statusänderungen (fixiert, abgesagt) |

---

## 4. Entwicklungsphasen – Checkliste

### Phase 0: Projekt-Setup 🔄 (teilweise)

- [x] Flutter-Projekt initialisieren (`flutter create`)
- [x] Ordnerstruktur anlegen (Feature-First)
- [x] Dependencies in `pubspec.yaml` definieren (Riverpod, go_router, supabase_flutter, equatable)
- [x] `analysis_options.yaml` mit lint Rules (very_good_analysis oder flutter_lints)
- [ ] Supabase-Projekt erstellen (Cloud oder lokal)
- [x] PostGIS Extension aktivieren (SQL-Migration vorbereitet)
- [x] Environment-Konfiguration (`--dart-define` für Keys)
- [x] Git-Repository einrichten, `.gitignore` konfigurieren
- [ ] CI/CD Grundgerüst (GitHub Actions: analyze, test, build)

### Phase 1: Backend-Fundament 🔄 (teilweise)

- [x] SQL-Migrationen: `profiles`, Trigger `handle_new_user`
- [x] SQL-Migrationen: `activities` (Basis-Schema)
- [x] SQL-Migrationen: `connections` (Freunde/Bekannte)
- [ ] SQL-Migrationen: `categories` + Seed-Daten
- [x] RLS Policies für `profiles`
- [x] RLS Policies für `activities`
- [x] RLS Policies für `connections`
- [ ] Supabase Auth konfigurieren (E-Mail, Google, Apple)
- [x] Storage Bucket `avatars` + Policies (Migration 00007)
- [x] Storage Bucket `activity-photos` + Policies (Migration 00007)
- [ ] Edge Function: Willkommens-E-Mail (optional)

### Phase 2: Auth & Profile ✅ (MVP)

- [x] Feature `auth`: Login, Register, Logout Screens
- [ ] OAuth-Flows (Google, Apple Sign-In) — *Post-MVP*
- [x] Auth-State Provider (Session-Management)
- [x] Feature `profile`: Profil anzeigen und bearbeiten
- [x] Avatar-Upload (Supabase Storage, Bucket `avatars`)
- [x] Profilfelder: Username, Alter, Bio, Interessen
- [ ] Profil-Setup-Onboarding (Username, Bio) — *optional*
- [ ] Unit Tests: Auth Repository, Profile Use Cases

### Phase 3: Freunde & Sozialer Graph 🔄 (teilweise)

- [x] SQL-Migration: `connections` + RLS (statt `friendships`)
- [x] Feature `friends`: Freundesliste, Suche, Hinzufügen/Entfernen
- [x] DB-RPC: `search_profiles`, `get_my_connections`, `add_friend`, `add_acquaintance`
- [ ] Freundschaftsanfragen mit Pending-State (statt direktem Add)

### Phase 4: Aktivitäten – Kern ✅ (MVP)

- [x] SQL-Migration: `activities` (Basis-Schema) + RLS
- [x] SQL-Migration: `activity_participants`
- [x] Feature `activities`: Aktivität erstellen (Formular)
- [x] Aktivitäten-Feed (Entdecken)
- [x] Aktivitäts-Detail-Screen (inkl. Host-Interessentenliste)
- [ ] Aktivität bearbeiten / löschen (nur Creator)
- [x] Wetter-Kategorie (indoor/outdoor/rain) beim Erstellen
- [ ] Aktivitätsbild-Upload
- [x] Status-Flow: `open` → `full` (bei vollem Event)

### Phase 5: Kreise & Sichtbarkeit ✅ (MVP)

- [x] Feature `circles`: Sichtbarkeitslogik implementieren
- [x] `friends`-Kreis: Direkte Anmeldung durch Freunde
- [x] `acquaintances`-Kreis: Sichtbar für Bekannte
- [x] `strangers`-Kreis: GPS-Radius-basierte Sichtbarkeit
- [x] RLS-Policies für visibility-basierten Zugriff (`can_view_activity`)
- [x] UI: Sichtbarkeits-Auswahl beim Erstellen

### Phase 6: Matching & Teilnahme ✅ (MVP)

- [x] SQL-Migration: `activity_interests` + RLS
- [x] Feature `matching`: Interesse bekunden (Bekannte + Fremde)
- [x] Creator kann Interesse annehmen/ablehnen
- [x] Feature `participants`: Teilnehmerverwaltung (DB + Counter)
- [x] Direkte Anmeldung für Freunde (ohne Interesse-Schritt)
- [ ] Aktivität fixieren (Teilnehmerkreis schließen)
- [ ] DB-Function `fix_activity()` + Gruppenchat-Erstellung
- [ ] Push-Notification bei Interesse / Annahme

### Phase 6b: Profile & Post-Event-Galerie ✅ (MVP)

- [x] SQL-Migration: `profiles.interests`, `activity_photos` + RLS
- [x] DB-Functions: `activity_is_past()`, `can_upload_activity_photo()`
- [x] RPC: `get_profile`, `get_past_activities_for_gallery`, `get_activity_photos`, `register_activity_photo`
- [x] Feature `profile`: Tinder-ähnliche Profilansicht (Avatar, Alter, Bio, Interessen)
- [x] Feature `profile`: Profil bearbeiten + Avatar-Upload
- [x] Profil-Link bei Interessenten (Host sieht Bewerber-Profil)
- [x] Feature `gallery`: Event-Galerie nur für vergangene Events
- [x] Upload nur für Teilnehmer nach Event-Ende (DB + UI)
- [x] Galerie-Grid mit Uploader-Namen, Vollbild-Dialog
- [x] Navigation: `/profile/:id`, `/profile/edit`, `/gallery`, `/activity/:id/gallery`

### Phase 7: Discovery & Karte 🔄 (teilweise)

- [x] PostGIS-Function `discover_activities()` (Radius + Kreise)
- [x] Feature `discovery`: Listen-Feed mit Aktivitäten
- [x] Standort-Berechtigungen (iOS/Android)
- [x] Radius-Filter einstellbar (beim Erstellen, 5–100 km)
- [ ] Kartenansicht mit Aktivitäten
- [ ] Listenansicht + Kartenansicht Toggle
- [x] Filter: Indoor/Outdoor, Wetter (Kälte/Regen/Sonne)

### Phase 8: Chat ✅ (MVP)

- [x] SQL-Migration: `chats`, `chat_participants`, `messages` + RLS
- [x] Supabase Realtime für `messages` aktivieren
- [x] Feature `chat`: Gruppenchat (automatisch ab 2 Teilnehmern)
- [x] Feature `chat`: Direktnachrichten (DMs via `start_dm_chat`)
- [x] Chat-Liste mit letzter Nachricht + Unread-Badge
- [x] Nachricht senden / empfangen (Realtime Stream)
- [ ] Bilder im Chat (Storage `chat-images`)
- [x] `last_read_at` für Unread-Tracking

### Phase 9: Bewertungen ⬜

- [ ] SQL-Migration: `reviews`, `review_photos` + RLS
- [ ] DB-Function `can_review()` + Trigger
- [ ] Feature `reviews`: Bewertung abgeben (nach Teilnahme)
- [ ] Sterne + Text + Foto-Upload
- [ ] Bewertungen auf Profil anzeigen
- [ ] Durchschnittsbewertung (Trigger `update_profile_rating`)
- [ ] Storage Bucket `review-photos`

### Phase 10: Benachrichtigungen ⬜

- [ ] SQL-Migration: `notifications` + RLS
- [ ] Feature `notifications`: In-App Notification Center
- [ ] Firebase Cloud Messaging Setup (iOS + Android)
- [ ] Supabase Edge Function: Push senden bei Events
- [ ] Realtime-Subscription für Notifications
- [ ] Notification-Typen: Interesse, Chat, Freundschaft, Fixierung, Bewertung

### Phase 11: Community Partner (B2B) 🔄 (teilweise)

- [x] `profiles.user_type = company` als Partner-Rolle
- [ ] SQL-Migration: `companies`, `company_members` + RLS (erweitert)
- [ ] Feature `community_partner`: dediziertes Unternehmensprofil
- [ ] Verifizierungs-Flow (Admin-Freigabe)
- [x] Gesponserte Aktivitäten erstellen (`is_sponsored`)
- [x] Erweiterte Filter (Indoor/Outdoor + Kälte/Regen/Sonne)
- [x] Featured-Ranking im Discover-Feed
- [ ] Company-Dashboard (eigene Aktivitäten, Statistiken)
- [ ] Storage Bucket `company-logos`
- [ ] Subscription-Tiers vorbereiten (Stripe-Integration, später)

### Phase 12: Polish & Launch-Vorbereitung ⬜

- [ ] UI/UX Feinschliff, Animationen, Empty States
- [ ] Lokalisierung (DE/EN) finalisieren
- [ ] Dark Mode
- [ ] Error Handling & Offline-Hinweise
- [ ] Performance-Optimierung (Bild-Caching, Pagination)
- [ ] Integration Tests (kritische Flows)
- [ ] App Store / Play Store Assets (Screenshots, Beschreibung)
- [ ] Datenschutzerklärung & AGB
- [ ] Beta-Test (TestFlight / Internal Testing)
- [ ] Monitoring (Sentry/Crashlytics)
- [ ] Production Deployment (Supabase Pro, App Stores)

### Phase 13: Post-Launch (Backlog) ⬜

- [ ] Offline-First mit lokalem Cache (Drift/Hive)
- [ ] Aktivitäts-Empfehlungen (ML-basiert)
- [ ] Kalender-Integration (iCal Export)
- [ ] Aktivitäts-Wiederholung (recurring Events)
- [ ] Admin-Panel (Web, z. B. Flutter Web oder Retool)
- [ ] Analytics Dashboard für Community Partner
- [ ] Stripe-Integration für B2B-Abonnements
- [ ] In-App Reporting / Moderation
- [ ] Mehrsprachigkeit erweitern

---

## 5. Implementierungsstand (Phase 5 – B2B & Filter)

### 5.1 Community Partner Modell

| Konzept | Umsetzung |
|---------|-----------|
| Partner-Rolle | `profiles.user_type = 'company'` |
| Gesponserte Events | `activities.is_sponsored = true` (nur für `company`) |
| Featured Ranking | `discover_activities` sortiert gesponserte Partner-Aktivitäten zuerst |
| UI-Hervorhebung | Goldener Rahmen, „Gesponsert · Partner“-Badge, Verified-Icon |

**Partner werden (aktuell) manuell in Supabase gesetzt:**

```sql
UPDATE profiles SET user_type = 'company' WHERE id = 'USER-UUID';
```

### 5.2 Filter-Struktur

Zwei unabhängige Dimensionen auf `activities`:

| Dimension | Spalte | Werte |
|-----------|--------|-------|
| **Ort** | `location_type` | `indoor`, `outdoor` |
| **Wetter** | `weather_condition` | `cold` (Kälte), `rain` (Regen), `sun` (Sonne) |

**RPC-Parameter `discover_activities`:**

| Parameter | Typ | Optional |
|-----------|-----|----------|
| `p_lat`, `p_lng` | `float` | nein |
| `p_location_type` | `location_type` | ja (NULL = alle) |
| `p_weather_condition` | `weather_condition` | ja (NULL = alle) |

**Ranking-Algorithmus (Featured):**

```sql
ORDER BY (is_sponsored AND user_type = 'company') DESC, date_time ASC
```

### 5.3 Flutter

- `DiscoverFilterBar` – Filter-Chips im Entdecken-Feed
- `discoverFiltersProvider` – State für aktive Filter
- `ActivityCard` – visuelles Featured/Sponsored-Styling
- `CreateActivityScreen` – Partner sehen „Als gesponsert markieren“

**Migration:** `20260708120006_b2b_partner_filters.sql`

---

## 6. Implementierungsstand (Phase 4 – Chat)

### 6.1 Chat DB-Schema

| Tabelle | Beschreibung |
|---------|-------------|
| `chats` | `activity_group` (1 pro Aktivität) oder `direct` (1 pro Interesse) |
| `chat_participants` | Mitglieder mit `last_read_at` für Unread-Count |
| `messages` | Textnachrichten, Realtime-fähig (`REPLICA IDENTITY FULL`) |

**Migration:** `20260708120005_create_chats.sql`

### 6.2 Chat-Logik

```
Teilnehmer tritt bei (direct / accepted)
        │
        ▼
Trigger → ensure_activity_group_chat()
        │   (ab 2 Teilnehmern: Host + 1)
        ▼
Gruppenchat erstellt, alle activity_participants hinzugefügt

Interessent bekundet Interesse (pending)
        │
        ▼
Host klickt "DM starten" → start_dm_chat(interest_id)
        │
        ▼
DM-Chat mit Host + Interessent (vor fester Zusage)
```

### 6.3 Chat RPC-API

| RPC | Zweck | Flutter |
|-----|-------|---------|
| `get_my_chats()` | Chat-Übersicht mit Preview & Unread | `ChatRepository.getChatList()` |
| `start_dm_chat(interest_id)` | DM zwischen Host & Interessent | `ChatRepository.startDmChat()` |
| `get_activity_group_chat_id(activity_id)` | Gruppenchat-ID für Teilnehmer | `ChatRepository.getActivityGroupChatId()` |
| `mark_chat_read(chat_id)` | Unread zurücksetzen | `ChatRepository.markChatRead()` |

**Direkter Zugriff:**

| Operation | Tabelle | Methode |
|-----------|---------|---------|
| Nachricht senden | `messages` | `.from('messages').insert({...})` |
| Nachrichten streamen | `messages` | `.from('messages').stream().eq('chat_id', id)` |

### 6.4 Flutter Chat-Struktur

```
lib/features/chat/
├── data/datasources/chat_remote_datasource.dart
├── domain/entities/chat.dart
└── presentation/
    ├── providers/chat_provider.dart
    ├── screens/chat_list_screen.dart, chat_room_screen.dart
    └── widgets/message_bubble.dart
```

### 6.5 Screens (aktualisiert)

| Screen | Route / Tab | Funktion |
|--------|-------------|----------|
| **Chats** | `/home` Tab 3 | Übersicht aller Chats |
| **Chat-Room** | `/chat/:id` | Echtzeit-Nachrichten via Supabase Stream |
| **Gruppenchat** | Button auf Aktivitäts-Detail | Nur für Teilnehmer |
| **DM starten** | Icon bei Interessent (Host) | Vor Annahme Details klären |

### 6.6 Aktivitäten & Matching (Phase 3 – Referenz)

_Siehe Migration `20260708120004` für `discover_activities`, `join_activity_direct`, `express_activity_interest`._

### 6.7 App starten

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://DEIN-PROJEKT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=DEIN-ANON-KEY
```

**Migrationen:** `00004` (Matching) + `00005` (Chat) + `00006` (B2B) + `00007` (Profile & Galerie) ausführen.

---

## 7. Implementierungsstand (Phase 6 – Profile & Event-Galerie)

### 7.1 Profil

| Screen | Route | Funktion |
|--------|-------|----------|
| **Profil anzeigen** | `/profile/:id` | Großes Profilbild, Alter, Bio, Interessen-Chips |
| **Profil bearbeiten** | `/profile/edit` | Username, Alter, Bio, Interessen, Avatar-Upload |
| **Eigenes Profil** | AppBar → Person-Icon | `?own=true` zeigt Bearbeiten-Button |

**RPC:** `get_profile(p_profile_id)` — liest öffentliche Profilfelder für authentifizierte User.

### 7.2 Post-Event-Galerie (kein Social-Feed)

Upload-Berechtigung wird **serverseitig** erzwungen:

```
can_upload_activity_photo(activity_id)
    ├── activity_is_past(activity_id)     → date_time < NOW(), nicht cancelled
    └── is_activity_participant(...)      → User war Teilnehmer
```

| Screen | Route | Funktion |
|--------|-------|----------|
| **Galerie-Übersicht** | `/gallery` | Vergangene Events mit Foto-Anzahl |
| **Event-Galerie** | `/activity/:id/gallery` | Grid + Upload-FAB (nur wenn berechtigt) |

**Storage:** Bucket `activity-photos` — Pfad `{activity_id}/{user_id}/{timestamp}.ext`

**Migration:** `20260708120007_profiles_gallery.sql`

### 7.3 Flutter-Struktur

```
lib/features/profile/
├── data/datasources/profile_remote_datasource.dart
├── domain/entities/user_profile.dart
└── presentation/screens/profile_view_screen.dart, profile_edit_screen.dart

lib/features/gallery/
├── data/datasources/gallery_remote_datasource.dart
├── domain/entities/gallery.dart
└── presentation/screens/activity_gallery_screen.dart
```

## 8. Entwickler-Handbuch – Stand, Setup & Fehlerbehebung

> **Version 1.6** – Vollständige Übersicht für lokales Testen und Debugging.  
> Siehe auch **Abschnitt 1** (Produktvision) und **Abschnitt 10** (Changelog).

---

### 8.1 Was ist implementiert? (Gesamtüberblick)

| Bereich | Status | Flutter-Feature | Supabase-Migration |
|---------|--------|-----------------|-------------------|
| Projekt-Setup | ✅ | `lib/main.dart`, `lib/app.dart`, Riverpod, go_router | `00000` |
| Auth (E-Mail) | ✅ | `lib/features/auth/` | `00001` (Trigger `handle_new_user`) |
| Profile | ✅ | `lib/features/profile/` | `00001`, `00007` |
| Aktivitäten CRUD | ✅ (ohne Edit/Delete) | `lib/features/activities/` | `00002` |
| Freunde/Bekannte (DB) | ✅ | `connections` via RPC | `00003`, `00004` |
| Matching & Teilnahme | ✅ | Discover, Join, Interesse | `00004` |
| Sichtbarkeitskreise | ✅ | `VisibilitySelector` | `00004` |
| Discovery + Filter | ✅ | `lib/features/discovery/` | `00004`, `00006` |
| B2B / Gesponsert | ✅ | `isCompanyPartnerProvider` | `00006` |
| Chat (Gruppe + DM) | ✅ | `lib/features/chat/` | `00005` |
| Event-Galerie | ✅ | `lib/features/gallery/` | `00007` |
| **Friends-UI** | ✅ | `lib/features/friends/` | `00008` |
| Bewertungen | ⬜ | — | — |
| Push / OAuth | ⬜ | — | — |

---

### 8.2 App starten (lokal)

```bash
flutter pub get

flutter run \
  --dart-define=SUPABASE_URL=https://DEIN-PROJEKT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=dein-publishable-oder-anon-key
```

**Wichtig:**

| Parameter | Richtig | Falsch |
|-----------|---------|--------|
| `SUPABASE_URL` | `https://xxx.supabase.co` | `.../rest/v1/` |
| `SUPABASE_ANON_KEY` | Publishable Key (`sb_publishable_...`) oder anon JWT | Service-Role-Key (geheim!) |

**Optional – GPS überspringen (Tests):**

```bash
--dart-define=USE_MOCK_LOCATION=true
```

Ohne Flag: Bei verweigerter GPS-Berechtigung (besonders **Web/Chrome**) nutzt die App automatisch **Berlin Mitte** (`52.520008, 13.404954`).

Implementierung: `lib/core/location/location_service.dart`

---

### 8.3 Supabase einrichten (Schritt für Schritt)

1. Projekt auf [supabase.com/dashboard](https://supabase.com/dashboard) anlegen
2. **Authentication → Providers** → E-Mail/Passwort aktivieren
3. Migrationen **in Reihenfolge** im SQL Editor ausführen (siehe `supabase/README.md`)
4. Optional: Demo-Daten laden (Abschnitt 8.5)
5. Keys aus **Project Settings → API** in `flutter run` eintragen

**Migrationen – Dateiliste:**

| Nr. | Datei | Inhalt |
|-----|-------|--------|
| 00000 | `enable_extensions.sql` | PostGIS im Schema `extensions` |
| 00001 | `create_profiles.sql` | `profiles`, `handle_new_user`, RLS |
| 00002 | `create_activities.sql` | `activities` Basis |
| 00003 | `create_connections.sql` | Freunde/Bekannte |
| 00004 | `activity_visibility_matching.sql` | Teilnehmer, Interessen, RPCs, Sichtbarkeit |
| 00005 | `create_chats.sql` | Chat + Realtime |
| 00006 | `b2b_partner_filters.sql` | `location_type`, `weather_condition`, Sponsoring |
| 00007 | `profiles_gallery.sql` | `interests`, `activity_photos`, Storage |
| 00008 | `friends_connections.sql` | Freunde suchen/hinzufügen RPCs |

**Prüfen ob alles da ist:**

```sql
-- Tabellen
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Wichtige RPCs
SELECT proname FROM pg_proc
WHERE proname IN (
  'discover_activities', 'join_activity_direct', 'get_profile',
  'seed_demo_data'
);
```

---

### 8.4 Bekannte Fehler & Fixes (Troubleshooting)

#### A) `type "geography" does not exist` (Migration 00004)

**Ursache:** PostGIS nicht aktiv oder `search_path` in Funktionen enthält nicht `extensions`.

**Fix:**

```sql
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;
GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;
```

Migration `00004`/`00006` nutzen `SET search_path = public, extensions` in Geo-Funktionen.

---

#### B) `type "activity_status" already exists` / `relation "..._idx" already exists`

**Ursache:** Migration wurde **teilweise** ausgeführt (SQL Editor committed pro Statement).

**Fix:** Migrationen `00001`–`00004` sind **idempotent** (`IF NOT EXISTS`, `DROP POLICY IF EXISTS`). Einfach **erneut ausführen** – nicht von vorne mit frischer DB, wenn schon Daten da sind.

**Regel:** Immer **00000 zuerst**, dann 00001 → 00007 der Reihe nach.

---

#### C) `policy "Aktivitäten nur bei Sichtbarkeit lesbar" already exists`

**Ursache:** Wie B) – 00004 teilweise gelaufen.

**Fix:** Aktualisierte `00004` erneut ausführen (enthält `DROP POLICY IF EXISTS`).

---

#### D) `activity_participants_activity_id_fkey` beim Aktivität erstellen

**Ursache:** Trigger `add_host_as_participant` lief als `BEFORE INSERT` – Eintrag in `activity_participants` **bevor** die Aktivität existiert.

**Fix (einmalig im SQL Editor):**

```sql
CREATE OR REPLACE FUNCTION public.add_host_as_participant()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.activity_participants (activity_id, profile_id, joined_via)
    VALUES (NEW.id, NEW.host_id, 'host');

    UPDATE public.activities
    SET current_participants = 1
    WHERE id = NEW.id;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS activities_add_host_participant ON public.activities;
CREATE TRIGGER activities_add_host_participant
    AFTER INSERT ON public.activities
    FOR EACH ROW
    EXECUTE FUNCTION public.add_host_as_participant();
```

---

#### E) `Standortberechtigung verweigert` / Entdecken leer

**Ursache:** Web-Browser oder GPS deaktiviert.

**Fix:** App neu starten – Fallback Berlin ist eingebaut. Banner „Test-Standort Berlin“ im Entdecken-Tab ist normal.

---

#### F) Aktivität erstellen schlägt fehl (Spalte fehlt)

**Ursache:** Migration `00006` nicht ausgeführt → Spalten `location_type`, `weather_condition` fehlen.

**Fix:** `00006` und `00007` nachziehen.

---

#### G) Keine Aktivitäten im Entdecken-Feed

**Checkliste:**

1. Eingeloggt?
2. Demo-Daten geladen? (8.5)
3. Entdecken-Tab pull-to-refresh
4. Filter zurücksetzen
5. Demo-Aktivitäten liegen um **Berlin** – Mock-GPS muss aktiv sein

---

### 8.5 Demo-Testdaten

Datei: `supabase/seed_demo_data.sql`

```sql
-- 1) Gesamte seed_demo_data.sql einmal ausführen (legt Funktion an)
-- 2) Dann:
SELECT public.seed_demo_data('eb0f85c8-18ad-4770-8c14-a5a862fcd572');
-- Eigene UUID: SELECT id, email FROM auth.users ORDER BY created_at DESC;
```

**Erzeugt:**

| Demo-User | Rolle | Aktivität im Feed |
|-----------|-------|-------------------|
| `lea_go` | Freundin | Go-Kart – Direkt beitreten, 3 Teilnehmer |
| `max_kick` | Freund | Fußball – 6/10 Teilnehmer |
| `sara_boards` | Bekannte | Brettspiel – Interesse bekunden |
| `tom_berlin` | Fremder | Open-Air – GPS-Radius |
| `kart_center` | Partner (`company`) | Gesponsert / Featured |

Zusätzlich: **`[Demo] Grillabend`** unter **Meine Events** mit 3 Interessenten (zum Testen der Host-Ansicht).

---

### 8.6 Navigation & Routen

| Route | Screen | Tab / Zugang |
|-------|--------|--------------|
| `/login` | Login | — |
| `/register` | Registrierung | — |
| `/home` | HomeShell | Bottom Nav |
| `/activity/:id` | Aktivitäts-Detail | Feed / Meine Events |
| `/chat/:id` | Chat-Raum | Chats |
| `/profile/:id` | Profil anzeigen | AppBar Person-Icon, Interessenten-Tile |
| `/profile/edit` | Profil bearbeiten | Eigenes Profil |
| `/gallery` | Event-Galerien-Übersicht | Meine Events |
| `/activity/:id/gallery` | Event-Galerie | Vergangene Events |

| **Home-Tabs:** Entdecken · Erstellen · Meine Events · **Freunde** · Chats

---

### 8.7 Wichtige RPC-Funktionen (App ↔ DB)

| RPC | Flutter-Aufruf | Zweck |
|-----|--------------|-------|
| `discover_activities(lat, lng, ...)` | `ActivityRepository.discoverActivities` | Entdecken-Feed |
| `join_activity_direct` | `ActivityRepository.joinDirect` | Freunde beitreten |
| `express_activity_interest` | `ActivityRepository.expressInterest` | Interesse bekunden |
| `accept/decline_activity_interest` | `ActivityActionsController` | Host entscheidet |
| `get_activity_interests` | `activityInterestsProvider` | Interessentenliste |
| `get_my_chats` | `ChatRepository.getChatList` | Chat-Übersicht |
| `start_dm_chat` | `ChatRepository.startDmChat` | DM vor Annahme |
| `get_profile` | `ProfileRepository.getProfile` | Profil anzeigen |
| `get_past_activities_for_gallery` | `GalleryRepository` | Galerie-Übersicht |
| `can_upload_activity_photo` | `canUploadPhotoProvider` | Upload-Berechtigung |
| `seed_demo_data(uuid)` | manuell SQL | Demo-Daten |
| `search_profiles` | `FriendsRepository.searchProfiles` | User suchen |
| `get_my_connections` | `FriendsRepository.getMyConnections` | Freundesliste |
| `add_friend` / `add_acquaintance` | `FriendsActionsController` | Verbindung hinzufügen |
| `remove_connection` | `FriendsActionsController` | Verbindung entfernen |

---

### 8.8 Projektstruktur (Flutter)

```
lib/
├── core/
│   ├── config/env.dart              # SUPABASE_URL, ANON_KEY, USE_MOCK_LOCATION
│   ├── location/location_service.dart
│   ├── network/supabase_client.dart
│   └── router/app_router.dart
├── features/
│   ├── auth/                        # Login, Register
│   ├── activities/                  # Erstellen, Detail, Cards
│   ├── discovery/                   # Entdecken-Feed
│   ├── chat/                        # Liste + Raum
│   ├── profile/                     # Anzeigen + Bearbeiten
│   ├── friends/                     # Freundesliste & Suche
│   ├── gallery/                     # Post-Event-Fotos
│   └── home/                        # HomeShell (Bottom Nav, 5 Tabs)
└── main.dart
```

**State Management:** Riverpod (`*Provider`, `*Controller`)  
**Tests:** `test/widget_test.dart` (Start ohne Supabase-Config)

---

### 8.9 Manuelle Admin-Befehle (Supabase)

**Community Partner setzen:**

```sql
UPDATE profiles SET user_type = 'company' WHERE id = 'USER-UUID';
```

**Trigger-Status prüfen:**

```sql
SELECT tgname, tgtype, tgenabled
FROM pg_trigger
WHERE tgname = 'activities_add_host_participant';
-- tgtype: sollte AFTER INSERT sein (nach Fix)
```

**Alle Demo-Daten neu laden:**

```sql
SELECT public.seed_demo_data('DEINE-USER-UUID');
-- Idempotent – überschreibt Demo-Aktivitäten
```

---

## 9. Nächste Schritte

1. **Bewertungen** – Sterne + Text nach Teilnahme (Phase 9)
2. **Freundschaftsanfragen** – Pending-State statt direktem Add
3. **Push-Benachrichtigungen** bei neuen Chat-Nachrichten
4. **Partner-Verifizierung** – Admin-Flow für `user_type = company`

---

## 10. Änderungsprotokoll (Changelog)

### v2.4 – Web UI Phase 2 & externe Event-Aggregation (09.07.2026)

| Änderung | Details |
|----------|---------|
| Web-Layout | 3-Spalten (Sidebar, Header, Right Panel), Breakpoint ≥ 900px |
| Entdecken | Hero + responsives Grid, Suche, Badges |
| Profil | Cover-Banner, Stats, Tabs, Level-Badge |
| Challenges | Level-System, Fortschrittskarten (Mock) |
| Externe Events | Migration `00011`, Edge Function `sync-external-events` |
| Stock-Bilder | Edge Function `generate-stock-image` (Pexels) |
| Sync-Log | Migration `00012`, Tabelle `external_event_sync_log` |

**Supabase ausführen:**

```sql
-- 1) Migration 00011 + 00012
-- 2) System-Host: supabase/setup_external_events_host.sql
-- 3) Edge Functions deployen (siehe DOKUMENTATION.md §3.6)
```

**Gesamtdokumentation:** `DOKUMENTATION.md`

### v2.3 – Erstellen-Fix, Löschen, Freund-DMs (08.07.2026)

| Änderung | Details |
|----------|---------|
| Aktivität erstellen | Web-Crash behoben (`bool?` bei SwitchListTile) |
| Aktivität löschen | Host kann eigene Events unter „Meine Events“ / Detail löschen |
| Freund-DMs | Migration `00010`, RPC `get_or_create_friend_chat`, Chat-Icon bei Freunden |

**Supabase:** `20260708120010_friend_direct_messages.sql` im SQL Editor ausführen.

### v2.2 – UI-Fixes & optionale Felder (08.07.2026)

**Behoben:**

| Problem | Lösung |
|---------|--------|
| Zusagen / Interesse-Button reagiert nicht | `ActivityCard`: Aktions-Button außerhalb des `InkWell` (kein Gesture-Konflikt, v. a. Web) |
| Profilbild-Upload schlägt fehl (Web) | Upload über `uploadBinary` + `XFile.readAsBytes()` statt `dart:io` `File` |
| Filter immer sichtbar | `DiscoverFilterBar` ein-/ausklappbar mit farbigem Gradient |
| Datum Pflichtfeld | `date_time` optional in DB + Toggle „Termin festlegen“ |
| Kein Aktivitätsbild | Optionales Titelbild beim Erstellen, Anzeige in der Karte |

**Neu (Backend – Migration `00009`):**

- Spalte `activities.image_url`, `date_time` nullable
- Storage-Bucket `activity-images`
- `discover_activities` mit `image_url`, Status `open`/`full`
- `join_activity_direct` synchronisiert `current_participants`

**Supabase ausführen:** Migration `20260708120009_activity_images_optional_date.sql` im SQL Editor.

### v2.1 – Freunde-Feature & Demo (08.07.2026)

**Neu:**

| Änderung | Details |
|----------|---------|
| Migration `00008` | RPCs: `search_profiles`, `get_my_connections`, `add_friend`, `add_acquaintance`, `remove_connection` |
| Feature `friends` | Tab „Freunde“: Liste, Username-Suche, Freund/Bekannter hinzufügen |
| HomeShell | 5. Tab „Freunde“ zwischen Events und Chats |
| Demo-Seed | Vorkonfiguriert für User `eb0f85c8-18ad-4770-8c14-a5a862fcd572` |

**Supabase ausführen:**

```sql
-- 1) Migration 00008 (friends_connections.sql)
-- 2) Demo-Daten:
SELECT public.seed_demo_data('eb0f85c8-18ad-4770-8c14-a5a862fcd572');
```

**Demo-User zum Suchen:** `lea_go`, `max_kick`, `sara_boards`, `tom_berlin`, `kart_center`

### v2.0 – Produktvision & Dokumentation (08.07.2026)

**Produktdokumentation erweitert:**

- Abschnitt **1.1–1.8** neu: Grundidee, Nutzerproblem, 3-Schritte-Flow, Marktpositionierung
- **Feature-Roadmap** mit Status (✅/🔄/⬜): Activity Marketplace, Circle Gruppen, Memory, Challenges, Sicherheit
- **Monetarisierung** dokumentiert (Premium, Boost, Events, Memories Plus) — noch nicht implementiert
- **MVP-Stand** (1.6) klar von Produktvision abgegrenzt
- Tagline: *„Erlebnisse verbinden Menschen"*

**Bereits in v1.5–1.6 umgesetzt (technisch):**

| Änderung | Dateien / Bereich |
|----------|-------------------|
| Phase 0–2: Flutter-Setup, Auth, Supabase-Migrationen 00000–00003 | `lib/`, `supabase/migrations/` |
| Phase 3–5: Matching, Sichtbarkeit, Discover, Filter, B2B | `00004`, `00006`, `lib/features/discovery/` |
| Phase 4: Chat Realtime | `00005`, `lib/features/chat/` |
| Phase 6: Profil + Event-Galerie | `00007`, `lib/features/profile/`, `lib/features/gallery/` |
| Mock-GPS / Berlin-Fallback | `lib/core/location/location_service.dart`, `USE_MOCK_LOCATION` |
| Trigger-Fix Aktivität erstellen | `add_host_as_participant` → `AFTER INSERT` in `00004` |
| Idempotente Migrationen | `00001`–`00004` (`IF NOT EXISTS`, `DROP POLICY IF EXISTS`) |
| PostGIS-Fix | `search_path = public, extensions` in Geo-RPCs |
| Demo-Testdaten | `supabase/seed_demo_data.sql` |
| Entwickler-Handbuch & Troubleshooting | `APP_DOCUMENTATION.md` §8, `supabase/README.md` |

### v1.5 – Phase 6 Profile & Galerie

- Profil-Ansicht/-Bearbeitung, Interessen, Avatar-Upload
- Post-Event-Galerie mit Upload-Berechtigung (DB-enforced)
- Routen: `/profile/:id`, `/gallery`, `/activity/:id/gallery`

### v1.4 – Phase 5 B2B & Filter

- `location_type`, `weather_condition`, gesponserte Aktivitäten
- `DiscoverFilterBar`, Featured-Ranking

### v1.0 – Initial

- Flutter-Projekt, Clean Architecture, Riverpod, go_router
- Supabase-Schema: profiles, activities, connections

---

*Dokumentation erstellt am: 08.07.2026*
*Version: 2.4 – Web UI Phase 2, externe Event-Aggregation*
