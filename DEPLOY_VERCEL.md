# Vercel Auto-Deploy – Circle Flutter Web

## So funktioniert der Flow

```
Du änderst Code lokal → git push → GitHub → Vercel baut neu → Live-URL aktualisiert
```

Jeder Push auf `main` (oder deinen Production-Branch) löst automatisch einen neuen Build aus.

---

## Einmalige Einrichtung

### 1. Projekt auf GitHub pushen

Falls noch nicht geschehen:

```bash
cd c:\Users\kevin\Circle
git add .
git commit -m "Vercel Deploy Setup"
git remote set-url origin https://github.com/DEIN_USER/DEIN_REPO.git
git push -u origin main
```

### 2. Vercel mit GitHub verbinden

1. [vercel.com](https://vercel.com) → Login mit GitHub
2. **Add New → Project**
3. Repository **Circle** auswählen → **Import**
4. Framework Preset: **Other** (wird über `vercel.json` gesteuert)

### 3. Umgebungsvariablen in Vercel setzen

**Settings → Environment Variables** (für Production, Preview, Development):

| Name | Wert |
|------|------|
| `SUPABASE_URL` | `https://unvmyeqvhnmhlkxtkjgo.supabase.co` |
| `SUPABASE_ANON_KEY` | dein Anon-Key |
| `USE_MOCK_LOCATION` | `true` |

> Der Anon-Key ist öffentlich im Client sichtbar – das ist bei Supabase normal.  
> **Niemals** den Service-Role-Key hier eintragen.

### 4. Deploy starten

**Deploy** klicken. Der erste Build dauert ca. 5–10 Minuten (Flutter wird im Build installiert).

Danach erhältst du eine URL wie: `https://circle-xyz.vercel.app`

---

## Automatische Updates

| Aktion | Ergebnis |
|--------|----------|
| `git push` auf `main` | **Production**-Deploy (deine Haupt-URL) |
| `git push` auf anderen Branch | **Preview**-URL (zum Testen vor Merge) |
| Pull Request | Vercel kommentiert Preview-Link im PR |

Du musst nichts manuell in Vercel hochladen – nur pushen.

---

## Lokaler Workflow

```bash
# Entwickeln (wie bisher)
flutter run -d chrome --dart-define-from-file=dart_define.local.json

# Wenn fertig → online bringen
git add .
git commit -m "Beschreibung der Änderung"
git push
```

Nach 5–10 Minuten ist die Vercel-Seite aktualisiert.

---

## Supabase für Production-Web

Im Supabase Dashboard → **Authentication → URL Configuration**:

| Feld | Wert |
|------|------|
| Site URL | `https://dein-projekt.vercel.app` |
| Redirect URLs | `https://dein-projekt.vercel.app/**` |

Sonst schlägt Login/E-Mail-Redirect auf der Live-Seite fehl.

---

## Dateien im Repo

| Datei | Zweck |
|-------|-------|
| `vercel.json` | Build-Befehl, Output `build/web`, SPA-Routing |
| `scripts/vercel-build.sh` | Flutter installieren (non-root) + Web-Build mit `dart_define.json` |

---

## Troubleshooting

| Problem | Lösung |
|---------|--------|
| Build: `SUPABASE_URL` fehlt | Env-Vars in Vercel prüfen |
| Login funktioniert nicht live | Supabase Redirect-URLs anpassen |
| 404 bei Deep-Links | `vercel.json` Rewrites sind gesetzt (SPA) |
| Build timeout | Erneut deployen; ggf. Vercel Pro für längere Builds |

Build-Logs: Vercel Dashboard → Deployments → fehlgeschlagenen Deploy anklicken.
