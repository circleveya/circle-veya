-- ============================================================
-- System-Host für externe Events: circle_events
-- ============================================================
--
-- Voraussetzung: Auth-User im Supabase Dashboard anlegen
--   Authentication → Users → Add user
--   E-Mail z. B.: circle-events@circle.app (Passwort nach Bedarf)
--
-- Dann die User-UUID unten eintragen und dieses Skript ausführen.
-- ============================================================

-- UUID des Auth-Users hier einsetzen:
-- SELECT id, email FROM auth.users WHERE email = 'circle-events@circle.app';

INSERT INTO public.profiles (
    id,
    username,
    user_type,
    bio,
    avatar_url
)
VALUES (
    '00000000-0000-0000-0000-000000000000',  -- ← HIER UUID ERSETZEN
    'circle_events',
    'company',
    'Automatisch aggregierte Events aus Eventbrite, Ticketmaster und weiteren Quellen.',
    NULL
)
ON CONFLICT (id) DO UPDATE SET
    username = EXCLUDED.username,
    user_type = EXCLUDED.user_type,
    bio = EXCLUDED.bio;

-- Prüfen:
SELECT public.get_external_events_host_id() AS host_id;
