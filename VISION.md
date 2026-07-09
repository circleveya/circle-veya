# Circle – Produktvision (Kurzfassung)

> **Was möchtest du heute erleben?**

Circle verbindet Menschen über **gemeinsame Aktivitäten** — nicht über oberflächliche Profile.

## Drei Schritte

1. **Aktivität wählen** — Joggen, Kaffee, Gaming, Wandern …
2. **Passende Menschen finden** — Freunde, Bekannte, Neue in deiner Nähe
3. **Erlebnis teilen** — Treffen, Chat, Erinnerungen (Fotos)

## MVP vs. Vision

| Vision | MVP-Status |
|--------|------------|
| Activity Marketplace | ✅ Entdecken + Erstellen |
| Drei soziale Kreise | ✅ Freunde / Bekannte / Fremde |
| Chat | ✅ Gruppe + DM |
| Profile | ✅ Bio, Interessen, Avatar |
| Memory / Galerie | 🔄 Post-Event-Fotos |
| Circle Gruppen | ⬜ Geplant |
| Freunde finden & hinzufügen | ✅ Tab „Freunde“ |
| Challenges | ⬜ Geplant |
| Premium / IAP | ⬜ Geplant |
| Bewertungen | ⬜ Geplant |
| **Web-App UI (3-Spalten)** | ⬜ Geplant → [`WEB_UI_STRATEGIE.md`](WEB_UI_STRATEGIE.md) |
| **Stock-Bilder / Externe Events** | ⬜ Architektur definiert → [`WEB_UI_STRATEGIE.md`](WEB_UI_STRATEGIE.md) §5 |

## Technik

- **App:** Flutter (iOS, Android, Web-Dev)
- **Backend:** Supabase (PostgreSQL, Auth, Realtime, Storage)
- **Vollständige Doku:** [`APP_DOCUMENTATION.md`](../APP_DOCUMENTATION.md)
- **Supabase-Setup:** [`supabase/README.md`](README.md)

## Demo-Daten testen

```sql
SELECT public.seed_demo_data('DEINE-USER-UUID');
```

## App starten

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=dein-key \
  --dart-define=USE_MOCK_LOCATION=true
```
